#import "OFWebServerResponse.h"

@interface OFWebServerDataResponse : OFWebServerResponse
{
	OFDataArray* _data;
}

@property (nonatomic, copy) OFDataArray *data;


+ (instancetype)responseWithData:(OFDataArray*)data contentType:(OFString*)type;
- (instancetype)initWithData:(OFDataArray*)data contentType:(OFString*)type;

+ (instancetype)responseWithText:(OFString*)text;
+ (instancetype)responseWithHTML:(OFString*)html;
+ (instancetype)responseWithHTMLTemplate:(OFString*)path variables:(OFDictionary*)variables;
- (instancetype)initWithText:(OFString*)text;  // Encodes using UTF-8
- (instancetype)initWithHTML:(OFString*)html;  // Encodes using UTF-8
- (instancetype)initWithHTMLTemplate:(OFString*)path variables:(OFDictionary*)variables;  // Simple template system that replaces all occurences of "%variable%" with corresponding value (encodes using UTF-8)

@end