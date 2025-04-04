#import "FaustBridge.h"

#include <map>
#include <memory>
#include <string>
#include <vector>

#include "faust/audio/coreaudio-dsp.h"
#include "faust/dsp/dsp.h"
#include "faust/dsp/libfaust.h"
#include "faust/dsp/llvm-dsp.h"
#include "faust/gui/JSONUI.h"
#include "faust/gui/MapUI.h"

std::string _generateSVGText(const std::string& text) {
    const int fontSize = 24;
    const int x = 10;
    const int y = 30;

    return "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"500\" height=\"100\">\n"
           "    <text x=\"" + std::to_string(x) + "\" y=\"" + std::to_string(y) + "\" font-size=\"" + std::to_string(fontSize) + "\" font-family=\"Arial\" fill=\"black\">"
           + text + "</text>\n"
           "</svg>";
}

// MARK: -

//struct FaustDSPObjectImplementation {
//    llvm_dsp_factory *_dspFactory ;
//    dsp *_DSP ;
//    MapUI _UI ;
//    JSONUI _jsonUI ;
//};

@implementation FaustDSPObject{
//    struct FaustDSPObjectImplementation _impl;

    llvm_dsp_factory *_dspFactory;
    dsp *_DSP;
    MapUI _UI;
    JSONUI *_jsonUI;

    NSString *_dspPath;
    
    size_t magicNumber ;
    
    uint inputCount;
    uint outputCount;
}

- (id)initWithDSPFactory:(llvm_dsp_factory *)factory path:(NSString *)path {
    self = [super init];

    if (self) {
        _dspFactory = factory;

        _DSP = _dspFactory->createDSPInstance();
        _DSP->buildUserInterface(&_UI);
        _DSP->init(44100); // fixed sample rate

        // JSON UI
        _jsonUI = new JSONUI(_DSP->getNumInputs(), _DSP->getNumOutputs());
        _DSP->buildUserInterface(_jsonUI);

        _dspPath = path;
        
        magicNumber = 0xCAFECAFE;
        
        inputCount = _DSP->getNumInputs();
        outputCount = _DSP->getNumOutputs();
    }

    return self;
}

- (void)dealloc {
    if (_jsonUI) {
        delete _jsonUI;
        _jsonUI = nullptr;
    }

    if (_DSP) {
        delete _DSP;
        _DSP = nullptr;
    }

    if (_dspFactory) {
        deleteDSPFactory(_dspFactory);
        _dspFactory = nullptr;
    }
}

//void accessLibFilesInSameFolder(NSString *path) {
//    // Get the directory of the provided file
//    NSString *directoryPath = [path stringByDeletingLastPathComponent];
//    
//    // Create a file coordinator
//    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
//    
//    // Define an error pointer
//    NSError *error = nil;
//
//    // Coordinate a reading operation on the directory
//    [fileCoordinator coordinateReadingItemAtURL:[NSURL fileURLWithPath:directoryPath]
//                                        options:0
//                                          error:&error
//                                     byAccessor:^(NSURL *directoryURL) {
//        // List all files in the directory
//        NSFileManager *fileManager = [NSFileManager defaultManager];
//        NSArray<NSString *> *fileList = [fileManager contentsOfDirectoryAtPath:directoryPath error:nil];
//        
//        // Filter for ".lib" files
//        for (NSString *file in fileList) {
//            if ([file.pathExtension isEqualToString:@"lib"]) {
//                NSString *fullFilePath = [directoryPath stringByAppendingPathComponent:file];
//                NSURL *fileURL = [NSURL fileURLWithPath:fullFilePath];
//
//                // Now, you have access to each ".lib" file in the same folder
//                NSLog(@"Found .lib file: %@", fileURL.path);
//                
//                // Read the file safely (Example: reading contents)
//                NSError *readError = nil;
//                NSString *fileContents = [NSString stringWithContentsOfFile:fileURL.path encoding:NSUTF8StringEncoding error:&readError];
//
//                if (fileContents) {
//                    NSLog(@"Contents of %@: %@", fileURL.lastPathComponent, fileContents);
//                } else {
//                    NSLog(@"Failed to read file: %@, Error: %@", fileURL.lastPathComponent, readError.localizedDescription);
//                }
//            }
//        }
//    }];
//    
//    // Handle any error from coordination
//    if (error) {
//        NSLog(@"Error coordinating access: %@", error.localizedDescription);
//    }
//}

bool accessLibFilesInSameFolder(NSString *path) {
    NSURL *fileURL = [NSURL fileURLWithPath:path];

    // Get directory URL
    NSURL *directoryURL = [fileURL URLByDeletingLastPathComponent];

    // Start accessing the security-scoped resource
    BOOL startedAccessing = [directoryURL startAccessingSecurityScopedResource];
    
    if (!startedAccessing) {
        NSLog(@"Failed to gain security access to directory: %@", directoryURL);
        return false;
    }

    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    NSError *error = nil;
    
    // Coordinate access to the directory
    [fileCoordinator coordinateReadingItemAtURL:directoryURL
                                        options:0
                                          error:&error
                                     byAccessor:^(NSURL *newURL) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray<NSURL *> *fileList = [fileManager contentsOfDirectoryAtURL:newURL
                                                   includingPropertiesForKeys:nil
                                                                      options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                        error:nil];

        for (NSURL *file in fileList) {
            if ([file.pathExtension isEqualToString:@"lib"]) {
                NSLog(@"Found .lib file: %@", file.path);

                NSError *readError = nil;
                NSString *fileContents = [NSString stringWithContentsOfURL:file encoding:NSUTF8StringEncoding error:&readError];

                if (fileContents) {
                    NSLog(@"Contents of %@: %@", file.lastPathComponent, fileContents);
                } else {
                    NSLog(@"Failed to read file: %@, Error: %@", file.lastPathComponent, readError.localizedDescription);
                }
            }
        }
    }];

    // Stop accessing the security-scoped resource
    [directoryURL stopAccessingSecurityScopedResource];

    if (error) {
        NSLog(@"Error accessing directory: %@", error.localizedDescription);
        return false;
    }
    
    return true;
}

