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

@implementation FaustDSPObject
{
//    struct FaustDSPObjectImplementation _impl;
    
    llvm_dsp_factory *_dspFactory ;
    dsp *_DSP ;
    MapUI _UI ;
    JSONUI * _jsonUI ;
    
    NSString* _dspPath;
}

-(id)initWithDSPFactory:(llvm_dsp_factory*) factory path:(NSString*) path{
self = [super init];
    if (self){
        _dspFactory = factory;
        
        _DSP = _dspFactory->createDSPInstance();
        _DSP->buildUserInterface(&_UI);
        _DSP->init(44100); // fixed sample rate
        
        // JSON UI
        _jsonUI = new JSONUI(_DSP->getNumInputs(), _DSP->getNumOutputs());
        _DSP->buildUserInterface(_jsonUI);
        
        _dspPath = path;
    }
    return self;
}

-(void)dealloc {
    if (_jsonUI){
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

+(NSObject<FaustDSPObjectProtocol>*) dspObjectWithPath:(NSString*) path{
    std::string error_msg {};
    
    NSString *tempRoot = NSTemporaryDirectory();
    NSString *outputDir = [tempRoot stringByAppendingPathComponent:@"faust_svg_output"];
    const char *outputDirCStr = [outputDir UTF8String];
    const char *argv[] = {
        "-svg", "--output-dir", outputDirCStr
    };
    int argc = 3;
    
    auto dspFactory = createDSPFactoryFromFile(path.UTF8String, argc, argv, "", error_msg);
    
    if (!dspFactory){
       // output error:
        //        if (!error_msg.size()) {
        //            error_msg = "factory failed";
        //        }
        //
        //        return [NSString stringWithUTF8String:error_msg.c_str()];
        return nil;
    }
    
    return [[FaustDSPObject alloc] initWithDSPFactory: dspFactory path:path];
}


-(void) setParameter:(NSString*) path value:(float) value{
    if (_DSP) {
        _UI.setParamValue(path.UTF8String, value);
    }
}
-(float) getParameter:(NSString*) path{
    if (_DSP) {
        _UI.getParamValue(path.UTF8String);
    }

    return 0.0f;
}

-(NSArray<NSString*>*) getParameterNames{
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

-(NSString*) getUIJSON{
    if (!_DSP || !_jsonUI){
        return @"[]";
    }
    
    std::string jsonString = _jsonUI->JSON();
    return [NSString stringWithUTF8String:jsonString.c_str()]; // Return as C-string
}

-(NSString*) getSVG{
    
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

- (void)processAudio:(float*)input output:(float*)output frames:(int)frames {
    if (_DSP)
        _DSP->compute(frames, &input, &output);
}

@end

// MARK: -

struct FaustBridgeData {
    llvm_dsp_factory *fFactory {
        nullptr
    };
    dsp *fDSP {
        nullptr
    };
    MapUI fUI {};
    JSONUI jsonUI {};
};

// Global instance (singleton for simplicity)
static FaustBridgeData gFaustData;

void Faust_Destroy();
NSString * Faust_Init(const char *dspPath) {
    if (gFaustData.fDSP) {
        Faust_Destroy();
    }

    std::string error_msg {};
    gFaustData.fFactory = createDSPFactoryFromFile(dspPath, 0, nullptr, "", error_msg);

    if (gFaustData.fFactory) {
        gFaustData.fDSP = gFaustData.fFactory->createDSPInstance();
        gFaustData.fDSP->buildUserInterface(&gFaustData.fUI);
        gFaustData.fDSP->init(44100); // fixed sample rate
    } else {
        gFaustData.fDSP = nullptr;

        if (!error_msg.size()) {
            error_msg = "factory failed";
        }

        return [NSString stringWithUTF8String:error_msg.c_str()];
    }

    return @"no error";
}

void Faust_Destroy() {
    if (gFaustData.fDSP) {
        delete gFaustData.fDSP;
        gFaustData.fDSP = nullptr;
    }

    if (gFaustData.fFactory) {
        deleteDSPFactory(gFaustData.fFactory);
        gFaustData.fFactory = nullptr;
    }
}

void Faust_SetParam(const char *path, float value) {
    if (gFaustData.fDSP) {
        gFaustData.fUI.setParamValue(path, value);
    }
}

float Faust_GetParam(const char *path) {
    if (gFaustData.fDSP) {
        return gFaustData.fUI.getParamValue(path);
    }

    return 0.0f;
}

NSArray<NSString *> * Faust_GetParams() {
    if (!gFaustData.fDSP) {
        return @[];
    }

    auto map = gFaustData.fUI.getFullpathMap();
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:map.size()];

    for (auto& e : map) {
        [result addObject:[NSString stringWithUTF8String:e.first.c_str()]];
    }

    return result;
}

NSString * Faust_GetUIJSON() {
    if (!gFaustData.fDSP) {
        return @"[]";
    }

    JSONUI jsonUI(gFaustData.fDSP->getNumInputs(), gFaustData.fDSP->getNumOutputs());
    gFaustData.fDSP->buildUserInterface(&jsonUI);
    static std::string jsonString = jsonUI.JSON();

    return [NSString stringWithUTF8String:jsonString.c_str()]; // Return as C-string
}



NSString * Faust_GenerateSVG(const char *dspPath) {
    static std::string svgFilePath;

    // Temporary directory
    NSString *tempRoot = NSTemporaryDirectory();
    NSString *outputDir = [tempRoot stringByAppendingPathComponent:@"faust_svg_output"];

    NSString *dspFileName = [[[[NSString stringWithCString:dspPath encoding:NSUTF8StringEncoding] lastPathComponent] stringByDeletingPathExtension] stringByAppendingString:@"-svg"];
    NSString *outputFileDir = [[tempRoot stringByAppendingPathComponent:@"faust_svg_output"] stringByAppendingPathComponent:dspFileName];

    [[NSFileManager defaultManager] createDirectoryAtPath:outputDir
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];

    const char *outputDirCStr = [outputDir UTF8String];
    const char *argv[] = {
        "-svg", "--output-dir", outputDirCStr
    };
    int argc = 3;
    std::string error_msg;

    auto dspFactory = createDSPFactoryFromFile(dspPath, argc, argv, "", error_msg);
    bool ok = dspFactory != nullptr;
    deleteDSPFactory(dspFactory);

    if (!ok) {
        return [NSString stringWithUTF8String:_generateSVGText(error_msg).c_str()];
    }

    // Look for .svg file in outputDir
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

void Faust_Compute(float *input, float *output, int bufferSize) {
    if (!gFaustData.fDSP) {
        return;
    }

    float *inputs[] = {
        input
    };
    float *outputs[] = {
        output
    };
    gFaustData.fDSP->compute(bufferSize, inputs, outputs);
}

void Faust_TestAudioCompute() {
    if (!gFaustData.fDSP) {
        return;
    }

    const int N = 512;
    float in[N] = {
        0
    };
    float out[N];
    gFaustData.fDSP->compute(N, (float *[]) { in }, (float *[]) { out });
}
