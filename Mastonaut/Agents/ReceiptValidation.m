//
//  BPReceiptValidation.m
//
//  Created by Satoshi Numata on 12/06/30.
//  Copyright (c) 2012 Sazameki and Satoshi Numata, Ph.D. All rights reserved.
//
//  This sample shows how to write the Mac App Store receipt validation code.
//  Replace kBPBundleID and kBPBundleVersion with your own ones.
//
//  This sample is provided because the coding sample found in "Validating Mac App Store Receipts"
//  is somehow out-of-date today and some functions are deprecated in Mac OS X 10.7.
//  (cf. Validating Mac App Store Receipts: )
//
//  You must want to make it much more robustness with some techniques, such as obfuscation
//  with your "own" way. If you use and share the same codes with your friends, attackers
//  will be able to make a special tool to patch application binaries so easily.
//  Again, this sample gives you the very basic idea that which APIs can be used for the validation.
//
//  Don't forget to add IOKit.framework and Security.framework to your project.
//  The main() function should be replaced with the (commented out) main() code at the bottom of this sample.
//  This sample assume that you are using Automatic Reference Counting for memory management.
//
//  Have a nice Cocoa flavor, guys!!
//

#import "ReceiptValidation.h"
#import "BundleVersions.h"
#import "GetMACAddress.h"

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import <CommonCrypto/CommonDigest.h>
#import <Security/CMSDecoder.h>
#import <Security/SecAsn1Coder.h>
#import <Security/SecAsn1Templates.h>
#import <Security/SecRequirement.h>

#import <IOKit/IOKitLib.h>

static NSString *kBPNBundleID = @"app.mastonaut.mac";
static NSString *kBPBundleVersion = @BUNDLE_VERSION;
static NSString *kBPPreviousPublicVersion = @"1.3.5";

typedef struct {
	size_t          length;
	unsigned char   *data;
} ASN1_Data;

typedef struct {
	ASN1_Data type;     // INTEGER
	ASN1_Data version;  // INTEGER
	ASN1_Data value;    // OCTET STRING
} OhOhReceiptAttribute;

typedef struct {
	OhOhReceiptAttribute **attrs;
} OhOhReceiptPayload;

// ASN.1 receipt attribute template
static const SecAsn1Template kReceiptAttributeTemplate[] = {
	{ SEC_ASN1_SEQUENCE, 0, NULL, sizeof(OhOhReceiptAttribute) },
	{ SEC_ASN1_INTEGER, offsetof(OhOhReceiptAttribute, type), NULL, 0 },
	{ SEC_ASN1_INTEGER, offsetof(OhOhReceiptAttribute, version), NULL, 0 },
	{ SEC_ASN1_OCTET_STRING, offsetof(OhOhReceiptAttribute, value), NULL, 0 },
	{ 0, 0, NULL, 0 }
};

// ASN.1 receipt template set
static const SecAsn1Template kSetOfReceiptAttributeTemplate[] = {
	{ SEC_ASN1_SET_OF, 0, kReceiptAttributeTemplate, sizeof(OhOhReceiptPayload) },
	{ 0, 0, NULL, 0 }
};


enum {
	kBPReceiptAttributeTypeBundleID                = 2,
	kBPReceiptAttributeTypeApplicationVersion      = 3,
	kBPReceiptAttributeTypeOpaqueValue             = 4,
	kBPReceiptAttributeTypeSHA1Hash                = 5,
	kBPReceiptAttributeTypeInAppPurchaseReceipt    = 17,

	kBPReceiptAttributeTypeInAppQuantity               = 1701,
	kBPReceiptAttributeTypeInAppProductID              = 1702,
	kBPReceiptAttributeTypeInAppTransactionID          = 1703,
	kBPReceiptAttributeTypeInAppPurchaseDate           = 1704,
	kBPReceiptAttributeTypeInAppOriginalTransactionID  = 1705,
	kBPReceiptAttributeTypeInAppOriginalPurchaseDate   = 1706,
};


static NSString *kBPReceiptInfoKeyBundleID                     = @"Bundle ID";
static NSString *kBPReceiptInfoKeyBundleIDData                 = @"Bundle ID Data";
static NSString *kBPReceiptInfoKeyApplicationVersion           = @"Application Version";
static NSString *kBPReceiptInfoKeyApplicationVersionData       = @"Application Version Data";
static NSString *kBPReceiptInfoKeyOpaqueValue                  = @"Opaque Value";
static NSString *kBPReceiptInfoKeySHA1Hash                     = @"SHA-1 Hash";
static NSString *kBPReceiptInfoKeyInAppPurchaseReceipt         = @"In App Purchase Receipt";

