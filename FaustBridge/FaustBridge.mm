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

+ (FaustDSPObject *)dspObjectWithPath:(NSString *)path error:(NSString **)err {
    std::string error_msg {};

    NSString *tempRoot = NSTemporaryDirectory();
    NSString *outputDir = [tempRoot stringByAppendingPathComponent:@"faust_svg_output"];
    const char *outputDirCStr = [outputDir UTF8String];
    const char *argv[] = {
        "-svg", "--output-dir", outputDirCStr
    };
    int argc = 3;

    auto dspFactory = createDSPFactoryFromFile(path.UTF8String, argc, argv, "", error_msg);

    if (!dspFactory) {
        if (!error_msg.size()) {
            error_msg = "factory failed";
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
    NSString *outputDir = [tempRoot stringByAppendingPathComponent:@"faust_svg_output"];

    NSString *dspFileName = [[[_dspPath lastPathComponent] stringByDeletingPathExtension] stringByAppendingString:@"-svg"];
    NSString *outputFileDir = [[tempRoot stringByAppendingPathComponent:@"faust_svg_output"] stringByAppendingPathComponent:dspFileName];

    [[NSFileManager defaultManager] createDirectoryAtPath:outputDir
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];

    if (!_DSP || !_jsonUI) {
        return [NSString stringWithUTF8String:_generateSVGText("FaustDSPObject SVG Error").c_str()];
    }

    // SVG File
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:outputFileDir error:nil];

    for (NSString *file in contents) {
        if ([[file pathExtension] isEqualToString:@"svg"]) {
            NSString *fullPath = [outputFileDir stringByAppendingPathComponent:file];
            NSError *error = nil;
            NSString *fileContents = [NSString stringWithContentsOfFile:fullPath
                                                               encoding:NSUTF8StringEncoding
                                                                  error:&error];

            if (error) {
                [NSString stringWithUTF8String:_generateSVGText(error.localizedDescription.UTF8String).c_str()];
            } else {
                return fileContents;
            }
        }
    }

    return [NSString stringWithUTF8String:_generateSVGText("Unknown error").c_str()];
}

- (void)processAudio:(float *)input output:(float *)output frames:(int)frames {
    // temporary fix:
//    if (inputCount != 2 || outputCount != 2)
//        return;
    
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

@end
