#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

NSString* Faust_Init(const char* path);

void Faust_SetParam(const char* path, float value);
float Faust_GetParam(const char* path);
NSArray<NSString*>* Faust_GetParams(void);

NSString* Faust_GetUIJSON() ;
NSString* Faust_GenerateSVG(const char* dspPath);

void Faust_TestAudioCompute(void);

#ifdef __cplusplus
}
#endif