static NSString *kBPReceiptInfoKeyInAppProductID               = @"In App Product ID";
static NSString *kBPReceiptInfoKeyInAppTransactionID           = @"In App Transaction ID";
static NSString *kBPReceiptInfoKeyInAppOriginalTransactionID   = @"In App Original Transaction ID";
static NSString *kBPReceiptInfoKeyInAppPurchaseDate            = @"In App Purchase Date";
static NSString *kBPReceiptInfoKeyInAppOriginalPurchaseDate    = @"In App Original Purchase Date";
static NSString *kBPReceiptInfoKeyInAppQuantity                = @"In App Quantity";


inline static bool OhOhCheckBundleIDAndVersion(void)
{
	CFDictionaryRef bundleInfo = CFBundleGetInfoDictionary(CFBundleGetMainBundle());

	CFStringRef bundleID = CFDictionaryGetValue(bundleInfo, kCFBundleIdentifierKey);
	if (CFStringCompare(bundleID, (CFStringRef)kBPNBundleID, 0) != kCFCompareEqualTo) {
		return false;
	}

	CFStringRef bundleVersion = CFDictionaryGetValue(bundleInfo, CFSTR("CFBundleShortVersionString"));
	if (CFStringCompare(bundleVersion, (CFStringRef)kBPBundleVersion, 0) != kCFCompareEqualTo
		&& CFStringCompare(bundleVersion, (CFStringRef)kBPPreviousPublicVersion, 0) != kCFCompareEqualTo) {
		return false;
	}

	return true;
}

inline static bool OhOhCheckBundleSignature(void)
{
	CFURLRef bundleURL = CFBundleCopyBundleURL(CFBundleGetMainBundle());
	if (bundleURL == NULL) {
		return false;
	}

	SecStaticCodeRef staticCode = NULL;
	OSStatus status = SecStaticCodeCreateWithPath(bundleURL, kSecCSDefaultFlags, &staticCode);
	CFRelease(bundleURL);

	if (status != errSecSuccess) {
		return false;
	}

	CFStringRef requirementText = CFSTR("anchor apple generic");   // For code signed by Apple

	SecRequirementRef requirement = NULL;
	status = SecRequirementCreateWithString(requirementText, kSecCSDefaultFlags, &requirement);
	if (status != errSecSuccess) {
		if (staticCode) CFRelease(staticCode);
		return false;
	}

	status = SecStaticCodeCheckValidity(staticCode, kSecCSDefaultFlags, requirement);
	if (staticCode) CFRelease(staticCode);
	if (requirement) CFRelease(requirement);

	return status == errSecSuccess;
}

inline static CFDataRef OhOhCopyReceiptData(void)
{
	CFURLRef bundleURL = CFBundleCopyBundleURL(CFBundleGetMainBundle());
	if (bundleURL == NULL) {
		return NULL;
	}

	CFURLRef receiptURL = CFURLCreateCopyAppendingPathComponent(NULL, bundleURL,
																CFSTR("/Contents/_MASReceipt/receipt"),
																false);
	CFRelease(bundleURL);

	if (receiptURL == NULL) {
		return NULL;
	}

	CGDataProviderRef dataProvider = CGDataProviderCreateWithURL(receiptURL);
	if (receiptURL) CFRelease(receiptURL);

	if (dataProvider == NULL) {
		return NULL;
	}

	CFDataRef receiptData = CGDataProviderCopyData(dataProvider);
	if (dataProvider) CGDataProviderRelease(dataProvider);

	return receiptData;
}

