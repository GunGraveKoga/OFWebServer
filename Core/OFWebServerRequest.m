#import <ObjFW/ObjFW.h>
#import "OFWebServerRequest.h"
#import "OFWebServerRequest+Private.h"
#import "OFDataArray+Search.h"
#import "OFWebServerFunctions.h"

/*
@interface OFWebServerRequest()

@property(nonatomic, copy, readwrite) OFString* method;
@property(nonatomic, copy, readwrite) OFURL* URL;
@property(nonatomic, copy, readwrite) OFDictionary* headers;
@property(nonatomic, copy, readwrite) OFString* path;
@property(nonatomic, copy, readwrite) OFDictionary* query;
@property(nonatomic, copy, readwrite) OFString* contentType;
@property(nonatomic, readwrite) size_t contentLength;

@end
*/

@implementation OFWebServerRequest

@synthesize method = _method;
@synthesize URL = _URL;
@synthesize headers = _headers;
@synthesize path = _path;
@synthesize query = _query;
@synthesize contentType = _contentType;
@synthesize contentLength = _contentLength;
@synthesize responseBlock = _responseBlock;
				
- (instancetype)initWithMethod:(OFString *)method URL:(OFURL *)url headers:(OFDictionary *)headers path:(OFString *)path query:(OFDictionary *)query
{
	self = [super init];

	self.method = method;
	self.URL = url;
	self.headers = headers;
	self.path = path;
	self.query = query;
	self.contentType = self.headers[@"Content-Type"];
	OFString* contentLengthString = self.headers[@"Content-Length"];
	self.contentLength = (contentLengthString != nil) ? contentLengthString.decimalValue : 0;
	

	if (self.contentLength > 0 && self.contentType == nil)
		self.contentType = @"application/octet-stream";

	return self;
}

- (void)dealloc
{
	[_method release];
	[_URL release];
	[_headers release];
	[_path release];
	[_query release];
	[_contentType release];
	[_responseBlock release];

	[super dealloc];
}

- (BOOL)hasBody
{
	return (self.contentType != nil ? YES : NO);
}

- (void)respondWith:(OFWebServerResponse *)response
{
	self.responseBlock ? self.responseBlock(response) : nil;
}

- (size_t)write:(const void*)buffer maxLength:(size_t)length
{
	[self doesNotRecognizeSelector:_cmd];
	return 0;
}

- (BOOL)open
{
	[self doesNotRecognizeSelector:_cmd];
  	return NO;
}

- (BOOL)close
{
	[self doesNotRecognizeSelector:_cmd];
  	return NO;
}

@end
