#import "FaustBridge.h"

#include <string>
#include <vector>
#include <memory>
#include <map>

#include "faust/dsp/dsp.h"
#include "faust/dsp/llvm-dsp.h"
#include "faust/dsp/libfaust.h"
#include "faust/gui/MapUI.h"
#include "faust/gui/JSONUI.h"
#include "faust/audio/coreaudio-dsp.h"

struct FaustBridgeData {
    llvm_dsp_factory* fFactory {nullptr};
    dsp* fDSP {nullptr};
    MapUI fUI {};
    JSONUI jsonUI{};
};

// Global instance (singleton for simplicity)
static FaustBridgeData gFaustData;

void Faust_Destroy();
NSString* Faust_Init(const char* dspPath) {
    if (gFaustData.fDSP)
        Faust_Destroy();
        
        // return @"already initialized"; // Already initialized

    std::string error_msg {};
    gFaustData.fFactory = createDSPFactoryFromFile(dspPath, 0, nullptr, "", error_msg);
    
    if (gFaustData.fFactory) {
        gFaustData.fDSP = gFaustData.fFactory->createDSPInstance();
        gFaustData.fDSP->buildUserInterface(&gFaustData.fUI);
        gFaustData.fDSP->init(44100); // fixed sample rate
    } else {
        gFaustData.fDSP = nullptr;
        if (!error_msg.size())
            error_msg = "factory failed";
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

void Faust_SetParam(const char* path, float value) {
    if (gFaustData.fDSP) {
        gFaustData.fUI.setParamValue(path, value);
    }
}

float Faust_GetParam(const char* path) {
    if (gFaustData.fDSP) {
        return gFaustData.fUI.getParamValue(path);
    }
    return 0.0f;
}

NSArray<NSString*>* Faust_GetParams() {
    if (!gFaustData.fDSP) return @[];

    auto map = gFaustData.fUI.getFullpathMap();
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:map.size()];
    for (auto& e : map) {
        [result addObject:[NSString stringWithUTF8String:e.first.c_str()]];
    }
    return result;
    
    
}

NSString* Faust_GetUIJSON() {
    if (!gFaustData.fDSP) return @"[]";

    // Create a new JSONUI with the same number of inputs and outputs as the DSP
    JSONUI jsonUI(gFaustData.fDSP->getNumInputs(), gFaustData.fDSP->getNumOutputs());

    // Build UI
    gFaustData.fDSP->buildUserInterface(&jsonUI);

    // Get the JSON string
    static std::string jsonString = jsonUI.JSON();

    return [NSString stringWithUTF8String:jsonString.c_str()]; // Return as C-string
}

std::string _generateSVGText(const std::string& text) {
    const int fontSize = 24;
    const int x = 10;
    const int y = 30;
    
    return "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"500\" height=\"100\">\n"
           "    <text x=\"" + std::to_string(x) + "\" y=\"" + std::to_string(y) + "\" font-size=\"" + std::to_string(fontSize) + "\" font-family=\"Arial\" fill=\"black\">"
           + text + "</text>\n"
           "</svg>";
}

NSString* Faust_GenerateSVG(const char* dspPath) {
    static std::string svgFilePath;

    // Temporary directory
    NSString* tempRoot = NSTemporaryDirectory();
    NSString* outputDir = [tempRoot stringByAppendingPathComponent:@"faust_svg_output"];
    
    NSString* dspFileName = [[[[NSString stringWithCString:dspPath encoding:NSUTF8StringEncoding] lastPathComponent] stringByDeletingPathExtension] stringByAppendingString:@"-svg"];
    NSString* outputFileDir = [[tempRoot stringByAppendingPathComponent:@"faust_svg_output"] stringByAppendingPathComponent:dspFileName];
    
    // Create output dir if needed
    [[NSFileManager defaultManager] createDirectoryAtPath:outputDir
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];

   
    
    // Convert outputDir to C-string
    const char* outputDirCStr = [outputDir UTF8String];
    
    // Prepare args like: ["-svg", "-output", outputDir]
    const char* argv[] = { "-svg", "--output-dir", outputDirCStr};
    int argc = 3;

    std::string error_msg;
//    bool ok = generateAuxFilesFromFile(dspPath, argc, argv, error_msg);
    
    auto dspFactory = createDSPFactoryFromFile(dspPath, argc, argv, "", error_msg);
    bool ok = dspFactory != nullptr;
    deleteDSPFactory(dspFactory);
    
//
//    if (dspFactory)
//        delete dspFactory;
    
//    return [NSString stringWithUTF8String:_generateSVGText(outputDirCStr).c_str()];

    if (!ok) {
//        NSLog(@"Faust SVG generation failed: %s", error_msg.c_str());
        return [NSString stringWithUTF8String:_generateSVGText(error_msg).c_str()];
    }
    
    // Look for .svg file in outputDir
    NSArray* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:outputFileDir error:nil];
    for (NSString* file in contents) {
        if ([[file pathExtension] isEqualToString:@"svg"]) {
            NSString* fullPath = [outputFileDir stringByAppendingPathComponent:file];
//            svgFilePath = [fullPath UTF8String];
//            return [NSString stringWithUTF8String:svgFilePath.c_str()];
            NSError *error = nil;
            NSString *fileContents = [NSString stringWithContentsOfFile:fullPath
                                                              encoding:NSUTF8StringEncoding
                                                                 error:&error];

            if (error) {
                //NSLog(@"Error reading file: %@", error.localizedDescription);
                [NSString stringWithUTF8String:_generateSVGText(error.localizedDescription.UTF8String).c_str()];
            } else {
                // Successfully read the contents of the file
                // NSLog(@"File contents: %@", fileContents);
                return fileContents;
            }
        }
    }

    return [NSString stringWithUTF8String:_generateSVGText("Unknown error").c_str()];
}

void Faust_Compute(float* input, float* output, int bufferSize) {
    if (!gFaustData.fDSP) return;
    float* inputs[] = { input };
    float* outputs[] = { output };
    gFaustData.fDSP->compute(bufferSize, inputs, outputs);
}

void Faust_TestAudioCompute() {
    if (!gFaustData.fDSP) return;
    const int N = 512;
    float in[N] = {0};
    float out[N];
    gFaustData.fDSP->compute(N, (float*[]){ in }, (float*[]){ out });
}

