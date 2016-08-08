#import <ObjFW/ObjFW.h>
#import "OFWebServerDataRequest.h"
#import "OFWebServerRequest+Private.h"

@interface OFWebServerDataRequest()

@property(nonatomic, copy, readwrite) OFDataArray* data;

@end

@implementation OFWebServerDataRequest{
	OFDataArray* _data;
}

@synthesize data = _data;

- (void)dealloc
{
	[_data release];

	[super dealloc];
}

- (size_t)write:(const void*)buffer maxLength:(size_t)length
{
	[self.data addItems:buffer count:length];

	return length;
}

- (BOOL)open
{
	_data = [[OFDataArray alloc] initWithItemSize:1];

	return _data ? YES : NO;
}

- (BOOL)close
{
	return YES;
}

@end