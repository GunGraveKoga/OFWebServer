#import "OFWebServerFunctions.h"
#import "OFDataArray+Search.h"

#include <wctype.h>

_Nullable OFString* _ExtractHeaderParameter(OFString* header, OFString* attribute) {
	OFString* value = nil;

	if (header == nil || attribute == nil)
		@throw [OFInvalidArgumentException exception];

	@autoreleasepool {
		OFString* str = [OFString stringWithFormat:@"%@=", attribute];

		of_range_t range = of_range(0, header.length);

		if ((range = [header rangeOfString:str options:0 range:range]).location != OF_NOT_FOUND) {

			range.length = header.length - (range.location + str.length);
			range.location += str.length;

			size_t pos = range.location;

			of_unichar_t ch;

			while ((ch = [header characterAtIndex:pos]) != '\0') {
				if (((iswalnum(ch) != 0) || (ch == '-')) && (ch != '"')) {
					pos++;
					continue;
				}

				break;
			}

			range.length = pos - range.location;

			value = [[header substringWithRange:range] stringByDeletingEnclosingWhitespaces];

			[value retain];
		}
	}

	if (value != nil)
		[value autorelease];

	return value;
}

OFString* _getTmpPath(void) {

	#if defined(OF_WINDOWS)
	wchar_t path[MAX_PATH] = {0};
	DWORD res = 0;

	if ((res = GetTempPathW(MAX_PATH, path)) != 0) {
		return [OFString stringWithUTF16String:path length:(size_t)res];
	}

	return @"C:\\Temp";
	#else
	const char* path = getenv("TMPDIR");
	if (path == 0)
		return [OFString stringWithUTF8String:path];

	return @"/tmp"
	#endif
}