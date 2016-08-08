#import <ObjFW/ObjFW.h>
#import "OFWeb.h"

@interface Test: OFObject<OFApplicationDelegate>
{
	OFWebServer* _srv;
}

@property (nonatomic, retain) OFWebServer* srv;

- (void)applicationDidFinishLaunching;

@end

OF_APPLICATION_DELEGATE(Test)

@implementation Test

@synthesize srv = _srv;

- (void)applicationDidFinishLaunching 
{
	self.srv = [OFWebServer server];
	self.srv.host = @"0.0.0.0";
	self.srv.port = 0;

	[self.srv addHandlerForBasePath:@"/" localPath:[[OFFileManager defaultManager] currentDirectoryPath] indexFilename:@"index.html" cacheAge:0];

	[self.srv start];

	of_log(@"Listening on %@:%zu", self.srv.host, self.srv.port);
}

@end