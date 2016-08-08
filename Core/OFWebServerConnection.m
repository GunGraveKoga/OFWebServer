#import <ObjFW/ObjFW.h>
#import "OFWebServerConnection.h"
#import "OFWebServer.h"
#import "OFWebServerRequest.h"
#import "OFWebServerResponse.h"

#define kBodyWriteBufferSize (32 * 1024)


@interface OFWebServerConnection()

@property(nonatomic, assign, readwrite)OFWebServer* server;
@property(nonatomic, retain)OFHTTPRequest* requestMessage;
@property(nonatomic, retain)OFHTTPResponse* responseMessage;
@property(nonatomic, assign)OFWebServerRequest* request;
@property(nonatomic, assign)OFWebServerResponse* response;
@property(nonatomic, assign) OFWebServerHandler* handler;
@property(nonatomic, copy)OFWebServerConnectionCompletionHandler completionHandler;


- (void)_readRequest;
- (void)_abortWithStatusCode:(short)code;
- (void)_abortWithStatusCode:(short)code exception:(OFException *)exception info:(OFDictionary *)info;
- (void)_processRequest;
- (size_t)_readAdditionalData;

@end


@implementation OFWebServerConnection {
	
	OFHTTPRequest* _requestMessage;
	OFHTTPResponse* _responseMessage;
	OFWebServerRequest* _request;
	OFWebServerResponse* _response;
	OFWebServerHandler* _handler;
	OFWebServerConnectionCompletionHandler _completionHandler;
}

@synthesize requestMessage = _requestMessage;
@synthesize responseMessage = _responseMessage;
@synthesize server = _server;
@synthesize request = _request;
@synthesize response = _response;
@synthesize handler = _handler;
@synthesize completionHandler = _completionHandler;

- (instancetype)initWithServer:(OFWebServer *)server request:(OFHTTPRequest *)request response:(OFHTTPResponse *)response
{
	self = [super init];

	self.server = server;
	self.requestMessage = request;
	self.responseMessage = response;
	self.request = nil;
	self.response = nil;
	self.handler = nil;
	self.completionHandler = nil;

	return self;
}

- (void)dealloc
{
	[_requestMessage release];
	[_responseMessage release];
	[_completionHandler release];

	[super dealloc];
}

- (size_t)_readAdditionalData
{
	
	Class cls = objc_getClass("OFHTTPServerResponse");

	if (cls == Nil)
		@throw [OFNotImplementedException exceptionWithSelector:_cmd object:self];


	OFIntrospection* ins = [OFIntrospection introspectionWithClass:cls];
	__block OFTCPSocket* socket = nil;

	[ins.instanceVariables enumerateObjectsUsingBlock:^(id object, size_t index, bool *stop){
		OFInstanceVariable* ivar_ = (OFInstanceVariable *)object;

		if (![ivar_.name isEqual:@"_socket"])
			return;

		socket = (__bridge id)*(void **)((__bridge void *)self.requestMessage + ivar_.offset);

		*stop = true;

		return;
	}];

	if (socket == nil)
		@throw [OFNotImplementedException exceptionWithSelector:_cmd object:self];

	[socket writeFormat: @"HTTP/1.1 %d %s\r\n"
			      	   @"Date: %@\r\n"
			      	   @"Server: %@\r\n"
			      	   @"\r\n",
			      	   100, "Continue",
			      	   [[OFDate date] dateStringWithFormat: @"%a, %d %b %Y %H:%M:%S GMT"], _server.name];

	OFDataArray* data = [socket readDataArrayWithItemSize:1 count:self.request.contentLength - self.requestMessage.body.count];

	socket = nil;

	return [self.request write:data.items maxLength:data.count];
}

