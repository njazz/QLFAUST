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

#pragma mark -

@protocol FaustDSPObjectProtocol

-(void) setParameter:(NSString*) path value:(float) value;
-(float) getParameter:(NSString*) path;

-(NSArray<NSString*>*) getParameterNames;

-(NSString*) getUIJSON;
-(NSString*) getSVG;

- (void)processAudio:(float*)input output:(float*)output frames:(int)frames;
@end

struct llvm_dsp_factory;

#pragma mark -
@interface FaustDSPObject : NSObject <FaustDSPObjectProtocol>

-(id)initWithDSPFactory:(struct llvm_dsp_factory*) factory path:(NSString*)path;

+(NSObject<FaustDSPObjectProtocol>*) dspObjectWithPath:(NSString*) path;

@end

#ifdef __cplusplus
}
#endif
