/**
 * Tae Won Ha
 * http://qvacua.com
 * https://github.com/qvacua
 *
 * See LICENSE
 */

#import "JMKeychainManager.h"
#import "JMLog.h"

@implementation JMKeychainManager {

}

- (void)doSth {
    NSURL *url = [NSURL URLWithString:@"http://www.spiegel.de/meinspiegel/login.html"];

    void *passwordBuffer;
    UInt32 passwordLength;

    char const *hostStr = url.host.UTF8String;
    char const *pathStr = url.path.UTF8String;

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
            NULL
    );

    if (err) {
        CFStringRef errorStr = SecCopyErrorMessageString(err, NULL);
        log4Debug(@"%@", errorStr);
        CFRelease(errorStr);

        return;
    }

    NSString *password = [[NSString alloc] initWithBytes:passwordBuffer length:passwordLength encoding:NSUTF8StringEncoding];
    SecKeychainItemFreeContent(NULL, passwordBuffer);

    log4Debug(@"%@", password);
}

@end