inline static CFDataRef OhOhCopyDecodedReceiptData(CFDataRef receiptData)
{
	CMSDecoderRef decoder = NULL;
	SecPolicyRef policyRef = NULL;
	SecTrustRef trustRef = NULL;

	// Create a decoder
	OSStatus status = CMSDecoderCreate(&decoder);
	if (status) {
		return NULL;
	}

	// Decrypt the message (1)
	status = CMSDecoderUpdateMessage(decoder, CFDataGetBytePtr(receiptData), CFDataGetLength(receiptData));
	if (status) {
		CFRelease(decoder);
		return NULL;
	}

	// Decrypt the message (2)
	status = CMSDecoderFinalizeMessage(decoder);
	if (status) {
		CFRelease(decoder);
		return NULL;
	}

	// Get the decrypted content
	CFDataRef dataRef = NULL;
	status = CMSDecoderCopyContent(decoder, &dataRef);
	if (status) {
		CFRelease(decoder);
		return NULL;
	}

	// Check the signature
	size_t numSigners;
	status = CMSDecoderGetNumSigners(decoder, &numSigners);
	if (status) {
		CFRelease(decoder);
		return NULL;
	}
	if (numSigners == 0) {
		CFRelease(decoder);
		return NULL;
	}

	policyRef = SecPolicyCreateBasicX509();

	CMSSignerStatus signerStatus;
	OSStatus certVerifyResult;
	status = CMSDecoderCopySignerStatus(decoder, 0, policyRef, TRUE, &signerStatus, &trustRef, &certVerifyResult);
	if (status) {
		CFRelease(policyRef);
		CFRelease(decoder);
		return NULL;
	}
	if (signerStatus != kCMSSignerValid) {
		CFRelease(policyRef);
		CFRelease(decoder);
		CFRelease(trustRef);
		return NULL;
	}

	CFRelease(policyRef);
	CFRelease(trustRef);
	CFRelease(decoder);

	return dataRef;
}

inline static NSData *OhOhGetASN1RawData(ASN1_Data asn1Data)
{
	return [NSData dataWithBytes:asn1Data.data length:asn1Data.length];
}

inline static int OhOhGetIntValueFromASN1Data(const ASN1_Data *asn1Data)
{
	int ret = 0;
	for (int i = 0; i < asn1Data->length; i++) {
		ret = (ret << 8) | asn1Data->data[i];
	}
	return ret;
}

inline static NSNumber *OhOhDecodeIntNumberFromASN1Data(SecAsn1CoderRef decoder, ASN1_Data srcData)
{
	ASN1_Data asn1Data;
	OSStatus status = SecAsn1Decode(decoder, srcData.data, srcData.length, kSecAsn1IntegerTemplate, &asn1Data);
	if (status) {
		return nil;
	}
	return [NSNumber numberWithInt:OhOhGetIntValueFromASN1Data(&asn1Data)];
}

inline static NSString *OhOhDecodeUTF8StringFromASN1Data(SecAsn1CoderRef decoder, ASN1_Data srcData)
{
	ASN1_Data asn1Data;
	OSStatus status = SecAsn1Decode(decoder, srcData.data, srcData.length, kSecAsn1UTF8StringTemplate, &asn1Data);
	if (status) {
		return nil;
	}
	return [[NSString alloc] initWithBytes:asn1Data.data length:asn1Data.length encoding:NSUTF8StringEncoding];
}

inline static NSDate *OhOhDecodeDateFromASN1Data(SecAsn1CoderRef decoder, ASN1_Data srcData)
{
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy-MM-ddTHH:mm:ssZ"];
	[dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];

	ASN1_Data asn1Data;
	OSStatus status = SecAsn1Decode(decoder, srcData.data, srcData.length, kSecAsn1IA5StringTemplate, &asn1Data);
	if (status) {
		return nil;
	}

	NSString *dateStr = [[NSString alloc] initWithBytes:asn1Data.data length:asn1Data.length encoding:NSASCIIStringEncoding];
	return [dateFormatter dateFromString:dateStr];
}

