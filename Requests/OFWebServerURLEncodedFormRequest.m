#import <ObjFW/ObjFW.h>
#import "OFWebServerURLEncodedFormRequest.h"
#import "OFWebServerRequest+Private.h"

@interface OFWebServerURLEncodedFormRequest()

@property(nonatomic, copy, readwrite) OFDictionary* arguments;

@end

@implementation OFWebServerURLEncodedFormRequest{
	OFDictionary* _arguments;
}

@synthesize arguments = _arguments;

- (void)dealloc
{
	[_arguments release];

	[super dealloc];
}

+ (OFString *)mimeType
{
	return @"application/x-www-form-urlencoded";
}

- (BOOL)close
{
	if (![super close])
		return NO;

	@autoreleasepool {

		OFString* argumentsString = [OFString stringWithUTF8String:self.data.items length:self.data.count];
		OFMutableDictionary* arguments = [OFMutableDictionary dictionary];

		of_range_t pairRange= of_range(0, argumentsString.length);
		size_t pos = 0;

		while (true) {
			OFString* key = nil;
			OFString* value = nil;

			if ((pairRange = [argumentsString rangeOfString:@"=" options:0 range:pairRange]).location == OF_NOT_FOUND)
				break;

			key = [argumentsString substringWithRange:of_range(pos, pairRange.location - pos)];

			pairRange.location += 1;
			pairRange.length = argumentsString.length - pairRange.location;

			if (pairRange.location == argumentsString.length)
				break;

			pos = pairRange.location;

			if ((pairRange = [argumentsString rangeOfString:@"&" options:0 range:pairRange]).location == OF_NOT_FOUND)
				value = [argumentsString substringWithRange:of_range(pos, argumentsString.length - pos)];
			else
				value = [argumentsString substringWithRange:of_range(pos, pairRange.location - pos)];


			key = [[key stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByURLDecoding];
			value = [[value stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByURLDecoding];

			[arguments setValue:value forKey:key];

			if (pairRange.location == OF_NOT_FOUND)
				break;

			pairRange.location += 1;
			pairRange.length = argumentsString.length - pairRange.location;

			pos = pairRange.location;
		}

		if (arguments.allKeys.count > 0)
			[arguments makeImmutable];
		else
			arguments = nil;

		self.arguments = arguments;
	}

	return (self.arguments ? YES : NO);
}

@end