#import <ObjFW/ObjFW.h>
#import "OFWebServerMultiPartFormRequest.h"
#import "OFWebServerRequest+Private.h"
#import "OFDataArray+Search.h"
#import "OFWebServerFunctions.h"

static OFDataArray* _newlineData = nil;
static OFDataArray* _newlinesData = nil;
static OFDataArray* _dashNewlineData = nil;

@interface OFWebServerMultiPart()

@property(nonatomic, copy, readwrite) OFString *contentType;
@property(nonatomic, copy, readwrite) OFString *mimeType;

@end

@implementation OFWebServerMultiPart{
	OFString* _contentType;
	OFString* _mimeType;
}

@synthesize contentType = _contentType;
@synthesize mimeType = _mimeType;

- (instancetype)initWithContentType:(OFString*)contentType
{
	self = [super init];

	self.contentType = nil;
	self.mimeType = nil;

	self.contentType = contentType;

	@autoreleasepool {
		OFArray* components = [self.contentType componentsSeparatedByString:@";"];

		if (components.count > 0) self.mimeType = components[0];
		else self.mimeType = @"text/plain";
	}

	return self;
}

- (void)dealloc
{
	[_contentType release];
	[_mimeType release];

	[super dealloc];
}

@end

@interface OFWebServerMultiPartArgument()

@property(nonatomic, copy, readwrite) OFDataArray *data;
@property(nonatomic, copy, readwrite) OFString *string;

@end

@implementation OFWebServerMultiPartArgument{
	OFDataArray* _data;
	OFString* _string;
}

@synthesize data = _data;
@synthesize string = _string;

- (instancetype)initWithContentType:(OFString *)contentType data:(OFDataArray *)data
{
	self = [super initWithContentType:contentType];

	self.data = data;
	self.string = nil;

	@autoreleasepool {
		if ([self.mimeType hasPrefix:@"text/"])
			self.string = [OFString stringWithUTF8String:self.data.items length:self.data.count];
	}

	return self;
}

- (void)dealloc
{
	[_data release];
	[_string release];

	[super dealloc];
}

- (OFString *)description 
{
  
  return [OFString stringWithFormat:@"<%@ | '%@' | %zu bytes>", [self className], self.mimeType, _data.count];

}

@end

@interface OFWebServerMultiPartFile()

@property(nonatomic, copy, readwrite) OFString *fileName;
@property(nonatomic, copy, readwrite) OFString *temporaryPath;

@end

@implementation OFWebServerMultiPartFile{
	OFString* _fileName;
	OFString* _temporaryPath;
}

@synthesize fileName = _fileName;
@synthesize temporaryPath = _temporaryPath;

- (instancetype)initWithContentType:(OFString*)contentType fileName:(OFString*)fileName temporaryPath:(OFString*)temporaryPath
{
	self = [super initWithContentType:contentType];

	self.fileName = fileName;
	self.temporaryPath = temporaryPath;

	return self;
}

- (void)dealloc
{
	OFFileManager* fm = [OFFileManager defaultManager];

	if ([fm fileExistsAtPath:self.temporaryPath])
		[fm removeItemAtPath:self.temporaryPath];

	[_fileName release];
	[_temporaryPath release];

	[super dealloc];
}

- (OFString *)description 
{
  return [OFString stringWithFormat:@"<%@ | '%@' | '%@>'", [self className], self.mimeType, self.fileName];
}

@end

typedef enum parser_state {
	kUndefined = 0,
	kStart,
	kHeader,
	kContent,
	kEnd

} parser_state_t;

OF_INLINE BOOL isEmptyString(OFString* string) {
	return ((string == nil || string.length == 0) ? YES : NO);
}

@interface OFWebServerMultiPartFormRequest()

@property (nonatomic, copy, readwrite) OFDataArray* data;
@property (nonatomic, copy, readwrite) OFDictionary* arguments;
@property (nonatomic, copy, readwrite) OFDictionary* files;
@property (nonatomic, copy) OFString* boundary;
@property (nonatomic, assign) parser_state_t parserState;
@property (nonatomic, copy) OFString *controlName;
@property (nonatomic, copy) OFString *fileName;
@property (nonatomic, copy) OFString *tmpPath;
@property (nonatomic, copy) OFFile* tmpFile;

