#import <ObjFW/OFObject.h>

@class OFDictionary;
@class OFString;
@class OFURL;
@class OFDataArray;

@interface OFWebServerResponse: OFObject
{
	OFString* _contentType;
	size_t _contentLength;
	short _statusCode;
	size_t _cacheControlMaxAge;
	OFDictionary* _userInfo;
}

@property(nonatomic, copy, readonly) OFString* contentType;
@property(nonatomic, readonly) size_t contentLength;
@property(nonatomic, assign, readwrite) short statusCode;
@property(nonatomic) size_t cacheControlMaxAge;
@property(nonatomic, readonly, copy) OFDictionary* additionalHeaders;
@property (nonatomic, copy) OFDictionary* userInfo;

+ (instancetype)response;
- (instancetype)init;
- (instancetype)initWithContentType:(OFString *)type contentLength:(size_t)length;
- (BOOL)hasBody;
- (void)setValue:(OFString*)value forAdditionalHeader:(OFString*)header;
- (BOOL)open;
- (size_t)read:(void *)buffer maxLength:(size_t)length;
- (BOOL)close;

+ (instancetype)responseWithStatusCode:(short)statusCode;
+ (instancetype)responseWithRedirect:(OFURL*)location permanent:(BOOL)permanent;
- (instancetype)initWithStatusCode:(short)statusCode;
- (instancetype)initWithRedirect:(OFURL*)location permanent:(BOOL)permanent;

@end;
