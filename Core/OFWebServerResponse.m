#import <ObjFW/ObjFW.h>
#import "OFWebServerResponse.h"
#import "OFDataArray+Search.h"
#import "OFWebServerMime.h"

@interface OFWebServerResponse()

@property(nonatomic, copy, readwrite) OFString *contentType;
@property(nonatomic, readwrite) size_t contentLength;
@property(nonatomic, readwrite, copy) OFDictionary *additionalHeaders;


@end

@implementation OFWebServerResponse {
	OFMutableDictionary* _additionalHeaders;
}

@dynamic additionalHeaders;
@synthesize contentType = _contentType;
@synthesize contentLength = _contentLength;
@synthesize cacheControlMaxAge = _cacheControlMaxAge;
@synthesize userInfo = _userInfo;

- (void)setAdditionalHeaders:(OFDictionary *)additionalHeaders 
{
	if (_additionalHeaders != nil)
		[_additionalHeaders release];

	_additionalHeaders = nil;
	_additionalHeaders = [additionalHeaders mutableCopy];
}

- (OFDictionary *)additionalHeaders 
{
	return [_additionalHeaders copy];
}

+ (instancetype)response 
{
	return [[[[self class] alloc] init] autorelease];
}

- (instancetype)init
{
	return [self initWithContentType:nil contentLength:0];
}

- (instancetype)initWithContentType:(OFString *)type contentLength:(size_t)length 
{
	self = [super init];

	self.contentType = type;
	self.contentLength = length;
	self.statusCode = 200;
	self.cacheControlMaxAge = 0;
	self.additionalHeaders = @{};

	if ((self.contentLength > 0) && (self.contentType == nil)) {
		self.contentType = @"application/octet-stream";
	}

	return self;
}

- (void)setValue:(OFString *)value forAdditionalHeader:(OFString *)header 
{
	[_additionalHeaders setValue:value forKey:header];
}

- (BOOL)hasBody 
{
	return self.contentType ? YES : NO;
}

- (BOOL)open
{
	[self doesNotRecognizeSelector:_cmd];

	return NO;
}

- (size_t)read:(void *)buffer maxLength:(size_t)length 
{
	[self doesNotRecognizeSelector:_cmd];
	return 0;
}

- (BOOL)close
{
	[self doesNotRecognizeSelector:_cmd];
	return NO;
}

+ (instancetype)responseWithStatusCode:(short)statusCode
{
	return [[[self alloc] initWithStatusCode:statusCode] autorelease];
}

+ (instancetype)responseWithRedirect:(OFURL *)location permanent:(BOOL)permanent 
{
	return [[[self alloc] initWithRedirect:location permanent:permanent] autorelease];
}

- (instancetype)initWithStatusCode:(short)statusCode
{
	self = [self initWithContentType:nil contentLength:0];

	self.statusCode = statusCode;

	return self;
}

- (instancetype)initWithRedirect:(OFURL *)location permanent:(BOOL)permanent 
{
	self = [self initWithContentType:nil contentLength:0];
	self.statusCode = permanent ? 301 : 307;
	[self setValue:location.string forAdditionalHeader:@"Location"];

	return self;
}

- (void)dealloc
{

	[_contentType release];
	[_userInfo release];
	[_additionalHeaders release];

	[super dealloc];
}

@end
