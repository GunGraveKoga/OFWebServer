#import <ObjFW/ObjFW.h>
#import "OFWebServerFileRequest.h"
#import "OFWebServerRequest+Private.h"

@interface OFWebServerFileRequest()

@property(nonatomic, copy, readwrite) OFString *filePath;

@end

@implementation OFWebServerFileRequest{
	OFString* _filePath;
	OFFile* _file;
}

@synthesize filePath = _filePath;

- (instancetype)initWithMethod:(OFString *)method URL:(OFURL *)url headers:(OFDictionary *)headers path:(OFString *)path query:(OFDictionary *)query
{
	self = [super initWithMethod:method URL:url headers:headers path:path query:query];

	#if defined(OF_WINDOWS)
	wchar_t* tmpname = _wtmpnam(NULL);
	#else
	char* tmpname = tmpnam(NULL);
	#endif

	if (tmpname == NULL) {
		[self release];

		@throw [OFInitializationFailedException exceptionWithClass:[OFWebServerFileRequest class]];
	}

	@autoreleasepool {
		
		#if defined(OF_WINDOWS)
		self.filePath = [OFString stringWithUTF16String:tmpname];
		#else
		self.filePath = [OFString stringWithUTF8String:tmpname];
		#endif

	}

	return self;

}

- (void)dealloc
{
	[_file release];

	OFFileManager* fm = [OFFileManager defaultManager];

	if ([fm fileExistsAtPath:self.filePath])
		[fm removeItemAtPath:self.filePath];

	[_filePath release];

	[super dealloc];
}

- (size_t)write:(const void*)buffer maxLength:(size_t)length
{
	[_file writeBuffer:buffer length:length];

	return YES;
}

- (BOOL)open
{
	_file = [[OFFile alloc] initWithPath:self.filePath mode:@"wb"];

	return _file ? YES : NO;
}

- (BOOL)close
{
	[_file close];

	return YES;
}

@end