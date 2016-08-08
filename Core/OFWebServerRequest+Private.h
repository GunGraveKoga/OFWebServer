@interface OFWebServerRequest()

@property(nonatomic, copy, readwrite) OFString* method;
@property(nonatomic, copy, readwrite) OFURL* URL;
@property(nonatomic, copy, readwrite) OFDictionary* headers;
@property(nonatomic, copy, readwrite) OFString* path;
@property(nonatomic, copy, readwrite) OFDictionary* query;
@property(nonatomic, copy, readwrite) OFString* contentType;
@property(nonatomic, readwrite) size_t contentLength;

@end