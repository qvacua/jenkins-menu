/**
 * Tae Won Ha
 * http://qvacua.com
 * https://github.com/qvacua
 *
 * See LICENSE
 */

#import "JMKeychainManager.h"
#import "JMLog.h"

@implementation JMCredential

@synthesize url = _url;
@synthesize username = _username;
@synthesize password = _password;

- (id)initWithUrl:(NSURL *)url username:(NSString *)username password:(NSString *)password {
    self = [super init];
    if (self) {
        self.url = url;
        self.username = username;
        self.password = password;
    }

    return self;
}

@end

@implementation JMKeychainManager {
}

- (JMCredential *)credentialForUrl:(NSURL *)url {
    void *passwordBuffer;
    UInt32 passwordLength;

    char const *hostStr = url.host.UTF8String;
    char const *pathStr = url.path.UTF8String;

    SecKeychainItemRef keychainItem = NULL;
    OSStatus err = SecKeychainFindInternetPassword(
            NULL,
            strlen(hostStr), hostStr, // serverName
            0, NULL, // securityDomain
            0, NULL, // no accountName
            strlen(pathStr), pathStr, // path
            (UInt16) url.port.intValue, // port
            kSecProtocolTypeAny, // protocol
            kSecAuthenticationTypeAny, // authType
            &passwordLength, &passwordBuffer, // no password
            &keychainItem
    );

    if (err) {
        [self printErrorWithOsStatus:err];
        return nil;
    }

    NSString *password = [self passwordFromKeychainBuffer:passwordBuffer length:passwordLength];
    NSString *username = [self usernameFromKeychainItem:keychainItem];

    if (username == nil || password == nil) {
        return nil;
    }

    SecKeychainItemFreeContent(NULL, passwordBuffer);
    CFRelease(keychainItem);

    return [[JMCredential alloc] initWithUrl:url username:username password:password];
}

#pragma mark Private
- (void)printErrorWithOsStatus:(OSStatus)err {
    CFStringRef errorStr = SecCopyErrorMessageString(err, NULL);
    log4Debug(@"%@", errorStr);
    CFRelease(errorStr);
}

- (NSString *)usernameFromKeychainItem:(SecKeychainItemRef)keychainItem {
    UInt32 attributeTags[1] = { kSecAccountItemAttr };
    UInt32 formatConstants[1] = { CSSM_DB_ATTRIBUTE_FORMAT_STRING };

    SecKeychainAttributeInfo attributeInfo;
    attributeInfo.count = 1;
    attributeInfo.tag = attributeTags;
    attributeInfo.format = formatConstants;

    SecKeychainAttributeList *attributeList = nil;
    OSStatus err = SecKeychainItemCopyAttributesAndData(keychainItem, &attributeInfo, NULL, &attributeList, 0, NULL);

    if (err) {
        [self printErrorWithOsStatus:err];
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
