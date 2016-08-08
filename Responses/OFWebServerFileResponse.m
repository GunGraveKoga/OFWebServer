#import <ObjFW/ObjFW.h>
#import "OFWebServerFileResponse.h"
#import "OFWebServerMime.h"

@interface OFWebServerFileResponse()

@property (nonatomic, copy) OFString* path;
@property (nonatomic, copy) OFFile* file;

@end

@implementation OFWebServerFileResponse {
	OFString* _path;
	OFFile* _file;
}

@synthesize path = _path;
@synthesize file = _file;

+ (instancetype)responseWithFile:(OFString *)path 
{
	return [[[[self class] alloc] initWithFile:path] autorelease];
}

+ (instancetype)responseWithFile:(OFString *)path isAttachment:(BOOL)attachment 
{
	return [[[[self class] alloc] initWithFile:path isAttachment:attachment] autorelease];
}

- (instancetype)initWithFile:(OFString *)path 
{
	return [self initWithFile:path isAttachment:NO];
}

- (instancetype)initWithFile:(OFString *)path isAttachment:(BOOL)attachment 
{
	OFFileManager* fm = [OFFileManager defaultManager];

	if (![fm fileExistsAtPath:path])
		@throw [OFInvalidArgumentException exception];

	OFWebServerFileInfo* fileInfo = nil;

	@autoreleasepool {
		fileInfo = [OFWebServerFileInfo infoForFile:path];

		[fileInfo retain];
	}

	of_log(@"Creating response for %@", fileInfo);

	self = [super initWithContentType:fileInfo.mimeType contentLength:[fm sizeOfFileAtPath:path]];

	self.path = path;

	if (attachment) {
		OFString* headerValue = [[OFString alloc] initWithFormat:@"attachment; filename=\"%@\"", path.lastPathComponent];
		[self setValue:headerValue forAdditionalHeader:@"Content-Disposition"];

		[headerValue release];
	}

	self.file = nil;

	[fileInfo release];

	return self;
}

- (void)dealloc
{
	[_path release];
	[_file release];

	[super dealloc];
}

- (BOOL)open
{
	OFFileManager* fm = [OFFileManager defaultManager];

	BOOL success = YES;

	if ([fm fileExistsAtPath:self.path]) {

		@try {
			self.file = [OFFile fileWithPath:self.path mode:@"rb"];

		}@catch (...) {
			success = NO;
			self.file = nil;
		}

	} else {
		success = NO;
	}

	return success;
}

- (size_t)read:(void *)buffer maxLength:(size_t)length 
{
	return [self.file readIntoBuffer:buffer length:length];
}

- (BOOL)close
{
	BOOL success = YES;

	@try {
		[self.file close];
	}@catch(...) {
		success = NO;
	}

	return success;
}

@end