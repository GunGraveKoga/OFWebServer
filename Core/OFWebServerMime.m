#import <ObjFW/ObjFW.h>
#import "OFWebServerMime.h"

typedef struct _fileInfo
{
	size_t extensionsCount;
	OFString** extensions;
	of_offset_t offset;
	size_t signLength;
	uint8_t* sign;
	OFString* description;
	OFString* mimeType;
} fileInfo;

static OFMutableDictionary* _mimesCache = nil;


static fileInfo _fileInfoWithMime[] = {
	{1, (OFString* []){@"attachment", nil}, 0, 7, (uint8_t []){0x4F, 0x50, 0x43, 0x4C, 0x44, 0x41, 0x54}, @"1Password 4 Cloud Keychain", @"application/octet-stream"},	//filemagic\1Password 4 Cloud Keychain attachment.xml
	{1, (OFString* []){@"(none)", nil}, 0, 8, (uint8_t []){0x6F, 0x70, 0x64, 0x61, 0x74, 0x61, 0x30, 0x31}, @"1Password 4 Cloud Keychain encrypted data", @"application/msonenote"},	//filemagic\1Password 4 Cloud Keychain encrypted data (none).xml
	{1, (OFString* []){@"3gp", nil}, 0, 8, (uint8_t []){0x00, 0x00, 0x00, 0x14, 0x66, 0x74, 0x79, 0x70}, @"3GPP multimedia files", @"text/plain"},	//filemagic\3GPP multimedia files 3GP.xml
	{1, (OFString* []){@"3gp", nil}, 0, 8, (uint8_t []){0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70}, @"3GPP2 multimedia files", @"text/plain"},	//filemagic\3GPP2 multimedia files 3GP.xml
	{3, (OFString* []){@"3gg", @"3gp", @"3g2", nil}, 0, 8, (uint8_t []){0x00, 0x00, 0x00, 0x14, 0x66, 0x74, 0x79, 0x70}, @"3rd Generation Partnership Project 3GPP", @"text/plain"},	//filemagic\3rd Generation Partnership Project 3GPP 3GG_3GP_3G2.xml
	{3, (OFString* []){@"3gg", @"3gp", @"3g2", nil}, 0, 8, (uint8_t []){0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70}, @"3rd Generation Partnership Project 3GPP2", @"text/plain"},	//filemagic\3rd Generation Partnership Project 3GPP2 3GG_3GP_3G2.xml
	{1, (OFString* []){@"4xm", nil}, 0, 4, (uint8_t []){0x52, 0x49, 0x46, 0x46}, @"4X Movie video", @"audio/xm"},	//filemagic\4X Movie video 4XM.xml
	{1, (OFString* []){@"7z", nil}, 0, 6, (uint8_t []){0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C}, @"7-Zip compressed file", @"application/x-7z-compressed"},	//filemagic\7-Zip compressed file 7Z.xml
	{1, (OFString* []){@"dat", nil}, 0, 8, (uint8_t []){0xA9, 0x0D, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, @"Access Data FTK evidence", @"application/octet-stream"},	//filemagic\Access Data FTK evidence DAT.xml
	{1, (OFString* []){@"adp", nil}, 0, 8, (uint8_t []){0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1}, @"Access project file", @"application/commonground"},	//filemagic\Access project file ADP.xml
	{1, (OFString* []){@"api", nil}, 0, 8, (uint8_t []){0x4D, 0x5A, 0x90, 0x00, 0x03, 0x00, 0x00, 0x00}, @"Acrobat plug-in", @"application/octet-stream"},	//filemagic\Acrobat plug-in API.xml
	{1, (OFString* []){@"tib", nil}, 0, 4, (uint8_t []){0xB4, 0x6E, 0x68, 0x44}, @"Acronis True Image", @"application/x-troff"},	//filemagic\Acronis True Image TIB.xml
	{1, (OFString* []){@"ocx", nil}, 0, 2, (uint8_t []){0x4D, 0x5A}, @"ActiveX|OLE Custom Control", @"application/octet-stream"},	//filemagic\ActiveX_OLE Custom Control OCX.xml
	{1, (OFString* []){@"amr", nil}, 0, 5, (uint8_t []){0x23, 0x21, 0x41, 0x4D, 0x52}, @"Adaptive Multi-Rate ACELP Codec (GSM)", @"application/octet-stream"},	//filemagic\Adaptive Multi-Rate ACELP Codec (GSM) AMR.xml
	{1, (OFString* []){@"eps", nil}, 0, 4, (uint8_t []){0xC5, 0xD0, 0xD3, 0xC6}, @"Adobe encapsulated PostScript", @"application/postscript"},	//filemagic\Adobe encapsulated PostScript EPS.xml
	{2, (OFString* []){@"fm", @"mif", nil}, 0, 8, (uint8_t []){0x3C, 0x4D, 0x61, 0x6B, 0x65, 0x72, 0x46, 0x69}, @"Adobe FrameMaker", @"application/vnd.framemaker"},	//filemagic\Adobe FrameMaker FM_MIF.xml
	{1, (OFString* []){@"asx", nil}, 0, 1, (uint8_t []){0x3C}, @"Advanced Stream Redirector", @"application/octet-stream"},	//filemagic\Advanced Stream Redirector ASX.xml
	{1, (OFString* []){@"cod", nil}, 0, 6, (uint8_t []){0x4E, 0x61, 0x6D, 0x65, 0x3A, 0x20}, @"Agent newsreader character map", @"application/octet-stream"},	//filemagic\Agent newsreader character map COD.xml
	{1, (OFString* []){@"ain", nil}, 0, 2, (uint8_t []){0x21, 0x12}, @"AIN Compressed Archive", @"application/octet-stream"},	//filemagic\AIN Compressed Archive AIN.xml
	{1, (OFString* []){@"dat", nil}, 0, 4, (uint8_t []){0x73, 0x6C, 0x68, 0x21}, @"Allegro Generic Packfile (compressed)", @"application/octet-stream"},	//filemagic\Allegro Generic Packfile (compressed) DAT.xml
	{1, (OFString* []){@"dat", nil}, 0, 4, (uint8_t []){0x73, 0x6C, 0x68, 0x2E}, @"Allegro Generic Packfile (uncompressed)", @"application/octet-stream"},	//filemagic\Allegro Generic Packfile (uncompressed) DAT.xml
	{1, (OFString* []){@"adf", nil}, 0, 3, (uint8_t []){0x44, 0x4F, 0x53}, @"Amiga disk file", @"application/octet-stream"},	//filemagic\Amiga disk file ADF.xml
	{1, (OFString* []){@"dms", nil}, 0, 4, (uint8_t []){0x44, 0x4D, 0x53, 0x21}, @"Amiga DiskMasher compressed archive", @"application/octet-stream"},	//filemagic\Amiga DiskMasher compressed archive DMS.xml
	{1, (OFString* []){@"info", nil}, 0, 8, (uint8_t []){0xE3, 0x10, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00}, @"Amiga icon", @"application/inf"},	//filemagic\Amiga icon INFO.xml
	{1, (OFString* []){@"ad", nil}, 0, 8, (uint8_t []){0x52, 0x45, 0x56, 0x4E, 0x55, 0x4D, 0x3A, 0x2C}, @"Antenna data file", @"application/octet-stream"},	//filemagic\Antenna data file AD.xml
	{1, (OFString* []){@"aby", nil}, 0, 5, (uint8_t []){0x41, 0x4F, 0x4C, 0x44, 0x42}, @"AOL address book", @"application/octet-stream"},	//filemagic\AOL address book ABY.xml
	{1, (OFString* []){@"abi", nil}, 0, 8, (uint8_t []){0x41, 0x4F, 0x4C, 0x49, 0x4E, 0x44, 0x45, 0x58}, @"AOL address book index", @"application/octet-stream"},	//filemagic\AOL address book index ABI.xml
	{1, (OFString* []){@"bag", nil}, 0, 8, (uint8_t []){0x41, 0x4F, 0x4C, 0x20, 0x46, 0x65, 0x65, 0x64}, @"AOL and AIM buddy list", @"application/octet-stream"},	//filemagic\AOL and AIM buddy list BAG.xml
	{1, (OFString* []){@"jg", nil}, 0, 4, (uint8_t []){0x4A, 0x47, 0x03, 0x0E}, @"AOL ART file_1", @"text/plain"},	//filemagic\AOL ART file_1 JG.xml
	{1, (OFString* []){@"jg", nil}, 0, 4, (uint8_t []){0x4A, 0x47, 0x04, 0x0E}, @"AOL ART file_2", @"text/plain"},	//filemagic\AOL ART file_2 JG.xml
	{1, (OFString* []){@"ind", nil}, 0, 6, (uint8_t []){0x41, 0x4F, 0x4C, 0x49, 0x44, 0x58}, @"AOL client preferences|settings file", @"text/plain"},	//filemagic\AOL client preferences_settings file IND.xml
	{6, (OFString* []){@"abi", @"aby", @"bag", @"idx", @"ind", @"pfc", nil}, 0, 3, (uint8_t []){0x41, 0x4F, 0x4C}, @"AOL config files", @"application/octet-stream"},	//filemagic\AOL config files ABI_ABY_BAG_IDX_IND_PFC.xml
	{2, (OFString* []){@"arl", @"aut", nil}, 0, 2, (uint8_t []){0xD4, 0x2A}, @"AOL history|typed URL files", @"application/octet-stream"},	//filemagic\AOL history_typed URL files ARL_AUT.xml
	{1, (OFString* []){@"dci", nil}, 0, 8, (uint8_t []){0x3C, 0x21, 0x64, 0x6F, 0x63, 0x74, 0x79, 0x70}, @"AOL HTML mail", @"text/plain"},	//filemagic\AOL HTML mail DCI.xml
	{1, (OFString* []){@"(none)", nil}, 0, 4, (uint8_t []){0x41, 0x43, 0x53, 0x44}, @"AOL parameter|info files", @"application/msonenote"},	//filemagic\AOL parameter_info files (none).xml
	{2, (OFString* []){@"org", @"pfc", nil}, 0, 8, (uint8_t []){0x41, 0x4F, 0x4C, 0x56, 0x4D, 0x31, 0x30, 0x30}, @"AOL personal file cabinet", @"application/octet-stream"},	//filemagic\AOL personal file cabinet ORG_PFC.xml
	{1, (OFString* []){@"idx", nil}, 0, 5, (uint8_t []){0x41, 0x4F, 0x4C, 0x44, 0x42}, @"AOL user configuration", @"application/octet-stream"},	//filemagic\AOL user configuration IDX.xml
	{1, (OFString* []){@"m4a", nil}, 0, 11, (uint8_t []){0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70, 0x4D, 0x34, 0x41}, @"Apple audio and video", @"application/octet-stream"},	//filemagic\Apple audio and video M4A.xml
	{1, (OFString* []){@"caf", nil}, 0, 4, (uint8_t []){0x63, 0x61, 0x66, 0x66}, @"Apple Core Audio File", @"application/octet-stream"},	//filemagic\Apple Core Audio File CAF.xml
	{1, (OFString* []){@"m4a", nil}, 4, 8, (uint8_t []){0x66, 0x74, 0x79, 0x70, 0x4D, 0x34, 0x41, 0x20}, @"Apple Lossless Audio Codec file", @"application/octet-stream"},	//filemagic\Apple Lossless Audio Codec file M4A.xml
	{1, (OFString* []){@"adx", nil}, 0, 8, (uint8_t []){0x03, 0x00, 0x00, 0x00, 0x41, 0x50, 0x50, 0x52}, @"Approach index file", @"application/octet-stream"},	//filemagic\Approach index file ADX.xml
	{1, (OFString* []){@"au", nil}, 0, 4, (uint8_t []){0x64, 0x6E, 0x73, 0x2E}, @"Audacity audio file", @"application/octet-stream"},	//filemagic\Audacity audio file AU.xml
	{1, (OFString* []){@"aiff", nil}, 0, 5, (uint8_t []){0x46, 0x4F, 0x52, 0x4D, 0x00}, @"Audio Interchange File", @"application/octet-stream"},	//filemagic\Audio Interchange File AIFF.xml
	{1, (OFString* []){@"flt", nil}, 0, 8, (uint8_t []){0x4D, 0x5A, 0x90, 0x00, 0x03, 0x00, 0x00, 0x00}, @"Audition graphic filter", @"application/x-troff"},	//filemagic\Audition graphic filter FLT.xml
	{1, (OFString* []){@"dat", nil}, 0, 8, (uint8_t []){0x41, 0x56, 0x47, 0x36, 0x5F, 0x49, 0x6E, 0x74}, @"AVG6 Integrity database", @"application/octet-stream"},	//filemagic\AVG6 Integrity database DAT.xml
	{1, (OFString* []){@"b85", nil}, 0, 13, (uint8_t []){0x3C, 0x7E, 0x36, 0x3C, 0x5C, 0x25, 0x5F, 0x30, 0x67, 0x53, 0x71, 0x68, 0x3B}, @"BASE85 file", @"application/octet-stream"},	//filemagic\BASE85 file B85.xml
	{1, (OFString* []){@"bpg", nil}, 0, 4, (uint8_t []){0x42, 0x50, 0x47, 0xFB}, @"Better Portable Graphics", @"text/plain"},	//filemagic\Better Portable Graphics BPG.xml
	{1, (OFString* []){@"pdb", nil}, 0, 8, (uint8_t []){0xAC, 0xED, 0x00, 0x05, 0x73, 0x72, 0x00, 0x12}, @"BGBlitz position database file", @"application/vnd.palm"},	//filemagic\BGBlitz position database file PDB.xml
	{1, (OFString* []){@"(none)", nil}, 0, 6, (uint8_t []){0x62, 0x70, 0x6C, 0x69, 0x73, 0x74}, @"Binary property list (plist)", @"application/msonenote"},	//filemagic\Binary property list (plist) (none).xml
	{1, (OFString* []){@"hqx", nil}, 0, 8, (uint8_t []){0x28, 0x54, 0x68, 0x69, 0x73, 0x20, 0x66, 0x69}, @"BinHex 4 Compressed Archive", @"application/binhex"},	//filemagic\BinHex 4 Compressed Archive HQX.xml
	{1, (OFString* []){@"(none)", nil}, 0, 6, (uint8_t []){0x00, 0x14, 0x00, 0x00, 0x01, 0x02}, @"BIOS details in RAM", @"application/msonenote"},	//filemagic\BIOS details in RAM (none).xml
	{1, (OFString* []){@"dat", nil}, 8, 24, (uint8_t []){0x00, 0x00, 0x00, 0x00, 0x62, 0x31, 0x05, 0x00, 0x09, 0x00, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x09, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, @"Bitcoin Core wallet.dat file", @"application/octet-stream"},	//filemagic\Bitcoin Core wallet.dat file DAT.xml
	{1, (OFString* []){@"dat", nil}, 0, 4, (uint8_t []){0xF9, 0xBE, 0xB4, 0xD9}, @"Bitcoin-Qt blockchain block file", @"application/octet-stream"},	//filemagic\Bitcoin-Qt blockchain block file DAT.xml
	{1, (OFString* []){@"(none)", nil}, 0, 8, (uint8_t []){0xEB, 0x52, 0x90, 0x2D, 0x46, 0x56, 0x45, 0x2D}, @"BitLocker boot sector (Vista)", @"application/msonenote"},	//filemagic\BitLocker boot sector (Vista) (none).xml
	{1, (OFString* []){@"(none)", nil}, 0, 8, (uint8_t []){0xEB, 0x58, 0x90, 0x2D, 0x46, 0x56, 0x45, 0x2D}, @"BitLocker boot sector (Win7)", @"application/msonenote"},	//filemagic\BitLocker boot sector (Win7) (none).xml
	{2, (OFString* []){@"bmp", @"dib", nil}, 0, 2, (uint8_t []){0x42, 0x4D}, @"Bitmap image", @"image/bmp"},	//filemagic\Bitmap image BMP_DIB.xml
	{1, (OFString* []){@"xdr", nil}, 0, 1, (uint8_t []){0x3C}, @"BizTalk XML-Data Reduced Schema", @"video/x-amt-demorun"},	//filemagic\BizTalk XML-Data Reduced Schema XDR.xml
	{1, (OFString* []){@"bli", nil}, 0, 5, (uint8_t []){0x42, 0x6C, 0x69, 0x6E, 0x6B}, @"Blink compressed archive", @"application/octet-stream"},	//filemagic\Blink compressed archive BLI.xml
	{1, (OFString* []){@"pec", nil}, 0, 8, (uint8_t []){0x23, 0x50, 0x45, 0x43, 0x30, 0x30, 0x30, 0x31}, @"Brother-Babylock-Bernina Home Embroidery", @"text/plain"},	//filemagic\Brother-Babylock-Bernina Home Embroidery PEC.xml
	{1, (OFString* []){@"pes", nil}, 0, 5, (uint8_t []){0x23, 0x50, 0x45, 0x53, 0x30}, @"Brother-Babylock-Bernina Home Embroidery", @"application/ecmascript"},	//filemagic\Brother-Babylock-Bernina Home Embroidery PES.xml
	{4, (OFString* []){@"bz2", @"tar.bz2", @"tbz2", @"tb2", nil}, 0, 3, (uint8_t []){0x42, 0x5A, 0x68}, @"bzip2 compressed archive", @"application/octet-stream"},	//filemagic\bzip2 compressed archive BZ2_TAR.BZ2_TBZ2_TB2.xml
	{1, (OFString* []){@"cin", nil}, 0, 16, (uint8_t []){0x43, 0x61, 0x6C, 0x63, 0x75, 0x6C, 0x75, 0x78, 0x20, 0x49, 0x6E, 0x64, 0x6F, 0x6F, 0x72, 0x20}, @"Calculux Indoor lighting project file", @"text/plain"},	//filemagic\Calculux Indoor lighting project file CIN.xml
	{1, (OFString* []){@"cal", nil}, 0, 8, (uint8_t []){0x73, 0x72, 0x63, 0x64, 0x6F, 0x63, 0x69, 0x64}, @"CALS raster bitmap", @"application/octet-stream"},	//filemagic\CALS raster bitmap CAL.xml
	{1, (OFString* []){@"crw", nil}, 0, 8, (uint8_t []){0x49, 0x49, 0x1A, 0x00, 0x00, 0x00, 0x48, 0x45}, @"Canon RAW file", @"text/plain"},	//filemagic\Canon RAW file CRW.xml
	{1, (OFString* []){@"ac_", nil}, 0, 8, (uint8_t []){0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1}, @"CaseWare Working Papers", @"application/octet-stream"},	//filemagic\CaseWare Working Papers AC_.xml
	{1, (OFString* []){@"dsn", nil}, 0, 2, (uint8_t []){0x4D, 0x56}, @"CD Stomper Pro label file", @"text/x-asm"},	//filemagic\CD Stomper Pro label file DSN.xml
	{1, (OFString* []){@"msi", nil}, 0, 2, (uint8_t []){0x23, 0x20}, @"Cerius2 file", @"application/x-msdownload"},	//filemagic\Cerius2 file MSI.xml
	{1, (OFString* []){@"img", nil}, 0, 6, (uint8_t []){0x50, 0x49, 0x43, 0x54, 0x00, 0x08}, @"ChromaGraph Graphics Card Bitmap", @"text/plain"},	//filemagic\ChromaGraph Graphics Card Bitmap IMG.xml
	{1, (OFString* []){@"clb", nil}, 0, 4, (uint8_t []){0x43, 0x4F, 0x4D, 0x2B}, @"COM+ Catalog", @"text/plain"},	//filemagic\COM+ Catalog CLB.xml
	{1, (OFString* []){@"arj", nil}, 0, 2, (uint8_t []){0x60, 0xEA}, @"Compressed archive file", @"application/arj"},	//filemagic\Compressed archive file ARJ.xml
	{1, (OFString* []){@"pak", nil}, 0, 2, (uint8_t []){0x1A, 0x0B}, @"Compressed archive file", @"application/octet-stream"},	//filemagic\Compressed archive file PAK.xml
	{2, (OFString* []){@"lha", @"lzh", nil}, 2, 3, (uint8_t []){0x2D, 0x6C, 0x68}, @"Compressed archive", @"application/lha"},	//filemagic\Compressed archive LHA_LZH.xml
	{1, (OFString* []){@"cso", nil}, 0, 4, (uint8_t []){0x43, 0x49, 0x53, 0x4F}, @"Compressed ISO CD image", @"application/octet-stream"},	//filemagic\Compressed ISO CD image CSO.xml
	{1, (OFString* []){@"tar.z", nil}, 0, 3, (uint8_t []){0x1F, 0x9D, 0x90}, @"Compressed tape archive_1", @"application/octet-stream"},	//filemagic\Compressed tape archive_1 TAR.Z.xml
	{1, (OFString* []){@"tar.z", nil}, 0, 2, (uint8_t []){0x1F, 0xA0}, @"Compressed tape archive_2", @"application/octet-stream"},	//filemagic\Compressed tape archive_2 TAR.Z.xml
	{1, (OFString* []){@"xxx", nil}, 0, 16, (uint8_t []){0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, @"Compucon-Singer embroidery design file", @"application/octet-stream"},	//filemagic\Compucon-Singer embroidery design file XXX.xml
	{1, (OFString* []){@"cpl", nil}, 0, 2, (uint8_t []){0x4D, 0x5A}, @"Control panel application", @"text/plain"},	//filemagic\Control panel application CPL.xml
	{1, (OFString* []){@"clb", nil}, 0, 4, (uint8_t []){0x43, 0x4D, 0x58, 0x31}, @"Corel Binary metafile", @"text/plain"},	//filemagic\Corel Binary metafile CLB.xml
	{1, (OFString* []){@"cpl", nil}, 0, 2, (uint8_t []){0xDC, 0xDC}, @"Corel color palette", @"text/plain"},	//filemagic\Corel color palette CPL.xml
	{1, (OFString* []){@"psp", nil}, 0, 4, (uint8_t []){0x7E, 0x42, 0x4B, 0x00}, @"Corel Paint Shop Pro image", @"application/postscript"},	//filemagic\Corel Paint Shop Pro image PSP.xml
	{1, (OFString* []){@"cpt", nil}, 0, 8, (uint8_t []){0x43, 0x50, 0x54, 0x37, 0x46, 0x49, 0x4C, 0x45}, @"Corel Photopaint file_1", @"application/mac-compactpro"},	//filemagic\Corel Photopaint file_1 CPT.xml
	{1, (OFString* []){@"cpt", nil}, 0, 7, (uint8_t []){0x43, 0x50, 0x54, 0x46, 0x49, 0x4C, 0x45}, @"Corel Photopaint file_2", @"application/mac-compactpro"},	//filemagic\Corel Photopaint file_2 CPT.xml
	{1, (OFString* []){@"cmx", nil}, 0, 4, (uint8_t []){0x52, 0x49, 0x46, 0x46}, @"Corel Presentation Exchange metadata", @"image/x-cmx"},	//filemagic\Corel Presentation Exchange metadata CMX.xml
	{1, (OFString* []){@"cdr", nil}, 0, 4, (uint8_t []){0x52, 0x49, 0x46, 0x46}, @"CorelDraw document", @"image/x-coreldraw"},	//filemagic\CorelDraw document CDR.xml
	{1, (OFString* []){@"(none)", nil}, 0, 5, (uint8_t []){0x30, 0x37, 0x30, 0x37, 0x30}, @"cpio archive", @"application/msonenote"},	//filemagic\cpio archive (none).xml
	{1, (OFString* []){@"voc", nil}, 0, 16, (uint8_t []){0x43, 0x72, 0x65, 0x61, 0x74, 0x69, 0x76, 0x65, 0x20, 0x56, 0x6F, 0x69, 0x63, 0x65, 0x20, 0x46}, @"Creative Voice", @"application/octet-stream"},	//filemagic\Creative Voice VOC.xml
	{1, (OFString* []){@"cru", nil}, 0, 7, (uint8_t []){0x43, 0x52, 0x55, 0x53, 0x48, 0x20, 0x76}, @"Crush compressed archive", @"text/plain"},	//filemagic\Crush compressed archive CRU.xml
	{1, (OFString* []){@"csd", nil}, 0, 16, (uint8_t []){0x3C, 0x43, 0x73, 0x6F, 0x75, 0x6E, 0x64, 0x53, 0x79, 0x6E, 0x74, 0x68, 0x65, 0x73, 0x69, 0x7A}, @"Csound music", @"text/plain"},	//filemagic\Csound music CSD.xml
	{1, (OFString* []){@"dax", nil}, 0, 5, (uint8_t []){0x46, 0x4F, 0x52, 0x4D, 0x00}, @"DAKX Compressed Audio", @"application/octet-stream"},	//filemagic\DAKX Compressed Audio DAX.xml
	{1, (OFString* []){@"dex", nil}, 0, 4, (uint8_t []){0x64, 0x65, 0x78, 0x0A}, @"Dalvik (Android) executable file", @"application/octet-stream"},	//filemagic\Dalvik (Android) executable file dex.xml
	{1, (OFString* []){@"dax", nil}, 0, 4, (uint8_t []){0x44, 0x41, 0x58, 0x00}, @"DAX Compressed CD image", @"application/octet-stream"},	//filemagic\DAX Compressed CD image DAX.xml
	{1, (OFString* []){@"cnv", nil}, 0, 8, (uint8_t []){0x53, 0x51, 0x4C, 0x4F, 0x43, 0x4F, 0x4E, 0x56}, @"DB2 conversion file", @"text/plain"},	//filemagic\DB2 conversion file CNV.xml
	{1, (OFString* []){@"db3", nil}, 0, 1, (uint8_t []){0x03}, @"dBASE III file", @"application/octet-stream"},	//filemagic\dBASE III file DB3.xml
	{1, (OFString* []){@"db4", nil}, 0, 1, (uint8_t []){0x04}, @"dBASE IV file", @"application/octet-stream"},	//filemagic\dBASE IV file DB4.xml
	{1, (OFString* []){@"db", nil}, 0, 1, (uint8_t []){0x08}, @"dBASE IV or dBFast configuration file", @"application/octet-stream"},	//filemagic\dBASE IV or dBFast configuration file DB.xml
	{1, (OFString* []){@"dtd", nil}, 0, 8, (uint8_t []){0x07, 0x64, 0x74, 0x32, 0x64, 0x64, 0x74, 0x64}, @"DesignTools 2D Design file", @"application/x-troff"},	//filemagic\DesignTools 2D Design file DTD.xml
	{1, (OFString* []){@"doc", nil}, 0, 4, (uint8_t []){0x0D, 0x44, 0x4F, 0x43}, @"DeskMate Document", @"application/msword"},	//filemagic\DeskMate Document DOC.xml
	{1, (OFString* []){@"wks", nil}, 0, 4, (uint8_t []){0x0E, 0x57, 0x4B, 0x53}, @"DeskMate Worksheet", @"application/vnd.ms-works"},	//filemagic\DeskMate Worksheet WKS.xml
	{1, (OFString* []){@"opt", nil}, 0, 8, (uint8_t []){0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1}, @"Developer Studio File Options file", @"application/octet-stream"},	//filemagic\Developer Studio File Options file OPT.xml
	{1, (OFString* []){@"opt", nil}, 512, 5, (uint8_t []){0xFD, 0xFF, 0xFF, 0xFF, 0x20}, @"Developer Studio subheader", @"application/octet-stream"},	//filemagic\Developer Studio subheader OPT.xml
	{1, (OFString* []){@"dun", nil}, 0, 7, (uint8_t []){0x5B, 0x50, 0x68, 0x6F, 0x6E, 0x65, 0x5D}, @"Dial-up networking file", @"application/octet-stream"},	//filemagic\Dial-up networking file DUN.xml
	{1, (OFString* []){@"dss", nil}, 0, 4, (uint8_t []){0x02, 0x64, 0x73, 0x73}, @"Digital Speech Standard file", @"text/x-asm"},	//filemagic\Digital Speech Standard file DSS.xml
	{1, (OFString* []){@"img", nil}, 0, 9, (uint8_t []){0x7E, 0x74, 0x2C, 0x01, 0x50, 0x70, 0x02, 0x4D, 0x52}, @"Digital Watchdog DW-TP-500G audio", @"text/plain"},	//filemagic\Digital Watchdog DW-TP-500G audio IMG.xml
	{1, (OFString* []){@"ax", nil}, 0, 8, (uint8_t []){0x4D, 0x5A, 0x90, 0x00, 0x03, 0x00, 0x00, 0x00}, @"DirectShow filter", @"application/octet-stream"},	//filemagic\DirectShow filter AX.xml
	{1, (OFString* []){@"sys", nil}, 0, 4, (uint8_t []){0xFF, 0xFF, 0xFF, 0xFF}, @"DOS system driver", @"text/x-asm"},	//filemagic\DOS system driver SYS.xml
	{1, (OFString* []){@"adx", nil}, 0, 7, (uint8_t []){0x80, 0x00, 0x00, 0x20, 0x03, 0x12, 0x04}, @"Dreamcast audio", @"application/octet-stream"},	//filemagic\Dreamcast audio ADX.xml
	{1, (OFString* []){@"dst", nil}, 0, 4, (uint8_t []){0x44, 0x53, 0x54, 0x62}, @"DST Compression", @"application/vnd.sailingtracker.track"},	//filemagic\DST Compression DST.xml
	{1, (OFString* []){@"ifo", nil}, 0, 3, (uint8_t []){0x44, 0x56, 0x44}, @"DVD info file", @"application/octet-stream"},	//filemagic\DVD info file IFO.xml
	{2, (OFString* []){@"mpg", @"vob", nil}, 0, 4, (uint8_t []){0x00, 0x00, 0x01, 0xBA}, @"DVD video file", @"application/octet-stream"},	//filemagic\DVD video file MPG_VOB.xml
	{1, (OFString* []){@"dvr", nil}, 0, 3, (uint8_t []){0x44, 0x56, 0x44}, @"DVR-Studio stream file", @"video/x-dv"},	//filemagic\DVR-Studio stream file DVR.xml
	{1, (OFString* []){@"cl5", nil}, 0, 4, (uint8_t []){0x10, 0x00, 0x00, 0x00}, @"Easy CD Creator 5 Layout file", @"text/plain"},	//filemagic\Easy CD Creator 5 Layout file CL5.xml
	{1, (OFString* []){@"dat", nil}, 0, 8, (uint8_t []){0x45, 0x52, 0x46, 0x53, 0x53, 0x41, 0x56, 0x45}, @"EasyRecovery Saved State file", @"application/octet-stream"},	//filemagic\EasyRecovery Saved State file DAT.xml
	{1, (OFString* []){@"efx", nil}, 0, 2, (uint8_t []){0xDC, 0xFE}, @"eFax file", @"text/plain"},	//filemagic\eFax file EFX.xml
	{1, (OFString* []){@"(none)", nil}, 0, 4, (uint8_t []){0x7F, 0x45, 0x4C, 0x46}, @"ELF executable", @"application/msonenote"},	//filemagic\ELF executable (none).xml
	{1, (OFString* []){@"cdr", nil}, 0, 8, (uint8_t []){0x45, 0x4C, 0x49, 0x54, 0x45, 0x20, 0x43, 0x6F}, @"Elite Plus Commander game file", @"image/x-coreldraw"},	//filemagic\Elite Plus Commander game file CDR.xml
	{1, (OFString* []){@"eps", nil}, 0, 8, (uint8_t []){0x25, 0x21, 0x50, 0x53, 0x2D, 0x41, 0x64, 0x6F}, @"Encapsulated PostScript file", @"application/postscript"},	//filemagic\Encapsulated PostScript file EPS.xml
	{2, (OFString* []){@"cas", @"cbk", nil}, 0, 6, (uint8_t []){0x5F, 0x43, 0x41, 0x53, 0x45, 0x5F}, @"EnCase case file", @"application/octet-stream"},	//filemagic\EnCase case file CAS_CBK.xml
	{1, (OFString* []){@"ex01", nil}, 0, 7, (uint8_t []){0x45, 0x56, 0x46, 0x32, 0x0D, 0x0A, 0x81}, @"EnCase Evidence File Format V2", @"application/octet-stream"},	//filemagic\EnCase Evidence File Format V2 Ex01.xml
	{1, (OFString* []){@"enl", nil}, 32, 10, (uint8_t []){0x40, 0x40, 0x40, 0x20, 0x00, 0x00, 0x40, 0x40, 0x40, 0x40}, @"EndNote Library File", @"application/octet-stream"},	//filemagic\EndNote Library File ENL.xml
	{1, (OFString* []){@"xpt", nil}, 0, 4, (uint8_t []){0x50, 0x4B, 0x03, 0x04}, @"eXact Packager Models", @"application/x-troff"},	//filemagic\eXact Packager Models XPT.xml
	{1, (OFString* []){@"xls", nil}, 512, 8, (uint8_t []){0x09, 0x08, 0x10, 0x00, 0x00, 0x06, 0x05, 0x00}, @"Excel spreadsheet subheader_1", @"application/excel"},	//filemagic\Excel spreadsheet subheader_1 XLS.xml
	{1, (OFString* []){@"xls", nil}, 512, 5, (uint8_t []){0xFD, 0xFF, 0xFF, 0xFF, 0x10}, @"Excel spreadsheet subheader_2", @"application/excel"},	//filemagic\Excel spreadsheet subheader_2 XLS.xml
	{1, (OFString* []){@"xls", nil}, 512, 5, (uint8_t []){0xFD, 0xFF, 0xFF, 0xFF, 0x1F}, @"Excel spreadsheet subheader_3", @"application/excel"},	//filemagic\Excel spreadsheet subheader_3 XLS.xml
	{1, (OFString* []){@"xls", nil}, 512, 5, (uint8_t []){0xFD, 0xFF, 0xFF, 0xFF, 0x22}, @"Excel spreadsheet subheader_4", @"application/excel"},	//filemagic\Excel spreadsheet subheader_4 XLS.xml
	{1, (OFString* []){@"xls", nil}, 512, 5, (uint8_t []){0xFD, 0xFF, 0xFF, 0xFF, 0x23}, @"Excel spreadsheet subheader_5", @"application/excel"},	//filemagic\Excel spreadsheet subheader_5 XLS.xml
	{1, (OFString* []){@"xls", nil}, 512, 5, (uint8_t []){0xFD, 0xFF, 0xFF, 0xFF, 0x28}, @"Excel spreadsheet subheader_6", @"application/excel"},	//filemagic\Excel spreadsheet subheader_6 XLS.xml
	{1, (OFString* []){@"xls", nil}, 512, 5, (uint8_t []){0xFD, 0xFF, 0xFF, 0xFF, 0x29}, @"Excel spreadsheet subheader_7", @"application/excel"},	//filemagic\Excel spreadsheet subheader_7 XLS.xml
	{1, (OFString* []){@"eml", nil}, 0, 2, (uint8_t []){0x58, 0x2D}, @"Exchange e-mail", @"message/rfc822"},	//filemagic\Exchange e-mail EML.xml
	{1, (OFString* []){@"e01", nil}, 0, 8, (uint8_t []){0x45, 0x56, 0x46, 0x09, 0x0D, 0x0A, 0xFF, 0x00}, @"Expert Witness Compression Format", @"application/octet-stream"},	//filemagic\Expert Witness Compression Format E01.xml
	{1, (OFString* []){@"(none)", nil}, 0, 4, (uint8_t []){0xA1, 0xB2, 0xCD, 0x34}, @"Extended tcpdump (libpcap) capture file", @"application/msonenote"},	//filemagic\Extended tcpdump (libpcap) capture file (none).xml
	{1, (OFString* []){@"xar", nil}, 0, 4, (uint8_t []){0x78, 0x61, 0x72, 0x21}, @"eXtensible ARchive file", @"application/octet-stream"},	//filemagic\eXtensible ARchive file XAR.xml
	{1, (OFString* []){@"(none)", nil}, 0, 3, (uint8_t []){0xF0, 0xFF, 0xFF}, @"FAT12 File Allocation Table", @"application/msonenote"},	//filemagic\FAT12 File Allocation Table (none).xml
	{1, (OFString* []){@"(none)", nil}, 0, 4, (uint8_t []){0xF8, 0xFF, 0xFF, 0xFF}, @"FAT16 File Allocation Table", @"application/msonenote"},	//filemagic\FAT16 File Allocation Table (none).xml
	{1, (OFString* []){@"(none)", nil}, 0, 8, (uint8_t []){0xF8, 0xFF, 0xFF, 0x0F, 0xFF, 0xFF, 0xFF, 0x0F}, @"FAT32 File Allocation Table_1", @"application/msonenote"},	//filemagic\FAT32 File Allocation Table_1 (none).xml
	{1, (OFString* []){@"(none)", nil}, 0, 8, (uint8_t []){0xF8, 0xFF, 0xFF, 0x0F, 0xFF, 0xFF, 0xFF, 0xFF}, @"FAT32 File Allocation Table_2", @"application/msonenote"},	//filemagic\FAT32 File Allocation Table_2 (none).xml
	{1, (OFString* []){@"fdb", nil}, 0, 5, (uint8_t []){0x46, 0x44, 0x42, 0x48, 0x00}, @"Fiasco database definition file", @"text/plain"},	//filemagic\Fiasco database definition file FDB.xml
	{2, (OFString* []){@"fdb", @"gdb", nil}, 0, 4, (uint8_t []){0x01, 0x00, 0x39, 0x30}, @"Firebird and Interbase database files", @"text/plain"},	//filemagic\Firebird and Interbase database files FDB_GDB.xml
	{1, (OFString* []){@"flv", nil}, 0, 3, (uint8_t []){0x46, 0x4C, 0x56}, @"Flash video file", @"text/plain"},	//filemagic\Flash video file FLV.xml
	{1, (OFString* []){@"fits", nil}, 0, 30, (uint8_t []){0x53, 0x49, 0x4D, 0x50, 0x4C, 0x45, 0x20, 0x20, 0x3D, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x54}, @"Flexible Image Transport System (FITS) file", @"application/x-troff"},	//filemagic\Flexible Image Transport System (FITS) file FITS.xml
	{1, (OFString* []){@"fli", nil}, 0, 2, (uint8_t []){0x00, 0x11}, @"FLIC animation", @"text/plain"},	//filemagic\FLIC animation FLI.xml
	{1, (OFString* []){@"cfg", nil}, 0, 8, (uint8_t []){0x5B, 0x66, 0x6C, 0x74, 0x73, 0x69, 0x6D, 0x2E}, @"Flight Simulator Aircraft Configuration", @"text/plain"},	//filemagic\Flight Simulator Aircraft Configuration CFG.xml
	{1, (OFString* []){@"fon", nil}, 0, 2, (uint8_t []){0x4D, 0x5A}, @"Font file", @"application/octet-stream"},	//filemagic\Font file FON.xml
	{1, (OFString* []){@"flac", nil}, 0, 8, (uint8_t []){0x66, 0x4C, 0x61, 0x43, 0x00, 0x00, 0x00, 0x22}, @"Free Lossless Audio Codec file", @"application/octet-stream"},	//filemagic\Free Lossless Audio Codec file FLAC.xml
	{1, (OFString* []){@"arc", nil}, 0, 4, (uint8_t []){0x41, 0x72, 0x43, 0x01}, @"FreeArc compressed file", @"application/octet-stream"},	//filemagic\FreeArc compressed file ARC.xml
	{1, (OFString* []){@"fbm", nil}, 0, 8, (uint8_t []){0x25, 0x62, 0x69, 0x74, 0x6D, 0x61, 0x70}, @"Fuzzy bitmap (FBM) file", @"application/x-maker"},	//filemagic\Fuzzy bitmap (FBM) file FBM.xml
	{1, (OFString* []){@"img", nil}, 0, 4, (uint8_t []){0xEB, 0x3C, 0x90, 0x2A}, @"GEM Raster file", @"text/plain"},	//filemagic\GEM Raster file IMG.xml
	{1, (OFString* []){@"dwg", nil}, 0, 4, (uint8_t []){0x41, 0x43, 0x31, 0x30}, @"Generic AutoCAD drawing", @"application/acad"},	//filemagic\Generic AutoCAD drawing DWG.xml
	{1, (OFString* []){@"drw", nil}, 0, 1, (uint8_t []){0x07}, @"Generic drawing programs", @"application/drafting"},	//filemagic\Generic drawing programs DRW.xml
	{1, (OFString* []){@"eml", nil}, 0, 8, (uint8_t []){0x52, 0x65, 0x74, 0x75, 0x72, 0x6E, 0x2D, 0x50}, @"Generic e-mail_1", @"message/rfc822"},	//filemagic\Generic e-mail_1 EML.xml
	{1, (OFString* []){@"eml", nil}, 0, 4, (uint8_t []){0x46, 0x72, 0x6F, 0x6D}, @"Generic e-mail_2", @"message/rfc822"},	//filemagic\Generic e-mail_2 EML.xml
	{1, (OFString* []){@"g64", nil}, 0, 16, (uint8_t []){0x47, 0x65, 0x6E, 0x65, 0x74, 0x65, 0x63, 0x20, 0x4F, 0x6D, 0x6E, 0x69, 0x63, 0x61, 0x73, 0x74}, @"Genetec video archive", @"text/plain"},	//filemagic\Genetec video archive G64.xml
	{1, (OFString* []){@"gif", nil}, 0, 4, (uint8_t []){0x47, 0x49, 0x46, 0x38}, @"GIF file", @"image/gif"},	//filemagic\GIF file GIF.xml
	{1, (OFString* []){@"xcf", nil}, 0, 8, (uint8_t []){0x67, 0x69, 0x6d, 0x70, 0x20, 0x78, 0x63, 0x66}, @"GIMP file", @"application/x-xcf"},	//filemagic\GIMP file XCF.xml
	{1, (OFString* []){@"pat", nil}, 0, 4, (uint8_t []){0x47, 0x50, 0x41, 0x54}, @"GIMP pattern file", @"application/octet-stream"},	//filemagic\GIMP pattern file PAT.xml
	{1, (OFString* []){@"info", nil}, 0, 8, (uint8_t []){0x54, 0x68, 0x69, 0x73, 0x20, 0x69, 0x73, 0x20}, @"GNU Info Reader file", @"application/inf"},	//filemagic\GNU Info Reader file INFO.xml
	{1, (OFString* []){@"kmz", nil}, 0, 4, (uint8_t []){0x50, 0x4B, 0x03, 0x04}, @"Google Earth session file", @"application/vnd.google-earth.kmz"},	//filemagic\Google Earth session file KMZ.xml
	{1, (OFString* []){@"gpg", nil}, 0, 1, (uint8_t []){0x99}, @"GPG public keyring", @"text/plain"},	//filemagic\GPG public keyring GPG.xml
	{1, (OFString* []){@"gpx", nil}, 0, 16, (uint8_t []){0x3C, 0x67, 0x70, 0x78, 0x20, 0x76, 0x65, 0x72, 0x73, 0x69, 0x6F, 0x6E, 0x3D, 0x22, 0x31, 0x2E}, @"GPS Exchange (v1.1)", @"application/gpx+xml"},	//filemagic\GPS Exchange (v1.1) GPX.xml
	{1, (OFString* []){@"gz", nil}, 0, 3, (uint8_t []){0x1F, 0x8B, 0x08}, @"GZIP archive file", @"application/octet-stream"},	//filemagic\GZIP archive file GZ.xml
	{1, (OFString* []){@"hap", nil}, 0, 4, (uint8_t []){0x91, 0x33, 0x48, 0x46}, @"Hamarsoft compressed archive", @"application/octet-stream"},	//filemagic\Hamarsoft compressed archive HAP.xml
	{1, (OFString* []){@"sh3", nil}, 0, 5, (uint8_t []){0x48, 0x48, 0x47, 0x42, 0x31}, @"Harvard Graphics presentation file", @"application/x-bsh"},	//filemagic\Harvard Graphics presentation file SH3.xml
	{1, (OFString* []){@"shw", nil}, 0, 4, (uint8_t []){0x53, 0x48, 0x4F, 0x57}, @"Harvard Graphics presentation", @"application/x-bsh"},	//filemagic\Harvard Graphics presentation SHW.xml
	{1, (OFString* []){@"syw", nil}, 0, 4, (uint8_t []){0x41, 0x4D, 0x59, 0x4F}, @"Harvard Graphics symbol graphic", @"text/x-asm"},	//filemagic\Harvard Graphics symbol graphic SYW.xml
	{1, (OFString* []){@"hus", nil}, 0, 4, (uint8_t []){0x5D, 0xFC, 0xC8, 0x00}, @"Husqvarna Designer", @"text/plain"},	//filemagic\Husqvarna Designer HUS.xml
	{1, (OFString* []){@"dat", nil}, 0, 8, (uint8_t []){0x43, 0x6C, 0x69, 0x65, 0x6E, 0x74, 0x20, 0x55}, @"IE History file", @"application/octet-stream"},	//filemagic\IE History file DAT.xml
	{1, (OFString* []){@"img", nil}, 0, 4, (uint8_t []){0x53, 0x43, 0x4D, 0x49}, @"Img Software Bitmap", @"text/plain"},	//filemagic\Img Software Bitmap IMG.xml
	{1, (OFString* []){@"(none)", nil}, 0, 4, (uint8_t []){0x04, 0x00, 0x00, 0x00}, @"INFO2 Windows recycle bin_1", @"application/msonenote"},	//filemagic\INFO2 Windows recycle bin_1 (none).xml
	{1, (OFString* []){@"(none)", nil}, 0, 4, (uint8_t []){0x05, 0x00, 0x00, 0x00}, @"INFO2 Windows recycle bin_2", @"application/msonenote"},	//filemagic\INFO2 Windows recycle bin_2 (none).xml
	{1, (OFString* []){@"dat", nil}, 0, 8, (uint8_t []){0x49, 0x6E, 0x6E, 0x6F, 0x20, 0x53, 0x65, 0x74}, @"Inno Setup Uninstall Log", @"application/octet-stream"},	//filemagic\Inno Setup Uninstall Log DAT.xml
	{2, (OFString* []){@"cab", @"hdr", nil}, 0, 4, (uint8_t []){0x49, 0x53, 0x63, 0x28}, @"Install Shield compressed file", @"application/octet-stream"},	//filemagic\Install Shield compressed file CAB_HDR.xml
	{1, (OFString* []){@"p10", nil}, 0, 4, (uint8_t []){0x64, 0x00, 0x00, 0x00}, @"Intel PROset|Wireless Profile", @"application/pkcs10"},	//filemagic\Intel PROset_Wireless Profile P10.xml
	{1, (OFString* []){@"ipd", nil}, 0, 17, (uint8_t []){0x49, 0x6E, 0x74, 0x65, 0x72, 0x40, 0x63, 0x74, 0x69, 0x76, 0x65, 0x20, 0x50, 0x61, 0x67, 0x65}, @"Inter@ctive Pager Backup (BlackBerry file", @"application/x-ip2"},	//filemagic\Inter@ctive Pager Backup (BlackBerry file IPD.xml
	{1, (OFString* []){@"mp4", nil}, 4, 8, (uint8_t []){0x66, 0x74, 0x79, 0x70, 0x69, 0x73, 0x6F, 0x6D}, @"ISO Base Media file (MPEG-4) v1", @"application/mp4"},	//filemagic\ISO Base Media file (MPEG-4) v1 MP4.xml
	{1, (OFString* []){@"iso", nil}, 0, 5, (uint8_t []){0x43, 0x44, 0x30, 0x30, 0x31}, @"ISO-9660 CD Disc Image", @"application/octet-stream"},	//filemagic\ISO-9660 CD Disc Image ISO.xml
	{1, (OFString* []){@"jar", nil}, 0, 4, (uint8_t []){0x5F, 0x27, 0xA8, 0x89}, @"Jar archive", @"application/java-archive"},	//filemagic\Jar archive JAR.xml
	{1, (OFString* []){@"jar", nil}, 0, 6, (uint8_t []){0x4A, 0x41, 0x52, 0x43, 0x53, 0x00}, @"JARCS compressed archive", @"application/java-archive"},	//filemagic\JARCS compressed archive JAR.xml
	{1, (OFString* []){@"jar", nil}, 0, 4, (uint8_t []){0x50, 0x4B, 0x03, 0x04}, @"Java archive_1", @"application/java-archive"},	//filemagic\Java archive_1 JAR.xml
	{1, (OFString* []){@"jar", nil}, 0, 8, (uint8_t []){0x50, 0x4B, 0x03, 0x04, 0x14, 0x00, 0x08, 0x00}, @"Java archive_2", @"application/java-archive"},	//filemagic\Java archive_2 JAR.xml
	{1, (OFString* []){@"class", nil}, 0, 4, (uint8_t []){0xCA, 0xFE, 0xBA, 0xBE}, @"Java bytecode", @"application/java"},	//filemagic\Java bytecode CLASS.xml
	{1, (OFString* []){@"jceks", nil}, 0, 4, (uint8_t []){0xCE, 0xCE, 0xCE, 0xCE}, @"Java Cryptography Extension keystore", @"text/plain"},	//filemagic\Java Cryptography Extension keystore JCEKS.xml
	{1, (OFString* []){@"(none)", nil}, 0, 2, (uint8_t []){0xAC, 0xED}, @"Java serialization data", @"application/msonenote"},	//filemagic\Java serialization data (none).xml
	{1, (OFString* []){@"(none)", nil}, 0, 4, (uint8_t []){0xFE, 0xED, 0xFE, 0xED}, @"JavaKeyStore", @"application/msonenote"},	//filemagic\JavaKeyStore (none).xml
	{1, (OFString* []){@"jb2", nil}, 0, 8, (uint8_t []){0x97, 0x4A, 0x42, 0x32, 0x0D, 0x0A, 0x1A, 0x0A}, @"JBOG2 image file", @"application/octet-stream"},	//filemagic\JBOG2 image file JB2.xml
	{1, (OFString* []){@"lbk", nil}, 0, 4, (uint8_t []){0xC8, 0x00, 0x79, 0x00}, @"Jeppesen FliteLog file", @"application/octet-stream"},	//filemagic\Jeppesen FliteLog file LBK.xml
	{1, (OFString* []){@"jp2", nil}, 0, 8, (uint8_t []){0x00, 0x00, 0x00, 0x0C, 0x6A, 0x50, 0x20, 0x20}, @"JPEG2000 image files", @"text/x-pascal"},	//filemagic\JPEG2000 image files JP2.xml
	{4, (OFString* []){@"jfif", @"jpe", @"jpeg", @"jpg", nil}, 0, 3, (uint8_t []){0xFF, 0xD8, 0xFF}, @"JPEG|EXIF|SPIFF images", @"application/fractals"},	//filemagic\JPEG_EXIF_SPIFF images JFIF_JPE_JPEG_JPG.xml
	{1, (OFString* []){@"sys", nil}, 0, 8, (uint8_t []){0xFF, 0x4B, 0x45, 0x59, 0x42, 0x20, 0x20, 0x20}, @"Keyboard driver file", @"text/x-asm"},	//filemagic\Keyboard driver file SYS.xml
	{1, (OFString* []){@"kgb", nil}, 0, 8, (uint8_t []){0x4B, 0x47, 0x42, 0x5F, 0x61, 0x72, 0x63, 0x68}, @"KGB archive", @"text/plain"},	//filemagic\KGB archive KGB.xml
	{1, (OFString* []){@"cin", nil}, 0, 4, (uint8_t []){0x80, 0x2A, 0x5F, 0xD7}, @"Kodak Cineon image", @"text/plain"},	//filemagic\Kodak Cineon image CIN.xml
	{1, (OFString* []){@"(none)", nil}, 0, 8, (uint8_t []){0x4B, 0x57, 0x41, 0x4A, 0x88, 0xF0, 0x27, 0xD1}, @"KWAJ (compressed) file", @"application/msonenote"},	//filemagic\KWAJ (compressed) file (none).xml
	{1, (OFString* []){@"kwd", nil}, 0, 4, (uint8_t []){0x50, 0x4B, 0x03, 0x04}, @"KWord document", @"application/vnd.kde.kword"},	//filemagic\KWord document KWD.xml
	{1, (OFString* []){@"arc", nil}, 0, 2, (uint8_t []){0x1A, 0x02}, @"LH archive (old vers.|type 1)", @"application/octet-stream"},	//filemagic\LH archive (old vers._type 1) ARC.xml
	{1, (OFString* []){@"arc", nil}, 0, 2, (uint8_t []){0x1A, 0x03}, @"LH archive (old vers.|type 2)", @"application/octet-stream"},	//filemagic\LH archive (old vers._type 2) ARC.xml
	{1, (OFString* []){@"arc", nil}, 0, 2, (uint8_t []){0x1A, 0x04}, @"LH archive (old vers.|type 3)", @"application/octet-stream"},	//filemagic\LH archive (old vers._type 3) ARC.xml
	{1, (OFString* []){@"arc", nil}, 0, 2, (uint8_t []){0x1A, 0x08}, @"LH archive (old vers.|type 4)", @"application/octet-stream"},	//filemagic\LH archive (old vers._type 4) ARC.xml
	{1, (OFString* []){@"arc", nil}, 0, 2, (uint8_t []){0x1A, 0x09}, @"LH archive (old vers.|type 5)", @"application/octet-stream"},	//filemagic\LH archive (old vers._type 5) ARC.xml
	{1, (OFString* []){@"ax", nil}, 0, 2, (uint8_t []){0x4D, 0x5A}, @"Library cache file", @"application/octet-stream"},	//filemagic\Library cache file AX.xml
	{1, (OFString* []){@"e01", nil}, 0, 8, (uint8_t []){0x4C, 0x56, 0x46, 0x09, 0x0D, 0x0A, 0xFF, 0x00}, @"Logical File Evidence Format", @"application/octet-stream"},	//filemagic\Logical File Evidence Format E01.xml
	{1, (OFString* []){@"wk1", nil}, 0, 8, (uint8_t []){0x00, 0x00, 0x02, 0x00, 0x06, 0x04, 0x06, 0x00}, @"Lotus 1-2-3 (v1)", @"application/x-123"},	//filemagic\Lotus 1-2-3 (v1) WK1.xml
	{1, (OFString* []){@"wk3", nil}, 0, 8, (uint8_t []){0x00, 0x00, 0x1A, 0x00, 0x00, 0x10, 0x04, 0x00}, @"Lotus 1-2-3 (v3)", @"application/x-123"},	//filemagic\Lotus 1-2-3 (v3) WK3.xml
	{2, (OFString* []){@"wk4", @"wk5", nil}, 0, 8, (uint8_t []){0x00, 0x00, 0x1A, 0x00, 0x02, 0x10, 0x04, 0x00}, @"Lotus 1-2-3 (v4|v5)", @"application/x-123"},	//filemagic\Lotus 1-2-3 (v4_v5) WK4_WK5.xml
	{1, (OFString* []){@"123", nil}, 0, 7, (uint8_t []){0x00, 0x00, 0x1A, 0x00, 0x05, 0x10, 0x04}, @"Lotus 1-2-3 (v9)", @"application/vnd.lotus-1-2-3"},	//filemagic\Lotus 1-2-3 (v9) 123.xml
	{1, (OFString* []){@"sam", nil}, 0, 5, (uint8_t []){0x5B, 0x56, 0x45, 0x52, 0x5D}, @"Lotus AMI Pro document_1", @"application/octet-stream"},	//filemagic\Lotus AMI Pro document_1 SAM.xml
	{1, (OFString* []){@"sam", nil}, 0, 5, (uint8_t []){0x5B, 0x76, 0x65, 0x72, 0x5D}, @"Lotus AMI Pro document_2", @"application/octet-stream"},	//filemagic\Lotus AMI Pro document_2 SAM.xml
	{1, (OFString* []){@"nsf", nil}, 0, 6, (uint8_t []){0x1A, 0x00, 0x00, 0x04, 0x00, 0x00}, @"Lotus Notes database", @"application/vnd.lotus-notes"},	//filemagic\Lotus Notes database NSF.xml
	{1, (OFString* []){@"ntf", nil}, 0, 3, (uint8_t []){0x1A, 0x00, 0x00}, @"Lotus Notes database template", @"application/vnd.nitf"},	//filemagic\Lotus Notes database template NTF.xml
	{1, (OFString* []){@"lwp", nil}, 0, 7, (uint8_t []){0x57, 0x6F, 0x72, 0x64, 0x50, 0x72, 0x6F}, @"Lotus WordPro file", @"application/vnd.lotus-wordpro"},	//filemagic\Lotus WordPro file LWP.xml
	{1, (OFString* []){@"apr", nil}, 0, 8, (uint8_t []){0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1}, @"Lotus|IBM Approach 97 file", @"application/octet-stream"},	//filemagic\Lotus_IBM Approach 97 file APR.xml
	{1, (OFString* []){@"zip", nil}, 0, 4, (uint8_t []){0x50, 0x4B, 0x03, 0x04}, @"MacOS X Dashboard Widget", @"application/octet-stream"},	//filemagic\MacOS X Dashboard Widget ZIP.xml
	{1, (OFString* []){@"dmg", nil}, 0, 7, (uint8_t []){0x78, 0x01, 0x73, 0x0D, 0x62, 0x62, 0x60}, @"MacOS X image file", @"application/octet-stream"},	//filemagic\MacOS X image file DMG.xml
	{1, (OFString* []){@"swf", nil}, 0, 3, (uint8_t []){0x5A, 0x57, 0x53}, @"Macromedia Shockwave Flash", @"application/x-shockwave-flash"},	//filemagic\Macromedia Shockwave Flash SWF.xml
	{1, (OFString* []){@"mif", nil}, 0, 8, (uint8_t []){0x56, 0x65, 0x72, 0x73, 0x69, 0x6F, 0x6E, 0x20}, @"MapInfo Interchange Format file", @"application/vnd.mif"},	//filemagic\MapInfo Interchange Format file MIF.xml
	{1, (OFString* []){@"dat", nil}, 0, 1, (uint8_t []){0x03}, @"MapInfo Native Data Format", @"application/octet-stream"},	//filemagic\MapInfo Native Data Format DAT.xml
	{1, (OFString* []){@"bsb", nil}, 0, 1, (uint8_t []){0x21}, @"MapInfo Sea Chart", @"text/x-asm"},	//filemagic\MapInfo Sea Chart BSB.xml
	{1, (OFString* []){@"mar", nil}, 0, 5, (uint8_t []){0x4D, 0x41, 0x72, 0x30, 0x00}, @"MAr compressed archive", @"application/mathematica"},	//filemagic\MAr compressed archive MAR.xml
	{1, (OFString* []){@"mkv", nil}, 0, 8, (uint8_t []){0x1A, 0x45, 0xDF, 0xA3, 0x93, 0x42, 0x82, 0x88}, @"Matroska stream file", @"text/plain"},	//filemagic\Matroska stream file MKV.xml
	{1, (OFString* []){@"(none)", nil}, 0, 4, (uint8_t []){0x00, 0x0D, 0xBB, 0xA0}, @"Mbox table of contents file", @"application/msonenote"},	//filemagic\Mbox table of contents file (none).xml
	{1, (OFString* []){@"pdb", nil}, 0, 8, (uint8_t []){0x4D, 0x2D, 0x57, 0x20, 0x50, 0x6F, 0x63, 0x6B}, @"Merriam-Webster Pocket Dictionary", @"application/vnd.palm"},	//filemagic\Merriam-Webster Pocket Dictionary PDB.xml
	{1, (OFString* []){@"ds4", nil}, 0, 4, (uint8_t []){0x52, 0x49, 0x46, 0x46}, @"Micrografx Designer graphic", @"text/x-asm"},	//filemagic\Micrografx Designer graphic DS4.xml
	{1, (OFString* []){@"drw", nil}, 0, 6, (uint8_t []){0x01, 0xFF, 0x02, 0x04, 0x03, 0x02}, @"Micrografx vector graphic file", @"application/drafting"},	//filemagic\Micrografx vector graphic file DRW.xml
	{1, (OFString* []){@"accdb", nil}, 0, 19, (uint8_t []){0x00, 0x01, 0x00, 0x00, 0x53, 0x74, 0x61, 0x6E, 0x64, 0x61, 0x72, 0x64, 0x20, 0x41, 0x43, 0x45, 0x20, 0x44, 0x42}, @"Microsoft Access 2007", @"application/octet-stream"},	//filemagic\Microsoft Access 2007 ACCDB.xml
	{1, (OFString* []){@"mdb", nil}, 0, 19, (uint8_t []){0x00, 0x01, 0x00, 0x00, 0x53, 0x74, 0x61, 0x6E, 0x64, 0x61, 0x72, 0x64, 0x20, 0x4A, 0x65, 0x74, 0x20, 0x44, 0x42}, @"Microsoft Access", @"application/msaccess"},	//filemagic\Microsoft Access MDB.xml
	{1, (OFString* []){@"cab", nil}, 0, 4, (uint8_t []){0x4D, 0x53, 0x43, 0x46}, @"Microsoft cabinet file", @"application/octet-stream"},	//filemagic\Microsoft cabinet file CAB.xml
	{1, (OFString* []){@"cpx", nil}, 0, 8, (uint8_t []){0x5B, 0x57, 0x69, 0x6E, 0x64, 0x6F, 0x77, 0x73}, @"Microsoft Code Page Translation file", @"text/plain"},	//filemagic\Microsoft Code Page Translation file CPX.xml
	{1, (OFString* []){@"msc", nil}, 0, 8, (uint8_t []){0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1}, @"Microsoft Common Console Document", @"application/vnd.ibm.secure-container"},	//filemagic\Microsoft Common Console Document MSC.xml
	{1, (OFString* []){@"msi", nil}, 0, 8, (uint8_t []){0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1}, @"Microsoft Installer package", @"application/x-msdownload"},	//filemagic\Microsoft Installer package MSI.xml
	{1, (OFString* []){@"mny", nil}, 0, 19, (uint8_t []){0x00, 0x01, 0x00, 0x00, 0x4D, 0x53, 0x49, 0x53, 0x41, 0x4D, 0x20, 0x44, 0x61, 0x74, 0x61, 0x62, 0x61, 0x73, 0x65}, @"Microsoft Money file", @"application/x-msmoney"},	//filemagic\Microsoft Money file MNY.xml
	{7, (OFString* []){@"doc", @"dot", @"pps", @"ppt", @"xla", @"xls", @"wiz", nil}, 0, 8, (uint8_t []){0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1}, @"Microsoft Office document", @"application/excel"},	//filemagic\Microsoft Office document DOC_DOT_PPS_PPT_XLA_XLS_WIZ.xml
	{1, (OFString* []){@"ost", nil}, 0, 4, (uint8_t []){0x21, 0x42, 0x44, 0x4E}, @"Microsoft Outlook Exchange Offline Storage Folder", @"application/octet-stream"},	//filemagic\Microsoft Outlook Exchange Offline Storage Folder OST.xml
	{1, (OFString* []){@"wim", nil}, 0, 5, (uint8_t []){0x4D, 0x53, 0x57, 0x49, 0x4D}, @"Microsoft Windows Imaging Format", @"text/plain"},	//filemagic\Microsoft Windows Imaging Format WIM.xml
	{1, (OFString* []){@"pmoccmoc", nil}, 0, 8, (uint8_t []){0x50, 0x4D, 0x4F, 0x43, 0x43, 0x4D, 0x4F, 0x43}, @"Microsoft Windows User State Migration Tool", @"application/octet-stream"},	//filemagic\Microsoft Windows User State Migration Tool PMOCCMOC.xml
	{1, (OFString* []){@"mar", nil}, 0, 4, (uint8_t []){0x4D, 0x41, 0x52, 0x43}, @"Microsoft|MSN MARC archive", @"application/mathematica"},	//filemagic\Microsoft_MSN MARC archive MAR.xml
	{2, (OFString* []){@"mid", @"midi", nil}, 0, 4, (uint8_t []){0x4D, 0x54, 0x68, 0x64}, @"MIDI sound file", @"application/x-midi"},	//filemagic\MIDI sound file MID_MIDI.xml
	{1, (OFString* []){@"mls", nil}, 0, 5, (uint8_t []){0x4D, 0x49, 0x4C, 0x45, 0x53}, @"Milestones project management file", @"text/plain"},	//filemagic\Milestones project management file MLS.xml
	{1, (OFString* []){@"mls", nil}, 0, 5, (uint8_t []){0x4D, 0x56, 0x32, 0x31, 0x34}, @"Milestones project management file_1", @"text/plain"},	//filemagic\Milestones project management file_1 MLS.xml
	{1, (OFString* []){@"mls", nil}, 0, 4, (uint8_t []){0x4D, 0x56, 0x32, 0x43}, @"Milestones project management file_2", @"text/plain"},	//filemagic\Milestones project management file_2 MLS.xml
	{1, (OFString* []){@"mtw", nil}, 0, 8, (uint8_t []){0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1}, @"Minitab data file", @"application/x-troff"},	//filemagic\Minitab data file MTW.xml
	{1, (OFString* []){@"msc", nil}, 0, 56, (uint8_t []){0x3C, 0x3F, 0x78, 0x6D, 0x6C, 0x20, 0x76, 0x65, 0x72, 0x73, 0x69, 0x6F, 0x6E, 0x3D, 0x22, 0x31, 0x2E, 0x30, 0x22, 0x3F, 0x3E, 0x0D, 0x0A, 0x3C, 0x4D, 0x4D, 0x43, 0x5F, 0x43, 0x6F, 0x6E, 0x73, 0x6F, 0x6C, 0x65, 0x46, 0x69, 0x6C, 0x65, 0x20, 0x43, 0x6F, 0x6E, 0x73, 0x6F, 0x6C, 0x65, 0x56, 0x65, 0x72, 0x73, 0x69, 0x6F, 0x6E, 0x3D, 0x22}, @"MMC Snap-in Control file", @"application/vnd.ibm.secure-container"},	//filemagic\MMC Snap-in Control file MSC.xml
	{1, (OFString* []){@"mp", nil}, 0, 2, (uint8_t []){0x0C, 0xED}, @"Monochrome Picture TIFF bitmap", @"text/plain"},	//filemagic\Monochrome Picture TIFF bitmap MP.xml
	{1, (OFString* []){@"mar", nil}, 0, 5, (uint8_t []){0x4D, 0x41, 0x52, 0x31, 0x00}, @"Mozilla archive", @"application/mathematica"},	//filemagic\Mozilla archive MAR.xml
	{1, (OFString* []){@"xpi", nil}, 0, 4, (uint8_t []){0x50, 0x4B, 0x03, 0x04}, @"Mozilla Browser Archive", @"application/x-xpinstall"},	//filemagic\Mozilla Browser Archive XPI.xml
	{1, (OFString* []){@"mp3", nil}, 0, 3, (uint8_t []){0x49, 0x44, 0x33}, @"MP3 audio file", @"audio/mpeg"},	//filemagic\MP3 audio file MP3.xml
	{1, (OFString* []){@"mpg", nil}, 0, 4, (uint8_t []){0x00, 0x00, 0x01, 0xB3}, @"MPEG video file", @"audio/mpeg"},	//filemagic\MPEG video file MPG.xml
	{1, (OFString* []){@"aac", nil}, 0, 2, (uint8_t []){0xFF, 0xF9}, @"MPEG-2 AAC audio", @"application/octet-stream"},	//filemagic\MPEG-2 AAC audio AAC.xml
	{1, (OFString* []){@"aac", nil}, 0, 2, (uint8_t []){0xFF, 0xF1}, @"MPEG-4 AAC audio", @"application/octet-stream"},	//filemagic\MPEG-4 AAC audio AAC.xml
	{1, (OFString* []){@"mp4", nil}, 0, 12, (uint8_t []){0x00, 0x00, 0x00, 0x14, 0x66, 0x74, 0x79, 0x70, 0x69, 0x73, 0x6F, 0x6D}, @"MPEG-4 v1", @"application/mp4"},	//filemagic\MPEG-4 v1 MP4.xml
	{1, (OFString* []){@"mp4", nil}, 4, 8, (uint8_t []){0x66, 0x74, 0x79, 0x70, 0x33, 0x67, 0x70, 0x35}, @"MPEG-4 video file_1", @"application/mp4"},	//filemagic\MPEG-4 video file_1 MP4.xml
	{1, (OFString* []){@"mp4", nil}, 4, 8, (uint8_t []){0x66, 0x74, 0x79, 0x70, 0x4D, 0x53, 0x4E, 0x56}, @"MPEG-4 video file_2", @"application/mp4"},	//filemagic\MPEG-4 video file_2 MP4.xml
	{3, (OFString* []){@"3gp5", @"m4v", @"mp4", nil}, 0, 8, (uint8_t []){0x00, 0x00, 0x00, 0x18, 0x66, 0x74, 0x79, 0x70}, @"MPEG-4 video_1", @"application/mp4"},	//filemagic\MPEG-4 video_1 3GP5_M4V_MP4.xml
	{1, (OFString* []){@"mp4", nil}, 0, 8, (uint8_t []){0x00, 0x00, 0x00, 0x1C, 0x66, 0x74, 0x79, 0x70}, @"MPEG-4 video_2", @"application/mp4"},	//filemagic\MPEG-4 video_2 MP4.xml
	{1, (OFString* []){@"m4v", nil}, 4, 8, (uint8_t []){0x66, 0x74, 0x79, 0x70, 0x6D, 0x70, 0x34, 0x32}, @"MPEG-4 video|QuickTime file", @"text/plain"},	//filemagic\MPEG-4 video_QuickTime file M4V.xml
	{1, (OFString* []){@"snp", nil}, 0, 4, (uint8_t []){0x4D, 0x53, 0x43, 0x46}, @"MS Access Snapshot Viewer file", @"text/x-asm"},	//filemagic\MS Access Snapshot Viewer file SNP.xml
	{1, (OFString* []){@"acs", nil}, 0, 4, (uint8_t []){0xC3, 0xAB, 0xCD, 0xAB}, @"MS Agent Character file", @"application/octet-stream"},	//filemagic\MS Agent Character file ACS.xml
	{1, (OFString* []){@"aw", nil}, 0, 8, (uint8_t []){0x8A, 0x01, 0x09, 0x00, 0x00, 0x00, 0xE1, 0x08}, @"MS Answer Wizard", @"application/applixware"},	//filemagic\MS Answer Wizard AW.xml
	{1, (OFString* []){@"acm", nil}, 0, 2, (uint8_t []){0x4D, 0x5A}, @"MS audio compression manager driver", @"application/octet-stream"},	//filemagic\MS audio compression manager driver ACM.xml
	{1, (OFString* []){@"pdb", nil}, 0, 16, (uint8_t []){0x4D, 0x69, 0x63, 0x72, 0x6F, 0x73, 0x6F, 0x66, 0x74, 0x20, 0x43, 0x2F, 0x43, 0x2B, 0x2B, 0x20}, @"MS C++ debugging symbols file", @"application/vnd.palm"},	//filemagic\MS C++ debugging symbols file PDB.xml
	{1, (OFString* []){@"obj", nil}, 0, 2, (uint8_t []){0x4C, 0x01}, @"MS COFF relocatable object code", @"application/octet-stream"},	//filemagic\MS COFF relocatable object code OBJ.xml
	{2, (OFString* []){@"chi", @"chm", nil}, 0, 4, (uint8_t []){0x49, 0x54, 0x53, 0x46}, @"MS Compiled HTML Help File", @"application/vnd.ms-htmlhelp"},	//filemagic\MS Compiled HTML Help File CHI_CHM.xml
	{1, (OFString* []){@"dsp", nil}, 0, 8, (uint8_t []){0x23, 0x20, 0x4D, 0x69, 0x63, 0x72, 0x6F, 0x73}, @"MS Developer Studio project file", @"text/x-asm"},	//filemagic\MS Developer Studio project file DSP.xml
	{1, (OFString* []){@"mdi", nil}, 0, 2, (uint8_t []){0x45, 0x50}, @"MS Document Imaging file", @"image/vnd.ms-modi"},	//filemagic\MS Document Imaging file MDI.xml
	{1, (OFString* []){@"ecf", nil}, 0, 8, (uint8_t []){0x5B, 0x47, 0x65, 0x6E, 0x65, 0x72, 0x61, 0x6C}, @"MS Exchange configuration file", @"text/plain"},	//filemagic\MS Exchange configuration file ECF.xml
	{1, (OFString* []){@"cpe", nil}, 0, 8, (uint8_t []){0x46, 0x41, 0x58, 0x43, 0x4F, 0x56, 0x45, 0x52}, @"MS Fax Cover Sheet", @"text/plain"},	//filemagic\MS Fax Cover Sheet CPE.xml
	{3, (OFString* []){@"docx", @"pptx", @"xlsx", nil}, 0, 8, (uint8_t []){0x50, 0x4B, 0x03, 0x04, 0x14, 0x00, 0x06, 0x00}, @"MS Office 2007 documents", @"application/excel"},	//filemagic\MS Office 2007 documents DOCX_PPTX_XLSX.xml
	{3, (OFString* []){@"docx", @"pptx", @"xlsx", nil}, 0, 4, (uint8_t []){0x50, 0x4B, 0x03, 0x04}, @"MS Office Open XML Format Document", @"application/excel"},	//filemagic\MS Office Open XML Format Document DOCX_PPTX_XLSX.xml
	{1, (OFString* []){@"one", nil}, 0, 8, (uint8_t []){0xE4, 0x52, 0x5C, 0x7B, 0x8C, 0xD8, 0xA7, 0x4D}, @"MS OneNote note", @"application/msonenote"},	//filemagic\MS OneNote note ONE.xml
	{1, (OFString* []){@"bdr", nil}, 0, 2, (uint8_t []){0x58, 0x54}, @"MS Publisher", @"application/octet-stream"},	//filemagic\MS Publisher BDR.xml
	{1, (OFString* []){@"pub", nil}, 0, 8, (uint8_t []){0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1}, @"MS Publisher file", @"application/x-mspublisher"},	//filemagic\MS Publisher file PUB.xml
	{1, (OFString* []){@"pub", nil}, 512, 5, (uint8_t []){0xFD, 0xFF, 0xFF, 0xFF, 0x02}, @"MS Publisher file subheader", @"application/x-mspublisher"},	//filemagic\MS Publisher file subheader PUB.xml
	{1, (OFString* []){@"pub", nil}, 512, 6, (uint8_t []){0xFD, 0x37, 0x7A, 0x58, 0x5A, 0x00}, @"MS Publisher subheader", @"application/x-mspublisher"},	//filemagic\MS Publisher subheader PUB.xml
	{1, (OFString* []){@"lit", nil}, 0, 8, (uint8_t []){0x49, 0x54, 0x4F, 0x4C, 0x49, 0x54, 0x4C, 0x53}, @"MS Reader eBook", @"application/x-troff"},	//filemagic\MS Reader eBook LIT.xml
	{1, (OFString* []){@"cat", nil}, 0, 1, (uint8_t []){0x30}, @"MS security catalog file", @"application/octet-stream"},	//filemagic\MS security catalog file CAT.xml
	{1, (OFString* []){@"dsw", nil}, 0, 7, (uint8_t []){0x64, 0x73, 0x77, 0x66, 0x69, 0x6C, 0x65}, @"MS Visual Studio workspace file", @"text/x-asm"},	//filemagic\MS Visual Studio workspace file DSW.xml
	{2, (OFString* []){@"jnt", @"jtp", nil}, 0, 4, (uint8_t []){0x4E, 0x42, 0x2A, 0x00}, @"MS Windows journal", @"application/x-troff"},	//filemagic\MS Windows journal JNT_JTP.xml
	{1, (OFString* []){@"pwi", nil}, 0, 5, (uint8_t []){0x7B, 0x5C, 0x70, 0x77, 0x69}, @"MS WinMobile personal note", @"text/x-pascal"},	//filemagic\MS WinMobile personal note PWI.xml
	{1, (OFString* []){@"wri", nil}, 0, 2, (uint8_t []){0x31, 0xBE}, @"MS Write file_1", @"application/mswrite"},	//filemagic\MS Write file_1 WRI.xml
	{1, (OFString* []){@"wri", nil}, 0, 2, (uint8_t []){0x32, 0xBE}, @"MS Write file_2", @"application/mswrite"},	//filemagic\MS Write file_2 WRI.xml
	{1, (OFString* []){@"wri", nil}, 0, 5, (uint8_t []){0xBE, 0x00, 0x00, 0x00, 0xAB}, @"MS Write file_3", @"application/mswrite"},	//filemagic\MS Write file_3 WRI.xml
	{1, (OFString* []){@"mof", nil}, 0, 8, (uint8_t []){0xFF, 0xFE, 0x23, 0x00, 0x6C, 0x00, 0x69, 0x00}, @"MSinfo file", @"application/octet-stream"},	//filemagic\MSinfo file MOF.xml
	{1, (OFString* []){@"db", nil}, 0, 8, (uint8_t []){0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1}, @"MSWorks database file", @"application/octet-stream"},	//filemagic\MSWorks database file DB.xml
	{1, (OFString* []){@"wps", nil}, 0, 8, (uint8_t []){0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1}, @"MSWorks text document", @"application/postscript"},	//filemagic\MSWorks text document WPS.xml
	{1, (OFString* []){@"spvb", nil}, 0, 4, (uint8_t []){0x53, 0x50, 0x56, 0x42}, @"MultiBit Bitcoin blockchain file", @"application/vnd.3gpp.pic-bw-var"},	//filemagic\MultiBit Bitcoin blockchain file SPVB.xml
	{1, (OFString* []){@"wallet", nil}, 0, 16, (uint8_t []){0x0A, 0x16, 0x6F, 0x72, 0x67, 0x2E, 0x62, 0x69, 0x74, 0x63, 0x6F, 0x69, 0x6E, 0x2E, 0x70, 0x72}, @"MultiBit Bitcoin wallet file", @"application/octet-stream"},	//filemagic\MultiBit Bitcoin wallet file WALLET.xml
	{1, (OFString* []){@"info", nil}, 0, 13, (uint8_t []){0x6D, 0x75, 0x6C, 0x74, 0x69, 0x42, 0x69, 0x74, 0x2E, 0x69, 0x6E, 0x66, 0x6F}, @"MultiBit Bitcoin wallet information", @"application/inf"},	//filemagic\MultiBit Bitcoin wallet information INFO.xml
	{1, (OFString* []){@"ntf", nil}, 0, 5, (uint8_t []){0x4E, 0x49, 0x54, 0x46, 0x30}, @"National Imagery Transmission Format file", @"application/vnd.nitf"},	//filemagic\National Imagery Transmission Format file NTF.xml
	{1, (OFString* []){@"ntf", nil}, 0, 8, (uint8_t []){0x30, 0x31, 0x4F, 0x52, 0x44, 0x4E, 0x41, 0x4E}, @"National Transfer Format Map", @"application/vnd.nitf"},	//filemagic\National Transfer Format Map NTF.xml
	{1, (OFString* []){@"(none)", nil}, 0, 8, (uint8_t []){0xCD, 0x20, 0xAA, 0xAA, 0x02, 0x00, 0x00, 0x00}, @"NAV quarantined virus file", @"application/msonenote"},	//filemagic\NAV quarantined virus file (none).xml
	{1, (OFString* []){@"nri", nil}, 0, 8, (uint8_t []){0x0E, 0x4E, 0x65, 0x72, 0x6F, 0x49, 0x53, 0x4F}, @"Nero CD compilation", @"application/octet-stream"},	//filemagic\Nero CD compilation NRI.xml
	{1, (OFString* []){@"nsf", nil}, 0, 6, (uint8_t []){0x4E, 0x45, 0x53, 0x4D, 0x1A, 0x01}, @"NES Sound file", @"application/vnd.lotus-notes"},	//filemagic\NES Sound file NSF.xml
	{1, (OFString* []){@"snm", nil}, 0, 8, (uint8_t []){0x00, 0x1E, 0x84, 0x90, 0x00, 0x00, 0x00, 0x00}, @"Netscape Communicator (v4) mail folder", @"text/plain"},	//filemagic\Netscape Communicator (v4) mail folder SNM.xml
	{1, (OFString* []){@"db", nil}, 0, 16, (uint8_t []){0x00, 0x06, 0x15, 0x61, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x04, 0xD2, 0x00, 0x00, 0x10, 0x00}, @"Netscape Navigator (v4) database", @"application/octet-stream"},	//filemagic\Netscape Navigator (v4) database DB.xml
	{1, (OFString* []){@"au", nil}, 0, 4, (uint8_t []){0x2E, 0x73, 0x6E, 0x64}, @"NeXT|Sun Microsystems audio file", @"application/octet-stream"},	//filemagic\NeXT_Sun Microsystems audio file AU.xml
	{1, (OFString* []){@"dat", nil}, 0, 8, (uint8_t []){0x50, 0x4E, 0x43, 0x49, 0x55, 0x4E, 0x44, 0x4F}, @"Norton Disk Doctor undo file", @"application/octet-stream"},	//filemagic\Norton Disk Doctor undo file DAT.xml
	{1, (OFString* []){@"tr1", nil}, 0, 2, (uint8_t []){0x01, 0x10}, @"Novell LANalyzer capture file", @"application/x-troff"},	//filemagic\Novell LANalyzer capture file TR1.xml
	{1, (OFString* []){@"(none)", nil}, 0, 4, (uint8_t []){0x42, 0x41, 0x41, 0x44}, @"NTFS MFT (BAAD)", @"application/msonenote"},	//filemagic\NTFS MFT (BAAD) (none).xml
	{1, (OFString* []){@"(none)", nil}, 0, 4, (uint8_t []){0x46, 0x49, 0x4C, 0x45}, @"NTFS MFT (FILE)", @"application/msonenote"},	//filemagic\NTFS MFT (FILE) (none).xml
	{4, (OFString* []){@"oga", @"ogg", @"ogv", @"ogx", nil}, 0, 8, (uint8_t []){0x4F, 0x67, 0x67, 0x53, 0x00, 0x02, 0x00, 0x00}, @"Ogg Vorbis Codec compressed file", @"application/octet-stream"},	//filemagic\Ogg Vorbis Codec compressed file OGA_OGG_OGV_OGX.xml
	{1, (OFString* []){@"olb", nil}, 0, 2, (uint8_t []){0x4D, 0x5A}, @"OLE object library", @"application/octet-stream"},	//filemagic\OLE object library OLB.xml
	{1, (OFString* []){@"tlb", nil}, 0, 8, (uint8_t []){0x4D, 0x53, 0x46, 0x54, 0x02, 0x00, 0x01, 0x00}, @"OLE|SPSS|Visual C++ library file", @"application/x-troff"},	//filemagic\OLE_SPSS_Visual C++ library file TLB.xml
	{1, (OFString* []){@"epub", nil}, 0, 8, (uint8_t []){0x50, 0x4B, 0x03, 0x04, 0x0A, 0x00, 0x02, 0x00}, @"Open Publication Structure eBook", @"application/epub+zip"},	//filemagic\Open Publication Structure eBook EPUB.xml
	{3, (OFString* []){@"odt", @"odp", @"ott", nil}, 0, 4, (uint8_t []){0x50, 0x4B, 0x03, 0x04}, @"OpenDocument template", @"application/commonground"},	//filemagic\OpenDocument template ODT_ODP_OTT.xml
	{1, (OFString* []){@"exr", nil}, 0, 4, (uint8_t []){0x76, 0x2F, 0x31, 0x01}, @"OpenEXR bitmap image", @"application/octet-stream"},	//filemagic\OpenEXR bitmap image EXR.xml
	{4, (OFString* []){@"sxc", @"sxd", @"sxi", @"sxw", nil}, 0, 4, (uint8_t []){0x50, 0x4B, 0x03, 0x04}, @"OpenOffice documents", @"application/vnd.sun.xml.calc"},	//filemagic\OpenOffice documents SXC_SXD_SXI_SXW.xml
	{1, (OFString* []){@"(none)", nil}, 0, 4, (uint8_t []){0xCE, 0xFA, 0xED, 0xFE}, @"OS X ABI Mach-O binary (32-bit reverse)", @"application/msonenote"},	//filemagic\OS X ABI Mach-O binary (32-bit reverse) (none).xml
	{1, (OFString* []){@"(none)", nil}, 0, 4, (uint8_t []){0xFE, 0xED, 0xFA, 0xCE}, @"OS X ABI Mach-O binary (32-bit)", @"application/msonenote"},	//filemagic\OS X ABI Mach-O binary (32-bit) (none).xml
	{1, (OFString* []){@"(none)", nil}, 0, 4, (uint8_t []){0xCF, 0xFA, 0xED, 0xFE}, @"OS X ABI Mach-O binary (64-bit reverse)", @"application/msonenote"},	//filemagic\OS X ABI Mach-O binary (64-bit reverse) (none).xml
	{1, (OFString* []){@"(none)", nil}, 0, 4, (uint8_t []){0xFE, 0xED, 0xFA, 0xCF}, @"OS X ABI Mach-O binary (64-bit)", @"application/msonenote"},	//filemagic\OS X ABI Mach-O binary (64-bit) (none).xml
	{1, (OFString* []){@"wab", nil}, 0, 8, (uint8_t []){0x9C, 0xCB, 0xCB, 0x8D, 0x13, 0x75, 0xD2, 0x11}, @"Outlook address file", @"application/octet-stream"},	//filemagic\Outlook address file WAB.xml
	{1, (OFString* []){@"wab", nil}, 0, 8, (uint8_t []){0x81, 0x32, 0x84, 0xC1, 0x85, 0x05, 0xD0, 0x11}, @"Outlook Express address book (Win95)", @"application/octet-stream"},	//filemagic\Outlook Express address book (Win95) WAB.xml
	{1, (OFString* []){@"dbx", nil}, 0, 4, (uint8_t []){0xCF, 0xAD, 0x12, 0xFE}, @"Outlook Express e-mail folder", @"application/octet-stream"},	//filemagic\Outlook Express e-mail folder DBX.xml
	{1, (OFString* []){@"cap", nil}, 0, 4, (uint8_t []){0x58, 0x43, 0x50, 0x00}, @"Packet sniffer files", @"application/octet-stream"},	//filemagic\Packet sniffer files CAP.xml
	{1, (OFString* []){@"aba", nil}, 0, 4, (uint8_t []){0x00, 0x01, 0x42, 0x41}, @"Palm Address Book Archive", @"application/octet-stream"},	//filemagic\Palm Address Book Archive ABA.xml
	{1, (OFString* []){@"dba", nil}, 0, 4, (uint8_t []){0x00, 0x01, 0x42, 0x44}, @"Palm DateBook Archive", @"application/octet-stream"},	//filemagic\Palm DateBook Archive DBA.xml
	{1, (OFString* []){@"dat", nil}, 0, 16, (uint8_t []){0xBE, 0xBA, 0xFE, 0xCA, 0x0F, 0x50, 0x61, 0x6C, 0x6D, 0x53, 0x47, 0x20, 0x44, 0x61, 0x74, 0x61}, @"Palm Desktop DateBook", @"application/octet-stream"},	//filemagic\Palm Desktop DateBook DAT.xml
	{1, (OFString* []){@"db", nil}, 0, 4, (uint8_t []){0x44, 0x42, 0x46, 0x48}, @"Palm Zire photo database", @"application/octet-stream"},	//filemagic\Palm Zire photo database DB.xml
	{1, (OFString* []){@"pdb", nil}, 0, 3, (uint8_t []){0x73, 0x6D, 0x5F}, @"PalmOS SuperMemo", @"application/vnd.palm"},	//filemagic\PalmOS SuperMemo PDB.xml
	{1, (OFString* []){@"prc", nil}, 0, 8, (uint8_t []){0x42, 0x4F, 0x4F, 0x4B, 0x4D, 0x4F, 0x42, 0x49}, @"Palmpilot resource file", @"application/x-mobipocket-ebook"},	//filemagic\Palmpilot resource file PRC.xml
	{1, (OFString* []){@"prc", nil}, 60, 8, (uint8_t []){0x74, 0x42, 0x4D, 0x50, 0x4B, 0x6E, 0x57, 0x72}, @"PathWay Map file", @"application/x-mobipocket-ebook"},	//filemagic\PathWay Map file PRC.xml
	{1, (OFString* []){@"pax", nil}, 0, 3, (uint8_t []){0x50, 0x41, 0x58}, @"PAX password protected bitmap", @"application/octet-stream"},	//filemagic\PAX password protected bitmap PAX.xml
	{1, (OFString* []){@"dcx", nil}, 0, 4, (uint8_t []){0xB1, 0x68, 0xDE, 0x3A}, @"PCX bitmap", @"text/plain"},	//filemagic\PCX bitmap DCX.xml
	{2, (OFString* []){@"pdf", @"fdf", nil}, 0, 4, (uint8_t []){0x25, 0x50, 0x44, 0x46}, @"PDF file", @"application/pdf"},	//filemagic\PDF file PDF_FDF.xml
	{1, (OFString* []){@"doc", nil}, 0, 8, (uint8_t []){0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1, 0x00}, @"Perfect Office document", @"application/msword"},	//filemagic\Perfect Office document DOC.xml
	{1, (OFString* []){@"dat", nil}, 0, 4, (uint8_t []){0x50, 0x45, 0x53, 0x54}, @"PestPatrol data|scan strings", @"application/octet-stream"},	//filemagic\PestPatrol data_scan strings DAT.xml
	{1, (OFString* []){@"pcs", nil}, 0, 16, (uint8_t []){0x32, 0x03, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00, 0xFF, 0x00}, @"Pfaff Home Embroidery", @"text/plain"},	//filemagic\Pfaff Home Embroidery PCS.xml
	{1, (OFString* []){@"pgd", nil}, 0, 8, (uint8_t []){0x50, 0x47, 0x50, 0x64, 0x4D, 0x41, 0x49, 0x4E}, @"PGP disk image", @"text/plain"},	//filemagic\PGP disk image PGD.xml
	{1, (OFString* []){@"pkr", nil}, 0, 2, (uint8_t []){0x99, 0x01}, @"PGP public keyring", @"application/x-tex-pk"},	//filemagic\PGP public keyring PKR.xml
	{1, (OFString* []){@"skr", nil}, 0, 2, (uint8_t []){0x95, 0x00}, @"PGP secret keyring_1", @"text/x-asm"},	//filemagic\PGP secret keyring_1 SKR.xml
	{1, (OFString* []){@"skr", nil}, 0, 2, (uint8_t []){0x95, 0x01}, @"PGP secret keyring_2", @"text/x-asm"},	//filemagic\PGP secret keyring_2 SKR.xml
	{1, (OFString* []){@"csh", nil}, 0, 8, (uint8_t []){0x63, 0x75, 0x73, 0x68, 0x00, 0x00, 0x00, 0x02}, @"Photoshop Custom Shape", @"application/x-bsh"},	//filemagic\Photoshop Custom Shape CSH.xml
	{1, (OFString* []){@"psd", nil}, 0, 4, (uint8_t []){0x38, 0x42, 0x50, 0x53}, @"Photoshop image", @"application/octet-stream"},	//filemagic\Photoshop image PSD.xml
	{1, (OFString* []){@"zip", nil}, 30, 6, (uint8_t []){0x50, 0x4B, 0x4C, 0x49, 0x54, 0x45}, @"PKLITE archive", @"application/octet-stream"},	//filemagic\PKLITE archive ZIP.xml
	{1, (OFString* []){@"zip", nil}, 526, 5, (uint8_t []){0x50, 0x4B, 0x53, 0x70, 0x58}, @"PKSFX self-extracting archive", @"application/octet-stream"},	//filemagic\PKSFX self-extracting archive ZIP.xml
	{1, (OFString* []){@"zip", nil}, 0, 4, (uint8_t []){0x50, 0x4B, 0x03, 0x04}, @"PKZIP archive_1", @"application/octet-stream"},	//filemagic\PKZIP archive_1 ZIP.xml
	{1, (OFString* []){@"zip", nil}, 0, 4, (uint8_t []){0x50, 0x4B, 0x05, 0x06}, @"PKZIP archive_2", @"application/octet-stream"},	//filemagic\PKZIP archive_2 ZIP.xml
	{1, (OFString* []){@"zip", nil}, 0, 4, (uint8_t []){0x50, 0x4B, 0x07, 0x08}, @"PKZIP archive_3", @"application/octet-stream"},	//filemagic\PKZIP archive_3 ZIP.xml
	{1, (OFString* []){@"png", nil}, 0, 8, (uint8_t []){0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A}, @"PNG image", @"image/png"},	//filemagic\PNG image PNG.xml
	{1, (OFString* []){@"pgm", nil}, 0, 3, (uint8_t []){0x50, 0x35, 0x0A}, @"Portable Graymap Graphic", @"image/x-portable-graymap"},	//filemagic\Portable Graymap Graphic PGM.xml
	{1, (OFString* []){@"pdb", nil}, 0, 4, (uint8_t []){0x73, 0x7A, 0x65, 0x7A}, @"PowerBASIC Debugger Symbols", @"application/vnd.palm"},	//filemagic\PowerBASIC Debugger Symbols PDB.xml
	{1, (OFString* []){@"ppz", nil}, 0, 4, (uint8_t []){0x4D, 0x53, 0x43, 0x46}, @"Powerpoint Packaged Presentation", @"application/mspowerpoint"},	//filemagic\Powerpoint Packaged Presentation PPZ.xml
	{1, (OFString* []){@"ppt", nil}, 512, 4, (uint8_t []){0x00, 0x6E, 0x1E, 0xF0}, @"PowerPoint presentation subheader_1", @"application/mspowerpoint"},	//filemagic\PowerPoint presentation subheader_1 PPT.xml
	{1, (OFString* []){@"ppt", nil}, 512, 4, (uint8_t []){0x0F, 0x00, 0xE8, 0x03}, @"PowerPoint presentation subheader_2", @"application/mspowerpoint"},	//filemagic\PowerPoint presentation subheader_2 PPT.xml
	{1, (OFString* []){@"ppt", nil}, 512, 4, (uint8_t []){0xA0, 0x46, 0x1D, 0xF0}, @"PowerPoint presentation subheader_3", @"application/mspowerpoint"},	//filemagic\PowerPoint presentation subheader_3 PPT.xml
	{1, (OFString* []){@"ppt", nil}, 512, 8, (uint8_t []){0xFD, 0xFF, 0xFF, 0xFF, 0x0E, 0x00, 0x00, 0x00}, @"PowerPoint presentation subheader_4", @"application/mspowerpoint"},	//filemagic\PowerPoint presentation subheader_4 PPT.xml
	{1, (OFString* []){@"ppt", nil}, 512, 8, (uint8_t []){0xFD, 0xFF, 0xFF, 0xFF, 0x1C, 0x00, 0x00, 0x00}, @"PowerPoint presentation subheader_5", @"application/mspowerpoint"},	//filemagic\PowerPoint presentation subheader_5 PPT.xml
	{1, (OFString* []){@"ppt", nil}, 512, 8, (uint8_t []){0xFD, 0xFF, 0xFF, 0xFF, 0x43, 0x00, 0x00, 0x00}, @"PowerPoint presentation subheader_6", @"application/mspowerpoint"},	//filemagic\PowerPoint presentation subheader_6 PPT.xml
	{1, (OFString* []){@"dbf", nil}, 0, 8, (uint8_t []){0x4F, 0x50, 0x4C, 0x44, 0x61, 0x74, 0x61, 0x62}, @"Psion Series 3 Database", @"text/plain"},	//filemagic\Psion Series 3 Database DBF.xml
	{1, (OFString* []){@"apuf", nil}, 0, 12, (uint8_t []){0x42, 0x65, 0x67, 0x69, 0x6E, 0x20, 0x50, 0x75, 0x66, 0x66, 0x65, 0x72}, @"Puffer ASCII encrypted archive", @"application/octet-stream"},	//filemagic\Puffer ASCII encrypted archive APUF.xml
	{1, (OFString* []){@"puf", nil}, 0, 4, (uint8_t []){0x50, 0x55, 0x46, 0x58}, @"Puffer encrypted archive", @"text/plain"},	//filemagic\Puffer encrypted archive PUF.xml
	{1, (OFString* []){@"(none)", nil}, 0, 8, (uint8_t []){0x53, 0x5A, 0x20, 0x88, 0xF0, 0x27, 0x33, 0xD1}, @"QBASIC SZDD file", @"application/msonenote"},	//filemagic\QBASIC SZDD file (none).xml
	{1, (OFString* []){@"qemu", nil}, 0, 3, (uint8_t []){0x51, 0x46, 0x49}, @"Qcow Disk Image", @"text/plain"},	//filemagic\Qcow Disk Image QEMU.xml
	{1, (OFString* []){@"flt", nil}, 0, 8, (uint8_t []){0x76, 0x32, 0x30, 0x30, 0x33, 0x2E, 0x31, 0x30}, @"Qimage filter", @"application/x-troff"},	//filemagic\Qimage filter FLT.xml
	{1, (OFString* []){@"pak", nil}, 0, 4, (uint8_t []){0x50, 0x41, 0x43, 0x4B}, @"Quake archive file", @"application/octet-stream"},	//filemagic\Quake archive file PAK.xml
	{1, (OFString* []){@"qxd", nil}, 0, 7, (uint8_t []){0x00, 0x00, 0x49, 0x49, 0x58, 0x50, 0x52}, @"Quark Express (Intel)", @"application/vnd.quark.quarkxpress"},	//filemagic\Quark Express (Intel) QXD.xml
	{1, (OFString* []){@"qxd", nil}, 0, 7, (uint8_t []){0x00, 0x00, 0x4D, 0x4D, 0x58, 0x50, 0x52}, @"Quark Express (Motorola)", @"application/vnd.quark.quarkxpress"},	//filemagic\Quark Express (Motorola) QXD.xml
	{1, (OFString* []){@"wb3", nil}, 24, 9, (uint8_t []){0x3E, 0x00, 0x03, 0x00, 0xFE, 0xFF, 0x09, 0x00, 0x06}, @"Quatro Pro for Windows 7.0", @"application/octet-stream"},	//filemagic\Quatro Pro for Windows 7.0 WB3.xml
	{1, (OFString* []){@"wb2", nil}, 0, 4, (uint8_t []){0x00, 0x00, 0x02, 0x00}, @"QuattroPro spreadsheet", @"application/octet-stream"},	//filemagic\QuattroPro spreadsheet WB2.xml
	{1, (OFString* []){@"qbb", nil}, 0, 6, (uint8_t []){0x45, 0x86, 0x00, 0x00, 0x06, 0x00}, @"QuickBooks backup", @"application/octet-stream"},	//filemagic\QuickBooks backup QBB.xml
	{2, (OFString* []){@"abd", @"qsd", nil}, 0, 8, (uint8_t []){0x51, 0x57, 0x20, 0x56, 0x65, 0x72, 0x2E, 0x20}, @"Quicken data file", @"application/octet-stream"},	//filemagic\Quicken data file ABD_QSD.xml
	{1, (OFString* []){@"qdf", nil}, 0, 6, (uint8_t []){0xAC, 0x9E, 0xBD, 0x8F, 0x00, 0x00}, @"Quicken data", @"text/plain"},	//filemagic\Quicken data QDF.xml
	{1, (OFString* []){@"qel", nil}, 92, 4, (uint8_t []){0x51, 0x45, 0x4C, 0x20}, @"Quicken data", @"text/plain"},	//filemagic\Quicken data QEL.xml
	{1, (OFString* []){@"qph", nil}, 0, 4, (uint8_t []){0x03, 0x00, 0x00, 0x00}, @"Quicken price history", @"text/plain"},	//filemagic\Quicken price history QPH.xml
	{1, (OFString* []){@"idx", nil}, 0, 8, (uint8_t []){0x50, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00}, @"Quicken QuickFinder Information File", @"application/octet-stream"},	//filemagic\Quicken QuickFinder Information File IDX.xml
	{1, (OFString* []){@"qrp", nil}, 0, 3, (uint8_t []){0xFF, 0x0A, 0x00}, @"QuickReport Report", @"image/vnd.rn-realpix"},	//filemagic\QuickReport Report QRP.xml
	{1, (OFString* []){@"mov", nil}, 4, 4, (uint8_t []){0x6D, 0x6F, 0x6F, 0x76}, @"QuickTime movie_1", @"application/octet-stream"},	//filemagic\QuickTime movie_1 MOV.xml
	{1, (OFString* []){@"mov", nil}, 4, 4, (uint8_t []){0x66, 0x72, 0x65, 0x65}, @"QuickTime movie_2", @"application/octet-stream"},	//filemagic\QuickTime movie_2 MOV.xml
	{1, (OFString* []){@"mov", nil}, 4, 4, (uint8_t []){0x6D, 0x64, 0x61, 0x74}, @"QuickTime movie_3", @"application/octet-stream"},	//filemagic\QuickTime movie_3 MOV.xml
	{1, (OFString* []){@"mov", nil}, 4, 4, (uint8_t []){0x77, 0x69, 0x64, 0x65}, @"QuickTime movie_4", @"application/octet-stream"},	//filemagic\QuickTime movie_4 MOV.xml
	{1, (OFString* []){@"mov", nil}, 4, 4, (uint8_t []){0x70, 0x6E, 0x6F, 0x74}, @"QuickTime movie_5", @"application/octet-stream"},	//filemagic\QuickTime movie_5 MOV.xml
	{1, (OFString* []){@"mov", nil}, 4, 4, (uint8_t []){0x73, 0x6B, 0x69, 0x70}, @"QuickTime movie_6", @"application/octet-stream"},	//filemagic\QuickTime movie_6 MOV.xml
	{1, (OFString* []){@"mov", nil}, 4, 8, (uint8_t []){0x66, 0x74, 0x79, 0x70, 0x71, 0x74, 0x20, 0x20}, @"QuickTime movie_7", @"application/octet-stream"},	//filemagic\QuickTime movie_7 MOV.xml
	{1, (OFString* []){@"hdr", nil}, 0, 8, (uint8_t []){0x23, 0x3F, 0x52, 0x41, 0x44, 0x49, 0x41, 0x4E}, @"Radiance High Dynamic Range image file", @"text/plain"},	//filemagic\Radiance High Dynamic Range image file HDR.xml
	{1, (OFString* []){@"rtd", nil}, 0, 8, (uint8_t []){0x43, 0x23, 0x2B, 0x44, 0xA4, 0x43, 0x4D, 0xA5}, @"RagTime document", @"application/x-troff"},	//filemagic\RagTime document RTD.xml
	{1, (OFString* []){@"ra", nil}, 0, 8, (uint8_t []){0x2E, 0x52, 0x4D, 0x46, 0x00, 0x00, 0x00, 0x12}, @"RealAudio file", @"application/octet-stream"},	//filemagic\RealAudio file RA.xml
	{1, (OFString* []){@"ra", nil}, 0, 5, (uint8_t []){0x2E, 0x72, 0x61, 0xFD, 0x00}, @"RealAudio streaming media", @"application/octet-stream"},	//filemagic\RealAudio streaming media RA.xml
	{1, (OFString* []){@"ram", nil}, 0, 7, (uint8_t []){0x72, 0x74, 0x73, 0x70, 0x3A, 0x2F, 0x2F}, @"RealMedia metafile", @"application/octet-stream"},	//filemagic\RealMedia metafile RAM.xml
	{2, (OFString* []){@"rm", @"rmvb", nil}, 0, 4, (uint8_t []){0x2E, 0x52, 0x4D, 0x46}, @"RealMedia streaming media", @"application/vnd.rn-realmedia"},	//filemagic\RealMedia streaming media RM_RMVB.xml
	{1, (OFString* []){@"ivr", nil}, 0, 4, (uint8_t []){0x2E, 0x52, 0x45, 0x43}, @"RealPlayer video file (V11+)", @"application/x-inventor"},	//filemagic\RealPlayer video file (V11+) IVR.xml
	{1, (OFString* []){@"rpm", nil}, 0, 4, (uint8_t []){0xED, 0xAB, 0xEE, 0xDB}, @"RedHat Package Manager", @"application/x-redhat-package-manager"},	//filemagic\RedHat Package Manager RPM.xml
	{1, (OFString* []){@"obj", nil}, 0, 1, (uint8_t []){0x80}, @"Relocatable object code", @"application/octet-stream"},	//filemagic\Relocatable object code OBJ.xml
	{6, (OFString* []){@"avi", @"cda", @"qcp", @"rmi", @"wav", @"webp", nil}, 0, 4, (uint8_t []){0x52, 0x49, 0x46, 0x46}, @"Resource Interchange File Format", @"application/octet-stream"},	//filemagic\Resource Interchange File Format AVI_CDA_QCP_RMI_WAV_WEBP.xml
	{1, (OFString* []){@"rvt", nil}, 0, 8, (uint8_t []){0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1}, @"Revit Project file", @"application/x-troff"},	//filemagic\Revit Project file RVT.xml
	{1, (OFString* []){@"rtf", nil}, 0, 6, (uint8_t []){0x7B, 0x5C, 0x72, 0x74, 0x66, 0x31}, @"Rich Text Format", @"application/rtf"},	//filemagic\Rich Text Format RTF.xml
	{1, (OFString* []){@"cda", nil}, 8, 8, (uint8_t []){0x43, 0x44, 0x44, 0x41, 0x66, 0x6D, 0x74, 0x20}, @"RIFF CD audio", @"application/octet-stream"},	//filemagic\RIFF CD audio CDA.xml
	{1, (OFString* []){@"qcp", nil}, 8, 8, (uint8_t []){0x51, 0x4C, 0x43, 0x4D, 0x66, 0x6D, 0x74, 0x20}, @"RIFF Qualcomm PureVoice", @"audio/vnd.qcelp"},	//filemagic\RIFF Qualcomm PureVoice QCP.xml
	{1, (OFString* []){@"webp", nil}, 8, 4, (uint8_t []){0x57, 0x45, 0x42, 0x50}, @"RIFF WebP", @"application/vnd.xara"},	//filemagic\RIFF WebP WEBP.xml
	{1, (OFString* []){@"avi", nil}, 8, 8, (uint8_t []){0x41, 0x56, 0x49, 0x20, 0x4C, 0x49, 0x53, 0x54}, @"RIFF Windows Audio", @"application/octet-stream"},	//filemagic\RIFF Windows Audio AVI.xml
	{1, (OFString* []){@"wav", nil}, 8, 8, (uint8_t []){0x57, 0x41, 0x56, 0x45, 0x66, 0x6D, 0x74, 0x20}, @"RIFF Windows Audio", @"application/octet-stream"},	//filemagic\RIFF Windows Audio WAV.xml
	{1, (OFString* []){@"rmi", nil}, 8, 8, (uint8_t []){0x52, 0x4D, 0x49, 0x44, 0x64, 0x61, 0x74, 0x61}, @"RIFF Windows MIDI", @"application/vnd.rn-realmedia"},	//filemagic\RIFF Windows MIDI RMI.xml
	{1, (OFString* []){@"dat", nil}, 0, 8, (uint8_t []){0x1A, 0x52, 0x54, 0x53, 0x20, 0x43, 0x4F, 0x4D}, @"Runtime Software disk image", @"application/octet-stream"},	//filemagic\Runtime Software disk image DAT.xml
	{1, (OFString* []){@"xpt", nil}, 0, 16, (uint8_t []){0x48, 0x45, 0x41, 0x44, 0x45, 0x52, 0x20, 0x52, 0x45, 0x43, 0x4F, 0x52, 0x44, 0x2A, 0x2A, 0x2A}, @"SAS Transport dataset", @"application/x-troff"},	//filemagic\SAS Transport dataset XPT.xml
	{1, (OFString* []){@"scr", nil}, 0, 2, (uint8_t []){0x4D, 0x5A}, @"Screen saver", @"application/vnd.ibm.secure-container"},	//filemagic\Screen saver SCR.xml
	{1, (OFString* []){@"dat", nil}, 0, 8, (uint8_t []){0x52, 0x41, 0x5A, 0x41, 0x54, 0x44, 0x42, 0x31}, @"Shareaza (P2P) thumbnail", @"application/octet-stream"},	//filemagic\Shareaza (P2P) thumbnail DAT.xml
	{1, (OFString* []){@"swf", nil}, 0, 3, (uint8_t []){0x43, 0x57, 0x53}, @"Shockwave Flash file", @"application/x-shockwave-flash"},	//filemagic\Shockwave Flash file SWF.xml
	{1, (OFString* []){@"swf", nil}, 0, 3, (uint8_t []){0x46, 0x57, 0x53}, @"Shockwave Flash player", @"application/x-shockwave-flash"},	//filemagic\Shockwave Flash player SWF.xml
	{1, (OFString* []){@"gx2", nil}, 0, 3, (uint8_t []){0x47, 0x58, 0x32}, @"Show Partner graphics file", @"text/plain"},	//filemagic\Show Partner graphics file GX2.xml
	{1, (OFString* []){@"cpi", nil}, 0, 8, (uint8_t []){0x53, 0x49, 0x45, 0x54, 0x52, 0x4F, 0x4E, 0x49}, @"Sietronics CPI XRD document", @"text/plain"},	//filemagic\Sietronics CPI XRD document CPI.xml
	{1, (OFString* []){@"rgb", nil}, 0, 6, (uint8_t []){0x01, 0xDA, 0x01, 0x01, 0x00, 0x03}, @"Silicon Graphics RGB Bitmap", @"image/x-rgb"},	//filemagic\Silicon Graphics RGB Bitmap RGB.xml
	{1, (OFString* []){@"skf", nil}, 0, 4, (uint8_t []){0x07, 0x53, 0x4B, 0x46}, @"SkinCrafter skin", @"text/plain"},	//filemagic\SkinCrafter skin SKF.xml
	{1, (OFString* []){@"sil", nil}, 0, 7, (uint8_t []){0x23, 0x21, 0x53, 0x49, 0x4C, 0x4B, 0x0A}, @"Skype audio compression", @"audio/silk"},	//filemagic\Skype audio compression SIL.xml
	{1, (OFString* []){@"mls", nil}, 0, 4, (uint8_t []){0x4D, 0x4C, 0x53, 0x57}, @"Skype localization data file", @"text/plain"},	//filemagic\Skype localization data file MLS.xml
	{1, (OFString* []){@"dbb", nil}, 0, 4, (uint8_t []){0x6C, 0x33, 0x33, 0x6C}, @"Skype user data file", @"application/octet-stream"},	//filemagic\Skype user data file DBB.xml
	{1, (OFString* []){@"sdr", nil}, 0, 8, (uint8_t []){0x53, 0x4D, 0x41, 0x52, 0x54, 0x44, 0x52, 0x57}, @"SmartDraw Drawing file", @"application/sounder"},	//filemagic\SmartDraw Drawing file SDR.xml
	{1, (OFString* []){@"sdpx", nil}, 0, 4, (uint8_t []){0x53, 0x44, 0x50, 0x58}, @"SMPTE DPX (big endian)", @"application/commonground"},	//filemagic\SMPTE DPX (big endian) SDPX.xml
	{1, (OFString* []){@"dpx", nil}, 0, 4, (uint8_t []){0x58, 0x50, 0x44, 0x53}, @"SMPTE DPX file (little endian)", @"application/commonground"},	//filemagic\SMPTE DPX file (little endian) DPX.xml
	{1, (OFString* []){@"(none)", nil}, 0, 2, (uint8_t []){0x6F, 0x3C}, @"SMS text (SIM)", @"application/msonenote"},	//filemagic\SMS text (SIM) (none).xml
	{1, (OFString* []){@"ac", nil}, 0, 4, (uint8_t []){0x72, 0x69, 0x66, 0x66}, @"Sonic Foundry Acid Music File", @"application/octet-stream"},	//filemagic\Sonic Foundry Acid Music File AC.xml
	{3, (OFString* []){@"cdr", @"dvf", @"msv", nil}, 0, 8, (uint8_t []){0x4D, 0x53, 0x5F, 0x56, 0x4F, 0x49, 0x43, 0x45}, @"Sony Compressed Voice File", @"application/x-troff-ms"},	//filemagic\Sony Compressed Voice File CDR_DVF_MSV.xml
	{3, (OFString* []){@"bin", @"bli", @"rbi", nil}, 0, 6, (uint8_t []){0x42, 0x4C, 0x49, 0x32, 0x32, 0x33}, @"Speedtouch router firmware", @"application/mac-binary"},	//filemagic\Speedtouch router firmware BIN_BLI_RBI.xml
	{1, (OFString* []){@"koz", nil}, 0, 7, (uint8_t []){0x49, 0x44, 0x33, 0x03, 0x00, 0x00, 0x00}, @"Sprint Music Store audio", @"application/octet-stream"},	//filemagic\Sprint Music Store audio KOZ.xml
	{1, (OFString* []){@"sav", nil}, 0, 8, (uint8_t []){0x24, 0x46, 0x4C, 0x32, 0x40, 0x28, 0x23, 0x29}, @"SPSS Data file", @"application/octet-stream"},	//filemagic\SPSS Data file SAV.xml
	{1, (OFString* []){@"spo", nil}, 0, 8, (uint8_t []){0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1}, @"SPSS output file", @"application/octet-stream"},	//filemagic\SPSS output file SPO.xml
	{1, (OFString* []){@"mdf", nil}, 0, 4, (uint8_t []){0x01, 0x0F, 0x00, 0x00}, @"SQL Data Base", @"text/plain"},	//filemagic\SQL Data Base MDF.xml
	{1, (OFString* []){@"db", nil}, 0, 16, (uint8_t []){0x53, 0x51, 0x4C, 0x69, 0x74, 0x65, 0x20, 0x66, 0x6F, 0x72, 0x6D, 0x61, 0x74, 0x20, 0x33, 0x00}, @"SQLite database file", @"application/octet-stream"},	//filemagic\SQLite database file DB.xml
	{1, (OFString* []){@"sxc", nil}, 0, 4, (uint8_t []){0x50, 0x4B, 0x03, 0x04}, @"StarOffice spreadsheet", @"application/vnd.sun.xml.calc"},	//filemagic\StarOffice spreadsheet SXC.xml
	{1, (OFString* []){@"sle", nil}, 0, 3, (uint8_t []){0x41, 0x43, 0x76}, @"Steganos virtual secure drive", @"application/x-seelogo"},	//filemagic\Steganos virtual secure drive SLE.xml
	{1, (OFString* []){@"spf", nil}, 0, 5, (uint8_t []){0x53, 0x50, 0x46, 0x49, 0x00}, @"StorageCraft ShadownProtect backup file", @"application/vnd.yamaha.smaf-phrase"},	//filemagic\StorageCraft ShadownProtect backup file SPF.xml
	{1, (OFString* []){@"sit", nil}, 0, 5, (uint8_t []){0x53, 0x49, 0x54, 0x21, 0x00}, @"StuffIt archive", @"application/x-sit"},	//filemagic\StuffIt archive SIT.xml
	{1, (OFString* []){@"sit", nil}, 0, 8, (uint8_t []){0x53, 0x74, 0x75, 0x66, 0x66, 0x49, 0x74, 0x20}, @"StuffIt compressed archive", @"application/x-sit"},	//filemagic\StuffIt compressed archive SIT.xml
	{1, (OFString* []){@"cal", nil}, 0, 8, (uint8_t []){0x53, 0x75, 0x70, 0x65, 0x72, 0x43, 0x61, 0x6C}, @"SuperCalc worksheet", @"application/octet-stream"},	//filemagic\SuperCalc worksheet CAL.xml
	{1, (OFString* []){@"sle", nil}, 0, 8, (uint8_t []){0x3A, 0x56, 0x45, 0x52, 0x53, 0x49, 0x4F, 0x4E}, @"Surfplan kite project file", @"application/x-seelogo"},	//filemagic\Surfplan kite project file SLE.xml
	{1, (OFString* []){@"log", nil}, 0, 9, (uint8_t []){0x2A, 0x2A, 0x2A, 0x20, 0x20, 0x49, 0x6E, 0x73}, @"Symantec Wise Installer log", @"application/octet-stream"},	//filemagic\Symantec Wise Installer log LOG.xml
	{2, (OFString* []){@"gho", @"ghs", nil}, 0, 2, (uint8_t []){0xFE, 0xEF}, @"Symantex Ghost image file", @"application/octet-stream"},	//filemagic\Symantex Ghost image file GHO_GHS.xml
	{1, (OFString* []){@"(none)", nil}, 0, 8, (uint8_t []){0x53, 0x5A, 0x44, 0x44, 0x88, 0xF0, 0x27, 0x33}, @"SZDD file format", @"application/msonenote"},	//filemagic\SZDD file format (none).xml
	{1, (OFString* []){@"dst", nil}, 0, 3, (uint8_t []){0x4C, 0x41, 0x3A}, @"Tajima emboridery", @"application/vnd.sailingtracker.track"},	//filemagic\Tajima emboridery DST.xml
	{1, (OFString* []){@"tar", nil}, 257, 5, (uint8_t []){0x75, 0x73, 0x74, 0x61, 0x72}, @"Tape Archive", @"application/octet-stream"},	//filemagic\Tape Archive TAR.xml
	{1, (OFString* []){@"mte", nil}, 0, 16, (uint8_t []){0x4D, 0x43, 0x57, 0x20, 0x54, 0x65, 0x63, 0x68, 0x6E, 0x6F, 0x67, 0x6F, 0x6C, 0x69, 0x65, 0x73}, @"TargetExpress target file", @"application/x-troff"},	//filemagic\TargetExpress target file MTE.xml
	{1, (OFString* []){@"(none)", nil}, 0, 4, (uint8_t []){0xA1, 0xB2, 0xC3, 0xD4}, @"tcpdump (libpcap) capture file", @"application/msonenote"},	//filemagic\tcpdump (libpcap) capture file (none).xml
	{1, (OFString* []){@"(none)", nil}, 0, 4, (uint8_t []){0x34, 0xCD, 0xB2, 0xA1}, @"Tcpdump capture file", @"application/msonenote"},	//filemagic\Tcpdump capture file (none).xml
	{1, (OFString* []){@"tbi", nil}, 0, 12, (uint8_t []){0x01, 0x01, 0x47, 0x19, 0xA4, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, @"The Bat! Message Base Index", @"application/x-troff"},	//filemagic\The Bat! Message Base Index TBI.xml
	{1, (OFString* []){@"db", nil}, 512, 4, (uint8_t []){0xFD, 0xFF, 0xFF, 0xFF}, @"Thumbs.db subheader", @"application/octet-stream"},	//filemagic\Thumbs.db subheader DB.xml
	{1, (OFString* []){@"msf", nil}, 0, 19, (uint8_t []){0x2F, 0x2F, 0x20, 0x3C, 0x21, 0x2D, 0x2D, 0x20, 0x3C, 0x6D, 0x64, 0x62, 0x3A, 0x6D, 0x6F, 0x72, 0x6B, 0x3A, 0x7A}, @"Thunderbird|Mozilla Mail Summary File", @"application/vnd.epson.msf"},	//filemagic\Thunderbird_Mozilla Mail Summary File MSF.xml
	{2, (OFString* []){@"tif", @"tiff", nil}, 0, 3, (uint8_t []){0x49, 0x20, 0x49}, @"TIFF file_1", @"application/x-troff"},	//filemagic\TIFF file_1 TIF_TIFF.xml
	{2, (OFString* []){@"tif", @"tiff", nil}, 0, 4, (uint8_t []){0x49, 0x49, 0x2A, 0x00}, @"TIFF file_2", @"application/x-troff"},	//filemagic\TIFF file_2 TIF_TIFF.xml
	{2, (OFString* []){@"tif", @"tiff", nil}, 0, 4, (uint8_t []){0x4D, 0x4D, 0x00, 0x2A}, @"TIFF file_3", @"application/x-troff"},	//filemagic\TIFF file_3 TIF_TIFF.xml
	{2, (OFString* []){@"tif", @"tiff", nil}, 0, 4, (uint8_t []){0x4D, 0x4D, 0x00, 0x2B}, @"TIFF file_4", @"application/x-troff"},	//filemagic\TIFF file_4 TIF_TIFF.xml
	{1, (OFString* []){@"dat", nil}, 0, 8, (uint8_t []){0x4E, 0x41, 0x56, 0x54, 0x52, 0x41, 0x46, 0x46}, @"TomTom traffic data", @"application/octet-stream"},	//filemagic\TomTom traffic data DAT.xml
	{1, (OFString* []){@"ttf", nil}, 0, 5, (uint8_t []){0x00, 0x01, 0x00, 0x00, 0x00}, @"TrueType font file", @"application/x-font-ttf"},	//filemagic\TrueType font file TTF.xml
	{1, (OFString* []){@"ufa", nil}, 0, 6, (uint8_t []){0x55, 0x46, 0x41, 0xC6, 0xD2, 0xC1}, @"UFA compressed archive", @"application/octet-stream"},	//filemagic\UFA compressed archive UFA.xml
	{1, (OFString* []){@"dat", nil}, 0, 8, (uint8_t []){0x55, 0x46, 0x4F, 0x4F, 0x72, 0x62, 0x69, 0x74}, @"UFO Capture map file", @"application/octet-stream"},	//filemagic\UFO Capture map file DAT.xml
	{1, (OFString* []){@"ast", nil}, 0, 4, (uint8_t []){0x53, 0x43, 0x48, 0x6C}, @"Underground Audio", @"application/octet-stream"},	//filemagic\Underground Audio AST.xml
	{1, (OFString* []){@"uce", nil}, 0, 4, (uint8_t []){0x55, 0x43, 0x45, 0x58}, @"Unicode extensions", @"text/plain"},	//filemagic\Unicode extensions UCE.xml
	{1, (OFString* []){@"lib", nil}, 0, 8, (uint8_t []){0x21, 0x3C, 0x61, 0x72, 0x63, 0x68, 0x3E, 0x0A}, @"Unix archiver (ar)|MS Program Library Common Object File Format (COFF)", @"application/octet-stream"},	//filemagic\Unix archiver (ar)_MS Program Library Common Object File Format (COFF) LIB.xml
	{1, (OFString* []){@"xml", nil}, 0, 21, (uint8_t []){0x3C, 0x3F, 0x78, 0x6D, 0x6C, 0x20, 0x76, 0x65, 0x72, 0x73, 0x69, 0x6F, 0x6E, 0x3D, 0x22, 0x31, 0x2E, 0x30, 0x22, 0x3F, 0x3E}, @"User Interface Language", @"application/atom+xml"},	//filemagic\User Interface Language XML.xml
	{1, (OFString* []){@"(none)", nil}, 0, 2, (uint8_t []){0xFE, 0xFF}, @"UTF-16|UCS-2 file", @"application/msonenote"},	//filemagic\UTF-16_UCS-2 file (NONE).xml
	{1, (OFString* []){@"(none)", nil}, 0, 2, (uint8_t []){0xFF, 0xFE}, @"UTF-32|UCS-2 file", @"application/msonenote"},	//filemagic\UTF-32_UCS-2 file (NONE).xml
	{1, (OFString* []){@"(none)", nil}, 0, 4, (uint8_t []){0xFF, 0xFE, 0x00, 0x00}, @"UTF-32|UCS-4 file", @"application/msonenote"},	//filemagic\UTF-32_UCS-4 file (NONE).xml
	{1, (OFString* []){@"(none)", nil}, 0, 3, (uint8_t []){0xEF, 0xBB, 0xBF}, @"UTF8 file", @"application/msonenote"},	//filemagic\UTF8 file (none).xml
	{1, (OFString* []){@"b64", nil}, 0, 12, (uint8_t []){0x62, 0x65, 0x67, 0x69, 0x6E, 0x2D, 0x62, 0x61, 0x73, 0x65, 0x36, 0x34}, @"UUencoded BASE64 file", @"application/octet-stream"},	//filemagic\UUencoded BASE64 file b64.xml
	{1, (OFString* []){@"(none)", nil}, 0, 5, (uint8_t []){0x62, 0x65, 0x67, 0x69, 0x6E}, @"UUencoded file", @"application/msonenote"},	//filemagic\UUencoded file (none).xml
	{1, (OFString* []){@"vcf", nil}, 0, 8, (uint8_t []){0x42, 0x45, 0x47, 0x49, 0x4E, 0x3A, 0x56, 0x43}, @"vCard", @"text/plain"},	//filemagic\vCard VCF.xml
	{1, (OFString* []){@"dat", nil}, 0, 4, (uint8_t []){0x52, 0x49, 0x46, 0x46}, @"Video CD MPEG movie", @"application/octet-stream"},	//filemagic\Video CD MPEG movie DAT.xml
	{1, (OFString* []){@"vcd", nil}, 0, 8, (uint8_t []){0x45, 0x4E, 0x54, 0x52, 0x59, 0x56, 0x43, 0x44}, @"VideoVCD|VCDImager file", @"application/x-cdlink"},	//filemagic\VideoVCD_VCDImager file VCD.xml
	{1, (OFString* []){@"vhd", nil}, 0, 8, (uint8_t []){0x63, 0x6F, 0x6E, 0x65, 0x63, 0x74, 0x69, 0x78}, @"Virtual PC HD image", @"text/plain"},	//filemagic\Virtual PC HD image VHD.xml
	{1, (OFString* []){@"vsd", nil}, 0, 8, (uint8_t []){0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1}, @"Visio file", @"application/vnd.visio"},	//filemagic\Visio file VSD.xml
	{1, (OFString* []){@"dw4", nil}, 0, 2, (uint8_t []){0x4F, 0x7B}, @"Visio|DisplayWrite 4 text file", @"application/octet-stream"},	//filemagic\Visio_DisplayWrite 4 text file DW4.xml
	{1, (OFString* []){@"ctl", nil}, 0, 8, (uint8_t []){0x56, 0x45, 0x52, 0x53, 0x49, 0x4F, 0x4E, 0x20}, @"Visual Basic User-defined Control file", @"application/x-troff"},	//filemagic\Visual Basic User-defined Control file CTL.xml
	{1, (OFString* []){@"pch", nil}, 0, 6, (uint8_t []){0x56, 0x43, 0x50, 0x43, 0x48, 0x30}, @"Visual C PreCompiled header", @"text/plain"},	//filemagic\Visual C PreCompiled header PCH.xml
	{1, (OFString* []){@"vcw", nil}, 0, 5, (uint8_t []){0x5B, 0x4D, 0x53, 0x56, 0x43}, @"Visual C++ Workbench Info File", @"text/plain"},	//filemagic\Visual C++ Workbench Info File VCW.xml
	{1, (OFString* []){@"sln", nil}, 0, 16, (uint8_t []){0x4D, 0x69, 0x63, 0x72, 0x6F, 0x73, 0x6F, 0x66, 0x74, 0x20, 0x56, 0x69, 0x73, 0x75, 0x61, 0x6C}, @"Visual Studio .NET file", @"application/x-seelogo"},	//filemagic\Visual Studio .NET file SLN.xml
	{1, (OFString* []){@"suo", nil}, 512, 5, (uint8_t []){0xFD, 0xFF, 0xFF, 0xFF, 0x04}, @"Visual Studio Solution subheader", @"application/octet-stream"},	//filemagic\Visual Studio Solution subheader SUO.xml
	{1, (OFString* []){@"sou", nil}, 0, 8, (uint8_t []){0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1}, @"Visual Studio Solution User Options file", @"application/octet-stream"},	//filemagic\Visual Studio Solution User Options file SOU.xml
	{1, (OFString* []){@"vbx", nil}, 0, 2, (uint8_t []){0x4D, 0x5A}, @"VisualBASIC application", @"application/octet-stream"},	//filemagic\VisualBASIC application VBX.xml
	{1, (OFString* []){@"vlt", nil}, 0, 3, (uint8_t []){0x1F, 0x8B, 0x08}, @"VLC Player Skin file", @"application/x-troff"},	//filemagic\VLC Player Skin file VLT.xml
	{1, (OFString* []){@"gdb", nil}, 0, 5, (uint8_t []){0x4D, 0x73, 0x52, 0x63, 0x66}, @"VMapSource GPS Waypoint Database", @"text/plain"},	//filemagic\VMapSource GPS Waypoint Database GDB.xml
	{1, (OFString* []){@"vmdk", nil}, 0, 4, (uint8_t []){0x43, 0x4F, 0x57, 0x44}, @"VMware 3 Virtual Disk", @"application/vocaltec-media-desc"},	//filemagic\VMware 3 Virtual Disk VMDK.xml
	{1, (OFString* []){@"vmdk", nil}, 0, 8, (uint8_t []){0x23, 0x20, 0x44, 0x69, 0x73, 0x6B, 0x20, 0x44}, @"VMware 4 Virtual Disk description", @"application/vocaltec-media-desc"},	//filemagic\VMware 4 Virtual Disk description VMDK.xml
	{1, (OFString* []){@"vmdk", nil}, 0, 3, (uint8_t []){0x4B, 0x44, 0x4D}, @"VMware 4 Virtual Disk", @"application/vocaltec-media-desc"},	//filemagic\VMware 4 Virtual Disk VMDK.xml
	{1, (OFString* []){@"nvram", nil}, 0, 4, (uint8_t []){0x4D, 0x52, 0x56, 0x4E}, @"VMware BIOS state file", @"application/octet-stream"},	//filemagic\VMware BIOS state file NVRAM.xml
	{1, (OFString* []){@"vmd", nil}, 0, 5, (uint8_t []){0x5B, 0x56, 0x4D, 0x44, 0x5D}, @"VocalTec VoIP media file", @"application/vocaltec-media-desc"},	//filemagic\VocalTec VoIP media file VMD.xml
	{1, (OFString* []){@"dat", nil}, 0, 4, (uint8_t []){0x57, 0x4D, 0x4D, 0x50}, @"Walkman MP3 file", @"application/octet-stream"},	//filemagic\Walkman MP3 file DAT.xml
	{1, (OFString* []){@"webm", nil}, 0, 4, (uint8_t []){0x1A, 0x45, 0xDF, 0xA3}, @"WebM video file", @"application/vnd.xara"},	//filemagic\WebM video file WEBM.xml
	{1, (OFString* []){@"ctf", nil}, 0, 8, (uint8_t []){0x43, 0x61, 0x74, 0x61, 0x6C, 0x6F, 0x67, 0x20}, @"WhereIsIt Catalog", @"application/x-troff"},	//filemagic\WhereIsIt Catalog CTF.xml
	{1, (OFString* []){@"thp", nil}, 0, 4, (uint8_t []){0x54, 0x48, 0x50, 0x00}, @"Wii-GameCube", @"application/x-troff"},	//filemagic\Wii-GameCube THP.xml
	{1, (OFString* []){@"shd", nil}, 0, 4, (uint8_t []){0x68, 0x49, 0x00, 0x00}, @"Win Server 2003 printer spool file", @"application/x-bsh"},	//filemagic\Win Server 2003 printer spool file SHD.xml
	{1, (OFString* []){@"shd", nil}, 0, 4, (uint8_t []){0x67, 0x49, 0x00, 0x00}, @"Win2000|XP printer spool file", @"application/x-bsh"},	//filemagic\Win2000_XP printer spool file SHD.xml
	{1, (OFString* []){@"pwl", nil}, 0, 4, (uint8_t []){0xB0, 0x4D, 0x46, 0x43}, @"Win95 password file", @"text/x-pascal"},	//filemagic\Win95 password file PWL.xml
	{1, (OFString* []){@"pwl", nil}, 0, 4, (uint8_t []){0xE3, 0x82, 0x85, 0x96}, @"Win98 password file", @"text/x-pascal"},	//filemagic\Win98 password file PWL.xml
	{1, (OFString* []){@"shd", nil}, 0, 4, (uint8_t []){0x4B, 0x49, 0x00, 0x00}, @"Win9x printer spool file", @"application/x-bsh"},	//filemagic\Win9x printer spool file SHD.xml
	{1, (OFString* []){@"dat", nil}, 0, 4, (uint8_t []){0x43, 0x52, 0x45, 0x47}, @"Win9x registry hive", @"application/octet-stream"},	//filemagic\Win9x registry hive DAT.xml
	{1, (OFString* []){@"pls", nil}, 0, 10, (uint8_t []){0x5B, 0x70, 0x6C, 0x61, 0x79, 0x6C, 0x69, 0x73, 0x74, 0x5D}, @"WinAmp Playlist", @"application/pls+xml"},	//filemagic\WinAmp Playlist PLS.xml
	{1, (OFString* []){@"db", nil}, 0, 8, (uint8_t []){0x43, 0x4D, 0x4D, 0x4D, 0x15, 0x00, 0x00, 0x00}, @"Windows 7 thumbnail", @"application/octet-stream"},	//filemagic\Windows 7 thumbnail DB.xml
	{1, (OFString* []){@"db", nil}, 0, 8, (uint8_t []){0x49, 0x4D, 0x4D, 0x4D, 0x15, 0x00, 0x00, 0x00}, @"Windows 7 thumbnail_2", @"application/octet-stream"},	//filemagic\Windows 7 thumbnail_2 DB.xml
	{1, (OFString* []){@"ani", nil}, 0, 4, (uint8_t []){0x52, 0x49, 0x46, 0x46}, @"Windows animated cursor", @"application/octet-stream"},	//filemagic\Windows animated cursor ANI.xml
	{2, (OFString* []){@"lgc", @"lgd", nil}, 0, 5, (uint8_t []){0x7B, 0x0D, 0x0A, 0x6F, 0x20}, @"Windows application log", @"text/plain"},	//filemagic\Windows application log LGC_LGD.xml
	{1, (OFString* []){@"cal", nil}, 0, 8, (uint8_t []){0xB5, 0xA2, 0xB0, 0xB3, 0xB3, 0xB0, 0xA5, 0xB5}, @"Windows calendar", @"application/octet-stream"},	//filemagic\Windows calendar CAL.xml
	{1, (OFString* []){@"cur", nil}, 0, 4, (uint8_t []){0x00, 0x00, 0x02, 0x00}, @"Windows cursor", @"application/cu-seeme"},	//filemagic\Windows cursor CUR.xml
	{1, (OFString* []){@"tbi", nil}, 0, 8, (uint8_t []){0x00, 0x00, 0x00, 0x00, 0x14, 0x00, 0x00, 0x00}, @"Windows Disk Image", @"application/x-troff"},	//filemagic\Windows Disk Image TBI.xml
	{2, (OFString* []){@"dmp", @"hdmp", nil}, 0, 6, (uint8_t []){0x4D, 0x44, 0x4D, 0x50, 0x93, 0xA7}, @"Windows dump file", @"application/vnd.tcpdump.pcap"},	//filemagic\Windows dump file DMP_HDMP.xml
	{1, (OFString* []){@"evt", nil}, 0, 8, (uint8_t []){0x30, 0x00, 0x00, 0x00, 0x4C, 0x66, 0x4C, 0x65}, @"Windows Event Viewer file", @"application/x-troff"},	//filemagic\Windows Event Viewer file EVT.xml
	{2, (OFString* []){@"com", @"sys", nil}, 0, 1, (uint8_t []){0xE8}, @"Windows executable file_1", @"application/octet-stream"},	//filemagic\Windows executable file_1 COM_SYS.xml
	{2, (OFString* []){@"com", @"sys", nil}, 0, 1, (uint8_t []){0xE9}, @"Windows executable file_2", @"application/octet-stream"},	//filemagic\Windows executable file_2 COM_SYS.xml
	{2, (OFString* []){@"com", @"sys", nil}, 0, 1, (uint8_t []){0xEB}, @"Windows executable file_3", @"application/octet-stream"},	//filemagic\Windows executable file_3 COM_SYS.xml
	{1, (OFString* []){@"sys", nil}, 0, 1, (uint8_t []){0xFF}, @"Windows executable", @"text/x-asm"},	//filemagic\Windows executable SYS.xml
	{1, (OFString* []){@"wmf", nil}, 0, 4, (uint8_t []){0xD7, 0xCD, 0xC6, 0x9A}, @"Windows graphics metafile", @"application/x-msmetafile"},	//filemagic\Windows graphics metafile WMF.xml
	{1, (OFString* []){@"hlp", nil}, 6, 6, (uint8_t []){0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF}, @"Windows Help file_1", @"application/hlp"},	//filemagic\Windows Help file_1 HLP.xml
	{2, (OFString* []){@"gid", @"hlp", nil}, 0, 4, (uint8_t []){0x3F, 0x5F, 0x03, 0x00}, @"Windows Help file_2", @"application/hlp"},	//filemagic\Windows Help file_2 GID_HLP.xml
	{2, (OFString* []){@"gid", @"hlp", nil}, 0, 4, (uint8_t []){0x4C, 0x4E, 0x02, 0x00}, @"Windows help file_3", @"application/hlp"},	//filemagic\Windows help file_3 GID_HLP.xml
	{2, (OFString* []){@"ico", @"spl", nil}, 0, 4, (uint8_t []){0x00, 0x00, 0x01, 0x00}, @"Windows icon|printer spool file", @"application/futuresplash"},	//filemagic\Windows icon_printer spool file ICO_SPL.xml
	{1, (OFString* []){@"cpi", nil}, 0, 5, (uint8_t []){0xFF, 0x46, 0x4F, 0x4E, 0x54}, @"Windows international code page", @"text/plain"},	//filemagic\Windows international code page CPI.xml
	{3, (OFString* []){@"asf", @"wma", @"wmv", nil}, 0, 8, (uint8_t []){0x30, 0x26, 0xB2, 0x75, 0x8E, 0x66, 0xCF, 0x11}, @"Windows Media Audio|Video File", @"application/mathematica"},	//filemagic\Windows Media Audio_Video File ASF_WMA_WMV.xml
	{1, (OFString* []){@"wmz", nil}, 0, 4, (uint8_t []){0x50, 0x4B, 0x03, 0x04}, @"Windows Media compressed skin file", @"application/x-compress"},	//filemagic\Windows Media compressed skin file WMZ.xml
	{1, (OFString* []){@"wpl", nil}, 84, 34, (uint8_t []){0x4D, 0x69, 0x63, 0x72, 0x6F, 0x73, 0x6F, 0x66, 0x74, 0x20, 0x57, 0x69, 0x6E, 0x64, 0x6F, 0x77, 0x73, 0x20, 0x4D, 0x65, 0x64, 0x69, 0x61, 0x20, 0x50, 0x6C, 0x61, 0x79, 0x65, 0x72, 0x20, 0x2D, 0x2D, 0x20}, @"Windows Media Player playlist", @"application/vnd.ms-wpl"},	//filemagic\Windows Media Player playlist WPL.xml
	{1, (OFString* []){@"dmp", nil}, 0, 6, (uint8_t []){0x50, 0x41, 0x47, 0x45, 0x44, 0x55}, @"Windows memory dump", @"application/vnd.tcpdump.pcap"},	//filemagic\Windows memory dump DMP.xml
	{1, (OFString* []){@"pf", nil}, 0, 8, (uint8_t []){0x11, 0x00, 0x00, 0x00, 0x53, 0x43, 0x43, 0x41}, @"Windows prefetch file", @"text/plain"},	//filemagic\Windows prefetch file PF.xml
	{1, (OFString* []){@"pf", nil}, 4, 4, (uint8_t []){0x53, 0x43, 0x43, 0x41}, @"Windows prefetch", @"text/plain"},	//filemagic\Windows prefetch PF.xml
	{1, (OFString* []){@"grp", nil}, 0, 4, (uint8_t []){0x50, 0x4D, 0x43, 0x43}, @"Windows Program Manager group file", @"image/vnd.rn-realpix"},	//filemagic\Windows Program Manager group file GRP.xml
	{1, (OFString* []){@"reg", nil}, 0, 2, (uint8_t []){0xFF, 0xFE}, @"Windows Registry file", @"text/plain"},	//filemagic\Windows Registry file REG.xml
	{1, (OFString* []){@"lnk", nil}, 0, 8, (uint8_t []){0x4C, 0x00, 0x00, 0x00, 0x01, 0x14, 0x02, 0x00}, @"Windows shortcut file", @"application/x-ms-shortcut"},	//filemagic\Windows shortcut file LNK.xml
	{2, (OFString* []){@"vxd", @"386", nil}, 0, 2, (uint8_t []){0x4D, 0x5A}, @"Windows virtual device drivers", @"application/octet-stream"},	//filemagic\Windows virtual device drivers VXD_386.xml
	{1, (OFString* []){@"evtx", nil}, 0, 8, (uint8_t []){0x45, 0x6C, 0x66, 0x46, 0x69, 0x6C, 0x65, 0x00}, @"Windows Vista event log", @"application/x-troff"},	//filemagic\Windows Vista event log EVTX.xml
	{1, (OFString* []){@"manifest", nil}, 0, 14, (uint8_t []){0x3C, 0x3F, 0x78, 0x6D, 0x6C, 0x20, 0x76, 0x65, 0x72, 0x73, 0x69, 0x6F, 0x6E, 0x3D}, @"Windows Visual Stylesheet", @"application/ecmascript"},	//filemagic\Windows Visual Stylesheet MANIFEST.xml
	{8, (OFString* []){@"com", @"dll", @"drv", @"exe", @"pif", @"qts", @"qtx", @"sys", nil}, 0, 2, (uint8_t []){0x4D, 0x5A}, @"Windows|DOS executable file", @"application/octet-stream"},	//filemagic\Windows_DOS executable file COM_DLL_DRV_EXE_PIF_QTS_QTX_SYS.xml
	{1, (OFString* []){@"(none)", nil}, 0, 4, (uint8_t []){0xD4, 0xC3, 0xB2, 0xA1}, @"WinDump (winpcap) capture file", @"application/msonenote"},	//filemagic\WinDump (winpcap) capture file (none).xml
	{1, (OFString* []){@"cap", nil}, 0, 4, (uint8_t []){0x52, 0x54, 0x53, 0x53}, @"WinNT Netmon capture file", @"application/octet-stream"},	//filemagic\WinNT Netmon capture file CAP.xml
	{1, (OFString* []){@"shd", nil}, 0, 4, (uint8_t []){0x66, 0x49, 0x00, 0x00}, @"WinNT printer spool file", @"application/x-bsh"},	//filemagic\WinNT printer spool file SHD.xml
	{1, (OFString* []){@"dat", nil}, 0, 4, (uint8_t []){0x72, 0x65, 0x67, 0x66}, @"WinNT registry file", @"application/octet-stream"},	//filemagic\WinNT registry file DAT.xml
	{2, (OFString* []){@"reg", @"sud", nil}, 0, 7, (uint8_t []){0x52, 0x45, 0x47, 0x45, 0x44, 0x49, 0x54}, @"WinNT Registry|Registry Undo files", @"text/plain"},	//filemagic\WinNT Registry_Registry Undo files REG_SUD.xml
	{1, (OFString* []){@"eth", nil}, 0, 4, (uint8_t []){0x1A, 0x35, 0x01, 0x00}, @"WinPharoah capture file", @"application/x-troff"},	//filemagic\WinPharoah capture file ETH.xml
	{1, (OFString* []){@"ftr", nil}, 0, 4, (uint8_t []){0xD2, 0x0A, 0x00, 0x00}, @"WinPharoah filter file", @"application/x-troff"},	//filemagic\WinPharoah filter file FTR.xml
	{1, (OFString* []){@"rar", nil}, 0, 7, (uint8_t []){0x52, 0x61, 0x72, 0x21, 0x1A, 0x07, 0x00}, @"WinRAR compressed archive", @"application/octet-stream"},	//filemagic\WinRAR compressed archive RAR.xml
	{1, (OFString* []){@"zip", nil}, 29152, 6, (uint8_t []){0x57, 0x69, 0x6E, 0x5A, 0x69, 0x70}, @"WinZip compressed archive", @"application/octet-stream"},	//filemagic\WinZip compressed archive ZIP.xml
	{1, (OFString* []){@"doc", nil}, 0, 4, (uint8_t []){0xDB, 0xA5, 0x2D, 0x00}, @"Word 2.0 file", @"application/msword"},	//filemagic\Word 2.0 file DOC.xml
	{1, (OFString* []){@"doc", nil}, 512, 4, (uint8_t []){0xEC, 0xA5, 0xC1, 0x00}, @"Word document subheader", @"application/msword"},	//filemagic\Word document subheader DOC.xml
	{1, (OFString* []){@"cbd", nil}, 0, 6, (uint8_t []){0x43, 0x42, 0x46, 0x49, 0x4C, 0x45}, @"WordPerfect dictionary", @"text/plain"},	//filemagic\WordPerfect dictionary CBD.xml
	{6, (OFString* []){@"wp", @"wpd", @"wpg", @"wpp", @"wp5", @"wp6", nil}, 0, 4, (uint8_t []){0xFF, 0x57, 0x50, 0x43}, @"WordPerfect text and graphics", @"application/vnd.wordperfect"},	//filemagic\WordPerfect text and graphics WP_WPD_WPG_WPP_WP5_WP6.xml
	{1, (OFString* []){@"wpf", nil}, 0, 3, (uint8_t []){0x81, 0xCD, 0xAB}, @"WordPerfect text", @"application/wordperfect"},	//filemagic\WordPerfect text WPF.xml
	{1, (OFString* []){@"ws2", nil}, 0, 6, (uint8_t []){0x57, 0x53, 0x32, 0x30, 0x30, 0x30}, @"WordStar for Windows file", @"text/x-asm"},	//filemagic\WordStar for Windows file WS2.xml
	{1, (OFString* []){@"ws", nil}, 0, 2, (uint8_t []){0x1D, 0x7D}, @"WordStar Version 5.0|6.0 document", @"text/x-asm"},	//filemagic\WordStar Version 5.0_6.0 document WS.xml
	{1, (OFString* []){@"wks", nil}, 0, 8, (uint8_t []){0xFF, 0x00, 0x02, 0x00, 0x04, 0x04, 0x05, 0x54}, @"Works for Windows spreadsheet", @"application/vnd.ms-works"},	//filemagic\Works for Windows spreadsheet WKS.xml
	{1, (OFString* []){@"xps", nil}, 0, 4, (uint8_t []){0x50, 0x4B, 0x03, 0x04}, @"XML paper specification file", @"application/postscript"},	//filemagic\XML paper specification file XPS.xml
	{1, (OFString* []){@"xpt", nil}, 0, 8, (uint8_t []){0x58, 0x50, 0x43, 0x4F, 0x4D, 0x0A, 0x54, 0x79}, @"XPCOM libraries", @"application/x-troff"},	//filemagic\XPCOM libraries XPT.xml
	{1, (OFString* []){@"xz", nil}, 0, 6, (uint8_t []){0xFD, 0x37, 0x7A, 0x58, 0x5A, 0x00}, @"XZ archive", @"application/x-compress"},	//filemagic\XZ archive XZ.xml
	{1, (OFString* []){@"pcs", nil}, 0, 4, (uint8_t []){0x4D, 0x54, 0x68, 0x64}, @"Yamaha Piano", @"text/plain"},	//filemagic\Yamaha Piano PCS.xml
	{1, (OFString* []){@"mmf", nil}, 0, 6, (uint8_t []){0x4D, 0x4D, 0x4D, 0x44, 0x00, 0x00}, @"Yamaha Synthetic music Mobile Application Format", @"application/base64"},	//filemagic\Yamaha Synthetic music Mobile Application Format MMF.xml
	{1, (OFString* []){@"(none)", nil}, 0, 8, (uint8_t []){0x37, 0xE4, 0x53, 0x96, 0xC9, 0xDB, 0xD6, 0x07}, @"zisofs compressed file", @"application/msonenote"},	//filemagic\zisofs compressed file (none).xml
	{1, (OFString* []){@"zip", nil}, 0, 8, (uint8_t []){0x50, 0x4B, 0x03, 0x04, 0x14, 0x00, 0x01, 0x00}, @"ZLock Pro encrypted ZIP", @"application/octet-stream"},	//filemagic\ZLock Pro encrypted ZIP ZIP.xml
	{1, (OFString* []){@"zap", nil}, 0, 14, (uint8_t []){0x4D, 0x5A, 0x90, 0x00, 0x03, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0xFF, 0xFF}, @"ZoneAlam data file", @"application/octet-stream"},	//filemagic\ZoneAlam data file ZAP.xml
	{1, (OFString* []){@"zoo", nil}, 0, 4, (uint8_t []){0x5A, 0x4F, 0x4F, 0x20}, @"ZOO compressed archive", @"application/octet-stream"},	//filemagic\ZOO compressed archive ZOO.xml
	{1, (OFString* []){@"info", nil}, 0, 4, (uint8_t []){0x7A, 0x62, 0x65, 0x78}, @"ZoomBrowser Image Index", @"application/inf"},	//filemagic\ZoomBrowser Image Index INFO.xml
	{1, (OFString* []){@"pcx", nil}, 0, 4, (uint8_t []){0x0A, 0x02, 0x01, 0x01}, @"ZSOFT Paintbrush file_1", @"image/pcx"},	//filemagic\ZSOFT Paintbrush file_1 PCX.xml
	{1, (OFString* []){@"pcx", nil}, 0, 4, (uint8_t []){0x0A, 0x03, 0x01, 0x01}, @"ZSOFT Paintbrush file_2", @"image/pcx"},	//filemagic\ZSOFT Paintbrush file_2 PCX.xml
	{1, (OFString* []){@"pcx", nil}, 0, 4, (uint8_t []){0x0A, 0x05, 0x01, 0x01}, @"ZSOFT Paintbrush file_3", @"image/pcx"},	//filemagic\ZSOFT Paintbrush file_3 PCX.xml
	{1, (OFString* []){@"pyc", nil}, 0, 0, NULL, nil, @"application/x-bytecode.python"},
	{1, (OFString* []){@"dwg", nil}, 0, 0, NULL, nil, @"application/acad"},
	{1, (OFString* []){@"ez", nil}, 0, 0, NULL, nil, @"application/andrew-inset"},
	{1, (OFString* []){@"aw", nil}, 0, 0, NULL, nil, @"application/applixware"},
	{1, (OFString* []){@"arj", nil}, 0, 0, NULL, nil, @"application/arj"},
	{2, (OFString* []){@"atom", @"xml", nil}, 0, 0, NULL, nil, @"application/atom+xml"},
	{1, (OFString* []){@"atomcat", nil}, 0, 0, NULL, nil, @"application/atomcat+xml"},
	{1, (OFString* []){@"atomsvc", nil}, 0, 0, NULL, nil, @"application/atomsvc+xml"},
	{2, (OFString* []){@"mm", @"mme", nil}, 0, 0, NULL, nil, @"application/base64"},
	{1, (OFString* []){@"hqx", nil}, 0, 0, NULL, nil, @"application/binhex"},
	{1, (OFString* []){@"hqx", nil}, 0, 0, NULL, nil, @"application/binhex4"},
	{2, (OFString* []){@"boo", @"book", nil}, 0, 0, NULL, nil, @"application/book"},
	{1, (OFString* []){@"ccxml", nil}, 0, 0, NULL, nil, @"application/ccxml+xml"},
	{1, (OFString* []){@"cdf", nil}, 0, 0, NULL, nil, @"application/cdf"},
	{1, (OFString* []){@"cdmia", nil}, 0, 0, NULL, nil, @"application/cdmi-capability"},
	{1, (OFString* []){@"cdmic", nil}, 0, 0, NULL, nil, @"application/cdmi-container"},
	{1, (OFString* []){@"cdmid", nil}, 0, 0, NULL, nil, @"application/cdmi-domain"},
	{1, (OFString* []){@"cdmio", nil}, 0, 0, NULL, nil, @"application/cdmi-object"},
	{1, (OFString* []){@"cdmiq", nil}, 0, 0, NULL, nil, @"application/cdmi-queue"},
	{1, (OFString* []){@"ccad", nil}, 0, 0, NULL, nil, @"application/clariscad"},
	{1, (OFString* []){@"dp", nil}, 0, 0, NULL, nil, @"application/commonground"},
	{2, (OFString* []){@"cu", @"csm", nil}, 0, 0, NULL, nil, @"application/cu-seeme"},
	{1, (OFString* []){@"davmount", nil}, 0, 0, NULL, nil, @"application/davmount+xml"},
	{1, (OFString* []){@"dbk", nil}, 0, 0, NULL, nil, @"application/docbook+xml"},
	{1, (OFString* []){@"drw", nil}, 0, 0, NULL, nil, @"application/drafting"},
	{1, (OFString* []){@"tsp", nil}, 0, 0, NULL, nil, @"application/dsptype"},
	{1, (OFString* []){@"dssc", nil}, 0, 0, NULL, nil, @"application/dssc+der"},
	{1, (OFString* []){@"xdssc", nil}, 0, 0, NULL, nil, @"application/dssc+xml"},
	{1, (OFString* []){@"dxf", nil}, 0, 0, NULL, nil, @"application/dxf"},
	{3, (OFString* []){@"es", @"ecma", @"js", nil}, 0, 0, NULL, nil, @"application/ecmascript"},
	{1, (OFString* []){@"emma", nil}, 0, 0, NULL, nil, @"application/emma+xml"},
	{1, (OFString* []){@"evy", nil}, 0, 0, NULL, nil, @"application/envoy"},
	{1, (OFString* []){@"epub", nil}, 0, 0, NULL, nil, @"application/epub+zip"},
	{12, (OFString* []){@"xl", @"xla", @"xlb", @"xlc", @"xld", @"xlk", @"xll", @"xlm", @"xls", @"xlt", @"xlv", @"xlw", nil}, 0, 0, NULL, nil, @"application/excel"},
	{1, (OFString* []){@"exi", nil}, 0, 0, NULL, nil, @"application/exi"},
	{1, (OFString* []){@"pfr", nil}, 0, 0, NULL, nil, @"application/font-tdpfr"},
	{1, (OFString* []){@"woff", nil}, 0, 0, NULL, nil, @"application/font-woff"},
	{1, (OFString* []){@"fif", nil}, 0, 0, NULL, nil, @"application/fractals"},
	{1, (OFString* []){@"frl", nil}, 0, 0, NULL, nil, @"application/freeloader"},
	{1, (OFString* []){@"spl", nil}, 0, 0, NULL, nil, @"application/futuresplash"},
	{1, (OFString* []){@"gml", nil}, 0, 0, NULL, nil, @"application/gml+xml"},
	{1, (OFString* []){@"tgz", nil}, 0, 0, NULL, nil, @"application/gnutar"},
	{1, (OFString* []){@"gpx", nil}, 0, 0, NULL, nil, @"application/gpx+xml"},
	{1, (OFString* []){@"vew", nil}, 0, 0, NULL, nil, @"application/groupwise"},
	{1, (OFString* []){@"gxf", nil}, 0, 0, NULL, nil, @"application/gxf"},
	{1, (OFString* []){@"hlp", nil}, 0, 0, NULL, nil, @"application/hlp"},
	{1, (OFString* []){@"hta", nil}, 0, 0, NULL, nil, @"application/hta"},
	{1, (OFString* []){@"stk", nil}, 0, 0, NULL, nil, @"application/hyperstudio"},
	{1, (OFString* []){@"unv", nil}, 0, 0, NULL, nil, @"application/i-deas"},
	{2, (OFString* []){@"iges", @"igs", nil}, 0, 0, NULL, nil, @"application/iges"},
	{1, (OFString* []){@"inf", nil}, 0, 0, NULL, nil, @"application/inf"},
	{2, (OFString* []){@"ink", @"inkml", nil}, 0, 0, NULL, nil, @"application/inkml+xml"},
	{1, (OFString* []){@"acx", nil}, 0, 0, NULL, nil, @"application/internet-property-stream"},
	{1, (OFString* []){@"ipfix", nil}, 0, 0, NULL, nil, @"application/ipfix"},
	{1, (OFString* []){@"class", nil}, 0, 0, NULL, nil, @"application/java"},
	{1, (OFString* []){@"jar", nil}, 0, 0, NULL, nil, @"application/java-archive"},
	{1, (OFString* []){@"class", nil}, 0, 0, NULL, nil, @"application/java-byte-code"},
	{1, (OFString* []){@"ser", nil}, 0, 0, NULL, nil, @"application/java-serialized-object"},
	{1, (OFString* []){@"class", nil}, 0, 0, NULL, nil, @"application/java-vm"},
	{1, (OFString* []){@"js", nil}, 0, 0, NULL, nil, @"application/javascript"},
	{1, (OFString* []){@"json", nil}, 0, 0, NULL, nil, @"application/json"},
	{1, (OFString* []){@"jsonml", nil}, 0, 0, NULL, nil, @"application/jsonml+json"},
	{1, (OFString* []){@"lha", nil}, 0, 0, NULL, nil, @"application/lha"},
	{1, (OFString* []){@"lostxml", nil}, 0, 0, NULL, nil, @"application/lost+xml"},
	{1, (OFString* []){@"lzx", nil}, 0, 0, NULL, nil, @"application/lzx"},
	{1, (OFString* []){@"bin", nil}, 0, 0, NULL, nil, @"application/mac-binary"},
	{1, (OFString* []){@"hqx", nil}, 0, 0, NULL, nil, @"application/mac-binhex"},
	{1, (OFString* []){@"hqx", nil}, 0, 0, NULL, nil, @"application/mac-binhex40"},
	{1, (OFString* []){@"cpt", nil}, 0, 0, NULL, nil, @"application/mac-compactpro"},
	{1, (OFString* []){@"bin", nil}, 0, 0, NULL, nil, @"application/macbinary"},
	{1, (OFString* []){@"mads", nil}, 0, 0, NULL, nil, @"application/mads+xml"},
	{1, (OFString* []){@"mrc", nil}, 0, 0, NULL, nil, @"application/marc"},
	{1, (OFString* []){@"mrcx", nil}, 0, 0, NULL, nil, @"application/marcxml+xml"},
	{3, (OFString* []){@"ma", @"nb", @"mb", nil}, 0, 0, NULL, nil, @"application/mathematica"},
	{1, (OFString* []){@"mathml", nil}, 0, 0, NULL, nil, @"application/mathml+xml"},
	{1, (OFString* []){@"mbd", nil}, 0, 0, NULL, nil, @"application/mbedlet"},
	{1, (OFString* []){@"mbox", nil}, 0, 0, NULL, nil, @"application/mbox"},
	{1, (OFString* []){@"mcd", nil}, 0, 0, NULL, nil, @"application/mcad"},
	{1, (OFString* []){@"mscml", nil}, 0, 0, NULL, nil, @"application/mediaservercontrol+xml"},
	{1, (OFString* []){@"metalink", nil}, 0, 0, NULL, nil, @"application/metalink+xml"},
	{1, (OFString* []){@"meta4", nil}, 0, 0, NULL, nil, @"application/metalink4+xml"},
	{1, (OFString* []){@"mets", nil}, 0, 0, NULL, nil, @"application/mets+xml"},
	{1, (OFString* []){@"aps", nil}, 0, 0, NULL, nil, @"application/mime"},
	{1, (OFString* []){@"mods", nil}, 0, 0, NULL, nil, @"application/mods+xml"},
	{2, (OFString* []){@"m21", @"mp21", nil}, 0, 0, NULL, nil, @"application/mp21"},
	{3, (OFString* []){@"mp4", @"m4p", @"mp4s", nil}, 0, 0, NULL, nil, @"application/mp4"},
	{1, (OFString* []){@"mdb", nil}, 0, 0, NULL, nil, @"application/msaccess"},
	{4, (OFString* []){@"one", @"onetoc2", @"onetmp", @"onepkg", nil}, 0, 0, NULL, nil, @"application/msonenote"},
	{4, (OFString* []){@"pot", @"pps", @"ppt", @"ppz", nil}, 0, 0, NULL, nil, @"application/mspowerpoint"},
	{5, (OFString* []){@"doc", @"dot", @"w6w", @"wiz", @"word", nil}, 0, 0, NULL, nil, @"application/msword"},
	{1, (OFString* []){@"wri", nil}, 0, 0, NULL, nil, @"application/mswrite"},
	{1, (OFString* []){@"mxf", nil}, 0, 0, NULL, nil, @"application/mxf"},
	{1, (OFString* []){@"mcp", nil}, 0, 0, NULL, nil, @"application/netmc"},
	{35, (OFString* []){@"bin", @"dms", @"lrf", @"mar", @"so", @"dist", @"distz", @"pkg", @"bpk", @"dump", @"elc", @"a", @"arc", @"arj", @"com", @"exe", @"lha", @"lhx", @"lzh", @"lzx", @"o", @"psd", @"saveme", @"uu", @"zoo", @"class", @"buffer", @"deploy", @"hqx", @"obj", @"lib", @"zip", @"gz", @"dmg", @"iso", nil}, 0, 0, NULL, nil, @"application/octet-stream"},
	{1, (OFString* []){@"oda", nil}, 0, 0, NULL, nil, @"application/oda"},
	{1, (OFString* []){@"opf", nil}, 0, 0, NULL, nil, @"application/oebps-package+xml"},
	{2, (OFString* []){@"ogx", @"ogg", nil}, 0, 0, NULL, nil, @"application/ogg"},
	{1, (OFString* []){@"axs", nil}, 0, 0, NULL, nil, @"application/olescript"},
	{1, (OFString* []){@"omdoc", nil}, 0, 0, NULL, nil, @"application/omdoc+xml"},
	{4, (OFString* []){@"onetoc", @"onetoc2", @"onetmp", @"onepkg", nil}, 0, 0, NULL, nil, @"application/onenote"},
	{1, (OFString* []){@"oxps", nil}, 0, 0, NULL, nil, @"application/oxps"},
	{1, (OFString* []){@"xer", nil}, 0, 0, NULL, nil, @"application/patch-ops-error+xml"},
	{1, (OFString* []){@"pdf", nil}, 0, 0, NULL, nil, @"application/pdf"},
	{1, (OFString* []){@"pgp", nil}, 0, 0, NULL, nil, @"application/pgp-encrypted"},
	{1, (OFString* []){@"key", nil}, 0, 0, NULL, nil, @"application/pgp-keys"},
	{3, (OFString* []){@"asc", @"pgp", @"sig", nil}, 0, 0, NULL, nil, @"application/pgp-signature"},
	{1, (OFString* []){@"prf", nil}, 0, 0, NULL, nil, @"application/pics-rules"},
	{1, (OFString* []){@"p12", nil}, 0, 0, NULL, nil, @"application/pkcs-12"},
	{1, (OFString* []){@"crl", nil}, 0, 0, NULL, nil, @"application/pkcs-crl"},
	{1, (OFString* []){@"p10", nil}, 0, 0, NULL, nil, @"application/pkcs10"},
	{2, (OFString* []){@"p7m", @"p7c", nil}, 0, 0, NULL, nil, @"application/pkcs7-mime"},
	{1, (OFString* []){@"p7s", nil}, 0, 0, NULL, nil, @"application/pkcs7-signature"},
	{1, (OFString* []){@"p8", nil}, 0, 0, NULL, nil, @"application/pkcs8"},
	{1, (OFString* []){@"ac", nil}, 0, 0, NULL, nil, @"application/pkix-attr-cert"},
	{2, (OFString* []){@"cer", @"crt", nil}, 0, 0, NULL, nil, @"application/pkix-cert"},
	{1, (OFString* []){@"crl", nil}, 0, 0, NULL, nil, @"application/pkix-crl"},
	{1, (OFString* []){@"pkipath", nil}, 0, 0, NULL, nil, @"application/pkix-pkipath"},
	{1, (OFString* []){@"pki", nil}, 0, 0, NULL, nil, @"application/pkixcmp"},
	{1, (OFString* []){@"text", nil}, 0, 0, NULL, nil, @"application/plain"},
	{1, (OFString* []){@"pls", nil}, 0, 0, NULL, nil, @"application/pls+xml"},
	{3, (OFString* []){@"ai", @"eps", @"ps", nil}, 0, 0, NULL, nil, @"application/postscript"},
	{1, (OFString* []){@"ppt", nil}, 0, 0, NULL, nil, @"application/powerpoint"},
	{2, (OFString* []){@"part", @"prt", nil}, 0, 0, NULL, nil, @"application/pro_eng"},
	{1, (OFString* []){@"cww", nil}, 0, 0, NULL, nil, @"application/prs.cww"},
	{1, (OFString* []){@"pskcxml", nil}, 0, 0, NULL, nil, @"application/pskc+xml"},
	{1, (OFString* []){@"rar", nil}, 0, 0, NULL, nil, @"application/rar"},
	{1, (OFString* []){@"rdf", nil}, 0, 0, NULL, nil, @"application/rdf+xml"},
	{1, (OFString* []){@"rif", nil}, 0, 0, NULL, nil, @"application/reginfo+xml"},
	{1, (OFString* []){@"rnc", nil}, 0, 0, NULL, nil, @"application/relax-ng-compact-syntax"},
	{1, (OFString* []){@"rl", nil}, 0, 0, NULL, nil, @"application/resource-lists+xml"},
	{1, (OFString* []){@"rld", nil}, 0, 0, NULL, nil, @"application/resource-lists-diff+xml"},
	{1, (OFString* []){@"rng", nil}, 0, 0, NULL, nil, @"application/ringing-tones"},
	{1, (OFString* []){@"rs", nil}, 0, 0, NULL, nil, @"application/rls-services+xml"},
	{1, (OFString* []){@"gbr", nil}, 0, 0, NULL, nil, @"application/rpki-ghostbusters"},
	{1, (OFString* []){@"mft", nil}, 0, 0, NULL, nil, @"application/rpki-manifest"},
	{1, (OFString* []){@"roa", nil}, 0, 0, NULL, nil, @"application/rpki-roa"},
	{1, (OFString* []){@"rsd", nil}, 0, 0, NULL, nil, @"application/rsd+xml"},
	{2, (OFString* []){@"rss", @"xml", nil}, 0, 0, NULL, nil, @"application/rss+xml"},
	{2, (OFString* []){@"rtf", @"rtx", nil}, 0, 0, NULL, nil, @"application/rtf"},
	{1, (OFString* []){@"sbml", nil}, 0, 0, NULL, nil, @"application/sbml+xml"},
	{1, (OFString* []){@"scq", nil}, 0, 0, NULL, nil, @"application/scvp-cv-request"},
	{1, (OFString* []){@"scs", nil}, 0, 0, NULL, nil, @"application/scvp-cv-response"},
	{1, (OFString* []){@"spq", nil}, 0, 0, NULL, nil, @"application/scvp-vp-request"},
	{1, (OFString* []){@"spp", nil}, 0, 0, NULL, nil, @"application/scvp-vp-response"},
	{1, (OFString* []){@"sdp", nil}, 0, 0, NULL, nil, @"application/sdp"},
	{1, (OFString* []){@"sea", nil}, 0, 0, NULL, nil, @"application/sea"},
	{1, (OFString* []){@"set", nil}, 0, 0, NULL, nil, @"application/set"},
	{1, (OFString* []){@"setpay", nil}, 0, 0, NULL, nil, @"application/set-payment-initiation"},
	{1, (OFString* []){@"setreg", nil}, 0, 0, NULL, nil, @"application/set-registration-initiation"},
	{1, (OFString* []){@"shf", nil}, 0, 0, NULL, nil, @"application/shf+xml"},
	{1, (OFString* []){@"stl", nil}, 0, 0, NULL, nil, @"application/sla"},
	{2, (OFString* []){@"smi", @"smil", nil}, 0, 0, NULL, nil, @"application/smil"},
	{2, (OFString* []){@"smi", @"smil", nil}, 0, 0, NULL, nil, @"application/smil+xml"},
	{1, (OFString* []){@"sol", nil}, 0, 0, NULL, nil, @"application/solids"},
	{1, (OFString* []){@"sdr", nil}, 0, 0, NULL, nil, @"application/sounder"},
	{1, (OFString* []){@"rq", nil}, 0, 0, NULL, nil, @"application/sparql-query"},
	{1, (OFString* []){@"srx", nil}, 0, 0, NULL, nil, @"application/sparql-results+xml"},
	{1, (OFString* []){@"gram", nil}, 0, 0, NULL, nil, @"application/srgs"},
	{1, (OFString* []){@"grxml", nil}, 0, 0, NULL, nil, @"application/srgs+xml"},
	{1, (OFString* []){@"sru", nil}, 0, 0, NULL, nil, @"application/sru+xml"},
	{1, (OFString* []){@"ssdl", nil}, 0, 0, NULL, nil, @"application/ssdl+xml"},
	{1, (OFString* []){@"ssml", nil}, 0, 0, NULL, nil, @"application/ssml+xml"},
	{2, (OFString* []){@"step", @"stp", nil}, 0, 0, NULL, nil, @"application/step"},
	{1, (OFString* []){@"ssm", nil}, 0, 0, NULL, nil, @"application/streamingmedia"},
	{2, (OFString* []){@"tei", @"teicorpus", nil}, 0, 0, NULL, nil, @"application/tei+xml"},
	{1, (OFString* []){@"tfi", nil}, 0, 0, NULL, nil, @"application/thraud+xml"},
	{1, (OFString* []){@"tsd", nil}, 0, 0, NULL, nil, @"application/timestamped-data"},
	{1, (OFString* []){@"tbk", nil}, 0, 0, NULL, nil, @"application/toolbook"},
	{1, (OFString* []){@"vda", nil}, 0, 0, NULL, nil, @"application/vda"},
	{1, (OFString* []){@"plb", nil}, 0, 0, NULL, nil, @"application/vnd.3gpp.pic-bw-large"},
	{1, (OFString* []){@"psb", nil}, 0, 0, NULL, nil, @"application/vnd.3gpp.pic-bw-small"},
	{1, (OFString* []){@"pvb", nil}, 0, 0, NULL, nil, @"application/vnd.3gpp.pic-bw-var"},
	{1, (OFString* []){@"tcap", nil}, 0, 0, NULL, nil, @"application/vnd.3gpp2.tcap"},
	{1, (OFString* []){@"pwn", nil}, 0, 0, NULL, nil, @"application/vnd.3m.post-it-notes"},
	{1, (OFString* []){@"aso", nil}, 0, 0, NULL, nil, @"application/vnd.accpac.simply.aso"},
	{1, (OFString* []){@"imp", nil}, 0, 0, NULL, nil, @"application/vnd.accpac.simply.imp"},
	{1, (OFString* []){@"acu", nil}, 0, 0, NULL, nil, @"application/vnd.acucobol"},
	{2, (OFString* []){@"atc", @"acutc", nil}, 0, 0, NULL, nil, @"application/vnd.acucorp"},
	{1, (OFString* []){@"air", nil}, 0, 0, NULL, nil, @"application/vnd.adobe.air-application-installer-package+zip"},
	{1, (OFString* []){@"fcdt", nil}, 0, 0, NULL, nil, @"application/vnd.adobe.formscentral.fcdt"},
	{2, (OFString* []){@"fxp", @"fxpl", nil}, 0, 0, NULL, nil, @"application/vnd.adobe.fxp"},
	{1, (OFString* []){@"xdp", nil}, 0, 0, NULL, nil, @"application/vnd.adobe.xdp+xml"},
	{1, (OFString* []){@"xfdf", nil}, 0, 0, NULL, nil, @"application/vnd.adobe.xfdf"},
	{1, (OFString* []){@"ahead", nil}, 0, 0, NULL, nil, @"application/vnd.ahead.space"},
	{1, (OFString* []){@"azf", nil}, 0, 0, NULL, nil, @"application/vnd.airzip.filesecure.azf"},
	{1, (OFString* []){@"azs", nil}, 0, 0, NULL, nil, @"application/vnd.airzip.filesecure.azs"},
	{1, (OFString* []){@"azw", nil}, 0, 0, NULL, nil, @"application/vnd.amazon.ebook"},
	{1, (OFString* []){@"acc", nil}, 0, 0, NULL, nil, @"application/vnd.americandynamics.acc"},
	{1, (OFString* []){@"ami", nil}, 0, 0, NULL, nil, @"application/vnd.amiga.ami"},
	{1, (OFString* []){@"apk", nil}, 0, 0, NULL, nil, @"application/vnd.android.package-archive"},
	{1, (OFString* []){@"cii", nil}, 0, 0, NULL, nil, @"application/vnd.anser-web-certificate-issue-initiation"},
	{1, (OFString* []){@"fti", nil}, 0, 0, NULL, nil, @"application/vnd.anser-web-funds-transfer-initiation"},
	{1, (OFString* []){@"atx", nil}, 0, 0, NULL, nil, @"application/vnd.antix.game-component"},
	{1, (OFString* []){@"mpkg", nil}, 0, 0, NULL, nil, @"application/vnd.apple.installer+xml"},
	{1, (OFString* []){@"m3u8", nil}, 0, 0, NULL, nil, @"application/vnd.apple.mpegurl"},
	{1, (OFString* []){@"swi", nil}, 0, 0, NULL, nil, @"application/vnd.arastra.swi"},
	{1, (OFString* []){@"swi", nil}, 0, 0, NULL, nil, @"application/vnd.aristanetworks.swi"},
	{1, (OFString* []){@"iota", nil}, 0, 0, NULL, nil, @"application/vnd.astraea-software.iota"},
	{1, (OFString* []){@"aep", nil}, 0, 0, NULL, nil, @"application/vnd.audiograph"},
	{1, (OFString* []){@"mpm", nil}, 0, 0, NULL, nil, @"application/vnd.blueice.multipass"},
	{1, (OFString* []){@"bmi", nil}, 0, 0, NULL, nil, @"application/vnd.bmi"},
	{1, (OFString* []){@"rep", nil}, 0, 0, NULL, nil, @"application/vnd.businessobjects"},
	{1, (OFString* []){@"cdxml", nil}, 0, 0, NULL, nil, @"application/vnd.chemdraw+xml"},
	{1, (OFString* []){@"mmd", nil}, 0, 0, NULL, nil, @"application/vnd.chipnuts.karaoke-mmd"},
	{1, (OFString* []){@"cdy", nil}, 0, 0, NULL, nil, @"application/vnd.cinderella"},
	{1, (OFString* []){@"cla", nil}, 0, 0, NULL, nil, @"application/vnd.claymore"},
	{1, (OFString* []){@"rp9", nil}, 0, 0, NULL, nil, @"application/vnd.cloanto.rp9"},
	{5, (OFString* []){@"c4g", @"c4d", @"c4f", @"c4p", @"c4u", nil}, 0, 0, NULL, nil, @"application/vnd.clonk.c4group"},
	{1, (OFString* []){@"c11amc", nil}, 0, 0, NULL, nil, @"application/vnd.cluetrust.cartomobile-config"},
	{1, (OFString* []){@"c11amz", nil}, 0, 0, NULL, nil, @"application/vnd.cluetrust.cartomobile-config-pkg"},
	{1, (OFString* []){@"csp", nil}, 0, 0, NULL, nil, @"application/vnd.commonspace"},
	{1, (OFString* []){@"cdbcmsg", nil}, 0, 0, NULL, nil, @"application/vnd.contact.cmsg"},
	{1, (OFString* []){@"cmc", nil}, 0, 0, NULL, nil, @"application/vnd.cosmocaller"},
	{1, (OFString* []){@"clkx", nil}, 0, 0, NULL, nil, @"application/vnd.crick.clicker"},
	{1, (OFString* []){@"clkk", nil}, 0, 0, NULL, nil, @"application/vnd.crick.clicker.keyboard"},
	{1, (OFString* []){@"clkp", nil}, 0, 0, NULL, nil, @"application/vnd.crick.clicker.palette"},
	{1, (OFString* []){@"clkt", nil}, 0, 0, NULL, nil, @"application/vnd.crick.clicker.template"},
	{1, (OFString* []){@"clkw", nil}, 0, 0, NULL, nil, @"application/vnd.crick.clicker.wordbank"},
	{1, (OFString* []){@"wbs", nil}, 0, 0, NULL, nil, @"application/vnd.criticaltools.wbs+xml"},
	{1, (OFString* []){@"pml", nil}, 0, 0, NULL, nil, @"application/vnd.ctc-posml"},
	{1, (OFString* []){@"ppd", nil}, 0, 0, NULL, nil, @"application/vnd.cups-ppd"},
	{1, (OFString* []){@"car", nil}, 0, 0, NULL, nil, @"application/vnd.curl.car"},
	{1, (OFString* []){@"pcurl", nil}, 0, 0, NULL, nil, @"application/vnd.curl.pcurl"},
	{1, (OFString* []){@"dart", nil}, 0, 0, NULL, nil, @"application/vnd.dart"},
	{1, (OFString* []){@"rdz", nil}, 0, 0, NULL, nil, @"application/vnd.data-vision.rdz"},
	{4, (OFString* []){@"uvf", @"uvvf", @"uvd", @"uvvd", nil}, 0, 0, NULL, nil, @"application/vnd.dece.data"},
	{2, (OFString* []){@"uvt", @"uvvt", nil}, 0, 0, NULL, nil, @"application/vnd.dece.ttml+xml"},
	{2, (OFString* []){@"uvx", @"uvvx", nil}, 0, 0, NULL, nil, @"application/vnd.dece.unspecified"},
	{2, (OFString* []){@"uvz", @"uvvz", nil}, 0, 0, NULL, nil, @"application/vnd.dece.zip"},
	{1, (OFString* []){@"fe_launch", nil}, 0, 0, NULL, nil, @"application/vnd.denovo.fcselayout-link"},
	{1, (OFString* []){@"dna", nil}, 0, 0, NULL, nil, @"application/vnd.dna"},
	{1, (OFString* []){@"mlp", nil}, 0, 0, NULL, nil, @"application/vnd.dolby.mlp"},
	{1, (OFString* []){@"dpg", nil}, 0, 0, NULL, nil, @"application/vnd.dpgraph"},
	{1, (OFString* []){@"dfac", nil}, 0, 0, NULL, nil, @"application/vnd.dreamfactory"},
	{1, (OFString* []){@"kpxx", nil}, 0, 0, NULL, nil, @"application/vnd.ds-keypoint"},
	{1, (OFString* []){@"ait", nil}, 0, 0, NULL, nil, @"application/vnd.dvb.ait"},
	{1, (OFString* []){@"svc", nil}, 0, 0, NULL, nil, @"application/vnd.dvb.service"},
	{1, (OFString* []){@"geo", nil}, 0, 0, NULL, nil, @"application/vnd.dynageo"},
	{1, (OFString* []){@"mag", nil}, 0, 0, NULL, nil, @"application/vnd.ecowin.chart"},
	{1, (OFString* []){@"nml", nil}, 0, 0, NULL, nil, @"application/vnd.enliven"},
	{1, (OFString* []){@"esf", nil}, 0, 0, NULL, nil, @"application/vnd.epson.esf"},
	{1, (OFString* []){@"msf", nil}, 0, 0, NULL, nil, @"application/vnd.epson.msf"},
	{1, (OFString* []){@"qam", nil}, 0, 0, NULL, nil, @"application/vnd.epson.quickanime"},
	{1, (OFString* []){@"slt", nil}, 0, 0, NULL, nil, @"application/vnd.epson.salt"},
	{1, (OFString* []){@"ssf", nil}, 0, 0, NULL, nil, @"application/vnd.epson.ssf"},
	{2, (OFString* []){@"es3", @"et3", nil}, 0, 0, NULL, nil, @"application/vnd.eszigno3+xml"},
	{1, (OFString* []){@"ez2", nil}, 0, 0, NULL, nil, @"application/vnd.ezpix-album"},
	{1, (OFString* []){@"ez3", nil}, 0, 0, NULL, nil, @"application/vnd.ezpix-package"},
	{1, (OFString* []){@"fdf", nil}, 0, 0, NULL, nil, @"application/vnd.fdf"},
	{1, (OFString* []){@"mseed", nil}, 0, 0, NULL, nil, @"application/vnd.fdsn.mseed"},
	{2, (OFString* []){@"seed", @"dataless", nil}, 0, 0, NULL, nil, @"application/vnd.fdsn.seed"},
	{1, (OFString* []){@"gph", nil}, 0, 0, NULL, nil, @"application/vnd.flographit"},
	{1, (OFString* []){@"ftc", nil}, 0, 0, NULL, nil, @"application/vnd.fluxtime.clip"},
	{4, (OFString* []){@"fm", @"frame", @"maker", @"book", nil}, 0, 0, NULL, nil, @"application/vnd.framemaker"},
	{1, (OFString* []){@"fnc", nil}, 0, 0, NULL, nil, @"application/vnd.frogans.fnc"},
	{1, (OFString* []){@"ltf", nil}, 0, 0, NULL, nil, @"application/vnd.frogans.ltf"},
	{1, (OFString* []){@"fsc", nil}, 0, 0, NULL, nil, @"application/vnd.fsc.weblaunch"},
	{1, (OFString* []){@"oas", nil}, 0, 0, NULL, nil, @"application/vnd.fujitsu.oasys"},
	{1, (OFString* []){@"oa2", nil}, 0, 0, NULL, nil, @"application/vnd.fujitsu.oasys2"},
	{1, (OFString* []){@"oa3", nil}, 0, 0, NULL, nil, @"application/vnd.fujitsu.oasys3"},
	{1, (OFString* []){@"fg5", nil}, 0, 0, NULL, nil, @"application/vnd.fujitsu.oasysgp"},
	{1, (OFString* []){@"bh2", nil}, 0, 0, NULL, nil, @"application/vnd.fujitsu.oasysprs"},
	{1, (OFString* []){@"ddd", nil}, 0, 0, NULL, nil, @"application/vnd.fujixerox.ddd"},
	{1, (OFString* []){@"xdw", nil}, 0, 0, NULL, nil, @"application/vnd.fujixerox.docuworks"},
	{1, (OFString* []){@"xbd", nil}, 0, 0, NULL, nil, @"application/vnd.fujixerox.docuworks.binder"},
	{1, (OFString* []){@"fzs", nil}, 0, 0, NULL, nil, @"application/vnd.fuzzysheet"},
	{1, (OFString* []){@"txd", nil}, 0, 0, NULL, nil, @"application/vnd.genomatix.tuxedo"},
	{1, (OFString* []){@"ggb", nil}, 0, 0, NULL, nil, @"application/vnd.geogebra.file"},
	{1, (OFString* []){@"ggt", nil}, 0, 0, NULL, nil, @"application/vnd.geogebra.tool"},
	{2, (OFString* []){@"gex", @"gre", nil}, 0, 0, NULL, nil, @"application/vnd.geometry-explorer"},
	{1, (OFString* []){@"gxt", nil}, 0, 0, NULL, nil, @"application/vnd.geonext"},
	{1, (OFString* []){@"g2w", nil}, 0, 0, NULL, nil, @"application/vnd.geoplan"},
	{1, (OFString* []){@"g3w", nil}, 0, 0, NULL, nil, @"application/vnd.geospace"},
	{1, (OFString* []){@"gmx", nil}, 0, 0, NULL, nil, @"application/vnd.gmx"},
	{1, (OFString* []){@"kml", nil}, 0, 0, NULL, nil, @"application/vnd.google-earth.kml+xml"},
	{1, (OFString* []){@"kmz", nil}, 0, 0, NULL, nil, @"application/vnd.google-earth.kmz"},
	{2, (OFString* []){@"gqf", @"gqs", nil}, 0, 0, NULL, nil, @"application/vnd.grafeq"},
	{1, (OFString* []){@"gac", nil}, 0, 0, NULL, nil, @"application/vnd.groove-account"},
	{1, (OFString* []){@"ghf", nil}, 0, 0, NULL, nil, @"application/vnd.groove-help"},
	{1, (OFString* []){@"gim", nil}, 0, 0, NULL, nil, @"application/vnd.groove-identity-message"},
	{1, (OFString* []){@"grv", nil}, 0, 0, NULL, nil, @"application/vnd.groove-injector"},
	{1, (OFString* []){@"gtm", nil}, 0, 0, NULL, nil, @"application/vnd.groove-tool-message"},
	{1, (OFString* []){@"tpl", nil}, 0, 0, NULL, nil, @"application/vnd.groove-tool-template"},
	{1, (OFString* []){@"vcg", nil}, 0, 0, NULL, nil, @"application/vnd.groove-vcard"},
	{1, (OFString* []){@"hal", nil}, 0, 0, NULL, nil, @"application/vnd.hal+xml"},
	{1, (OFString* []){@"zmm", nil}, 0, 0, NULL, nil, @"application/vnd.handheld-entertainment+xml"},
	{1, (OFString* []){@"hbci", nil}, 0, 0, NULL, nil, @"application/vnd.hbci"},
	{1, (OFString* []){@"les", nil}, 0, 0, NULL, nil, @"application/vnd.hhe.lesson-player"},
	{3, (OFString* []){@"hgl", @"hpg", @"hpgl", nil}, 0, 0, NULL, nil, @"application/vnd.hp-hpgl"},
	{1, (OFString* []){@"hpid", nil}, 0, 0, NULL, nil, @"application/vnd.hp-hpid"},
	{1, (OFString* []){@"hps", nil}, 0, 0, NULL, nil, @"application/vnd.hp-hps"},
	{1, (OFString* []){@"jlt", nil}, 0, 0, NULL, nil, @"application/vnd.hp-jlyt"},
	{1, (OFString* []){@"pcl", nil}, 0, 0, NULL, nil, @"application/vnd.hp-pcl"},
	{1, (OFString* []){@"pclxl", nil}, 0, 0, NULL, nil, @"application/vnd.hp-pclxl"},
	{1, (OFString* []){@"sfd-hdstx", nil}, 0, 0, NULL, nil, @"application/vnd.hydrostatix.sof-data"},
	{1, (OFString* []){@"x3d", nil}, 0, 0, NULL, nil, @"application/vnd.hzn-3d-crossword"},
	{1, (OFString* []){@"mpy", nil}, 0, 0, NULL, nil, @"application/vnd.ibm.minipay"},
	{3, (OFString* []){@"afp", @"listafp", @"list3820", nil}, 0, 0, NULL, nil, @"application/vnd.ibm.modcap"},
	{1, (OFString* []){@"irm", nil}, 0, 0, NULL, nil, @"application/vnd.ibm.rights-management"},
	{1, (OFString* []){@"sc", nil}, 0, 0, NULL, nil, @"application/vnd.ibm.secure-container"},
	{2, (OFString* []){@"icc", @"icm", nil}, 0, 0, NULL, nil, @"application/vnd.iccprofile"},
	{1, (OFString* []){@"igl", nil}, 0, 0, NULL, nil, @"application/vnd.igloader"},
	{1, (OFString* []){@"ivp", nil}, 0, 0, NULL, nil, @"application/vnd.immervision-ivp"},
	{1, (OFString* []){@"ivu", nil}, 0, 0, NULL, nil, @"application/vnd.immervision-ivu"},
	{1, (OFString* []){@"igm", nil}, 0, 0, NULL, nil, @"application/vnd.insors.igm"},
	{2, (OFString* []){@"xpw", @"xpx", nil}, 0, 0, NULL, nil, @"application/vnd.intercon.formnet"},
	{1, (OFString* []){@"i2g", nil}, 0, 0, NULL, nil, @"application/vnd.intergeo"},
	{1, (OFString* []){@"qbo", nil}, 0, 0, NULL, nil, @"application/vnd.intu.qbo"},
	{1, (OFString* []){@"qfx", nil}, 0, 0, NULL, nil, @"application/vnd.intu.qfx"},
	{1, (OFString* []){@"rcprofile", nil}, 0, 0, NULL, nil, @"application/vnd.ipunplugged.rcprofile"},
	{1, (OFString* []){@"irp", nil}, 0, 0, NULL, nil, @"application/vnd.irepository.package+xml"},
	{1, (OFString* []){@"xpr", nil}, 0, 0, NULL, nil, @"application/vnd.is-xpr"},
	{1, (OFString* []){@"fcs", nil}, 0, 0, NULL, nil, @"application/vnd.isac.fcs"},
	{1, (OFString* []){@"jam", nil}, 0, 0, NULL, nil, @"application/vnd.jam"},
	{1, (OFString* []){@"rms", nil}, 0, 0, NULL, nil, @"application/vnd.jcp.javame.midlet-rms"},
	{1, (OFString* []){@"jisp", nil}, 0, 0, NULL, nil, @"application/vnd.jisp"},
	{1, (OFString* []){@"joda", nil}, 0, 0, NULL, nil, @"application/vnd.joost.joda-archive"},
	{2, (OFString* []){@"ktz", @"ktr", nil}, 0, 0, NULL, nil, @"application/vnd.kahootz"},
	{1, (OFString* []){@"karbon", nil}, 0, 0, NULL, nil, @"application/vnd.kde.karbon"},
	{1, (OFString* []){@"chrt", nil}, 0, 0, NULL, nil, @"application/vnd.kde.kchart"},
	{1, (OFString* []){@"kfo", nil}, 0, 0, NULL, nil, @"application/vnd.kde.kformula"},
	{1, (OFString* []){@"flw", nil}, 0, 0, NULL, nil, @"application/vnd.kde.kivio"},
	{1, (OFString* []){@"kon", nil}, 0, 0, NULL, nil, @"application/vnd.kde.kontour"},
	{2, (OFString* []){@"kpr", @"kpt", nil}, 0, 0, NULL, nil, @"application/vnd.kde.kpresenter"},
	{1, (OFString* []){@"ksp", nil}, 0, 0, NULL, nil, @"application/vnd.kde.kspread"},
	{2, (OFString* []){@"kwd", @"kwt", nil}, 0, 0, NULL, nil, @"application/vnd.kde.kword"},
	{1, (OFString* []){@"htke", nil}, 0, 0, NULL, nil, @"application/vnd.kenameaapp"},
	{1, (OFString* []){@"kia", nil}, 0, 0, NULL, nil, @"application/vnd.kidspiration"},
	{2, (OFString* []){@"kne", @"knp", nil}, 0, 0, NULL, nil, @"application/vnd.kinar"},
	{4, (OFString* []){@"skp", @"skd", @"skt", @"skm", nil}, 0, 0, NULL, nil, @"application/vnd.koan"},
	{1, (OFString* []){@"sse", nil}, 0, 0, NULL, nil, @"application/vnd.kodak-descriptor"},
	{1, (OFString* []){@"lasxml", nil}, 0, 0, NULL, nil, @"application/vnd.las.las+xml"},
	{1, (OFString* []){@"lbd", nil}, 0, 0, NULL, nil, @"application/vnd.llamagraphics.life-balance.desktop"},
	{1, (OFString* []){@"lbe", nil}, 0, 0, NULL, nil, @"application/vnd.llamagraphics.life-balance.exchange+xml"},
	{1, (OFString* []){@"apr", nil}, 0, 0, NULL, nil, @"application/vnd.lotus-approach"},
	{1, (OFString* []){@"pre", nil}, 0, 0, NULL, nil, @"application/vnd.lotus-freelance"},
	{1, (OFString* []){@"nsf", nil}, 0, 0, NULL, nil, @"application/vnd.lotus-notes"},
	{1, (OFString* []){@"org", nil}, 0, 0, NULL, nil, @"application/vnd.lotus-organizer"},
	{1, (OFString* []){@"scm", nil}, 0, 0, NULL, nil, @"application/vnd.lotus-screencam"},
	{1, (OFString* []){@"lwp", nil}, 0, 0, NULL, nil, @"application/vnd.lotus-wordpro"},
	{1, (OFString* []){@"portpkg", nil}, 0, 0, NULL, nil, @"application/vnd.macports.portpkg"},
	{1, (OFString* []){@"mcd", nil}, 0, 0, NULL, nil, @"application/vnd.mcd"},
	{1, (OFString* []){@"mc1", nil}, 0, 0, NULL, nil, @"application/vnd.medcalcdata"},
	{1, (OFString* []){@"cdkey", nil}, 0, 0, NULL, nil, @"application/vnd.mediastation.cdkey"},
	{1, (OFString* []){@"mwf", nil}, 0, 0, NULL, nil, @"application/vnd.mfer"},
	{1, (OFString* []){@"mfm", nil}, 0, 0, NULL, nil, @"application/vnd.mfmp"},
	{1, (OFString* []){@"flo", nil}, 0, 0, NULL, nil, @"application/vnd.micrografx.flo"},
	{1, (OFString* []){@"igx", nil}, 0, 0, NULL, nil, @"application/vnd.micrografx.igx"},
	{1, (OFString* []){@"mif", nil}, 0, 0, NULL, nil, @"application/vnd.mif"},
	{1, (OFString* []){@"daf", nil}, 0, 0, NULL, nil, @"application/vnd.mobius.daf"},
	{1, (OFString* []){@"dis", nil}, 0, 0, NULL, nil, @"application/vnd.mobius.dis"},
	{1, (OFString* []){@"mbk", nil}, 0, 0, NULL, nil, @"application/vnd.mobius.mbk"},
	{1, (OFString* []){@"mqy", nil}, 0, 0, NULL, nil, @"application/vnd.mobius.mqy"},
	{1, (OFString* []){@"msl", nil}, 0, 0, NULL, nil, @"application/vnd.mobius.msl"},
	{1, (OFString* []){@"plc", nil}, 0, 0, NULL, nil, @"application/vnd.mobius.plc"},
	{1, (OFString* []){@"txf", nil}, 0, 0, NULL, nil, @"application/vnd.mobius.txf"},
	{1, (OFString* []){@"mpn", nil}, 0, 0, NULL, nil, @"application/vnd.mophun.application"},
	{1, (OFString* []){@"mpc", nil}, 0, 0, NULL, nil, @"application/vnd.mophun.certificate"},
	{1, (OFString* []){@"xul", nil}, 0, 0, NULL, nil, @"application/vnd.mozilla.xul+xml"},
	{1, (OFString* []){@"cil", nil}, 0, 0, NULL, nil, @"application/vnd.ms-artgalry"},
	{1, (OFString* []){@"cab", nil}, 0, 0, NULL, nil, @"application/vnd.ms-cab-compressed"},
	{8, (OFString* []){@"xls", @"xlm", @"xla", @"xlc", @"xlt", @"xlb", @"xll", @"xlw", nil}, 0, 0, NULL, nil, @"application/vnd.ms-excel"},
	{1, (OFString* []){@"xlam", nil}, 0, 0, NULL, nil, @"application/vnd.ms-excel.addin.macroEnabled.12"},
	{1, (OFString* []){@"xlam", nil}, 0, 0, NULL, nil, @"application/vnd.ms-excel.addin.macroenabled.12"},
	{1, (OFString* []){@"xlsb", nil}, 0, 0, NULL, nil, @"application/vnd.ms-excel.sheet.binary.macroEnabled.12"},
	{1, (OFString* []){@"xlsb", nil}, 0, 0, NULL, nil, @"application/vnd.ms-excel.sheet.binary.macroenabled.12"},
	{1, (OFString* []){@"xlsm", nil}, 0, 0, NULL, nil, @"application/vnd.ms-excel.sheet.macroEnabled.12"},
	{1, (OFString* []){@"xlsm", nil}, 0, 0, NULL, nil, @"application/vnd.ms-excel.sheet.macroenabled.12"},
	{1, (OFString* []){@"xltm", nil}, 0, 0, NULL, nil, @"application/vnd.ms-excel.template.macroEnabled.12"},
	{1, (OFString* []){@"xltm", nil}, 0, 0, NULL, nil, @"application/vnd.ms-excel.template.macroenabled.12"},
	{1, (OFString* []){@"eot", nil}, 0, 0, NULL, nil, @"application/vnd.ms-fontobject"},
	{1, (OFString* []){@"chm", nil}, 0, 0, NULL, nil, @"application/vnd.ms-htmlhelp"},
	{1, (OFString* []){@"ims", nil}, 0, 0, NULL, nil, @"application/vnd.ms-ims"},
	{1, (OFString* []){@"lrm", nil}, 0, 0, NULL, nil, @"application/vnd.ms-lrm"},
	{1, (OFString* []){@"thmx", nil}, 0, 0, NULL, nil, @"application/vnd.ms-officetheme"},
	{1, (OFString* []){@"msg", nil}, 0, 0, NULL, nil, @"application/vnd.ms-outlook"},
	{1, (OFString* []){@"sst", nil}, 0, 0, NULL, nil, @"application/vnd.ms-pki.certstore"},
	{1, (OFString* []){@"pko", nil}, 0, 0, NULL, nil, @"application/vnd.ms-pki.pko"},
	{1, (OFString* []){@"cat", nil}, 0, 0, NULL, nil, @"application/vnd.ms-pki.seccat"},
	{1, (OFString* []){@"stl", nil}, 0, 0, NULL, nil, @"application/vnd.ms-pki.stl"},
	{1, (OFString* []){@"sst", nil}, 0, 0, NULL, nil, @"application/vnd.ms-pkicertstore"},
	{1, (OFString* []){@"cat", nil}, 0, 0, NULL, nil, @"application/vnd.ms-pkiseccat"},
	{1, (OFString* []){@"stl", nil}, 0, 0, NULL, nil, @"application/vnd.ms-pkistl"},
	{5, (OFString* []){@"ppt", @"pps", @"pot", @"ppa", @"pwz", nil}, 0, 0, NULL, nil, @"application/vnd.ms-powerpoint"},
	{1, (OFString* []){@"ppam", nil}, 0, 0, NULL, nil, @"application/vnd.ms-powerpoint.addin.macroEnabled.12"},
	{1, (OFString* []){@"ppam", nil}, 0, 0, NULL, nil, @"application/vnd.ms-powerpoint.addin.macroenabled.12"},
	{2, (OFString* []){@"pptm", @"potm", nil}, 0, 0, NULL, nil, @"application/vnd.ms-powerpoint.presentation.macroEnabled.12"},
	{2, (OFString* []){@"pptm", @"potm", nil}, 0, 0, NULL, nil, @"application/vnd.ms-powerpoint.presentation.macroenabled.12"},
	{1, (OFString* []){@"sldm", nil}, 0, 0, NULL, nil, @"application/vnd.ms-powerpoint.slide.macroEnabled.12"},
	{1, (OFString* []){@"sldm", nil}, 0, 0, NULL, nil, @"application/vnd.ms-powerpoint.slide.macroenabled.12"},
	{1, (OFString* []){@"ppsm", nil}, 0, 0, NULL, nil, @"application/vnd.ms-powerpoint.slideshow.macroEnabled.12"},
	{1, (OFString* []){@"ppsm", nil}, 0, 0, NULL, nil, @"application/vnd.ms-powerpoint.slideshow.macroenabled.12"},
	{1, (OFString* []){@"potm", nil}, 0, 0, NULL, nil, @"application/vnd.ms-powerpoint.template.macroEnabled.12"},
	{1, (OFString* []){@"potm", nil}, 0, 0, NULL, nil, @"application/vnd.ms-powerpoint.template.macroenabled.12"},
	{2, (OFString* []){@"mpp", @"mpt", nil}, 0, 0, NULL, nil, @"application/vnd.ms-project"},
	{1, (OFString* []){@"docm", nil}, 0, 0, NULL, nil, @"application/vnd.ms-word.document.macroEnabled.12"},
	{1, (OFString* []){@"docm", nil}, 0, 0, NULL, nil, @"application/vnd.ms-word.document.macroenabled.12"},
	{1, (OFString* []){@"dotm", nil}, 0, 0, NULL, nil, @"application/vnd.ms-word.template.macroEnabled.12"},
	{1, (OFString* []){@"dotm", nil}, 0, 0, NULL, nil, @"application/vnd.ms-word.template.macroenabled.12"},
	{4, (OFString* []){@"wps", @"wks", @"wcm", @"wdb", nil}, 0, 0, NULL, nil, @"application/vnd.ms-works"},
	{1, (OFString* []){@"wpl", nil}, 0, 0, NULL, nil, @"application/vnd.ms-wpl"},
	{1, (OFString* []){@"xps", nil}, 0, 0, NULL, nil, @"application/vnd.ms-xpsdocument"},
	{1, (OFString* []){@"mseq", nil}, 0, 0, NULL, nil, @"application/vnd.mseq"},
	{1, (OFString* []){@"mus", nil}, 0, 0, NULL, nil, @"application/vnd.musician"},
	{1, (OFString* []){@"msty", nil}, 0, 0, NULL, nil, @"application/vnd.muvee.style"},
	{1, (OFString* []){@"taglet", nil}, 0, 0, NULL, nil, @"application/vnd.mynfc"},
	{1, (OFString* []){@"nlu", nil}, 0, 0, NULL, nil, @"application/vnd.neurolanguage.nlu"},
	{2, (OFString* []){@"ntf", @"nitf", nil}, 0, 0, NULL, nil, @"application/vnd.nitf"},
	{1, (OFString* []){@"nnd", nil}, 0, 0, NULL, nil, @"application/vnd.noblenet-directory"},
	{1, (OFString* []){@"nns", nil}, 0, 0, NULL, nil, @"application/vnd.noblenet-sealer"},
	{1, (OFString* []){@"nnw", nil}, 0, 0, NULL, nil, @"application/vnd.noblenet-web"},
	{1, (OFString* []){@"ncm", nil}, 0, 0, NULL, nil, @"application/vnd.nokia.configuration-message"},
	{1, (OFString* []){@"ngdat", nil}, 0, 0, NULL, nil, @"application/vnd.nokia.n-gage.data"},
	{1, (OFString* []){@"n-gage", nil}, 0, 0, NULL, nil, @"application/vnd.nokia.n-gage.symbian.install"},
	{1, (OFString* []){@"rpst", nil}, 0, 0, NULL, nil, @"application/vnd.nokia.radio-preset"},
	{1, (OFString* []){@"rpss", nil}, 0, 0, NULL, nil, @"application/vnd.nokia.radio-presets"},
	{1, (OFString* []){@"rng", nil}, 0, 0, NULL, nil, @"application/vnd.nokia.ringing-tone"},
	{1, (OFString* []){@"edm", nil}, 0, 0, NULL, nil, @"application/vnd.novadigm.EDM"},
	{1, (OFString* []){@"edx", nil}, 0, 0, NULL, nil, @"application/vnd.novadigm.EDX"},
	{1, (OFString* []){@"ext", nil}, 0, 0, NULL, nil, @"application/vnd.novadigm.EXT"},
	{1, (OFString* []){@"edm", nil}, 0, 0, NULL, nil, @"application/vnd.novadigm.edm"},
	{1, (OFString* []){@"edx", nil}, 0, 0, NULL, nil, @"application/vnd.novadigm.edx"},
	{1, (OFString* []){@"ext", nil}, 0, 0, NULL, nil, @"application/vnd.novadigm.ext"},
	{1, (OFString* []){@"odc", nil}, 0, 0, NULL, nil, @"application/vnd.oasis.opendocument.chart"},
	{1, (OFString* []){@"otc", nil}, 0, 0, NULL, nil, @"application/vnd.oasis.opendocument.chart-template"},
	{1, (OFString* []){@"odb", nil}, 0, 0, NULL, nil, @"application/vnd.oasis.opendocument.database"},
	{1, (OFString* []){@"odf", nil}, 0, 0, NULL, nil, @"application/vnd.oasis.opendocument.formula"},
	{1, (OFString* []){@"odft", nil}, 0, 0, NULL, nil, @"application/vnd.oasis.opendocument.formula-template"},
	{1, (OFString* []){@"odg", nil}, 0, 0, NULL, nil, @"application/vnd.oasis.opendocument.graphics"},
	{1, (OFString* []){@"otg", nil}, 0, 0, NULL, nil, @"application/vnd.oasis.opendocument.graphics-template"},
	{1, (OFString* []){@"odi", nil}, 0, 0, NULL, nil, @"application/vnd.oasis.opendocument.image"},
	{1, (OFString* []){@"oti", nil}, 0, 0, NULL, nil, @"application/vnd.oasis.opendocument.image-template"},
	{1, (OFString* []){@"odp", nil}, 0, 0, NULL, nil, @"application/vnd.oasis.opendocument.presentation"},
	{1, (OFString* []){@"otp", nil}, 0, 0, NULL, nil, @"application/vnd.oasis.opendocument.presentation-template"},
	{1, (OFString* []){@"ods", nil}, 0, 0, NULL, nil, @"application/vnd.oasis.opendocument.spreadsheet"},
	{1, (OFString* []){@"ots", nil}, 0, 0, NULL, nil, @"application/vnd.oasis.opendocument.spreadsheet-template"},
	{1, (OFString* []){@"odt", nil}, 0, 0, NULL, nil, @"application/vnd.oasis.opendocument.text"},
	{2, (OFString* []){@"odm", @"otm", nil}, 0, 0, NULL, nil, @"application/vnd.oasis.opendocument.text-master"},
	{1, (OFString* []){@"ott", nil}, 0, 0, NULL, nil, @"application/vnd.oasis.opendocument.text-template"},
	{1, (OFString* []){@"oth", nil}, 0, 0, NULL, nil, @"application/vnd.oasis.opendocument.text-web"},
	{1, (OFString* []){@"xo", nil}, 0, 0, NULL, nil, @"application/vnd.olpc-sugar"},
	{1, (OFString* []){@"dd2", nil}, 0, 0, NULL, nil, @"application/vnd.oma.dd2+xml"},
	{1, (OFString* []){@"oxt", nil}, 0, 0, NULL, nil, @"application/vnd.openofficeorg.extension"},
	{1, (OFString* []){@"pptx", nil}, 0, 0, NULL, nil, @"application/vnd.openxmlformats-officedocument.presentationml.presentation"},
	{1, (OFString* []){@"sldx", nil}, 0, 0, NULL, nil, @"application/vnd.openxmlformats-officedocument.presentationml.slide"},
	{1, (OFString* []){@"ppsx", nil}, 0, 0, NULL, nil, @"application/vnd.openxmlformats-officedocument.presentationml.slideshow"},
	{1, (OFString* []){@"potx", nil}, 0, 0, NULL, nil, @"application/vnd.openxmlformats-officedocument.presentationml.template"},
	{1, (OFString* []){@"xlsx", nil}, 0, 0, NULL, nil, @"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"},
	{1, (OFString* []){@"xltx", nil}, 0, 0, NULL, nil, @"application/vnd.openxmlformats-officedocument.spreadsheetml.template"},
	{1, (OFString* []){@"docx", nil}, 0, 0, NULL, nil, @"application/vnd.openxmlformats-officedocument.wordprocessingml.document"},
	{1, (OFString* []){@"dotx", nil}, 0, 0, NULL, nil, @"application/vnd.openxmlformats-officedocument.wordprocessingml.template"},
	{1, (OFString* []){@"mgp", nil}, 0, 0, NULL, nil, @"application/vnd.osgeo.mapguide.package"},
	{1, (OFString* []){@"dp", nil}, 0, 0, NULL, nil, @"application/vnd.osgi.dp"},
	{1, (OFString* []){@"esa", nil}, 0, 0, NULL, nil, @"application/vnd.osgi.subsystem"},
	{3, (OFString* []){@"pdb", @"pqa", @"oprc", nil}, 0, 0, NULL, nil, @"application/vnd.palm"},
	{1, (OFString* []){@"paw", nil}, 0, 0, NULL, nil, @"application/vnd.pawaafile"},
	{1, (OFString* []){@"str", nil}, 0, 0, NULL, nil, @"application/vnd.pg.format"},
	{1, (OFString* []){@"ei6", nil}, 0, 0, NULL, nil, @"application/vnd.pg.osasli"},
	{1, (OFString* []){@"efif", nil}, 0, 0, NULL, nil, @"application/vnd.picsel"},
	{1, (OFString* []){@"wg", nil}, 0, 0, NULL, nil, @"application/vnd.pmi.widget"},
	{1, (OFString* []){@"plf", nil}, 0, 0, NULL, nil, @"application/vnd.pocketlearn"},
	{1, (OFString* []){@"pbd", nil}, 0, 0, NULL, nil, @"application/vnd.powerbuilder6"},
	{1, (OFString* []){@"box", nil}, 0, 0, NULL, nil, @"application/vnd.previewsystems.box"},
	{1, (OFString* []){@"mgz", nil}, 0, 0, NULL, nil, @"application/vnd.proteus.magazine"},
	{1, (OFString* []){@"qps", nil}, 0, 0, NULL, nil, @"application/vnd.publishare-delta-tree"},
	{1, (OFString* []){@"ptid", nil}, 0, 0, NULL, nil, @"application/vnd.pvi.ptid1"},
	{6, (OFString* []){@"qxd", @"qxt", @"qwd", @"qwt", @"qxl", @"qxb", nil}, 0, 0, NULL, nil, @"application/vnd.quark.quarkxpress"},
	{1, (OFString* []){@"bed", nil}, 0, 0, NULL, nil, @"application/vnd.realvnc.bed"},
	{1, (OFString* []){@"mxl", nil}, 0, 0, NULL, nil, @"application/vnd.recordare.musicxml"},
	{1, (OFString* []){@"musicxml", nil}, 0, 0, NULL, nil, @"application/vnd.recordare.musicxml+xml"},
	{1, (OFString* []){@"cryptonote", nil}, 0, 0, NULL, nil, @"application/vnd.rig.cryptonote"},
	{1, (OFString* []){@"cod", nil}, 0, 0, NULL, nil, @"application/vnd.rim.cod"},
	{1, (OFString* []){@"rm", nil}, 0, 0, NULL, nil, @"application/vnd.rn-realmedia"},
	{1, (OFString* []){@"rmvb", nil}, 0, 0, NULL, nil, @"application/vnd.rn-realmedia-vbr"},
	{1, (OFString* []){@"rnx", nil}, 0, 0, NULL, nil, @"application/vnd.rn-realplayer"},
	{1, (OFString* []){@"link66", nil}, 0, 0, NULL, nil, @"application/vnd.route66.link66+xml"},
	{1, (OFString* []){@"st", nil}, 0, 0, NULL, nil, @"application/vnd.sailingtracker.track"},
	{1, (OFString* []){@"see", nil}, 0, 0, NULL, nil, @"application/vnd.seemail"},
	{1, (OFString* []){@"sema", nil}, 0, 0, NULL, nil, @"application/vnd.sema"},
	{1, (OFString* []){@"semd", nil}, 0, 0, NULL, nil, @"application/vnd.semd"},
	{1, (OFString* []){@"semf", nil}, 0, 0, NULL, nil, @"application/vnd.semf"},
	{1, (OFString* []){@"ifm", nil}, 0, 0, NULL, nil, @"application/vnd.shana.informed.formdata"},
	{1, (OFString* []){@"itp", nil}, 0, 0, NULL, nil, @"application/vnd.shana.informed.formtemplate"},
	{1, (OFString* []){@"iif", nil}, 0, 0, NULL, nil, @"application/vnd.shana.informed.interchange"},
	{1, (OFString* []){@"ipk", nil}, 0, 0, NULL, nil, @"application/vnd.shana.informed.package"},
	{2, (OFString* []){@"twd", @"twds", nil}, 0, 0, NULL, nil, @"application/vnd.simtech-mindmapper"},
	{1, (OFString* []){@"mmf", nil}, 0, 0, NULL, nil, @"application/vnd.smaf"},
	{1, (OFString* []){@"teacher", nil}, 0, 0, NULL, nil, @"application/vnd.smart.teacher"},
	{2, (OFString* []){@"sdkm", @"sdkd", nil}, 0, 0, NULL, nil, @"application/vnd.solent.sdkm+xml"},
	{1, (OFString* []){@"dxp", nil}, 0, 0, NULL, nil, @"application/vnd.spotfire.dxp"},
	{1, (OFString* []){@"sfs", nil}, 0, 0, NULL, nil, @"application/vnd.spotfire.sfs"},
	{1, (OFString* []){@"sdc", nil}, 0, 0, NULL, nil, @"application/vnd.stardivision.calc"},
	{1, (OFString* []){@"sda", nil}, 0, 0, NULL, nil, @"application/vnd.stardivision.draw"},
	{2, (OFString* []){@"sdd", @"sdp", nil}, 0, 0, NULL, nil, @"application/vnd.stardivision.impress"},
	{1, (OFString* []){@"smf", nil}, 0, 0, NULL, nil, @"application/vnd.stardivision.math"},
	{2, (OFString* []){@"sdw", @"vor", nil}, 0, 0, NULL, nil, @"application/vnd.stardivision.writer"},
	{1, (OFString* []){@"sgl", nil}, 0, 0, NULL, nil, @"application/vnd.stardivision.writer-global"},
	{1, (OFString* []){@"smzip", nil}, 0, 0, NULL, nil, @"application/vnd.stepmania.package"},
	{1, (OFString* []){@"sm", nil}, 0, 0, NULL, nil, @"application/vnd.stepmania.stepchart"},
	{1, (OFString* []){@"sxc", nil}, 0, 0, NULL, nil, @"application/vnd.sun.xml.calc"},
	{1, (OFString* []){@"stc", nil}, 0, 0, NULL, nil, @"application/vnd.sun.xml.calc.template"},
	{1, (OFString* []){@"sxd", nil}, 0, 0, NULL, nil, @"application/vnd.sun.xml.draw"},
	{1, (OFString* []){@"std", nil}, 0, 0, NULL, nil, @"application/vnd.sun.xml.draw.template"},
	{1, (OFString* []){@"sxi", nil}, 0, 0, NULL, nil, @"application/vnd.sun.xml.impress"},
	{1, (OFString* []){@"sti", nil}, 0, 0, NULL, nil, @"application/vnd.sun.xml.impress.template"},
	{1, (OFString* []){@"sxm", nil}, 0, 0, NULL, nil, @"application/vnd.sun.xml.math"},
	{1, (OFString* []){@"sxw", nil}, 0, 0, NULL, nil, @"application/vnd.sun.xml.writer"},
	{1, (OFString* []){@"sxg", nil}, 0, 0, NULL, nil, @"application/vnd.sun.xml.writer.global"},
	{1, (OFString* []){@"stw", nil}, 0, 0, NULL, nil, @"application/vnd.sun.xml.writer.template"},
	{2, (OFString* []){@"sus", @"susp", nil}, 0, 0, NULL, nil, @"application/vnd.sus-calendar"},
	{1, (OFString* []){@"svd", nil}, 0, 0, NULL, nil, @"application/vnd.svd"},
	{2, (OFString* []){@"sis", @"sisx", nil}, 0, 0, NULL, nil, @"application/vnd.symbian.install"},
	{1, (OFString* []){@"xsm", nil}, 0, 0, NULL, nil, @"application/vnd.syncml+xml"},
	{1, (OFString* []){@"bdm", nil}, 0, 0, NULL, nil, @"application/vnd.syncml.dm+wbxml"},
	{1, (OFString* []){@"xdm", nil}, 0, 0, NULL, nil, @"application/vnd.syncml.dm+xml"},
	{1, (OFString* []){@"tao", nil}, 0, 0, NULL, nil, @"application/vnd.tao.intent-module-archive"},
	{3, (OFString* []){@"pcap", @"cap", @"dmp", nil}, 0, 0, NULL, nil, @"application/vnd.tcpdump.pcap"},
	{1, (OFString* []){@"tmo", nil}, 0, 0, NULL, nil, @"application/vnd.tmobile-livetv"},
	{1, (OFString* []){@"tpt", nil}, 0, 0, NULL, nil, @"application/vnd.trid.tpt"},
	{1, (OFString* []){@"mxs", nil}, 0, 0, NULL, nil, @"application/vnd.triscape.mxs"},
	{1, (OFString* []){@"tra", nil}, 0, 0, NULL, nil, @"application/vnd.trueapp"},
	{2, (OFString* []){@"ufd", @"ufdl", nil}, 0, 0, NULL, nil, @"application/vnd.ufdl"},
	{1, (OFString* []){@"utz", nil}, 0, 0, NULL, nil, @"application/vnd.uiq.theme"},
	{1, (OFString* []){@"umj", nil}, 0, 0, NULL, nil, @"application/vnd.umajin"},
	{1, (OFString* []){@"unityweb", nil}, 0, 0, NULL, nil, @"application/vnd.unity"},
	{1, (OFString* []){@"uoml", nil}, 0, 0, NULL, nil, @"application/vnd.uoml+xml"},
	{1, (OFString* []){@"vcx", nil}, 0, 0, NULL, nil, @"application/vnd.vcx"},
	{4, (OFString* []){@"vsd", @"vst", @"vss", @"vsw", nil}, 0, 0, NULL, nil, @"application/vnd.visio"},
	{1, (OFString* []){@"vis", nil}, 0, 0, NULL, nil, @"application/vnd.visionary"},
	{1, (OFString* []){@"vsf", nil}, 0, 0, NULL, nil, @"application/vnd.vsf"},
	{1, (OFString* []){@"sic", nil}, 0, 0, NULL, nil, @"application/vnd.wap.sic"},
	{1, (OFString* []){@"slc", nil}, 0, 0, NULL, nil, @"application/vnd.wap.slc"},
	{1, (OFString* []){@"wbxml", nil}, 0, 0, NULL, nil, @"application/vnd.wap.wbxml"},
	{1, (OFString* []){@"wmlc", nil}, 0, 0, NULL, nil, @"application/vnd.wap.wmlc"},
	{1, (OFString* []){@"wmlsc", nil}, 0, 0, NULL, nil, @"application/vnd.wap.wmlscriptc"},
	{1, (OFString* []){@"wtb", nil}, 0, 0, NULL, nil, @"application/vnd.webturbo"},
	{1, (OFString* []){@"nbp", nil}, 0, 0, NULL, nil, @"application/vnd.wolfram.player"},
	{1, (OFString* []){@"wpd", nil}, 0, 0, NULL, nil, @"application/vnd.wordperfect"},
	{1, (OFString* []){@"wqd", nil}, 0, 0, NULL, nil, @"application/vnd.wqd"},
	{1, (OFString* []){@"stf", nil}, 0, 0, NULL, nil, @"application/vnd.wt.stf"},
	{2, (OFString* []){@"xar", @"web", nil}, 0, 0, NULL, nil, @"application/vnd.xara"},
	{1, (OFString* []){@"xfdl", nil}, 0, 0, NULL, nil, @"application/vnd.xfdl"},
	{1, (OFString* []){@"hvd", nil}, 0, 0, NULL, nil, @"application/vnd.yamaha.hv-dic"},
	{1, (OFString* []){@"hvs", nil}, 0, 0, NULL, nil, @"application/vnd.yamaha.hv-script"},
	{1, (OFString* []){@"hvp", nil}, 0, 0, NULL, nil, @"application/vnd.yamaha.hv-voice"},
	{1, (OFString* []){@"osf", nil}, 0, 0, NULL, nil, @"application/vnd.yamaha.openscoreformat"},
	{1, (OFString* []){@"osfpvg", nil}, 0, 0, NULL, nil, @"application/vnd.yamaha.openscoreformat.osfpvg+xml"},
	{1, (OFString* []){@"saf", nil}, 0, 0, NULL, nil, @"application/vnd.yamaha.smaf-audio"},
	{1, (OFString* []){@"spf", nil}, 0, 0, NULL, nil, @"application/vnd.yamaha.smaf-phrase"},
	{1, (OFString* []){@"cmp", nil}, 0, 0, NULL, nil, @"application/vnd.yellowriver-custom-menu"},
	{2, (OFString* []){@"zir", @"zirz", nil}, 0, 0, NULL, nil, @"application/vnd.zul"},
	{1, (OFString* []){@"zaz", nil}, 0, 0, NULL, nil, @"application/vnd.zzazz.deck+xml"},
	{1, (OFString* []){@"vmd", nil}, 0, 0, NULL, nil, @"application/vocaltec-media-desc"},
	{1, (OFString* []){@"vmf", nil}, 0, 0, NULL, nil, @"application/vocaltec-media-file"},
	{1, (OFString* []){@"vxml", nil}, 0, 0, NULL, nil, @"application/voicexml+xml"},
	{1, (OFString* []){@"wgt", nil}, 0, 0, NULL, nil, @"application/widget"},
	{1, (OFString* []){@"hlp", nil}, 0, 0, NULL, nil, @"application/winhlp"},
	{4, (OFString* []){@"wp", @"wp5", @"wp6", @"wpd", nil}, 0, 0, NULL, nil, @"application/wordperfect"},
	{1, (OFString* []){@"wp5", nil}, 0, 0, NULL, nil, @"application/wordperfect5.1"},
	{2, (OFString* []){@"w60", @"wp5", nil}, 0, 0, NULL, nil, @"application/wordperfect6.0"},
	{1, (OFString* []){@"w61", nil}, 0, 0, NULL, nil, @"application/wordperfect6.1"},
	{1, (OFString* []){@"wsdl", nil}, 0, 0, NULL, nil, @"application/wsdl+xml"},
	{1, (OFString* []){@"wspolicy", nil}, 0, 0, NULL, nil, @"application/wspolicy+xml"},
	{2, (OFString* []){@"wk1", @"wk", nil}, 0, 0, NULL, nil, @"application/x-123"},
	{1, (OFString* []){@"7z", nil}, 0, 0, NULL, nil, @"application/x-7z-compressed"},
	{1, (OFString* []){@"abw", nil}, 0, 0, NULL, nil, @"application/x-abiword"},
	{1, (OFString* []){@"ace", nil}, 0, 0, NULL, nil, @"application/x-ace-compressed"},
	{1, (OFString* []){@"aim", nil}, 0, 0, NULL, nil, @"application/x-aim"},
	{1, (OFString* []){@"dmg", nil}, 0, 0, NULL, nil, @"application/x-apple-diskimage"},
	{4, (OFString* []){@"aab", @"x32", @"u32", @"vox", nil}, 0, 0, NULL, nil, @"application/x-authorware-bin"},
	{1, (OFString* []){@"aam", nil}, 0, 0, NULL, nil, @"application/x-authorware-map"},
	{1, (OFString* []){@"aas", nil}, 0, 0, NULL, nil, @"application/x-authorware-seg"},
	{1, (OFString* []){@"bcpio", nil}, 0, 0, NULL, nil, @"application/x-bcpio"},
	{1, (OFString* []){@"bin", nil}, 0, 0, NULL, nil, @"application/x-binary"},
	{1, (OFString* []){@"hqx", nil}, 0, 0, NULL, nil, @"application/x-binhex40"},
	{1, (OFString* []){@"torrent", nil}, 0, 0, NULL, nil, @"application/x-bittorrent"},
	{2, (OFString* []){@"blb", @"blorb", nil}, 0, 0, NULL, nil, @"application/x-blorb"},
	{3, (OFString* []){@"bsh", @"sh", @"shar", nil}, 0, 0, NULL, nil, @"application/x-bsh"},
	{1, (OFString* []){@"elc", nil}, 0, 0, NULL, nil, @"application/x-bytecode.elisp"},
	{1, (OFString* []){@"elc", nil}, 0, 0, NULL, nil, @"application/x-bytecode.elisp(compiledelisp)"},
	{1, (OFString* []){@"pyc", nil}, 0, 0, NULL, nil, @"application/x-bytecode.python"},
	{1, (OFString* []){@"bz", nil}, 0, 0, NULL, nil, @"application/x-bzip"},
	{2, (OFString* []){@"bz2", @"boz", nil}, 0, 0, NULL, nil, @"application/x-bzip2"},
	{5, (OFString* []){@"cbr", @"cba", @"cbt", @"cbz", @"cb7", nil}, 0, 0, NULL, nil, @"application/x-cbr"},
	{1, (OFString* []){@"cdf", nil}, 0, 0, NULL, nil, @"application/x-cdf"},
	{1, (OFString* []){@"vcd", nil}, 0, 0, NULL, nil, @"application/x-cdlink"},
	{1, (OFString* []){@"cfs", nil}, 0, 0, NULL, nil, @"application/x-cfs-compressed"},
	{2, (OFString* []){@"chat", @"cha", nil}, 0, 0, NULL, nil, @"application/x-chat"},
	{1, (OFString* []){@"pgn", nil}, 0, 0, NULL, nil, @"application/x-chess-pgn"},
	{1, (OFString* []){@"chm", nil}, 0, 0, NULL, nil, @"application/x-chm"},
	{1, (OFString* []){@"crx", nil}, 0, 0, NULL, nil, @"application/x-chrome-extension"},
	{1, (OFString* []){@"ras", nil}, 0, 0, NULL, nil, @"application/x-cmu-raster"},
	{1, (OFString* []){@"cco", nil}, 0, 0, NULL, nil, @"application/x-cocoa"},
	{1, (OFString* []){@"cpt", nil}, 0, 0, NULL, nil, @"application/x-compactpro"},
	{1, (OFString* []){@"z", nil}, 0, 0, NULL, nil, @"application/x-compress"},
	{4, (OFString* []){@"gz", @"tgz", @"z", @"zip", nil}, 0, 0, NULL, nil, @"application/x-compressed"},
	{1, (OFString* []){@"nsc", nil}, 0, 0, NULL, nil, @"application/x-conference"},
	{1, (OFString* []){@"cpio", nil}, 0, 0, NULL, nil, @"application/x-cpio"},
	{1, (OFString* []){@"cpt", nil}, 0, 0, NULL, nil, @"application/x-cpt"},
	{1, (OFString* []){@"csh", nil}, 0, 0, NULL, nil, @"application/x-csh"},
	{2, (OFString* []){@"deb", @"udeb", nil}, 0, 0, NULL, nil, @"application/x-debian-package"},
	{1, (OFString* []){@"deepv", nil}, 0, 0, NULL, nil, @"application/x-deepv"},
	{1, (OFString* []){@"dgc", nil}, 0, 0, NULL, nil, @"application/x-dgc-compressed"},
	{9, (OFString* []){@"dir", @"dcr", @"dxr", @"cst", @"cct", @"cxt", @"w3d", @"fgd", @"swa", nil}, 0, 0, NULL, nil, @"application/x-director"},
	{1, (OFString* []){@"dms", nil}, 0, 0, NULL, nil, @"application/x-dms"},
	{1, (OFString* []){@"wad", nil}, 0, 0, NULL, nil, @"application/x-doom"},
	{1, (OFString* []){@"ncx", nil}, 0, 0, NULL, nil, @"application/x-dtbncx+xml"},
	{1, (OFString* []){@"dtb", nil}, 0, 0, NULL, nil, @"application/x-dtbook+xml"},
	{1, (OFString* []){@"res", nil}, 0, 0, NULL, nil, @"application/x-dtbresource+xml"},
	{1, (OFString* []){@"dvi", nil}, 0, 0, NULL, nil, @"application/x-dvi"},
	{1, (OFString* []){@"elc", nil}, 0, 0, NULL, nil, @"application/x-elc"},
	{2, (OFString* []){@"env", @"evy", nil}, 0, 0, NULL, nil, @"application/x-envoy"},
	{1, (OFString* []){@"es", nil}, 0, 0, NULL, nil, @"application/x-esrehber"},
	{1, (OFString* []){@"eva", nil}, 0, 0, NULL, nil, @"application/x-eva"},
	{11, (OFString* []){@"xla", @"xlb", @"xlc", @"xld", @"xlk", @"xll", @"xlm", @"xls", @"xlt", @"xlv", @"xlw", nil}, 0, 0, NULL, nil, @"application/x-excel"},
	{1, (OFString* []){@"flac", nil}, 0, 0, NULL, nil, @"application/x-flac"},
	{5, (OFString* []){@"pfa", @"pfb", @"gsf", @"pcf", @"pcf.z", nil}, 0, 0, NULL, nil, @"application/x-font"},
	{1, (OFString* []){@"bdf", nil}, 0, 0, NULL, nil, @"application/x-font-bdf"},
	{1, (OFString* []){@"gsf", nil}, 0, 0, NULL, nil, @"application/x-font-ghostscript"},
	{1, (OFString* []){@"psf", nil}, 0, 0, NULL, nil, @"application/x-font-linux-psf"},
	{1, (OFString* []){@"otf", nil}, 0, 0, NULL, nil, @"application/x-font-otf"},
	{1, (OFString* []){@"pcf", nil}, 0, 0, NULL, nil, @"application/x-font-pcf"},
	{1, (OFString* []){@"snf", nil}, 0, 0, NULL, nil, @"application/x-font-snf"},
	{2, (OFString* []){@"ttf", @"ttc", nil}, 0, 0, NULL, nil, @"application/x-font-ttf"},
	{4, (OFString* []){@"pfa", @"pfb", @"pfm", @"afm", nil}, 0, 0, NULL, nil, @"application/x-font-type1"},
	{1, (OFString* []){@"woff", nil}, 0, 0, NULL, nil, @"application/x-font-woff"},
	{1, (OFString* []){@"mif", nil}, 0, 0, NULL, nil, @"application/x-frame"},
	{1, (OFString* []){@"arc", nil}, 0, 0, NULL, nil, @"application/x-freearc"},
	{1, (OFString* []){@"pre", nil}, 0, 0, NULL, nil, @"application/x-freelance"},
	{1, (OFString* []){@"spl", nil}, 0, 0, NULL, nil, @"application/x-futuresplash"},
	{1, (OFString* []){@"gca", nil}, 0, 0, NULL, nil, @"application/x-gca-compressed"},
	{1, (OFString* []){@"ulx", nil}, 0, 0, NULL, nil, @"application/x-glulx"},
	{1, (OFString* []){@"gnumeric", nil}, 0, 0, NULL, nil, @"application/x-gnumeric"},
	{1, (OFString* []){@"sgf", nil}, 0, 0, NULL, nil, @"application/x-go-sgf"},
	{1, (OFString* []){@"gramps", nil}, 0, 0, NULL, nil, @"application/x-gramps-xml"},
	{1, (OFString* []){@"gcf", nil}, 0, 0, NULL, nil, @"application/x-graphing-calculator"},
	{1, (OFString* []){@"gsp", nil}, 0, 0, NULL, nil, @"application/x-gsp"},
	{1, (OFString* []){@"gss", nil}, 0, 0, NULL, nil, @"application/x-gss"},
	{3, (OFString* []){@"gtar", @"tgz", @"taz", nil}, 0, 0, NULL, nil, @"application/x-gtar"},
	{3, (OFString* []){@"gz", @"gzip", @"tgz", nil}, 0, 0, NULL, nil, @"application/x-gzip"},
	{1, (OFString* []){@"hdf", nil}, 0, 0, NULL, nil, @"application/x-hdf"},
	{2, (OFString* []){@"help", @"hlp", nil}, 0, 0, NULL, nil, @"application/x-helpfile"},
	{1, (OFString* []){@"imap", nil}, 0, 0, NULL, nil, @"application/x-httpd-imap"},
	{3, (OFString* []){@"phtml", @"pht", @"php", nil}, 0, 0, NULL, nil, @"application/x-httpd-php"},
	{1, (OFString* []){@"phps", nil}, 0, 0, NULL, nil, @"application/x-httpd-php-source"},
	{1, (OFString* []){@"php3", nil}, 0, 0, NULL, nil, @"application/x-httpd-php3"},
	{1, (OFString* []){@"php3p", nil}, 0, 0, NULL, nil, @"application/x-httpd-php3-preprocessed"},
	{1, (OFString* []){@"php4", nil}, 0, 0, NULL, nil, @"application/x-httpd-php4"},
	{1, (OFString* []){@"ica", nil}, 0, 0, NULL, nil, @"application/x-ica"},
	{1, (OFString* []){@"ima", nil}, 0, 0, NULL, nil, @"application/x-ima"},
	{1, (OFString* []){@"install", nil}, 0, 0, NULL, nil, @"application/x-install-instructions"},
	{2, (OFString* []){@"ins", @"isp", nil}, 0, 0, NULL, nil, @"application/x-internet-signup"},
	{1, (OFString* []){@"ins", nil}, 0, 0, NULL, nil, @"application/x-internett-signup"},
	{1, (OFString* []){@"iv", nil}, 0, 0, NULL, nil, @"application/x-inventor"},
	{1, (OFString* []){@"ip", nil}, 0, 0, NULL, nil, @"application/x-ip2"},
	{1, (OFString* []){@"iii", nil}, 0, 0, NULL, nil, @"application/x-iphone"},
	{1, (OFString* []){@"iso", nil}, 0, 0, NULL, nil, @"application/x-iso9660-image"},
	{1, (OFString* []){@"jar", nil}, 0, 0, NULL, nil, @"application/x-java-archive"},
	{1, (OFString* []){@"class", nil}, 0, 0, NULL, nil, @"application/x-java-class"},
	{1, (OFString* []){@"jcm", nil}, 0, 0, NULL, nil, @"application/x-java-commerce"},
	{1, (OFString* []){@"jnlp", nil}, 0, 0, NULL, nil, @"application/x-java-jnlp-file"},
	{1, (OFString* []){@"ser", nil}, 0, 0, NULL, nil, @"application/x-java-serialized-object"},
	{1, (OFString* []){@"class", nil}, 0, 0, NULL, nil, @"application/x-java-vm"},
	{1, (OFString* []){@"js", nil}, 0, 0, NULL, nil, @"application/x-javascript"},
	{1, (OFString* []){@"chrt", nil}, 0, 0, NULL, nil, @"application/x-kchart"},
	{1, (OFString* []){@"kil", nil}, 0, 0, NULL, nil, @"application/x-killustrator"},
	{4, (OFString* []){@"skd", @"skm", @"skp", @"skt", nil}, 0, 0, NULL, nil, @"application/x-koan"},
	{2, (OFString* []){@"kpr", @"kpt", nil}, 0, 0, NULL, nil, @"application/x-kpresenter"},
	{1, (OFString* []){@"ksh", nil}, 0, 0, NULL, nil, @"application/x-ksh"},
	{1, (OFString* []){@"ksp", nil}, 0, 0, NULL, nil, @"application/x-kspread"},
	{2, (OFString* []){@"kwd", @"kwt", nil}, 0, 0, NULL, nil, @"application/x-kword"},
	{2, (OFString* []){@"latex", @"ltx", nil}, 0, 0, NULL, nil, @"application/x-latex"},
	{1, (OFString* []){@"lha", nil}, 0, 0, NULL, nil, @"application/x-lha"},
	{1, (OFString* []){@"lsp", nil}, 0, 0, NULL, nil, @"application/x-lisp"},
	{1, (OFString* []){@"ivy", nil}, 0, 0, NULL, nil, @"application/x-livescreen"},
	{1, (OFString* []){@"wq1", nil}, 0, 0, NULL, nil, @"application/x-lotus"},
	{1, (OFString* []){@"scm", nil}, 0, 0, NULL, nil, @"application/x-lotusscreencam"},
	{1, (OFString* []){@"luac", nil}, 0, 0, NULL, nil, @"application/x-lua-bytecode"},
	{1, (OFString* []){@"lzh", nil}, 0, 0, NULL, nil, @"application/x-lzh"},
	{2, (OFString* []){@"lzh", @"lha", nil}, 0, 0, NULL, nil, @"application/x-lzh-compressed"},
	{1, (OFString* []){@"lzx", nil}, 0, 0, NULL, nil, @"application/x-lzx"},
	{1, (OFString* []){@"hqx", nil}, 0, 0, NULL, nil, @"application/x-mac-binhex40"},
	{1, (OFString* []){@"bin", nil}, 0, 0, NULL, nil, @"application/x-macbinary"},
	{1, (OFString* []){@"mc$", nil}, 0, 0, NULL, nil, @"application/x-magic-cap-package-1.0"},
	{7, (OFString* []){@"frm", @"maker", @"frame", @"fm", @"fb", @"book", @"fbdoc", nil}, 0, 0, NULL, nil, @"application/x-maker"},
	{1, (OFString* []){@"mcd", nil}, 0, 0, NULL, nil, @"application/x-mathcad"},
	{1, (OFString* []){@"mm", nil}, 0, 0, NULL, nil, @"application/x-meme"},
	{2, (OFString* []){@"mid", @"midi", nil}, 0, 0, NULL, nil, @"application/x-midi"},
	{1, (OFString* []){@"mie", nil}, 0, 0, NULL, nil, @"application/x-mie"},
	{1, (OFString* []){@"mif", nil}, 0, 0, NULL, nil, @"application/x-mif"},
	{1, (OFString* []){@"nix", nil}, 0, 0, NULL, nil, @"application/x-mix-transfer"},
	{2, (OFString* []){@"prc", @"mobi", nil}, 0, 0, NULL, nil, @"application/x-mobipocket-ebook"},
	{1, (OFString* []){@"m3u8", nil}, 0, 0, NULL, nil, @"application/x-mpegURL"},
	{1, (OFString* []){@"asx", nil}, 0, 0, NULL, nil, @"application/x-mplayer2"},
	{1, (OFString* []){@"application", nil}, 0, 0, NULL, nil, @"application/x-ms-application"},
	{1, (OFString* []){@"lnk", nil}, 0, 0, NULL, nil, @"application/x-ms-shortcut"},
	{1, (OFString* []){@"wmd", nil}, 0, 0, NULL, nil, @"application/x-ms-wmd"},
	{1, (OFString* []){@"wmz", nil}, 0, 0, NULL, nil, @"application/x-ms-wmz"},
	{1, (OFString* []){@"xbap", nil}, 0, 0, NULL, nil, @"application/x-ms-xbap"},
	{1, (OFString* []){@"mdb", nil}, 0, 0, NULL, nil, @"application/x-msaccess"},
	{1, (OFString* []){@"obd", nil}, 0, 0, NULL, nil, @"application/x-msbinder"},
	{1, (OFString* []){@"crd", nil}, 0, 0, NULL, nil, @"application/x-mscardfile"},
	{1, (OFString* []){@"clp", nil}, 0, 0, NULL, nil, @"application/x-msclip"},
	{4, (OFString* []){@"com", @"exe", @"bat", @"dll", nil}, 0, 0, NULL, nil, @"application/x-msdos-program"},
	{5, (OFString* []){@"exe", @"dll", @"com", @"bat", @"msi", nil}, 0, 0, NULL, nil, @"application/x-msdownload"},
	{3, (OFString* []){@"xla", @"xls", @"xlw", nil}, 0, 0, NULL, nil, @"application/x-msexcel"},
	{1, (OFString* []){@"msi", nil}, 0, 0, NULL, nil, @"application/x-msi"},
	{3, (OFString* []){@"mvb", @"m13", @"m14", nil}, 0, 0, NULL, nil, @"application/x-msmediaview"},
	{4, (OFString* []){@"wmf", @"wmz", @"emf", @"emz", nil}, 0, 0, NULL, nil, @"application/x-msmetafile"},
	{1, (OFString* []){@"mny", nil}, 0, 0, NULL, nil, @"application/x-msmoney"},
	{1, (OFString* []){@"ppt", nil}, 0, 0, NULL, nil, @"application/x-mspowerpoint"},
	{1, (OFString* []){@"pub", nil}, 0, 0, NULL, nil, @"application/x-mspublisher"},
	{1, (OFString* []){@"scd", nil}, 0, 0, NULL, nil, @"application/x-msschedule"},
	{1, (OFString* []){@"trm", nil}, 0, 0, NULL, nil, @"application/x-msterminal"},
	{1, (OFString* []){@"wri", nil}, 0, 0, NULL, nil, @"application/x-mswrite"},
	{1, (OFString* []){@"ani", nil}, 0, 0, NULL, nil, @"application/x-navi-animation"},
	{1, (OFString* []){@"nvd", nil}, 0, 0, NULL, nil, @"application/x-navidoc"},
	{1, (OFString* []){@"map", nil}, 0, 0, NULL, nil, @"application/x-navimap"},
	{1, (OFString* []){@"stl", nil}, 0, 0, NULL, nil, @"application/x-navistyle"},
	{2, (OFString* []){@"nc", @"cdf", nil}, 0, 0, NULL, nil, @"application/x-netcdf"},
	{1, (OFString* []){@"pkg", nil}, 0, 0, NULL, nil, @"application/x-newton-compatible-pkg"},
	{1, (OFString* []){@"aos", nil}, 0, 0, NULL, nil, @"application/x-nokia-9000-communicator-add-on-software"},
	{1, (OFString* []){@"pac", nil}, 0, 0, NULL, nil, @"application/x-ns-proxy-autoconfig"},
	{1, (OFString* []){@"nwc", nil}, 0, 0, NULL, nil, @"application/x-nwc"},
	{1, (OFString* []){@"nzb", nil}, 0, 0, NULL, nil, @"application/x-nzb"},
	{1, (OFString* []){@"o", nil}, 0, 0, NULL, nil, @"application/x-object"},
	{1, (OFString* []){@"omc", nil}, 0, 0, NULL, nil, @"application/x-omc"},
	{1, (OFString* []){@"omcd", nil}, 0, 0, NULL, nil, @"application/x-omcdatamaker"},
	{1, (OFString* []){@"omcr", nil}, 0, 0, NULL, nil, @"application/x-omcregerator"},
	{1, (OFString* []){@"oza", nil}, 0, 0, NULL, nil, @"application/x-oz-application"},
	{2, (OFString* []){@"pm4", @"pm5", nil}, 0, 0, NULL, nil, @"application/x-pagemaker"},
	{1, (OFString* []){@"pcl", nil}, 0, 0, NULL, nil, @"application/x-pcl"},
	{5, (OFString* []){@"pma", @"pmc", @"pml", @"pmr", @"pmw", nil}, 0, 0, NULL, nil, @"application/x-perfmon"},
	{1, (OFString* []){@"plx", nil}, 0, 0, NULL, nil, @"application/x-pixclscript"},
	{1, (OFString* []){@"p10", nil}, 0, 0, NULL, nil, @"application/x-pkcs10"},
	{2, (OFString* []){@"p12", @"pfx", nil}, 0, 0, NULL, nil, @"application/x-pkcs12"},
	{2, (OFString* []){@"p7b", @"spc", nil}, 0, 0, NULL, nil, @"application/x-pkcs7-certificates"},
	{1, (OFString* []){@"p7r", nil}, 0, 0, NULL, nil, @"application/x-pkcs7-certreqresp"},
	{1, (OFString* []){@"crl", nil}, 0, 0, NULL, nil, @"application/x-pkcs7-crl"},
	{2, (OFString* []){@"p7c", @"p7m", nil}, 0, 0, NULL, nil, @"application/x-pkcs7-mime"},
	{2, (OFString* []){@"p7a", @"p7s", nil}, 0, 0, NULL, nil, @"application/x-pkcs7-signature"},
	{1, (OFString* []){@"pnm", nil}, 0, 0, NULL, nil, @"application/x-portable-anymap"},
	{4, (OFString* []){@"mpc", @"mpt", @"mpv", @"mpx", nil}, 0, 0, NULL, nil, @"application/x-project"},
	{2, (OFString* []){@"pyc", @"pyo", nil}, 0, 0, NULL, nil, @"application/x-python-code"},
	{1, (OFString* []){@"wb1", nil}, 0, 0, NULL, nil, @"application/x-qpro"},
	{1, (OFString* []){@"qtl", nil}, 0, 0, NULL, nil, @"application/x-quicktimeplayer"},
	{1, (OFString* []){@"rar", nil}, 0, 0, NULL, nil, @"application/x-rar-compressed"},
	{1, (OFString* []){@"rpm", nil}, 0, 0, NULL, nil, @"application/x-redhat-package-manager"},
	{1, (OFString* []){@"ris", nil}, 0, 0, NULL, nil, @"application/x-research-info-systems"},
	{1, (OFString* []){@"rpm", nil}, 0, 0, NULL, nil, @"application/x-rpm"},
	{1, (OFString* []){@"rtf", nil}, 0, 0, NULL, nil, @"application/x-rtf"},
	{1, (OFString* []){@"sdp", nil}, 0, 0, NULL, nil, @"application/x-sdp"},
	{1, (OFString* []){@"sea", nil}, 0, 0, NULL, nil, @"application/x-sea"},
	{1, (OFString* []){@"sl", nil}, 0, 0, NULL, nil, @"application/x-seelogo"},
	{1, (OFString* []){@"sh", nil}, 0, 0, NULL, nil, @"application/x-sh"},
	{2, (OFString* []){@"shar", @"sh", nil}, 0, 0, NULL, nil, @"application/x-shar"},
	{2, (OFString* []){@"swf", @"swfl", nil}, 0, 0, NULL, nil, @"application/x-shockwave-flash"},
	{1, (OFString* []){@"xap", nil}, 0, 0, NULL, nil, @"application/x-silverlight-app"},
	{1, (OFString* []){@"sit", nil}, 0, 0, NULL, nil, @"application/x-sit"},
	{2, (OFString* []){@"spr", @"sprite", nil}, 0, 0, NULL, nil, @"application/x-sprite"},
	{1, (OFString* []){@"sql", nil}, 0, 0, NULL, nil, @"application/x-sql"},
	{1, (OFString* []){@"sit", nil}, 0, 0, NULL, nil, @"application/x-stuffit"},
	{1, (OFString* []){@"sitx", nil}, 0, 0, NULL, nil, @"application/x-stuffitx"},
	{1, (OFString* []){@"srt", nil}, 0, 0, NULL, nil, @"application/x-subrip"},
	{1, (OFString* []){@"sv4cpio", nil}, 0, 0, NULL, nil, @"application/x-sv4cpio"},
	{1, (OFString* []){@"sv4crc", nil}, 0, 0, NULL, nil, @"application/x-sv4crc"},
	{1, (OFString* []){@"t3", nil}, 0, 0, NULL, nil, @"application/x-t3vm-image"},
	{1, (OFString* []){@"gam", nil}, 0, 0, NULL, nil, @"application/x-tads"},
	{1, (OFString* []){@"tar", nil}, 0, 0, NULL, nil, @"application/x-tar"},
	{2, (OFString* []){@"sbk", @"tbk", nil}, 0, 0, NULL, nil, @"application/x-tbook"},
	{1, (OFString* []){@"tcl", nil}, 0, 0, NULL, nil, @"application/x-tcl"},
	{1, (OFString* []){@"tex", nil}, 0, 0, NULL, nil, @"application/x-tex"},
	{1, (OFString* []){@"gf", nil}, 0, 0, NULL, nil, @"application/x-tex-gf"},
	{1, (OFString* []){@"pk", nil}, 0, 0, NULL, nil, @"application/x-tex-pk"},
	{1, (OFString* []){@"tfm", nil}, 0, 0, NULL, nil, @"application/x-tex-tfm"},
	{2, (OFString* []){@"texinfo", @"texi", nil}, 0, 0, NULL, nil, @"application/x-texinfo"},
	{1, (OFString* []){@"obj", nil}, 0, 0, NULL, nil, @"application/x-tgif"},
	{5, (OFString* []){@"~", @"%", @"bak", @"old", @"sik", nil}, 0, 0, NULL, nil, @"application/x-trash"},
	{3, (OFString* []){@"roff", @"t", @"tr", nil}, 0, 0, NULL, nil, @"application/x-troff"},
	{1, (OFString* []){@"man", nil}, 0, 0, NULL, nil, @"application/x-troff-man"},
	{1, (OFString* []){@"me", nil}, 0, 0, NULL, nil, @"application/x-troff-me"},
	{1, (OFString* []){@"ms", nil}, 0, 0, NULL, nil, @"application/x-troff-ms"},
	{1, (OFString* []){@"avi", nil}, 0, 0, NULL, nil, @"application/x-troff-msvideo"},
	{1, (OFString* []){@"ustar", nil}, 0, 0, NULL, nil, @"application/x-ustar"},
	{3, (OFString* []){@"vsd", @"vst", @"vsw", nil}, 0, 0, NULL, nil, @"application/x-visio"},
	{1, (OFString* []){@"mzz", nil}, 0, 0, NULL, nil, @"application/x-vnd.audioexplosion.mzz"},
	{1, (OFString* []){@"xpix", nil}, 0, 0, NULL, nil, @"application/x-vnd.ls-xpix"},
	{1, (OFString* []){@"vrml", nil}, 0, 0, NULL, nil, @"application/x-vrml"},
	{2, (OFString* []){@"src", @"wsrc", nil}, 0, 0, NULL, nil, @"application/x-wais-source"},
	{1, (OFString* []){@"webapp", nil}, 0, 0, NULL, nil, @"application/x-web-app-manifest+json"},
	{1, (OFString* []){@"wz", nil}, 0, 0, NULL, nil, @"application/x-wingz"},
	{1, (OFString* []){@"hlp", nil}, 0, 0, NULL, nil, @"application/x-winhelp"},
	{1, (OFString* []){@"wtk", nil}, 0, 0, NULL, nil, @"application/x-wintalk"},
	{2, (OFString* []){@"svr", @"wrl", nil}, 0, 0, NULL, nil, @"application/x-world"},
	{1, (OFString* []){@"wpd", nil}, 0, 0, NULL, nil, @"application/x-wpwin"},
	{1, (OFString* []){@"wri", nil}, 0, 0, NULL, nil, @"application/x-wri"},
	{3, (OFString* []){@"der", @"cer", @"crt", nil}, 0, 0, NULL, nil, @"application/x-x509-ca-cert"},
	{1, (OFString* []){@"crt", nil}, 0, 0, NULL, nil, @"application/x-x509-user-cert"},
	{1, (OFString* []){@"xcf", nil}, 0, 0, NULL, nil, @"application/x-xcf"},
	{1, (OFString* []){@"fig", nil}, 0, 0, NULL, nil, @"application/x-xfig"},
	{1, (OFString* []){@"xlf", nil}, 0, 0, NULL, nil, @"application/x-xliff+xml"},
	{1, (OFString* []){@"xpi", nil}, 0, 0, NULL, nil, @"application/x-xpinstall"},
	{1, (OFString* []){@"xz", nil}, 0, 0, NULL, nil, @"application/x-xz"},
	{1, (OFString* []){@"zip", nil}, 0, 0, NULL, nil, @"application/x-zip-compressed"},
	{8, (OFString* []){@"z1", @"z2", @"z3", @"z4", @"z5", @"z6", @"z7", @"z8", nil}, 0, 0, NULL, nil, @"application/x-zmachine"},
	{1, (OFString* []){@"xaml", nil}, 0, 0, NULL, nil, @"application/xaml+xml"},
	{1, (OFString* []){@"xdf", nil}, 0, 0, NULL, nil, @"application/xcap-diff+xml"},
	{1, (OFString* []){@"xenc", nil}, 0, 0, NULL, nil, @"application/xenc+xml"},
	{2, (OFString* []){@"xhtml", @"xht", nil}, 0, 0, NULL, nil, @"application/xhtml+xml"},
	{3, (OFString* []){@"xml", @"xsl", @"xpdl", nil}, 0, 0, NULL, nil, @"application/xml"},
	{1, (OFString* []){@"dtd", nil}, 0, 0, NULL, nil, @"application/xml-dtd"},
	{1, (OFString* []){@"xop", nil}, 0, 0, NULL, nil, @"application/xop+xml"},
	{1, (OFString* []){@"xpl", nil}, 0, 0, NULL, nil, @"application/xproc+xml"},
	{1, (OFString* []){@"xslt", nil}, 0, 0, NULL, nil, @"application/xslt+xml"},
	{1, (OFString* []){@"xspf", nil}, 0, 0, NULL, nil, @"application/xspf+xml"},
	{4, (OFString* []){@"mxml", @"xhvml", @"xvml", @"xvm", nil}, 0, 0, NULL, nil, @"application/xv+xml"},
	{1, (OFString* []){@"yang", nil}, 0, 0, NULL, nil, @"application/yang"},
	{1, (OFString* []){@"yin", nil}, 0, 0, NULL, nil, @"application/yin+xml"},
	{1, (OFString* []){@"pko", nil}, 0, 0, NULL, nil, @"application/ynd.ms-pkipko"},
	{1, (OFString* []){@"zip", nil}, 0, 0, NULL, nil, @"application/zip"},
	{1, (OFString* []){@"adp", nil}, 0, 0, NULL, nil, @"audio/adpcm"},
	{3, (OFString* []){@"aif", @"aifc", @"aiff", nil}, 0, 0, NULL, nil, @"audio/aiff"},
	{2, (OFString* []){@"au", @"snd", nil}, 0, 0, NULL, nil, @"audio/basic"},
	{1, (OFString* []){@"flac", nil}, 0, 0, NULL, nil, @"audio/flac"},
	{1, (OFString* []){@"it", nil}, 0, 0, NULL, nil, @"audio/it"},
	{3, (OFString* []){@"funk", @"my", @"pfunk", nil}, 0, 0, NULL, nil, @"audio/make"},
	{1, (OFString* []){@"pfunk", nil}, 0, 0, NULL, nil, @"audio/make.my.funk"},
	{2, (OFString* []){@"rmi", @"mid", nil}, 0, 0, NULL, nil, @"audio/mid"},
	{4, (OFString* []){@"mid", @"midi", @"kar", @"rmi", nil}, 0, 0, NULL, nil, @"audio/midi"},
	{1, (OFString* []){@"mod", nil}, 0, 0, NULL, nil, @"audio/mod"},
	{2, (OFString* []){@"mp4a", @"m4a", nil}, 0, 0, NULL, nil, @"audio/mp4"},
	{10, (OFString* []){@"mpga", @"mp2", @"mp2a", @"mp3", @"m2a", @"mpa", @"mpg", @"m3a", @"mpega", @"m4a", nil}, 0, 0, NULL, nil, @"audio/mpeg"},
	{1, (OFString* []){@"mp3", nil}, 0, 0, NULL, nil, @"audio/mpeg3"},
	{1, (OFString* []){@"m3u", nil}, 0, 0, NULL, nil, @"audio/mpegurl"},
	{2, (OFString* []){@"la", @"lma", nil}, 0, 0, NULL, nil, @"audio/nspaudio"},
	{3, (OFString* []){@"oga", @"ogg", @"spx", nil}, 0, 0, NULL, nil, @"audio/ogg"},
	{1, (OFString* []){@"sid", nil}, 0, 0, NULL, nil, @"audio/prs.sid"},
	{1, (OFString* []){@"s3m", nil}, 0, 0, NULL, nil, @"audio/s3m"},
	{1, (OFString* []){@"sil", nil}, 0, 0, NULL, nil, @"audio/silk"},
	{1, (OFString* []){@"tsi", nil}, 0, 0, NULL, nil, @"audio/tsp-audio"},
	{1, (OFString* []){@"tsp", nil}, 0, 0, NULL, nil, @"audio/tsplayer"},
	{2, (OFString* []){@"uva", @"uvva", nil}, 0, 0, NULL, nil, @"audio/vnd.dece.audio"},
	{1, (OFString* []){@"eol", nil}, 0, 0, NULL, nil, @"audio/vnd.digital-winds"},
	{1, (OFString* []){@"dra", nil}, 0, 0, NULL, nil, @"audio/vnd.dra"},
	{1, (OFString* []){@"dts", nil}, 0, 0, NULL, nil, @"audio/vnd.dts"},
	{1, (OFString* []){@"dtshd", nil}, 0, 0, NULL, nil, @"audio/vnd.dts.hd"},
	{1, (OFString* []){@"lvp", nil}, 0, 0, NULL, nil, @"audio/vnd.lucent.voice"},
	{1, (OFString* []){@"pya", nil}, 0, 0, NULL, nil, @"audio/vnd.ms-playready.media.pya"},
	{1, (OFString* []){@"ecelp4800", nil}, 0, 0, NULL, nil, @"audio/vnd.nuera.ecelp4800"},
	{1, (OFString* []){@"ecelp7470", nil}, 0, 0, NULL, nil, @"audio/vnd.nuera.ecelp7470"},
	{1, (OFString* []){@"ecelp9600", nil}, 0, 0, NULL, nil, @"audio/vnd.nuera.ecelp9600"},
	{1, (OFString* []){@"qcp", nil}, 0, 0, NULL, nil, @"audio/vnd.qcelp"},
	{1, (OFString* []){@"rip", nil}, 0, 0, NULL, nil, @"audio/vnd.rip"},
	{1, (OFString* []){@"voc", nil}, 0, 0, NULL, nil, @"audio/voc"},
	{1, (OFString* []){@"vox", nil}, 0, 0, NULL, nil, @"audio/voxware"},
	{1, (OFString* []){@"wav", nil}, 0, 0, NULL, nil, @"audio/wav"},
	{1, (OFString* []){@"weba", nil}, 0, 0, NULL, nil, @"audio/webm"},
	{1, (OFString* []){@"aac", nil}, 0, 0, NULL, nil, @"audio/x-aac"},
	{1, (OFString* []){@"snd", nil}, 0, 0, NULL, nil, @"audio/x-adpcm"},
	{3, (OFString* []){@"aif", @"aiff", @"aifc", nil}, 0, 0, NULL, nil, @"audio/x-aiff"},
	{1, (OFString* []){@"au", nil}, 0, 0, NULL, nil, @"audio/x-au"},
	{1, (OFString* []){@"caf", nil}, 0, 0, NULL, nil, @"audio/x-caf"},
	{1, (OFString* []){@"flac", nil}, 0, 0, NULL, nil, @"audio/x-flac"},
	{2, (OFString* []){@"gsd", @"gsm", nil}, 0, 0, NULL, nil, @"audio/x-gsm"},
	{1, (OFString* []){@"jam", nil}, 0, 0, NULL, nil, @"audio/x-jam"},
	{1, (OFString* []){@"lam", nil}, 0, 0, NULL, nil, @"audio/x-liveaudio"},
	{1, (OFString* []){@"mka", nil}, 0, 0, NULL, nil, @"audio/x-matroska"},
	{2, (OFString* []){@"mid", @"midi", nil}, 0, 0, NULL, nil, @"audio/x-mid"},
	{2, (OFString* []){@"mid", @"midi", nil}, 0, 0, NULL, nil, @"audio/x-midi"},
	{1, (OFString* []){@"mod", nil}, 0, 0, NULL, nil, @"audio/x-mod"},
	{1, (OFString* []){@"mp2", nil}, 0, 0, NULL, nil, @"audio/x-mpeg"},
	{1, (OFString* []){@"mp3", nil}, 0, 0, NULL, nil, @"audio/x-mpeg-3"},
	{1, (OFString* []){@"m3u", nil}, 0, 0, NULL, nil, @"audio/x-mpegurl"},
	{1, (OFString* []){@"m3u", nil}, 0, 0, NULL, nil, @"audio/x-mpequrl"},
	{1, (OFString* []){@"wax", nil}, 0, 0, NULL, nil, @"audio/x-ms-wax"},
	{1, (OFString* []){@"wma", nil}, 0, 0, NULL, nil, @"audio/x-ms-wma"},
	{2, (OFString* []){@"la", @"lma", nil}, 0, 0, NULL, nil, @"audio/x-nspaudio"},
	{5, (OFString* []){@"ram", @"ra", @"rm", @"rmm", @"rmp", nil}, 0, 0, NULL, nil, @"audio/x-pn-realaudio"},
	{3, (OFString* []){@"rmp", @"ra", @"rpm", nil}, 0, 0, NULL, nil, @"audio/x-pn-realaudio-plugin"},
	{1, (OFString* []){@"sid", nil}, 0, 0, NULL, nil, @"audio/x-psid"},
	{1, (OFString* []){@"ra", nil}, 0, 0, NULL, nil, @"audio/x-realaudio"},
	{1, (OFString* []){@"pls", nil}, 0, 0, NULL, nil, @"audio/x-scpls"},
	{1, (OFString* []){@"sd2", nil}, 0, 0, NULL, nil, @"audio/x-sd2"},
	{1, (OFString* []){@"vqf", nil}, 0, 0, NULL, nil, @"audio/x-twinvq"},
	{2, (OFString* []){@"vqe", @"vql", nil}, 0, 0, NULL, nil, @"audio/x-twinvq-plugin"},
	{1, (OFString* []){@"mjf", nil}, 0, 0, NULL, nil, @"audio/x-vnd.audioexplosion.mjuicemediafile"},
	{1, (OFString* []){@"voc", nil}, 0, 0, NULL, nil, @"audio/x-voc"},
	{1, (OFString* []){@"wav", nil}, 0, 0, NULL, nil, @"audio/x-wav"},
	{1, (OFString* []){@"xm", nil}, 0, 0, NULL, nil, @"audio/xm"},
	{1, (OFString* []){@"cdx", nil}, 0, 0, NULL, nil, @"chemical/x-cdx"},
	{1, (OFString* []){@"cif", nil}, 0, 0, NULL, nil, @"chemical/x-cif"},
	{1, (OFString* []){@"cmdf", nil}, 0, 0, NULL, nil, @"chemical/x-cmdf"},
	{1, (OFString* []){@"cml", nil}, 0, 0, NULL, nil, @"chemical/x-cml"},
	{1, (OFString* []){@"csml", nil}, 0, 0, NULL, nil, @"chemical/x-csml"},
	{2, (OFString* []){@"pdb", @"xyz", nil}, 0, 0, NULL, nil, @"chemical/x-pdb"},
	{1, (OFString* []){@"xyz", nil}, 0, 0, NULL, nil, @"chemical/x-xyz"},
	{1, (OFString* []){@"dwf", nil}, 0, 0, NULL, nil, @"drawing/x-dwf"},
	{1, (OFString* []){@"dwf", nil}, 0, 0, NULL, nil, @"drawing/x-dwf(old)"},
	{1, (OFString* []){@"otf", nil}, 0, 0, NULL, nil, @"font/opentype"},
	{1, (OFString* []){@"ivr", nil}, 0, 0, NULL, nil, @"i-world/i-vrml"},
	{2, (OFString* []){@"bmp", @"bm", nil}, 0, 0, NULL, nil, @"image/bmp"},
	{1, (OFString* []){@"cgm", nil}, 0, 0, NULL, nil, @"image/cgm"},
	{1, (OFString* []){@"cod", nil}, 0, 0, NULL, nil, @"image/cis-cod"},
	{2, (OFString* []){@"ras", @"rast", nil}, 0, 0, NULL, nil, @"image/cmu-raster"},
	{1, (OFString* []){@"fif", nil}, 0, 0, NULL, nil, @"image/fif"},
	{2, (OFString* []){@"flo", @"turbot", nil}, 0, 0, NULL, nil, @"image/florian"},
	{1, (OFString* []){@"g3", nil}, 0, 0, NULL, nil, @"image/g3fax"},
	{1, (OFString* []){@"gif", nil}, 0, 0, NULL, nil, @"image/gif"},
	{2, (OFString* []){@"ief", @"iefs", nil}, 0, 0, NULL, nil, @"image/ief"},
	{5, (OFString* []){@"jpeg", @"jpg", @"jfif", @"jfif-tbnl", @"jpe", nil}, 0, 0, NULL, nil, @"image/jpeg"},
	{1, (OFString* []){@"jut", nil}, 0, 0, NULL, nil, @"image/jutvision"},
	{1, (OFString* []){@"ktx", nil}, 0, 0, NULL, nil, @"image/ktx"},
	{2, (OFString* []){@"nap", @"naplps", nil}, 0, 0, NULL, nil, @"image/naplps"},
	{1, (OFString* []){@"pcx", nil}, 0, 0, NULL, nil, @"image/pcx"},
	{2, (OFString* []){@"pic", @"pict", nil}, 0, 0, NULL, nil, @"image/pict"},
	{1, (OFString* []){@"jfif", nil}, 0, 0, NULL, nil, @"image/pipeg"},
	{4, (OFString* []){@"jfif", @"jpe", @"jpeg", @"jpg", nil}, 0, 0, NULL, nil, @"image/pjpeg"},
	{2, (OFString* []){@"png", @"x-png", nil}, 0, 0, NULL, nil, @"image/png"},
	{1, (OFString* []){@"btif", nil}, 0, 0, NULL, nil, @"image/prs.btif"},
	{1, (OFString* []){@"sgi", nil}, 0, 0, NULL, nil, @"image/sgi"},
	{2, (OFString* []){@"svg", @"svgz", nil}, 0, 0, NULL, nil, @"image/svg+xml"},
	{2, (OFString* []){@"tiff", @"tif", nil}, 0, 0, NULL, nil, @"image/tiff"},
	{1, (OFString* []){@"mcf", nil}, 0, 0, NULL, nil, @"image/vasa"},
	{1, (OFString* []){@"psd", nil}, 0, 0, NULL, nil, @"image/vnd.adobe.photoshop"},
	{4, (OFString* []){@"uvi", @"uvvi", @"uvg", @"uvvg", nil}, 0, 0, NULL, nil, @"image/vnd.dece.graphic"},
	{2, (OFString* []){@"djvu", @"djv", nil}, 0, 0, NULL, nil, @"image/vnd.djvu"},
	{1, (OFString* []){@"sub", nil}, 0, 0, NULL, nil, @"image/vnd.dvb.subtitle"},
	{3, (OFString* []){@"dwg", @"dxf", @"svf", nil}, 0, 0, NULL, nil, @"image/vnd.dwg"},
	{1, (OFString* []){@"dxf", nil}, 0, 0, NULL, nil, @"image/vnd.dxf"},
	{1, (OFString* []){@"fbs", nil}, 0, 0, NULL, nil, @"image/vnd.fastbidsheet"},
	{2, (OFString* []){@"fpx", @"fpix", nil}, 0, 0, NULL, nil, @"image/vnd.fpx"},
	{1, (OFString* []){@"fst", nil}, 0, 0, NULL, nil, @"image/vnd.fst"},
	{1, (OFString* []){@"mmr", nil}, 0, 0, NULL, nil, @"image/vnd.fujixerox.edmics-mmr"},
	{1, (OFString* []){@"rlc", nil}, 0, 0, NULL, nil, @"image/vnd.fujixerox.edmics-rlc"},
	{1, (OFString* []){@"mdi", nil}, 0, 0, NULL, nil, @"image/vnd.ms-modi"},
	{1, (OFString* []){@"wdp", nil}, 0, 0, NULL, nil, @"image/vnd.ms-photo"},
	{2, (OFString* []){@"npx", @"fpx", nil}, 0, 0, NULL, nil, @"image/vnd.net-fpx"},
	{1, (OFString* []){@"rf", nil}, 0, 0, NULL, nil, @"image/vnd.rn-realflash"},
	{1, (OFString* []){@"rp", nil}, 0, 0, NULL, nil, @"image/vnd.rn-realpix"},
	{1, (OFString* []){@"wbmp", nil}, 0, 0, NULL, nil, @"image/vnd.wap.wbmp"},
	{1, (OFString* []){@"xif", nil}, 0, 0, NULL, nil, @"image/vnd.xiff"},
	{1, (OFString* []){@"webp", nil}, 0, 0, NULL, nil, @"image/webp"},
	{1, (OFString* []){@"3ds", nil}, 0, 0, NULL, nil, @"image/x-3ds"},
	{1, (OFString* []){@"ras", nil}, 0, 0, NULL, nil, @"image/x-cmu-rast"},
	{1, (OFString* []){@"ras", nil}, 0, 0, NULL, nil, @"image/x-cmu-raster"},
	{1, (OFString* []){@"cmx", nil}, 0, 0, NULL, nil, @"image/x-cmx"},
	{1, (OFString* []){@"cdr", nil}, 0, 0, NULL, nil, @"image/x-coreldraw"},
	{1, (OFString* []){@"pat", nil}, 0, 0, NULL, nil, @"image/x-coreldrawpattern"},
	{1, (OFString* []){@"cdt", nil}, 0, 0, NULL, nil, @"image/x-coreldrawtemplate"},
	{1, (OFString* []){@"cpt", nil}, 0, 0, NULL, nil, @"image/x-corelphotopaint"},
	{3, (OFString* []){@"dwg", @"dxf", @"svf", nil}, 0, 0, NULL, nil, @"image/x-dwg"},
	{5, (OFString* []){@"fh", @"fhc", @"fh4", @"fh5", @"fh7", nil}, 0, 0, NULL, nil, @"image/x-freehand"},
	{1, (OFString* []){@"ico", nil}, 0, 0, NULL, nil, @"image/x-icon"},
	{1, (OFString* []){@"art", nil}, 0, 0, NULL, nil, @"image/x-jg"},
	{1, (OFString* []){@"jng", nil}, 0, 0, NULL, nil, @"image/x-jng"},
	{1, (OFString* []){@"jps", nil}, 0, 0, NULL, nil, @"image/x-jps"},
	{1, (OFString* []){@"sid", nil}, 0, 0, NULL, nil, @"image/x-mrsid-image"},
	{1, (OFString* []){@"bmp", nil}, 0, 0, NULL, nil, @"image/x-ms-bmp"},
	{2, (OFString* []){@"nif", @"niff", nil}, 0, 0, NULL, nil, @"image/x-niff"},
	{1, (OFString* []){@"pcx", nil}, 0, 0, NULL, nil, @"image/x-pcx"},
	{1, (OFString* []){@"psd", nil}, 0, 0, NULL, nil, @"image/x-photoshop"},
	{2, (OFString* []){@"pic", @"pct", nil}, 0, 0, NULL, nil, @"image/x-pict"},
	{1, (OFString* []){@"pnm", nil}, 0, 0, NULL, nil, @"image/x-portable-anymap"},
	{1, (OFString* []){@"pbm", nil}, 0, 0, NULL, nil, @"image/x-portable-bitmap"},
	{1, (OFString* []){@"pgm", nil}, 0, 0, NULL, nil, @"image/x-portable-graymap"},
	{1, (OFString* []){@"pgm", nil}, 0, 0, NULL, nil, @"image/x-portable-greymap"},
	{1, (OFString* []){@"ppm", nil}, 0, 0, NULL, nil, @"image/x-portable-pixmap"},
	{3, (OFString* []){@"qif", @"qti", @"qtif", nil}, 0, 0, NULL, nil, @"image/x-quicktime"},
	{1, (OFString* []){@"rgb", nil}, 0, 0, NULL, nil, @"image/x-rgb"},
	{1, (OFString* []){@"tga", nil}, 0, 0, NULL, nil, @"image/x-tga"},
	{2, (OFString* []){@"tif", @"tiff", nil}, 0, 0, NULL, nil, @"image/x-tiff"},
	{1, (OFString* []){@"bmp", nil}, 0, 0, NULL, nil, @"image/x-windows-bmp"},
	{2, (OFString* []){@"xbm", @"xpm", nil}, 0, 0, NULL, nil, @"image/x-xbitmap"},
	{1, (OFString* []){@"xbm", nil}, 0, 0, NULL, nil, @"image/x-xbm"},
	{2, (OFString* []){@"xpm", @"pm", nil}, 0, 0, NULL, nil, @"image/x-xpixmap"},
	{1, (OFString* []){@"xwd", nil}, 0, 0, NULL, nil, @"image/x-xwd"},
	{1, (OFString* []){@"xwd", nil}, 0, 0, NULL, nil, @"image/x-xwindowdump"},
	{1, (OFString* []){@"xbm", nil}, 0, 0, NULL, nil, @"image/xbm"},
	{1, (OFString* []){@"xpm", nil}, 0, 0, NULL, nil, @"image/xpm"},
	{5, (OFString* []){@"eml", @"mht", @"mhtml", @"mime", @"nws", nil}, 0, 0, NULL, nil, @"message/rfc822"},
	{2, (OFString* []){@"igs", @"iges", nil}, 0, 0, NULL, nil, @"model/iges"},
	{3, (OFString* []){@"msh", @"mesh", @"silo", nil}, 0, 0, NULL, nil, @"model/mesh"},
	{1, (OFString* []){@"dae", nil}, 0, 0, NULL, nil, @"model/vnd.collada+xml"},
	{1, (OFString* []){@"dwf", nil}, 0, 0, NULL, nil, @"model/vnd.dwf"},
	{1, (OFString* []){@"gdl", nil}, 0, 0, NULL, nil, @"model/vnd.gdl"},
	{1, (OFString* []){@"gtw", nil}, 0, 0, NULL, nil, @"model/vnd.gtw"},
	{1, (OFString* []){@"mts", nil}, 0, 0, NULL, nil, @"model/vnd.mts"},
	{1, (OFString* []){@"vtu", nil}, 0, 0, NULL, nil, @"model/vnd.vtu"},
	{3, (OFString* []){@"wrl", @"vrml", @"wrz", nil}, 0, 0, NULL, nil, @"model/vrml"},
	{1, (OFString* []){@"pov", nil}, 0, 0, NULL, nil, @"model/x-pov"},
	{2, (OFString* []){@"x3db", @"x3dbz", nil}, 0, 0, NULL, nil, @"model/x3d+binary"},
	{2, (OFString* []){@"x3dv", @"x3dvz", nil}, 0, 0, NULL, nil, @"model/x3d+vrml"},
	{2, (OFString* []){@"x3d", @"x3dz", nil}, 0, 0, NULL, nil, @"model/x3d+xml"},
	{1, (OFString* []){@"gzip", nil}, 0, 0, NULL, nil, @"multipart/x-gzip"},
	{1, (OFString* []){@"ustar", nil}, 0, 0, NULL, nil, @"multipart/x-ustar"},
	{1, (OFString* []){@"zip", nil}, 0, 0, NULL, nil, @"multipart/x-zip"},
	{2, (OFString* []){@"mid", @"midi", nil}, 0, 0, NULL, nil, @"music/crescendo"},
	{1, (OFString* []){@"kar", nil}, 0, 0, NULL, nil, @"music/x-karaoke"},
	{1, (OFString* []){@"pvu", nil}, 0, 0, NULL, nil, @"paleovu/x-pv"},
	{1, (OFString* []){@"asp", nil}, 0, 0, NULL, nil, @"text/asp"},
	{2, (OFString* []){@"appcache", @"manifest", nil}, 0, 0, NULL, nil, @"text/cache-manifest"},
	{3, (OFString* []){@"ics", @"ifb", @"icz", nil}, 0, 0, NULL, nil, @"text/calendar"},
	{1, (OFString* []){@"csv", nil}, 0, 0, NULL, nil, @"text/comma-separated-values"},
	{1, (OFString* []){@"css", nil}, 0, 0, NULL, nil, @"text/css"},
	{1, (OFString* []){@"csv", nil}, 0, 0, NULL, nil, @"text/csv"},
	{1, (OFString* []){@"js", nil}, 0, 0, NULL, nil, @"text/ecmascript"},
	{1, (OFString* []){@"event-stream", nil}, 0, 0, NULL, nil, @"text/event-stream"},
	{1, (OFString* []){@"323", nil}, 0, 0, NULL, nil, @"text/h323"},
	{7, (OFString* []){@"html", @"acgi", @"htm", @"htmls", @"htx", @"shtml", @"stm", nil}, 0, 0, NULL, nil, @"text/html"},
	{1, (OFString* []){@"uls", nil}, 0, 0, NULL, nil, @"text/iuls"},
	{1, (OFString* []){@"js", nil}, 0, 0, NULL, nil, @"text/javascript"},
	{1, (OFString* []){@"mml", nil}, 0, 0, NULL, nil, @"text/mathml"},
	{1, (OFString* []){@"mcf", nil}, 0, 0, NULL, nil, @"text/mcf"},
	{1, (OFString* []){@"n3", nil}, 0, 0, NULL, nil, @"text/n3"},
	{1, (OFString* []){@"pas", nil}, 0, 0, NULL, nil, @"text/pascal"},
	{32, (OFString* []){@"txt", @"text", @"conf", @"def", @"list", @"log", @"c", @"c++", @"cc", @"com", @"cxx", @"f", @"f90", @"for", @"g", @"h", @"hh", @"idc", @"jav", @"java", @"lst", @"m", @"mar", @"pl", @"sdml", @"bas", @"in", @"asc", @"diff", @"pot", @"el", @"ksh", nil}, 0, 0, NULL, nil, @"text/plain"},
	{1, (OFString* []){@"par", nil}, 0, 0, NULL, nil, @"text/plain-bas"},
	{1, (OFString* []){@"dsc", nil}, 0, 0, NULL, nil, @"text/prs.lines.tag"},
	{3, (OFString* []){@"rtx", @"rt", @"rtf", nil}, 0, 0, NULL, nil, @"text/richtext"},
	{1, (OFString* []){@"rtf", nil}, 0, 0, NULL, nil, @"text/rtf"},
	{1, (OFString* []){@"wsc", nil}, 0, 0, NULL, nil, @"text/scriplet"},
	{2, (OFString* []){@"sct", @"wsc", nil}, 0, 0, NULL, nil, @"text/scriptlet"},
	{2, (OFString* []){@"sgml", @"sgm", nil}, 0, 0, NULL, nil, @"text/sgml"},
	{1, (OFString* []){@"tsv", nil}, 0, 0, NULL, nil, @"text/tab-separated-values"},
	{2, (OFString* []){@"tm", @"ts", nil}, 0, 0, NULL, nil, @"text/texmacs"},
	{6, (OFString* []){@"t", @"tr", @"roff", @"man", @"me", @"ms", nil}, 0, 0, NULL, nil, @"text/troff"},
	{1, (OFString* []){@"ttl", nil}, 0, 0, NULL, nil, @"text/turtle"},
	{5, (OFString* []){@"uri", @"uris", @"uni", @"unis", @"urls", nil}, 0, 0, NULL, nil, @"text/uri-list"},
	{1, (OFString* []){@"vcard", nil}, 0, 0, NULL, nil, @"text/vcard"},
	{1, (OFString* []){@"abc", nil}, 0, 0, NULL, nil, @"text/vnd.abc"},
	{1, (OFString* []){@"curl", nil}, 0, 0, NULL, nil, @"text/vnd.curl"},
	{1, (OFString* []){@"dcurl", nil}, 0, 0, NULL, nil, @"text/vnd.curl.dcurl"},
	{1, (OFString* []){@"mcurl", nil}, 0, 0, NULL, nil, @"text/vnd.curl.mcurl"},
	{1, (OFString* []){@"scurl", nil}, 0, 0, NULL, nil, @"text/vnd.curl.scurl"},
	{1, (OFString* []){@"sub", nil}, 0, 0, NULL, nil, @"text/vnd.dvb.subtitle"},
	{1, (OFString* []){@"fly", nil}, 0, 0, NULL, nil, @"text/vnd.fly"},
	{1, (OFString* []){@"flx", nil}, 0, 0, NULL, nil, @"text/vnd.fmi.flexstor"},
	{1, (OFString* []){@"gv", nil}, 0, 0, NULL, nil, @"text/vnd.graphviz"},
	{1, (OFString* []){@"3dml", nil}, 0, 0, NULL, nil, @"text/vnd.in3d.3dml"},
	{1, (OFString* []){@"spot", nil}, 0, 0, NULL, nil, @"text/vnd.in3d.spot"},
	{1, (OFString* []){@"rt", nil}, 0, 0, NULL, nil, @"text/vnd.rn-realtext"},
	{1, (OFString* []){@"jad", nil}, 0, 0, NULL, nil, @"text/vnd.sun.j2me.app-descriptor"},
	{1, (OFString* []){@"si", nil}, 0, 0, NULL, nil, @"text/vnd.wap.si"},
	{1, (OFString* []){@"sl", nil}, 0, 0, NULL, nil, @"text/vnd.wap.sl"},
	{1, (OFString* []){@"wml", nil}, 0, 0, NULL, nil, @"text/vnd.wap.wml"},
	{1, (OFString* []){@"wmls", nil}, 0, 0, NULL, nil, @"text/vnd.wap.wmlscript"},
	{1, (OFString* []){@"vtt", nil}, 0, 0, NULL, nil, @"text/vtt"},
	{1, (OFString* []){@"htt", nil}, 0, 0, NULL, nil, @"text/webviewhtml"},
	{2, (OFString* []){@"s", @"asm", nil}, 0, 0, NULL, nil, @"text/x-asm"},
	{1, (OFString* []){@"aip", nil}, 0, 0, NULL, nil, @"text/x-audiosoft-intra"},
	{7, (OFString* []){@"c", @"cc", @"cxx", @"cpp", @"h", @"hh", @"dic", nil}, 0, 0, NULL, nil, @"text/x-c"},
	{4, (OFString* []){@"h++", @"hpp", @"hxx", @"hh", nil}, 0, 0, NULL, nil, @"text/x-c++hdr"},
	{4, (OFString* []){@"c++", @"cpp", @"cxx", @"cc", nil}, 0, 0, NULL, nil, @"text/x-c++src"},
	{1, (OFString* []){@"h", nil}, 0, 0, NULL, nil, @"text/x-chdr"},
	{1, (OFString* []){@"htc", nil}, 0, 0, NULL, nil, @"text/x-component"},
	{1, (OFString* []){@"csh", nil}, 0, 0, NULL, nil, @"text/x-csh"},
	{1, (OFString* []){@"c", nil}, 0, 0, NULL, nil, @"text/x-csrc"},
	{4, (OFString* []){@"f", @"for", @"f77", @"f90", nil}, 0, 0, NULL, nil, @"text/x-fortran"},
	{2, (OFString* []){@"h", @"hh", nil}, 0, 0, NULL, nil, @"text/x-h"},
	{1, (OFString* []){@"java", nil}, 0, 0, NULL, nil, @"text/x-java"},
	{2, (OFString* []){@"java", @"jav", nil}, 0, 0, NULL, nil, @"text/x-java-source"},
	{1, (OFString* []){@"lsx", nil}, 0, 0, NULL, nil, @"text/x-la-asf"},
	{1, (OFString* []){@"lua", nil}, 0, 0, NULL, nil, @"text/x-lua"},
	{1, (OFString* []){@"m", nil}, 0, 0, NULL, nil, @"text/x-m"},
	{3, (OFString* []){@"markdown", @"md", @"mkd", nil}, 0, 0, NULL, nil, @"text/x-markdown"},
	{1, (OFString* []){@"moc", nil}, 0, 0, NULL, nil, @"text/x-moc"},
	{1, (OFString* []){@"nfo", nil}, 0, 0, NULL, nil, @"text/x-nfo"},
	{1, (OFString* []){@"opml", nil}, 0, 0, NULL, nil, @"text/x-opml"},
	{2, (OFString* []){@"p", @"pas", nil}, 0, 0, NULL, nil, @"text/x-pascal"},
	{1, (OFString* []){@"gcd", nil}, 0, 0, NULL, nil, @"text/x-pcs-gcd"},
	{2, (OFString* []){@"pl", @"pm", nil}, 0, 0, NULL, nil, @"text/x-perl"},
	{1, (OFString* []){@"py", nil}, 0, 0, NULL, nil, @"text/x-python"},
	{1, (OFString* []){@"hlb", nil}, 0, 0, NULL, nil, @"text/x-script"},
	{1, (OFString* []){@"csh", nil}, 0, 0, NULL, nil, @"text/x-script.csh"},
	{1, (OFString* []){@"el", nil}, 0, 0, NULL, nil, @"text/x-script.elisp"},
	{1, (OFString* []){@"scm", nil}, 0, 0, NULL, nil, @"text/x-script.guile"},
	{1, (OFString* []){@"ksh", nil}, 0, 0, NULL, nil, @"text/x-script.ksh"},
	{1, (OFString* []){@"lsp", nil}, 0, 0, NULL, nil, @"text/x-script.lisp"},
	{1, (OFString* []){@"pl", nil}, 0, 0, NULL, nil, @"text/x-script.perl"},
	{1, (OFString* []){@"pm", nil}, 0, 0, NULL, nil, @"text/x-script.perl-module"},
	{1, (OFString* []){@"py", nil}, 0, 0, NULL, nil, @"text/x-script.phyton"},
	{1, (OFString* []){@"rexx", nil}, 0, 0, NULL, nil, @"text/x-script.rexx"},
	{1, (OFString* []){@"scm", nil}, 0, 0, NULL, nil, @"text/x-script.scheme"},
	{1, (OFString* []){@"sh", nil}, 0, 0, NULL, nil, @"text/x-script.sh"},
	{1, (OFString* []){@"tcl", nil}, 0, 0, NULL, nil, @"text/x-script.tcl"},
	{1, (OFString* []){@"tcsh", nil}, 0, 0, NULL, nil, @"text/x-script.tcsh"},
	{1, (OFString* []){@"zsh", nil}, 0, 0, NULL, nil, @"text/x-script.zsh"},
	{2, (OFString* []){@"shtml", @"ssi", nil}, 0, 0, NULL, nil, @"text/x-server-parsed-html"},
	{1, (OFString* []){@"etx", nil}, 0, 0, NULL, nil, @"text/x-setext"},
	{1, (OFString* []){@"sfv", nil}, 0, 0, NULL, nil, @"text/x-sfv"},
	{2, (OFString* []){@"sgm", @"sgml", nil}, 0, 0, NULL, nil, @"text/x-sgml"},
	{1, (OFString* []){@"sh", nil}, 0, 0, NULL, nil, @"text/x-sh"},
	{2, (OFString* []){@"spc", @"talk", nil}, 0, 0, NULL, nil, @"text/x-speech"},
	{2, (OFString* []){@"tcl", @"tk", nil}, 0, 0, NULL, nil, @"text/x-tcl"},
	{4, (OFString* []){@"tex", @"ltx", @"sty", @"cls", nil}, 0, 0, NULL, nil, @"text/x-tex"},
	{1, (OFString* []){@"uil", nil}, 0, 0, NULL, nil, @"text/x-uil"},
	{2, (OFString* []){@"uu", @"uue", nil}, 0, 0, NULL, nil, @"text/x-uuencode"},
	{1, (OFString* []){@"vcs", nil}, 0, 0, NULL, nil, @"text/x-vcalendar"},
	{1, (OFString* []){@"vcf", nil}, 0, 0, NULL, nil, @"text/x-vcard"},
	{1, (OFString* []){@"xml", nil}, 0, 0, NULL, nil, @"text/xml"},
	{1, (OFString* []){@"3gp", nil}, 0, 0, NULL, nil, @"video/3gpp"},
	{1, (OFString* []){@"3g2", nil}, 0, 0, NULL, nil, @"video/3gpp2"},
	{1, (OFString* []){@"ts", nil}, 0, 0, NULL, nil, @"video/MP2T"},
	{1, (OFString* []){@"afl", nil}, 0, 0, NULL, nil, @"video/animaflex"},
	{1, (OFString* []){@"avi", nil}, 0, 0, NULL, nil, @"video/avi"},
	{1, (OFString* []){@"avs", nil}, 0, 0, NULL, nil, @"video/avs-video"},
	{1, (OFString* []){@"dl", nil}, 0, 0, NULL, nil, @"video/dl"},
	{2, (OFString* []){@"flc", @"fli", nil}, 0, 0, NULL, nil, @"video/flc"},
	{2, (OFString* []){@"flc", @"fli", nil}, 0, 0, NULL, nil, @"video/fli"},
	{1, (OFString* []){@"gl", nil}, 0, 0, NULL, nil, @"video/gl"},
	{1, (OFString* []){@"h261", nil}, 0, 0, NULL, nil, @"video/h261"},
	{1, (OFString* []){@"h263", nil}, 0, 0, NULL, nil, @"video/h263"},
	{1, (OFString* []){@"h264", nil}, 0, 0, NULL, nil, @"video/h264"},
	{1, (OFString* []){@"jpgv", nil}, 0, 0, NULL, nil, @"video/jpeg"},
	{2, (OFString* []){@"jpm", @"jpgm", nil}, 0, 0, NULL, nil, @"video/jpm"},
	{2, (OFString* []){@"mj2", @"mjp2", nil}, 0, 0, NULL, nil, @"video/mj2"},
	{3, (OFString* []){@"mp4", @"mp4v", @"mpg4", nil}, 0, 0, NULL, nil, @"video/mp4"},
	{9, (OFString* []){@"mpeg", @"mpg", @"mpe", @"m1v", @"m2v", @"mp2", @"mp3", @"mpa", @"mpv2", nil}, 0, 0, NULL, nil, @"video/mpeg"},
	{1, (OFString* []){@"avi", nil}, 0, 0, NULL, nil, @"video/msvideo"},
	{1, (OFString* []){@"ogv", nil}, 0, 0, NULL, nil, @"video/ogg"},
	{3, (OFString* []){@"qt", @"moov", @"mov", nil}, 0, 0, NULL, nil, @"video/quicktime"},
	{1, (OFString* []){@"vdo", nil}, 0, 0, NULL, nil, @"video/vdo"},
	{2, (OFString* []){@"viv", @"vivo", nil}, 0, 0, NULL, nil, @"video/vivo"},
	{2, (OFString* []){@"uvh", @"uvvh", nil}, 0, 0, NULL, nil, @"video/vnd.dece.hd"},
	{2, (OFString* []){@"uvm", @"uvvm", nil}, 0, 0, NULL, nil, @"video/vnd.dece.mobile"},
	{2, (OFString* []){@"uvp", @"uvvp", nil}, 0, 0, NULL, nil, @"video/vnd.dece.pd"},
	{2, (OFString* []){@"uvs", @"uvvs", nil}, 0, 0, NULL, nil, @"video/vnd.dece.sd"},
	{2, (OFString* []){@"uvv", @"uvvv", nil}, 0, 0, NULL, nil, @"video/vnd.dece.video"},
	{1, (OFString* []){@"dvb", nil}, 0, 0, NULL, nil, @"video/vnd.dvb.file"},
	{1, (OFString* []){@"fvt", nil}, 0, 0, NULL, nil, @"video/vnd.fvt"},
	{2, (OFString* []){@"mxu", @"m4u", nil}, 0, 0, NULL, nil, @"video/vnd.mpegurl"},
	{1, (OFString* []){@"pyv", nil}, 0, 0, NULL, nil, @"video/vnd.ms-playready.media.pyv"},
	{1, (OFString* []){@"rv", nil}, 0, 0, NULL, nil, @"video/vnd.rn-realvideo"},
	{2, (OFString* []){@"uvu", @"uvvu", nil}, 0, 0, NULL, nil, @"video/vnd.uvvu.mp4"},
	{2, (OFString* []){@"viv", @"vivo", nil}, 0, 0, NULL, nil, @"video/vnd.vivo"},
	{1, (OFString* []){@"vos", nil}, 0, 0, NULL, nil, @"video/vosaic"},
	{1, (OFString* []){@"webm", nil}, 0, 0, NULL, nil, @"video/webm"},
	{1, (OFString* []){@"xdr", nil}, 0, 0, NULL, nil, @"video/x-amt-demorun"},
	{1, (OFString* []){@"xsr", nil}, 0, 0, NULL, nil, @"video/x-amt-showrun"},
	{1, (OFString* []){@"fmf", nil}, 0, 0, NULL, nil, @"video/x-atomic3d-feature"},
	{1, (OFString* []){@"dl", nil}, 0, 0, NULL, nil, @"video/x-dl"},
	{2, (OFString* []){@"dif", @"dv", nil}, 0, 0, NULL, nil, @"video/x-dv"},
	{1, (OFString* []){@"f4v", nil}, 0, 0, NULL, nil, @"video/x-f4v"},
	{1, (OFString* []){@"fli", nil}, 0, 0, NULL, nil, @"video/x-fli"},
	{1, (OFString* []){@"flv", nil}, 0, 0, NULL, nil, @"video/x-flv"},
	{1, (OFString* []){@"gl", nil}, 0, 0, NULL, nil, @"video/x-gl"},
	{1, (OFString* []){@"isu", nil}, 0, 0, NULL, nil, @"video/x-isvideo"},
	{2, (OFString* []){@"lsf", @"lsx", nil}, 0, 0, NULL, nil, @"video/x-la-asf"},
	{1, (OFString* []){@"m4v", nil}, 0, 0, NULL, nil, @"video/x-m4v"},
	{3, (OFString* []){@"mkv", @"mk3d", @"mks", nil}, 0, 0, NULL, nil, @"video/x-matroska"},
	{1, (OFString* []){@"mng", nil}, 0, 0, NULL, nil, @"video/x-mng"},
	{1, (OFString* []){@"mjpg", nil}, 0, 0, NULL, nil, @"video/x-motion-jpeg"},
	{2, (OFString* []){@"mp2", @"mp3", nil}, 0, 0, NULL, nil, @"video/x-mpeg"},
	{1, (OFString* []){@"mp2", nil}, 0, 0, NULL, nil, @"video/x-mpeq2a"},
	{3, (OFString* []){@"asf", @"asx", @"asr", nil}, 0, 0, NULL, nil, @"video/x-ms-asf"},
	{1, (OFString* []){@"asx", nil}, 0, 0, NULL, nil, @"video/x-ms-asf-plugin"},
	{1, (OFString* []){@"vob", nil}, 0, 0, NULL, nil, @"video/x-ms-vob"},
	{1, (OFString* []){@"wm", nil}, 0, 0, NULL, nil, @"video/x-ms-wm"},
	{1, (OFString* []){@"wmv", nil}, 0, 0, NULL, nil, @"video/x-ms-wmv"},
	{1, (OFString* []){@"wmx", nil}, 0, 0, NULL, nil, @"video/x-ms-wmx"},
	{1, (OFString* []){@"wvx", nil}, 0, 0, NULL, nil, @"video/x-ms-wvx"},
	{1, (OFString* []){@"avi", nil}, 0, 0, NULL, nil, @"video/x-msvideo"},
	{1, (OFString* []){@"qtc", nil}, 0, 0, NULL, nil, @"video/x-qtc"},
	{1, (OFString* []){@"scm", nil}, 0, 0, NULL, nil, @"video/x-scm"},
	{2, (OFString* []){@"movie", @"mv", nil}, 0, 0, NULL, nil, @"video/x-sgi-movie"},
	{1, (OFString* []){@"smv", nil}, 0, 0, NULL, nil, @"video/x-smv"},
	{1, (OFString* []){@"wmf", nil}, 0, 0, NULL, nil, @"windows/metafile"},
	{1, (OFString* []){@"mime", nil}, 0, 0, NULL, nil, @"www/mime"},
	{1, (OFString* []){@"ice", nil}, 0, 0, NULL, nil, @"x-conference/x-cooltalk"},
	{2, (OFString* []){@"mid", @"midi", nil}, 0, 0, NULL, nil, @"x-music/x-midi"},
	{4, (OFString* []){@"3dm", @"3dmf", @"qd3", @"qd3d", nil}, 0, 0, NULL, nil, @"x-world/x-3dmf"},
	{1, (OFString* []){@"svr", nil}, 0, 0, NULL, nil, @"x-world/x-svr"},
	{7, (OFString* []){@"vrml", @"wrl", @"wrz", @"flr", @"xaf", @"xof", @"vrm", nil}, 0, 0, NULL, nil, @"x-world/x-vrml"},
	{1, (OFString* []){@"vrt", nil}, 0, 0, NULL, nil, @"x-world/x-vrt"},
	{1, (OFString* []){@"xgz", nil}, 0, 0, NULL, nil, @"xgl/drawing"},
	{1, (OFString* []){@"xmz", nil}, 0, 0, NULL, nil, @"xgl/movie"},
	{0, NULL, 0, 0, NULL, nil, nil}
};

@interface OFWebServerFileInfo()

@property (nonatomic, copy, readwrite) OFString* fileDescription;
@property (nonatomic, copy, readwrite) OFString* extension;
@property (nonatomic, copy, readwrite) OFArray* altExtensions;
@property (nonatomic, copy, readwrite) OFString* mimeType;
@property (nonatomic, copy, readwrite) OFString* name;

@end

@implementation OFWebServerFileInfo

@synthesize fileDescription = _fileDescription;
@synthesize extension = _extension;
@synthesize altExtensions = _altExtensions;
@synthesize mimeType = _mimeType;
@synthesize name = _name;

+ (void)initialize 
{
	if ([self class] == [OFWebServerFileInfo class]) {
		_mimesCache = [[OFMutableDictionary alloc] init];
	}
}

- (instancetype)initWithInfoOfFile:(OFString *)path
{
	self = [super init];
	self.name = path.lastPathComponent;

	void* pool = objc_autoreleasePoolPush();

	OFNumber* index = nil;

	if ((index = [_mimesCache objectForKey:self.name.pathExtension.lowercaseString]) != nil) {

		fileInfo indexedInfo = _fileInfoWithMime[index.sizeValue];

		if (indexedInfo.mimeType != nil) {
			self.mimeType = indexedInfo.mimeType;
			self.extension = path.pathExtension.lowercaseString;
			self.altExtensions = [[OFArray arrayWithObjects:indexedInfo.extensions count:indexedInfo.extensionsCount] arrayByRemovingObject:self.extension];
			self.fileDescription = indexedInfo.description;

			objc_autoreleasePoolPop(pool);

			return self;
		}
	}

	@try {

		fileInfo* info = _fileInfoWithMime;

		while ((info->extensions != NULL) && (info->mimeType != nil)) {

			@autoreleasepool {
				
				for (size_t idx = 0; idx < info->extensionsCount; idx++) {
					if ((info->extensions[idx] != nil) && ([[path.pathExtension lowercaseString] isEqual:info->extensions[idx]])) {

						if (info->signLength == 0 || info->sign == NULL) {
							self.mimeType = info->mimeType;
							self.extension = path.pathExtension.lowercaseString;
							self.altExtensions = [[OFArray arrayWithObjects:info->extensions count:info->extensionsCount] arrayByRemovingObject:self.extension];
							self.fileDescription = info->description;

							[_mimesCache setObject:self.extension forKey:[OFNumber numberWithSize:idx]];

							break;
						}

						OFFile* file = [OFFile fileWithPath:path mode:@"rb"];

						uint8_t* header = (uint8_t *)__builtin_alloca(info->signLength);

						[file seekToOffset:info->offset whence:SEEK_SET];

						[file readIntoBuffer:header exactLength:info->signLength];

						if ((memcmp(header, info->sign, info->signLength)) == 0) {

							[file close];

							self.mimeType = info->mimeType;
							self.extension = path.pathExtension.lowercaseString;
							self.altExtensions = [[OFArray arrayWithObjects:info->extensions count:info->extensionsCount] arrayByRemovingObject:self.extension];
							self.fileDescription = info->description;

							break;

							[_mimesCache setObject:self.extension forKey:[OFNumber numberWithSize:idx]];

						}

						[file close];

					}

				}

				if (self.mimeType != nil)
					break;
			}

			info++;
		}

		if (self.mimeType == nil) {
			self.extension = path.pathExtension.lowercaseString;
			self.altExtensions = nil;
			self.fileDescription = nil;
			self.mimeType = @"application/octet-stream";
		}

	}@catch (...) {
		[self release];

		@throw [OFInitializationFailedException exceptionWithClass:[OFWebServerFileInfo class]];
	}

	return self;
}

+ (instancetype)fileInfo
{
	return [[[self alloc] init] autorelease];
}

+ (instancetype)infoForFile:(OFString *)path
{
	return [[[self alloc] initWithInfoOfFile:path] autorelease];
}

- (void)dealloc
{
	[_fileDescription release];
	[_extension release];
	[_altExtensions release];
	[_mimeType release];
	[_name release];

	[super dealloc];
}

- (OFString *)description 
{
	return [OFString stringWithFormat:@"<%@: %@ (%@) MimeType:%@>", self.className, self.name, self.fileDescription, self.mimeType];
}

@end