#import <ObjFW/OFObject.h>

@class OFWebServerResponse;
@class OFString;
@class OFDictionary;
@class OFURL;
@class OFDataArray;

typedef void(^OFWebServerResponseBlock)(OFWebServerResponse *response);

@interface OFWebServerRequest: OFObject
{
	OFString* _method;
	OFURL* _URL;
	OFDictionary* _headers;
	OFString* _path;
	OFDictionary* _query;
	OFString* _contentType;
	size_t _contentLength;
	OFWebServerResponseBlock _responseBlock;
}

@property(nonatomic, copy, readonly) OFString* method;
@property(nonatomic, copy, readonly) OFURL* URL;
@property(nonatomic, copy, readonly) OFDictionary* headers;
@property(nonatomic, copy, readonly) OFString* path;
@property(nonatomic, copy, readonly) OFDictionary* query;
@property(nonatomic, copy, readonly) OFString* contentType;
@property(nonatomic, readonly) size_t contentLength;
@property(nonatomic, copy)OFWebServerResponseBlock responseBlock;

- (instancetype)initWithMethod:(OFString *)method URL:(OFURL *)url headers:(OFDictionary *)headers path:(OFString *)path query:(OFDictionary *)query;
- (BOOL)hasBody;
- (void)respondWith:(OFWebServerResponse *)response;
- (BOOL)open;
- (BOOL)close;
- (size_t)write:(const void*)buffer maxLength:(size_t)length;

@end
