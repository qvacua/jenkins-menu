/**
 * Jenkins Menu
 * https://github.com/qvacua/jenkins-menu
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "JMTrustedHostManager.h"

@implementation JMTrustedHostManager {
}

@synthesize userDefaults = _userDefaults;

- (id)init {
    self = [super init];
    if (self) {
        _userDefaults = [NSUserDefaults standardUserDefaults];
    }

    return self;
}

- (BOOL)shouldTrustHost:(NSString *)host {
    NSArray *trustedHosts = [self.userDefaults arrayForKey:qDefaultTrustedHostsKey];
    return [trustedHosts containsObject:host];
}

- (void)trustHost:(NSString *)host {
    NSMutableArray *trustedHosts = [NSMutableArray arrayWithArray:[self.userDefaults arrayForKey:qDefaultTrustedHostsKey]];

    if ([trustedHosts containsObject:host]) {
        return;
    }

    [trustedHosts addObject:host];
    [self.userDefaults setObject:trustedHosts forKey:qDefaultTrustedHostsKey];
}

@end
