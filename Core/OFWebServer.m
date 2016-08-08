#import <ObjFW/ObjFW.h>
#import "OFWebServer.h"
#import "OFWebServerConnection.h"
#import "OFWebServerRequest.h"
#import "OFWebServerResponse.h"
#import "OFWebServerDataRequest.h"
#import "OFWebServerFileRequest.h"
#import "OFWebServerMultiPartFormRequest.h"
#import "OFWebServerURLEncodedFormRequest.h"
#import "OFWebServerDataResponse.h"
#import "OFWebServerErrorResponse.h"
#import "OFWebServerFileResponse.h"
#import "OFWebServerStreamedResponse.h"
#import "OFDataArray+Search.h"
#import "OFWebServerFunctions.h"


static Class __of_web_connection_class = Nil;

static OFThreadPool* __connectionsPool = nil;

@interface OFWebServer()

@property(nonatomic, copy, readwrite) OFArray* handlers;
@property(nonatomic, assign) OFMutableArray* connections;

+ (Class)connectionClass;

- (OFWebServerResponse*)_responseWithContentsOfFile:(OFString*)path;
- (OFWebServerResponse*)_responseWithContentsOfDirectory:(OFString*)path basePath:(OFString *)basePath;
- (void)_performRequest:(OFHTTPRequest *)request response:(OFHTTPResponse *)response;


@end

@interface OFWebServerHandler()

@property(nonatomic, copy, readwrite)OFWebServerMatchBlock matchBlock;
@property(nonatomic, copy, readwrite)OFWebServerProcessBlock processBlock;

@end

@implementation OFWebServerHandler

- (instancetype)initWithMatchBlock:(OFWebServerMatchBlock)matchBlock processBlock:(OFWebServerProcessBlock)processBlock
{
	self = [super init];

	self.matchBlock = matchBlock;
	self.processBlock = processBlock;

	return self;
}

@end

@implementation OFWebServer {
	OFMutableArray* _connections;
}

@dynamic handlers;
@synthesize connections = _connections;

+ (void)initialize
{
	__of_web_connection_class = [OFWebServerConnection class];

	__connectionsPool = [[OFThreadPool alloc] init];
}

+ (Class)connectionClass
{
	return __of_web_connection_class;
}

- (instancetype)init
{
	self = [super init];

	_handlers = [OFMutableArray new];
	self.connections = [OFMutableArray new];

	return self;
}

- (void)start
{
	self.delegate = self;

	[super start];
}

- (void)dealloc
{
	[_handlers release];

	[super dealloc];
}

- (OFArray *)handlers
{
	return [[_handlers copy] autorelease];
}

- (void)setHandlers:(OFArray *)handlers
{
	_handlers = [handlers mutableCopy];
}

- (void)addHandlerWithMatchBlock:(OFWebServerMatchBlock)matchBlock processBlock:(OFWebServerProcessBlock)processBlock
{
	OFWebServerHandler* handler = [[OFWebServerHandler alloc] initWithMatchBlock:matchBlock processBlock:processBlock];

	[_handlers insertObject:handler atIndex:0];
}

- (OFWebServerResponse*)_responseWithContentsOfFile:(OFString*)path
{
	return [OFWebServerFileResponse responseWithFile:path];
}

- (OFWebServerResponse*)_responseWithContentsOfDirectory:(OFString*)path basePath:(OFString *)basePath
{
	OFMutableString* html = [OFMutableString string];

	[html appendString:@"<html><body>\n"
					   @"<ul>\n"];

	OFFileManager* fm = [OFFileManager defaultManager];

	for (OFString* element in [fm contentsOfDirectoryAtPath:path]) {
		@autoreleasepool {
			if (![element hasPrefix:@"."]) {
				OFString* relativePath = [[path substringWithRange:of_range(basePath.length, path.length - basePath.length)] stringByStandardizingURLPath];
				if ([relativePath hasPrefix:@"/"])
					relativePath = [relativePath substringWithRange:of_range(1, relativePath.length - 1)];

				OFString* escapedPath = [[relativePath stringByAppendingFormat:@"/%@", element] stringByURLEncodingWithIgnoredCharacters:"/"];
				
				[html appendFormat:@"<li><a href=\"%@\">%@</a></li>\n", escapedPath, element];

			}
		}
	}

	[html appendString:@"</ul>\n"
						@"</body></html>\n"];

	[html makeImmutable];

	return [OFWebServerDataResponse responseWithHTML:html];
}

- (void)addDefaultHandlerForMethod:(OFString*)method requestClass:(Class)class processBlock:(OFWebServerProcessBlock)block
{
	SEL baseSel = _cmd;

	[self addHandlerWithMatchBlock:^OFWebServerRequest *(OFString* requestMethod, OFURL* requestURL, OFDictionary* requestHeaders, OFString* urlPath, OFDictionary* urlQuery) {
		
		of_log(@"Method: %s", sel_getName(baseSel));
		of_log(@"Request [%@:]%@", requestMethod, requestURL.string);
		of_log(@"Path %@", urlPath);
		of_log(@"Query %@", urlQuery);
		of_log(@"Headers \n%@", requestHeaders);

		return [[[class alloc] initWithMethod:requestMethod URL:requestURL headers:requestHeaders path:urlPath query:urlQuery] autorelease];

	} processBlock:block];
}

