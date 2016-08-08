#import <ObjFW/OFObject.h>

@class OFString;
@class OFArray;

@interface OFWebServerFileInfo: OFObject
{
	OFString* _fileDescription;
	OFArray* _altExtensions;
	OFString* _extension;
	OFString* _mimeType;
	OFString* _name;
}

@property (nonatomic, copy, readonly) OFString* fileDescription;
@property (nonatomic, copy, readonly) OFString* extension;
@property (nonatomic, copy, readonly) OFArray* altExtensions;
@property (nonatomic, copy, readonly) OFString* mimeType;
@property (nonatomic, copy, readonly) OFString* name;

+ (instancetype)fileInfo;
+ (instancetype)infoForFile:(OFString *)path;
- (instancetype)initWithInfoOfFile:(OFString *)path;

@end

