#import "OFWebServerRequest.h"

@interface OFWebServerMultiPart : OFObject

@property(nonatomic, copy, readonly) OFString *contentType;
@property(nonatomic, copy, readonly) OFString *mimeType;

@end

@interface OFWebServerMultiPartArgument : OFWebServerMultiPart


@property(nonatomic, copy, readonly) OFDataArray *data;
@property(nonatomic, copy, readonly) OFString *string;

@end

@interface OFWebServerMultiPartFile : OFWebServerMultiPart

@property(nonatomic, copy, readonly) OFString *fileName;
@property(nonatomic, copy, readonly) OFString *temporaryPath;

@end

@interface OFWebServerMultiPartFormRequest : OFWebServerRequest

@property (nonatomic, copy, readonly) OFDataArray* data;
@property (nonatomic, copy, readonly) OFDictionary* arguments;
@property (nonatomic, copy, readonly) OFDictionary* files;

+ (OFString *)mimeType;

@end