inline static NSDictionary *OhOhGetReceiptPayload(CFDataRef payloadData)
{
	SecAsn1CoderRef asn1Decoder = NULL;

	@try {
		NSMutableDictionary *ret = [NSMutableDictionary dictionary];

		// Create the ASN.1 parser
		OSStatus status = SecAsn1CoderCreate(&asn1Decoder);
		if (status) {
			[NSException raise:@"MAS receipt validation error"
						format:@"Failed to create ASN1 decoder", nil];
		}

		// Decode the receipt payload
		OhOhReceiptPayload payload = { NULL };
		status = SecAsn1Decode(asn1Decoder, CFDataGetBytePtr(payloadData), CFDataGetLength(payloadData), kSetOfReceiptAttributeTemplate, &payload);
		if (status) {
			[NSException raise:@"MAS receipt validation error"
						format:@"Failed to decode receipt payload", nil];
		}

		// Fetch all attributes
		OhOhReceiptAttribute *anAttr;
		for (int i = 0; (anAttr = payload.attrs[i]); i++) {
			int type = OhOhGetIntValueFromASN1Data(&anAttr->type);
			switch (type) {
					// UTF-8 String
				case kBPReceiptAttributeTypeBundleID:
					[ret setValue:OhOhDecodeUTF8StringFromASN1Data(asn1Decoder, anAttr->value) forKey:kBPReceiptInfoKeyBundleID];
					[ret setValue:OhOhGetASN1RawData(anAttr->value) forKey:kBPReceiptInfoKeyBundleIDData];
					break;
				case kBPReceiptAttributeTypeApplicationVersion:
					[ret setValue:OhOhDecodeUTF8StringFromASN1Data(asn1Decoder, anAttr->value) forKey:kBPReceiptInfoKeyApplicationVersion];
					[ret setValue:OhOhGetASN1RawData(anAttr->value) forKey:kBPReceiptInfoKeyApplicationVersionData];
					break;
				case kBPReceiptAttributeTypeInAppProductID:
					[ret setValue:OhOhDecodeUTF8StringFromASN1Data(asn1Decoder, anAttr->value) forKey:kBPReceiptInfoKeyInAppProductID];
					break;
				case kBPReceiptAttributeTypeInAppTransactionID:
					[ret setValue:OhOhDecodeUTF8StringFromASN1Data(asn1Decoder, anAttr->value) forKey:kBPReceiptInfoKeyInAppTransactionID];
					break;
				case kBPReceiptAttributeTypeInAppOriginalTransactionID:
					[ret setValue:OhOhDecodeUTF8StringFromASN1Data(asn1Decoder, anAttr->value) forKey:kBPReceiptInfoKeyInAppOriginalTransactionID];
					break;

					// Purchase Date (As IA5 String (almost identical to the ASCII String))
				case kBPReceiptAttributeTypeInAppPurchaseDate:
					[ret setValue:OhOhDecodeDateFromASN1Data(asn1Decoder, anAttr->value) forKey:kBPReceiptInfoKeyInAppPurchaseDate];
					break;
				case kBPReceiptAttributeTypeInAppOriginalPurchaseDate:
					[ret setValue:OhOhDecodeDateFromASN1Data(asn1Decoder, anAttr->value) forKey:kBPReceiptInfoKeyInAppOriginalPurchaseDate];
					break;

					// Quantity (Integer Value)
				case kBPReceiptAttributeTypeInAppQuantity:
					[ret setValue:OhOhDecodeIntNumberFromASN1Data(asn1Decoder, anAttr->value)
						   forKey:kBPReceiptInfoKeyInAppQuantity];
					break;

					// Opaque Value (Octet Data)
				case kBPReceiptAttributeTypeOpaqueValue:
					[ret setValue:OhOhGetASN1RawData(anAttr->value) forKey:kBPReceiptInfoKeyOpaqueValue];
					break;

					// SHA-1 Hash (Octet Data)
				case kBPReceiptAttributeTypeSHA1Hash:
					[ret setValue:OhOhGetASN1RawData(anAttr->value) forKey:kBPReceiptInfoKeySHA1Hash];
					break;

					// In App Purchases Receipt
				case kBPReceiptAttributeTypeInAppPurchaseReceipt: {
					NSMutableArray *inAppPurchases = [ret valueForKey:kBPReceiptInfoKeyInAppPurchaseReceipt];
					if (!inAppPurchases) {
						inAppPurchases = [NSMutableArray array];
						[ret setValue:inAppPurchases forKey:kBPReceiptInfoKeyInAppPurchaseReceipt];
					}
					CFDataRef inAppData = CFDataCreate(NULL, anAttr->value.data, anAttr->value.length);
					NSDictionary *inAppInfo = OhOhGetReceiptPayload(inAppData);
					if (inAppData) CFRelease(inAppData);
					[inAppPurchases addObject:inAppInfo];
					break;
				}

					// Otherwise
				default:
					break;
			}
		}
		return ret;
	} @catch (NSException *e) {
		@throw e;
	} @finally {
		if (asn1Decoder) SecAsn1CoderRelease(asn1Decoder);
	}
}