- (void)_readRequest
{
	@autoreleasepool {
		OFString* requestMethod = @(of_http_request_method_to_string(self.requestMessage.method));

		OFMutableDictionary* query = nil;
		OFString* queryString = self.requestMessage.URL.query;

		if (queryString != nil) {
			query = [OFMutableDictionary dictionary];

			of_range_t pairRange= of_range(0, queryString.length);
			size_t pos = 0;

			while (true) {
				OFString* key = nil;
				OFString* value = nil;

				if ((pairRange = [queryString rangeOfString:@"=" options:0 range:pairRange]).location == OF_NOT_FOUND)
					break;

				key = [queryString substringWithRange:of_range(pos, pairRange.location - pos)];

				pairRange.location += 1;
				pairRange.length = queryString.length - pairRange.location;

				if (pairRange.location == queryString.length)
					break;

				pos = pairRange.location;

				if ((pairRange = [queryString rangeOfString:@"&" options:0 range:pairRange]).location == OF_NOT_FOUND)
					value = [queryString substringWithRange:of_range(pos, queryString.length - pos)];
				else
					value = [queryString substringWithRange:of_range(pos, pairRange.location - pos)];


				key = [[key stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByURLDecoding];
				value = [[value stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByURLDecoding];

				[query setValue:value forKey:key];

				if (pairRange.location == OF_NOT_FOUND)
					break;

				pairRange.location += 1;
				pairRange.length = queryString.length - pairRange.location;

				pos = pairRange.location;
			}

			if (query.allKeys.count > 0)
				[query makeImmutable];
			else
				query = nil;

		}

		OFString* urlPath = self.requestMessage.URL.path.stringByURLDecoding;

		if (urlPath == nil || urlPath.length == 0)
			urlPath = @"/";

		if (![urlPath hasPrefix:@"/"])
			urlPath = [urlPath stringByPrependingString:@"/"];

		for (OFWebServerHandler* handler in self.server.handlers) {
			self.request = handler.matchBlock(requestMethod, self.requestMessage.URL, self.requestMessage.headers, urlPath, query);

			if (self.request != nil) {
				self.handler = handler;

				break;
			}
		}

		if (self.request != nil) {
			if (self.request.hasBody) {
				SEL bodySetter = @selector(write:maxLength:);

				if ([self.request respondsToSelector:bodySetter]) {
					@try {
						size_t written = [self.request write:self.requestMessage.body.items maxLength:self.requestMessage.body.count];

						if (self.requestMessage.headers[@"Expect"] != nil)
							written += [self _readAdditionalData];

						if (written < self.request.contentLength)
							@throw [OFWriteFailedException exceptionWithObject:self.request requestedLength:(self.request.contentLength > 0) ? self.request.contentLength : self.requestMessage.body.count];

					}@catch (id e) {

						[self _abortWithStatusCode:500 exception:e info:@{
															@"Line": @(__LINE__),
															@"File": @(__FILE__),
															@"Class": [self className],
															@"Function": @(__PRETTY_FUNCTION__)
															}];
					}

				} else {
					[self _abortWithStatusCode:400 exception:nil info:@{
															@"Line": @(__LINE__),
															@"File": @(__FILE__),
															@"Class": [self className],
															@"Function": @(__PRETTY_FUNCTION__)
															}];
				}
			}

			[self _processRequest];

		} else {
			[self _abortWithStatusCode:405 exception:nil info:@{
															@"Line": @(__LINE__),
															@"File": @(__FILE__),
															@"Class": [self className],
															@"Function": @(__PRETTY_FUNCTION__)
															}];
		}
	}
}

- (void)_processRequest
{
	@try {
		void* voidSelf = (__bridge void*)self;
		__block __typeof__(self) weakSelf = nil;

		self.request.responseBlock = ^(OFWebServerResponse* response) {
			weakSelf = (__bridge __typeof__(weakSelf))voidSelf;

			if (![response hasBody] || [response open])
				weakSelf.response = response;

			if (weakSelf.response != nil) {
				of_log(@"Response class is %@", response.className);
				OFMutableDictionary* headers = [OFMutableDictionary dictionary];
				weakSelf.responseMessage.statusCode = self.response.statusCode;

				size_t maxAge = weakSelf.response.cacheControlMaxAge;

				if (maxAge > 0) {
					[headers setValue:[OFString stringWithFormat:@"%zu", maxAge] forKey:@"Cache-Control"];

				} else {

					[headers setValue:@"no-cache" forKey:@"Cache-Control"];
				}

				[weakSelf.response.additionalHeaders enumerateKeysAndObjectsUsingBlock:^(id key, id object, bool *stop){

					[headers setValue:object forKey:key];

				}];


				if (weakSelf.response.hasBody) {
					[headers setValue:weakSelf.response.contentType forKey:@"Content-Type"];
					[headers setValue:[OFString stringWithFormat:@"%zu", weakSelf.response.contentLength] forKey:@"Content-Length"];
					of_log(@"Connection %@", weakSelf);
					of_log(@"Response with length: %zu", weakSelf.response.contentLength);
				}

				[headers makeImmutable];
				weakSelf.responseMessage.headers = headers;

				if (weakSelf.response.hasBody) {

					of_log(@"Sending data...");

					void* buffer = (void *)__builtin_alloca(kBodyWriteBufferSize);
					size_t write = 0;
					memset(buffer, 0, kBodyWriteBufferSize);
					size_t sended = 0;

					while ((write = [weakSelf.response read:buffer maxLength:kBodyWriteBufferSize]) != 0) {

						[weakSelf.responseMessage writeBuffer:buffer length:write];
						memset(buffer, 0, kBodyWriteBufferSize);
						sended += write;
						of_log(@"Sended %zu/%zu", sended, weakSelf.response.contentLength);
					}

					of_log(@"Sended %zu bytes.", sended);

					[weakSelf.response close];
					[weakSelf close];

				} else {
					[weakSelf close];
				}


			} else {

				[self _abortWithStatusCode:500 exception:nil info:@{
															@"Line": @(__LINE__),
															@"File": @(__FILE__),
															@"Class": [self className],
															@"Function": @(__PRETTY_FUNCTION__)
															}];

			}

		};

		self.handler.processBlock(self.request);

	}@catch (OFException* e) {
		[self _abortWithStatusCode:500 exception:e info:@{
															@"Line": @(__LINE__),
															@"File": @(__FILE__),
															@"Class": [self className],
															@"Function": @(__PRETTY_FUNCTION__)
															}];
	}
}

- (void)_abortWithStatusCode:(short)code
{
	if (code >= 400 && code <= 600) {
		self.responseMessage.statusCode = code;
		[self close];

		return;
	}

	@throw [OFInvalidArgumentException exception];
}

- (void)_abortWithStatusCode:(short)code exception:(OFException *)exception info:(_Nullable OFDictionary *)info
{
	@autoreleasepool {
		OFMutableString* descriptionString = [OFMutableString stringWithFormat:@"<h1>HTTP %hu</h1><br>", code];

		[descriptionString appendFormat:@"<p><h3>%@</h3></p><br>", exception];

		if (info != nil) {
			[info enumerateKeysAndObjectsUsingBlock:^(id key, id object, bool *stop){
				[descriptionString appendFormat:@"<p>%@: %@</p>", key, object];
			}];
		}

		[descriptionString makeImmutable];

		self.responseMessage.statusCode = code;

		[self.responseMessage writeString:descriptionString];
	}

	[self close];
}

- (void)openWithCompletionHandler:(OFWebServerConnectionCompletionHandler)completionHandler
{
	self.completionHandler = completionHandler;

	[self _readRequest];
}

- (void)close
{
	self.completionHandler ? self.completionHandler() : nil;
}

@end
