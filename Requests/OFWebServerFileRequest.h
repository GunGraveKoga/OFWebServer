#import "OFWebServerRequest.h"

@interface OFWebServerFileRequest : OFWebServerRequest

@property(nonatomic, copy, readonly) OFString *filePath;

@end