- (BOOL)_parseData;

@end


@implementation OFWebServerMultiPartFormRequest{
	OFDataArray* _data;
	OFMutableDictionary* _arguments;
	OFMutableDictionary* _files;
	OFString* _boundary;
	parser_state_t _parserState;
	OFString* _controlName;
	OFString* _fileName;
	OFString* _tmpPath;
	OFFile* _tmpFile;
}

@synthesize data = _data;
@dynamic arguments;
@dynamic files;
@synthesize boundary = _boundary;
@synthesize parserState = _parserState;
@synthesize controlName = _controlName;
@synthesize fileName = _fileName;
@synthesize tmpPath = _tmpPath;
@synthesize tmpFile = _tmpFile;

- (instancetype)initWithMethod:(OFString *)method URL:(OFURL *)url headers:(OFDictionary *)headers path:(OFString *)path query:(OFDictionary *)query
{
	self = [super initWithMethod:method URL:url headers:headers path:path query:query];

	@autoreleasepool {
		self.boundary = _ExtractHeaderParameter(self.contentType, @"boundary");

		if (self.boundary != nil && ![self.boundary hasPrefix:@"--"]) {
			self.boundary = [self.boundary stringByPrependingString:@"--"];

			self.arguments = @{};
			self.files = @{};
		}
	}

	if (self.boundary == nil) {
		[self release];

		@throw [OFInitializationFailedException exceptionWithClass:[OFWebServerMultiPartFormRequest class]];
	}

	return self;
}

- (void)dealloc
{
	[_arguments release];
	[_files release];
	[_data release];
	[_boundary release];
	[_data release];
	[_controlName release];
	[_fileName release];
	[_tmpPath release];
	[_tmpFile release];

	[super dealloc];
}

- (void)setArguments:(OFDictionary *)arguments
{
	if (_arguments)
		[_arguments release];

	_arguments = [arguments mutableCopy];
}

- (OFDictionary *)arguments
{
	return [[_arguments copy] autorelease];
}

- (void)setFiles:(OFDictionary *)files
{
	if (_files)
		[_files release];

	_files = [files mutableCopy];
}

- (OFDictionary *)files
{
	return [[_files copy] autorelease];
}

- (size_t)write:(const void*)buffer maxLength:(size_t)length
{
	[self.data addItems:buffer count:length];

	return ([self _parseData] ? length : 0);
}


