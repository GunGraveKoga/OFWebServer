#import <ObjFW/ObjFW.h>
#import "OFWebServerDataResponse.h"
#import "OFDataArray+Search.h"

#ifndef MIN
#define MIN(a,b) (((a)<(b))?(a):(b))
#endif

#ifndef MAX
#define MAX(a,b) (((a)>(b))?(a):(b))
#endif

@interface OFWebServerDataResponse()

@property (nonatomic, assign) of_offset_t offset;

@end

@implementation OFWebServerDataResponse {
	of_offset_t _offset;
}

@synthesize offset = _offset;
@synthesize data = _data;

+ (instancetype)responseWithData:(OFDataArray *)data contentType:(OFString *)type 
{
	return [[[[self class] alloc] initWithData:data contentType:type] autorelease];
}

- (instancetype)initWithData:(OFDataArray *)data contentType:(OFString *)type 
{
	if (data == nil)
		@throw [OFInvalidArgumentException exception];

	self = [super initWithContentType:type contentLength:(data.count * data.itemSize)];

	self.data = data;
	self.offset = -1;

	return self;
}

- (void)dealloc
{
	[_data release];
	[super dealloc];
}

- (BOOL)open
{
	if (self.offset < 0) {
		self.offset = 0;
		return YES;
	}

	return NO;
}

- (size_t)read:(void *)buffer maxLength:(size_t)length 
{
	if (self.offset < 0)
		@throw [OFReadFailedException exceptionWithObject:self requestedLength:length];

	size_t size = 0;
	size_t datalength = (self.data.count * self.data.itemSize);

	if (self.offset < datalength) {
		size = MIN(datalength - self.offset, length);
		
		[self.data getItems:buffer inRange:of_range(self.offset, size)];
		
		self.offset += size;
	}
	
	return size;
}

- (BOOL)close
{
	if (self.offset >= 0) {
		self.offset = -1;

		return YES;
	}

	return NO;
}

+ (instancetype)responseWithText:(OFString *)text 
{
	return [[[self alloc] initWithText:text] autorelease];
}

+ (instancetype)responseWithHTML:(OFString *)html
{
	return [[[self alloc] initWithHTML:html] autorelease];
}

+ (instancetype)responseWithHTMLTemplate:(OFString *)path variables:(OFDictionary *)variables 
{
	return [[[[self class] alloc] initWithHTMLTemplate:path variables:variables] autorelease];
}

- (instancetype)initWithText:(OFString *)text 
{
	OFDataArray* data = [[OFDataArray alloc] init];

	[data addItems:text.UTF8String count:text.UTF8StringLength];

	id response = [self initWithData:data contentType:@"text/plain; charset=utf-8"];

	[data release];

	return response;
}

- (instancetype)initWithHTML:(OFString *)html 
{
	OFDataArray* data = [[OFDataArray alloc] init];

	[data addItems:html.UTF8String count:html.UTF8StringLength];

	id response = [self initWithData:data contentType:@"text/html; charset=utf-8"];

	[data release];

	return response;
}

- (instancetype)initWithHTMLTemplate:(OFString *)path variables:(OFDictionary *)variables 
{
	OFMutableString* html = [[OFMutableString alloc] initWithContentsOfFile:path];

	void* pool = objc_autoreleasePoolPush();

	[variables enumerateKeysAndObjectsUsingBlock:^(id key, id object, bool *stop){

		[html replaceOccurrencesOfString:[OFString stringWithFormat:@"%%%@%%", key] withString:[OFString stringWithFormat:@"%@", object]];
	}];

	objc_autoreleasePoolPop(pool);
	[html makeImmutable];

	id response = [self initWithHTML:html];

	[html release];

	return response;
}

@end
