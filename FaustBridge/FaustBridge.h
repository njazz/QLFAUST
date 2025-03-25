#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

#pragma mark -

@protocol FaustDSPObjectProtocol

- (void)setParameter:(NSString *)path value:(float)value;
- (float)getParameter:(NSString *)path;

- (NSArray<NSString *> *)getParameterNames;

- (NSString *)getUIJSON;
- (NSString *)getSVG;

- (void)processAudio:(float *)input output:(float *)output frames:(int)frames;
@end

struct llvm_dsp_factory;

#pragma mark -
@interface FaustDSPObject : NSObject <FaustDSPObjectProtocol>

- (id)initWithDSPFactory:(struct llvm_dsp_factory *)factory path:(NSString *)path;

+ (FaustDSPObject *)dspObjectWithPath:(NSString *)path error:(NSString **)err;

@end

#ifdef __cplusplus
}
#endif