- (BOOL)_parseData
{
	BOOL success = YES;

	if (self.parserState == kHeader) {
		of_range_t newLinesRange = [self.data rangeOfData:_newlinesData options:0 range:of_range(0, self.data.count)];

		if (newLinesRange.location != OF_NOT_FOUND) {
			self.controlName = nil;
      		self.fileName = nil;
      		self.contentType = nil;
      		self.tmpPath = nil;

      		OFString* lines = [OFString stringWithUTF8String:self.data.items length:newLinesRange.location];

      		OFArray* components = [lines componentsSeparatedByString:@"\r\n"];
      		OFMutableDictionary* headers = [OFMutableDictionary dictionary];

      		for (OFString* component in components) {
      			@autoreleasepool {
      				of_range_t keyRange = [component rangeOfString:@" "];
      				OFString* key = [component substringWithRange:of_range(0, keyRange.location)];
      				OFString* value = [component substringWithRange:of_range((keyRange.location + keyRange.length), (component.length - (keyRange.location + keyRange.length)))];

      				key = [key stringByDeletingEnclosingWhitespaces];
      				value = [value stringByDeletingEnclosingWhitespaces];

      				if ([key isEqual:@"Content-Type"]) {
      					self.contentType = value;
      					continue;
      				}

      				if ([key isEqual:@"Content-Disposition"]) {
      					if ([[value lowercaseString] hasPrefix:@"form-data;"]) {
      						self.controlName = _ExtractHeaderParameter(value, @"name");
      						self.fileName = _ExtractHeaderParameter(value, @"filename");

      						continue;
      					}

      				}
      			}
      		}

      		if (self.controlName != nil) {

      			if (self.fileName != nil) {
      				@try {
      					self.tmpPath = [_getTmpPath() stringByAppendingPathComponent:[[OFApplication programName] MD5Hash]];

      					OFFileManager* fm = [OFFileManager defaultManager];

      					if (![fm directoryExistsAtPath:self.tmpPath])
      						[fm createDirectoryAtPath:self.tmpPath createParents:true];

      					self.tmpFile = [OFFile fileWithPath:[self.tmpPath stringByAppendingPathComponent:self.fileName] mode:@"wb"];

      				}@catch(...) {

      					self.tmpPath = nil;

      					success = NO;
      				}
      			}

      		} else {
      			success = NO;
      		}

      		[self.data removeItemsInRange:of_range(0, (newLinesRange.location + newLinesRange.length))];
      		self.parserState = kContent;

		}
	}

	if ((self.parserState == kStart) || (self.parserState == kContent)) {

		OFDataArray* boundaryData = [OFDataArray dataArray];

		[boundaryData addItems:self.boundary.UTF8String count:self.boundary.UTF8StringLength];

		of_range_t boundaryRange = [self.data rangeOfData:boundaryData options:0 range:of_range(0, self.data.count)];

		if (boundaryRange.location != OF_NOT_FOUND) {

			of_range_t dataRange = of_range((boundaryRange.location + boundaryRange.length), (self.data.count - (boundaryRange.location + boundaryRange.length)));

			of_range_t newLineRange = [self.data rangeOfData:_newlineData options:OF_DATA_SEARCH_ANCHORED range:dataRange];
			of_range_t dashNewLineRange = [self.data rangeOfData:_dashNewlineData options:OF_DATA_SEARCH_ANCHORED range:dataRange];

			if ((newLineRange.location != OF_NOT_FOUND) || (dashNewLineRange.location != OF_NOT_FOUND)) {

				if (self.parserState == kContent) {

					if (self.tmpPath) {

						@try {

							[self.tmpFile writeBuffer:self.data.items length:(boundaryRange.location - 2)];
							[self.tmpFile close];

							OFWebServerMultiPartFile* file = [[[OFWebServerMultiPartFile alloc] initWithContentType:self.contentType fileName:self.fileName temporaryPath:self.tmpPath] autorelease];
							_files[self.controlName] = file;

						}@catch (...) {

							success = NO;

						}

						self.tmpPath = nil;

					} else {

						OFDataArray* data = [self.data subDataWithRange:of_range(0, (boundaryRange.location - 2))];

						OFWebServerMultiPartArgument* argument = [[OFWebServerMultiPartArgument alloc] initWithContentType:self.contentType data:data];

						_arguments[self.controlName] = argument;

					}
				}

				if (newLineRange.location != OF_NOT_FOUND) {

					[self.data removeItemsInRange:of_range(0, (boundaryRange.location + boundaryRange.length))];

					self.parserState = kHeader;

					success = [self _parseData];

				} else {
					self.parserState = kEnd;
				}

			}

		} else {

			if ((self.tmpPath != nil) && (self.data.count > (self.boundary.length * 2))) {

				@try {
					[self.tmpFile writeBuffer:self.data.items length:(self.data.count - ((self.boundary.length * 2)))];

				} @catch (...) {
					success = NO;
				}

				if (success)
					[self.data removeItemsInRange:of_range(0, (self.data.count - ((self.boundary.length * 2))))];
			}
		}
	}

	return success;
}

- (BOOL)open
{
	_data = [OFDataArray new];
	self.parserState = kStart;

	return YES;
}

- (BOOL)close
{
	return (self.parserState == kEnd ? YES : NO);
}

+ (void)initialize 
{
	const char* newLine = "\r\n";
	const char* newLines = "\r\n\r\n";
	const char* dashNewLine = "--\r\n";

	if (_newlineData == nil) {
		_newlineData = [OFDataArray new];
		[_newlineData addItems:newLine count:strlen(newLine)];
	}

	if (_newlinesData == nil) {
		_newlinesData = [OFDataArray new];
		[_newlinesData addItems:newLines count:strlen(newLines)];
	}

	if (_dashNewlineData == nil) {
		_dashNewlineData = [OFDataArray new];
		[_dashNewlineData addItems:dashNewLine count:strlen(dashNewLine)];
	}
}

+ (OFString *)mimeType {
  return @"multipart/form-data";
}

@end