+ (FaustDSPObject *)dspObjectWithPath:(NSString *)path error:(NSString **)err {
    std::string error_msg {};

    NSString *tempRoot = NSTemporaryDirectory();
    NSString *outputDir = [tempRoot stringByAppendingPathComponent:@"faust_svg_output"];
    
    
    
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];

        if ([fileManager fileExistsAtPath:outputDir]) {
            NSError *removeError = nil;
            [fileManager removeItemAtPath:outputDir error:&removeError];
            if (removeError) {
                NSLog(@"Error deleting directory: %@", removeError.localizedDescription);
            }
        }

        NSError *createError = nil;
        [fileManager createDirectoryAtPath:outputDir
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:&createError];

        if (createError) {
            NSLog(@"Error creating directory: %@", createError.localizedDescription);
            *err = [createError localizedDescription];
            return nil;
        }
    }
           
    NSString* libraryPath = [[NSBundle mainBundle] pathForResource:[NSString stringWithUTF8String:"faustlibraries"] ofType:nil];
    NSString *directoryPath = [path stringByDeletingLastPathComponent];
    
    const char *outputDirCStr = [outputDir UTF8String];
    
    std::vector<const char*> args { "-svg", "--output-dir", outputDirCStr };
    
    if (libraryPath){
        args.push_back("--import-dir");
        args.push_back(libraryPath.UTF8String);
    }
    
    auto hasDirectoryAccess = accessLibFilesInSameFolder(path);
    if (hasDirectoryAccess){
        args.push_back("--import-dir");
        args.push_back(directoryPath.UTF8String);
    }
    
    auto dspFactory = createDSPFactoryFromFile(path.UTF8String, (int)args.size(), args.data(), "", error_msg);

    if (!dspFactory) {
        if (!error_msg.size()) {
            error_msg = "createDSPFactoryFromFile() failed\nfile: '"+std::string(path.UTF8String)+"'";
        }

        *err =  [NSString stringWithUTF8String:error_msg.c_str()];
        return nil;
    }

    return [[FaustDSPObject alloc] initWithDSPFactory:dspFactory path:path];
}

- (void)setParameter:(NSString *)path value:(float)value {
    if (_DSP) {
        _UI.setParamValue(path.UTF8String, value);
    }
}

- (float)getParameter:(NSString *)path {
    if (_DSP) {
        return _UI.getParamValue(path.UTF8String);
    }

    return 0.0f;
}

- (NSArray<NSString *> *)getParameterNames {
    if (!_DSP) {
        return @[];
    }

    auto map = _UI.getFullpathMap();
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:map.size()];

    for (auto& e : map) {
        [result addObject:[NSString stringWithUTF8String:e.first.c_str()]];
    }

    return result;
}

- (NSString *)getUIJSON {
    if (!_DSP || !_jsonUI) {
        return @"[]";
    }

    std::string jsonString = _jsonUI->JSON();
    return [NSString stringWithUTF8String:jsonString.c_str()]; // Return as C-string
}

- (NSString *)getSVG {
    // Temporary directory
    NSString *tempRoot = NSTemporaryDirectory();

    NSString *dspFileName = [[[_dspPath lastPathComponent] stringByDeletingPathExtension] stringByAppendingString:@"-svg"];
    NSString *outputFileDir = [[tempRoot stringByAppendingPathComponent:@"faust_svg_output"] stringByAppendingPathComponent:dspFileName];

    

    if (!_DSP || !_jsonUI) {
        return [NSString stringWithUTF8String:_generateSVGText("FaustDSPObject SVG Error").c_str()];
    }

    // SVG File
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:outputFileDir error:nil];

//    for (NSString *file in contents) {
//        if ([[file pathExtension] isEqualToString:@"svg"])
//        {
            NSString *fullPath = [outputFileDir stringByAppendingPathComponent:@"process.svg"];
            NSError *error = nil;
            NSString *fileContents = [NSString stringWithContentsOfFile:fullPath
                                                               encoding:NSUTF8StringEncoding
                                                                  error:&error];

            if (error) {
                [NSString stringWithUTF8String:_generateSVGText(error.localizedDescription.UTF8String).c_str()];
            } else {
                return fileContents;
            }
//        }
//    }

    return [NSString stringWithUTF8String:_generateSVGText("Unknown error").c_str()];
}

- (void)processAudio:(float *)input output:(float *)output frames:(int)frames {    
    if (_DSP) {
        _DSP->compute(frames, &input, &output);
    }
}

-(int) getInputsCount {
    return inputCount;
}
-(int) getOutputsCount{
    return outputCount;
}

+(NSString*)libFAUSTVersion{
    return [NSString stringWithCString:getCLibFaustVersion() encoding:NSUTF8StringEncoding];
}

@end
