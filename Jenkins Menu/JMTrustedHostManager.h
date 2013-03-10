/**
 * Jenkins Menu
 * https://github.com/qvacua/jenkins-menu
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Foundation/Foundation.h>

static NSString *const qDefaultTrustedHostsKey = @"trustedURLs";

@interface JMTrustedHostManager : NSObject

@property NSUserDefaults *userDefaults;

- (BOOL)shouldTrustHost:(NSString *)host;
- (void)trustHost:(NSString *)host;

@end
