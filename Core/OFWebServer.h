#import <ObjFW/OFObject.h>
#import <ObjFW/OFHTTPServer.h>

@class OFMutableArray;
@class OFWebServerRequest;
@class OFURL;
@class OFString;
@class OFDictionary;
@class OFArray;

typedef OFWebServerRequest*(^OFWebServerMatchBlock)(OFString* requestMethod, OFURL* requestURL, OFDictionary* requestHeaders, OFString* urlPath, OFDictionary* urlQuery);
typedef void(^OFWebServerProcessBlock)(OFWebServerRequest* request);

@interface OFWebServer: OFHTTPServer<OFHTTPServerDelegate>
{
	OFMutableArray* _handlers;
}

@property(nonatomic, copy, readonly) OFArray* handlers;

- (void)addHandlerWithMatchBlock:(OFWebServerMatchBlock)matchBlock processBlock:(OFWebServerProcessBlock)processBlock;
- (void)addDefaultHandlerForMethod:(OFString*)method requestClass:(Class)class processBlock:(OFWebServerProcessBlock)block;
- (void)addHandlerForBasePath:(OFString*)basePath localPath:(OFString*)localPath indexFilename:(OFString*)indexFilename cacheAge:(size_t)cacheAge;
- (void)addHandlerForMethod:(OFString*)method path:(OFString*)path requestClass:(Class)class processBlock:(OFWebServerProcessBlock)block;
//- (void)addHandlerForMethod:(OFString*)method pathRegex:(OFString*)regex requestClass:(Class)class processBlock:(OCFWebServerProcessBlock)block;
- (void)removeAllHandlers;

@end


@interface OFWebServerHandler: OFObject
{
	OFWebServerMatchBlock _matchBlock;
	OFWebServerProcessBlock _processBlock;
}

@property(nonatomic, copy, readonly)OFWebServerMatchBlock matchBlock;
@property(nonatomic, copy, readonly)OFWebServerProcessBlock processBlock;

- (id)initWithMatchBlock:(OFWebServerMatchBlock)matchBlock processBlock:(OFWebServerProcessBlock)processBlock;

@end