- (void)addHandlerForBasePath:(OFString*)basePath localPath:(OFString*)localPath indexFilename:(OFString*)indexFilename cacheAge:(size_t)cacheAge
{
	SEL baseSel = _cmd;

	void* voidSelf = (__bridge void*)self;
	__block __typeof__(self) weakSelf = nil;

	if ([basePath hasPrefix:@"/"] && [basePath hasSuffix:@"/"]) {

		[self addHandlerWithMatchBlock:^OFWebServerRequest *(OFString *requestMethod, OFURL *requestURL, OFDictionary *requestHeaders, OFString *urlPath, OFDictionary *urlQuery){

			of_log(@"Method: %s", sel_getName(baseSel));
			of_log(@"Request [%@:]%@", requestMethod, requestURL.string);
			of_log(@"Path %@", urlPath);
			of_log(@"Query %@", urlQuery);
			of_log(@"Headers \n%@", requestHeaders);

			if (![requestMethod isEqual:@"GET"])
				return nil;

			if (![urlPath hasPrefix:basePath])
				return nil;

			return [[[OFWebServerRequest alloc] initWithMethod:requestMethod URL:requestURL headers:requestHeaders path:urlPath query:urlQuery] autorelease];

		} processBlock:^(OFWebServerRequest *request){

			@autoreleasepool {
				OFWebServerResponse* response = nil;
				weakSelf = (__bridge __typeof__(weakSelf))voidSelf;

				OFString* fullPath = [localPath stringByAppendingPathComponent:[request.path substringWithRange:of_range(basePath.length, (request.path.length - basePath.length))]];
				fullPath = [fullPath stringByStandardizingPath];

				OFFileManager* fm = [OFFileManager defaultManager];

				if ([fm directoryExistsAtPath:fullPath]) {
					OFString* indexPath = [fullPath stringByAppendingPathComponent:indexFilename];

					if ([fm fileExistsAtPath:indexPath])
						response = [weakSelf _responseWithContentsOfFile:indexPath];
					else
						response = [weakSelf _responseWithContentsOfDirectory:fullPath basePath:localPath];

				} else if ([fm fileExistsAtPath:fullPath]) {
					response = [weakSelf _responseWithContentsOfFile:fullPath];
				}

				if (response != nil)
					response.cacheControlMaxAge = cacheAge;
				else
					response = [OFWebServerResponse responseWithStatusCode:404];

				[request respondWith:response];
			}

		}];

	} else {
		@throw [OFInvalidArgumentException exception];
	}
}

- (void)addHandlerForMethod:(OFString*)method path:(OFString*)path requestClass:(Class)class processBlock:(OFWebServerProcessBlock)block
{
	SEL baseSel = _cmd;

	if ([path hasPrefix:@"/"] && [class isSubclassOfClass:[OFWebServerRequest class]]) {

		[self addHandlerWithMatchBlock:^OFWebServerRequest *(OFString *requestMethod, OFURL *requestURL, OFDictionary *requestHeaders, OFString *urlPath, OFDictionary *urlQuery){
			of_log(@"Method: %s", sel_getName(baseSel));
			of_log(@"Request [%@:]%@", requestMethod, requestURL.string);
			of_log(@"Path %@", urlPath);
			of_log(@"Query %@", urlQuery);
			of_log(@"Headers \n%@", requestHeaders);

			if (![requestMethod isEqual:method])
				return nil;

			if (![urlPath caseInsensitiveCompare:path] != OF_ORDERED_SAME)
				return nil;

			return [[[class alloc] initWithMethod:requestMethod URL:requestURL headers:requestHeaders path:urlPath query:urlQuery] autorelease];

		} processBlock:block];

	} else {
		@throw [OFInvalidArgumentException exception];
	}
}

- (void)removeAllHandlers
{
	[_handlers removeAllObjects];
}

- (bool)server:(OFHTTPServer *)server didReceiveExceptionOnListeningSocket:(OFException *)exception
{
	of_log(@"Listening exception %@", exception);

	return false;
}

- (void)server:(OFHTTPServer *)server didReceiveRequest:(OFHTTPRequest *)request response:(OFHTTPResponse *)response
{
	void* voidSelf = (__bridge void*)self;
	__block __typeof__(self) weakSelf = nil;


	[__connectionsPool dispatchWithBlock:^{

		of_log(@"Prform action in thread %lu", GetCurrentThreadId());

		weakSelf = (__bridge __typeof__(weakSelf))voidSelf;

		[weakSelf _performRequest:request response:response];

	}];

}

- (void)_performRequest:(OFHTTPRequest *)request response:(OFHTTPResponse *)response
{
	Class connectionClass = [[self class] connectionClass];

	OFWebServerConnection* connection = [[[connectionClass alloc] initWithServer:self request:request response:response] autorelease];

	@synchronized(_connections) {
		[self.connections addObject:connection];

		of_log(@"Accepted connection from %@", request.remoteAddress);
		of_log(@"Created connection %@", connection);
		of_log(@"Total connections: %zu", self.connections.count);
	}

	void* voidConnection = (__bridge void*)connection;
	__block __typeof__(connection) weakConnection = nil;
	void* voidSelf = (__bridge void*)self;
	__block __typeof__(self) weakSelf = nil;

	[connection openWithCompletionHandler:^{
		weakConnection = (__bridge __typeof__(weakConnection))voidConnection;
		weakSelf = (__bridge __typeof__(weakSelf))voidSelf;

		@synchronized(weakSelf->_connections) {
			if (weakConnection != nil) {
				[weakSelf.connections removeObject:weakConnection];

				of_log(@"Closing connection %@", weakConnection);
				of_log(@"Total connections: %zu", weakSelf.connections.count);
			}
		}
	}];
}

- (void)server:(OFHTTPServer *)server didReceiveExceptionForResponse:(OFHTTPResponse *)response request:(OFHTTPRequest *)request exception:(OFException *)exception
{
	of_log(@"Request: \n%@", request);
	of_log(@"Response: \n%@", response);
	of_log(@"Exception: %@", exception);
}

@end