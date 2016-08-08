#import "OFWebServerResponse.h"

@interface OFWebServerFileResponse : OFWebServerResponse


+ (instancetype)responseWithFile:(OFString*)path;
+ (instancetype)responseWithFile:(OFString*)path isAttachment:(BOOL)attachment;
- (instancetype)initWithFile:(OFString*)path;
- (instancetype)initWithFile:(OFString*)path isAttachment:(BOOL)attachment;
@end