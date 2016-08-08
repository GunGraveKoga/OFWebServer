#import "OFWebServerRequest.h"
#import "OFWebServerDataRequest.h"

@interface OFWebServerURLEncodedFormRequest : OFWebServerDataRequest

@property(nonatomic, copy, readonly) OFDictionary* arguments;

+ (OFString *)mimeType;

@end