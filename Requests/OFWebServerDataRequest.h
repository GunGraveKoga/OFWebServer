#import "OFWebServerRequest.h"

@interface OFWebServerDataRequest : OFWebServerRequest

@property(nonatomic, copy, readonly) OFDataArray* data;

@end