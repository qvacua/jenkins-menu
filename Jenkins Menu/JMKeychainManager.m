/**
 * Tae Won Ha
 * http://qvacua.com
 * https://github.com/qvacua
 *
 * See LICENSE
 */

#import "JMKeychainManager.h"

@implementation JMCredential

@synthesize username = _username;
@synthesize password = _password;

- (id)initWithUsername:(NSString *)username password:(NSString *)password {
    self = [super init];
    if (self) {
        self.username = username;
        self.password = password;
    }

    return self;
}

@end

@interface JMKeychainManager ()

@property (readwrite) NSString *lastErrorMessage;

@end

@implementation JMKeychainManager {
}

@synthesize lastErrorMessage = _lastErrorMessage;

- (JMCredential *)credentialForUrl:(NSURL *)url {
    NSString *host = url.host;
    NSString *path = url.path;

    UInt32 passwordLength = 0;
    void *passwordBuffer = NULL;
    SecKeychainItemRef keychainItem = NULL;
    OSStatus err = SecKeychainFindInternetPassword(
            NULL,                             // keychain, NULL == default one
            host.length, host.UTF8String,     // serverName
            0, NULL,                          // securityDomain
            0, NULL,                          // no accountName
            path.length, path.UTF8String,     // path
            (UInt16) url.port.intValue,       // port
            kSecProtocolTypeAny,              // protocol
            kSecAuthenticationTypeAny,        // authType
            &passwordLength, &passwordBuffer, // no password
            &keychainItem                     // keychain item
    );

    if (err) {
        self.lastErrorMessage = [self errorMessageFromOsStatus:err];
        return nil;
    }

    NSString *password = [self passwordFromKeychainBuffer:passwordBuffer length:passwordLength];
    NSString *username = [self usernameFromKeychainItem:keychainItem];

    SecKeychainItemFreeContent(NULL, passwordBuffer);
    CFRelease(keychainItem);

    if (username == nil) {
        return nil;
    }

    if (password == nil) {
        self.lastErrorMessage = [NSString stringWithFormat:NSLocalizedString(@"ErrorKeychainItem", @"There was an error obtaining the keychain item for %@"), url];
        return nil;
    }

    return [[JMCredential alloc] initWithUsername:username password:password];
}

- (BOOL)storeCredential:(JMCredential *)credential forUrl:(NSURL *)url {
    NSString *host = url.host;
    NSString *path = url.path;

    OSStatus err = SecKeychainAddInternetPassword(
            NULL,                                                       // keychain
            host.length, host.UTF8String,                               // serverName
            0, NULL,                                                    // securityDomain
            credential.username.length, credential.username.UTF8String, // accountName
            path.length, path.UTF8String,                               // path
            (UInt16) url.port.intValue,                                 // port
            kSecProtocolTypeHTTP,                                       // protocol
            kSecAuthenticationTypeHTTPBasic,                            // authenticationType
            credential.password.length, credential.password.UTF8String, // password
            NULL                                                        // keychain item
    );

    if (err) {
        self.lastErrorMessage = [self errorMessageFromOsStatus:err];
        return NO;
    }

    return YES;
}

#pragma mark Private
- (NSString *)errorMessageFromOsStatus:(OSStatus)err {
    CFStringRef errorStr = SecCopyErrorMessageString(err, NULL);
    NSString *errorMsg = [NSString stringWithString:(__bridge NSString *) errorStr];
    CFRelease(errorStr);

    return errorMsg;
}

- (NSString *)usernameFromKeychainItem:(SecKeychainItemRef)keychainItem {
    UInt32 attributeTags[1] = {kSecAccountItemAttr};
    UInt32 formatConstants[1] = {CSSM_DB_ATTRIBUTE_FORMAT_STRING};

    SecKeychainAttributeInfo attributeInfo;
    attributeInfo.count = 1;
    attributeInfo.tag = attributeTags;
    attributeInfo.format = formatConstants;

    SecKeychainAttributeList *attributeList = nil;
    OSStatus err = SecKeychainItemCopyAttributesAndData(keychainItem, &attributeInfo, NULL, &attributeList, 0, NULL);

    if (err) {
        self.lastErrorMessage = [self errorMessageFromOsStatus:err];
        return nil;
    }

    SecKeychainAttribute accountNameAttribute = attributeList->attr[0];
    NSString *username = [[NSString alloc] initWithBytes:accountNameAttribute.data length:accountNameAttribute.length encoding:NSUTF8StringEncoding];
    return username;
}

- (NSString *)passwordFromKeychainBuffer:(void *)passwordBuffer length:(UInt32)passwordLength {
    NSString *password = [[NSString alloc] initWithBytes:passwordBuffer length:passwordLength encoding:NSUTF8StringEncoding];
    return password;
}

@end