inline static NSData *OhOhGetMacAddress(void)
{
	mach_port_t masterPort;
	kern_return_t result = IOMasterPort(MACH_PORT_NULL, &masterPort);
	if (result != KERN_SUCCESS) {
		return nil;
	}

	CFMutableDictionaryRef matchingDict = IOBSDNameMatching(masterPort, 0, "en0");
	if (!matchingDict) {
		return nil;
	}

	io_iterator_t iterator;
	result = IOServiceGetMatchingServices(masterPort, matchingDict, &iterator);
	if (result != KERN_SUCCESS) {
		return nil;
	}

	CFDataRef macAddressDataRef = nil;
	io_object_t aService;
	while ((aService = IOIteratorNext(iterator)) != 0) {
		io_object_t parentService;
		result = IORegistryEntryGetParentEntry(aService, kIOServicePlane, &parentService);
		if (result == KERN_SUCCESS) {
			if (macAddressDataRef) CFRelease(macAddressDataRef);
			macAddressDataRef = (CFDataRef)IORegistryEntryCreateCFProperty(parentService, (CFStringRef)@"IOMACAddress", kCFAllocatorDefault, 0);
			IOObjectRelease(parentService);
		}
		IOObjectRelease(aService);
	}
	IOObjectRelease(iterator);

	NSData *ret = nil;
	if (macAddressDataRef) {
		ret = [NSData dataWithData:(__bridge NSData *)macAddressDataRef];
		CFRelease(macAddressDataRef);
	}
	return ret;
}

inline static bool OhOhCheckReceiptIDAndVersion(NSDictionary *receiptInfo)
{
	NSString *bundleID = [receiptInfo valueForKey:kBPReceiptInfoKeyBundleID];
	if (![bundleID isEqualToString:kBPNBundleID]) {
		return false;
	}

	NSString *bundleVersion = [receiptInfo objectForKey:kBPReceiptInfoKeyApplicationVersion];
	if (![bundleVersion isEqualToString:kBPBundleVersion]
		&& ![bundleVersion isEqualToString:kBPPreviousPublicVersion]) {
		return false;
	}

	return true;
}

inline static bool OhOhCheckReceiptHash(NSDictionary *receiptInfo)
{
	NSData *macAddressData = GetMACAddressData();
	if (macAddressData == nil) {
		return false;
	}

	NSData *data2 = [receiptInfo valueForKey:kBPReceiptInfoKeyBundleIDData];
	NSData *data1 = [receiptInfo valueForKey:kBPReceiptInfoKeyOpaqueValue];

	NSMutableData *digestData = [NSMutableData dataWithData:macAddressData];
	[digestData appendData:data1];
	[digestData appendData:data2];

	unsigned char digestBuffer[CC_SHA1_DIGEST_LENGTH];
	CC_SHA1(digestData.bytes, (CC_LONG)digestData.length, digestBuffer);

	NSData *hashData = [receiptInfo valueForKey:kBPReceiptInfoKeySHA1Hash];

	return memcmp(digestBuffer, hashData.bytes, CC_SHA1_DIGEST_LENGTH) == 0;
}

int OhOhTakeTheMoneyAndRun(int argc, char *argv[])
{
	///// Check the bundle information
	if (OhOhCheckBundleIDAndVersion() == false) { exit(173); }
	if (OhOhCheckBundleSignature() == false) { exit(173); }

	///// Check the receipt information
	CFDataRef receiptData = OhOhCopyReceiptData();
	if (receiptData == nil) { exit(173); }

	CFDataRef receiptDataDecoded = OhOhCopyDecodedReceiptData(receiptData);
	if (receiptData) CFRelease(receiptData);
	if (receiptDataDecoded == nil) { exit(173); }

	NSDictionary *receiptInfo = OhOhGetReceiptPayload(receiptDataDecoded);
	if (receiptDataDecoded) CFRelease(receiptDataDecoded);
	if (receiptInfo == nil) { exit(173); }

	if (OhOhCheckReceiptIDAndVersion(receiptInfo) == false) { exit(173); }
	if (OhOhCheckReceiptHash(receiptInfo) == false) { exit(173); }

	return NSApplicationMain(argc, (const char **)argv);
}


int main(int argc, char *argv[])
{
	@autoreleasepool {
#ifdef DEBUG
		return NSApplicationMain(argc, (const char **)argv);
#else
		return OhOhTakeTheMoneyAndRun(argc, argv);
#endif
	}
}
