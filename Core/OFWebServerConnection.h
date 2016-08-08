#import <ObjFW/OFObject.h>

@class OFWebServerHandler;
@class OFWebServer;
@class OFHTTPRequest;
@class OFHTTPResponse;
@class OFWebServerRequest;
@class OFWebServerResponse;

typedef void(^OFWebServerConnectionCompletionHandler)(void);


@interface OFWebServerConnection: OFObject
{
	OFWebServer* _server;
}

@property(nonatomic, assign, readonly)OFWebServer* server;

- (instancetype)initWithServer:(OFWebServer *)server request:(OFHTTPRequest *)request response:(OFHTTPResponse *)response;
- (void)openWithCompletionHandler:(OFWebServerConnectionCompletionHandler)completionHandler;
- (void)close;

@end