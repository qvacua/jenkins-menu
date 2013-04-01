/**
 * Jenkins Menu
 * https://github.com/qvacua/jenkins-menu
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "JMTrustedHostManager.h"

@interface JMTrustedHostManager ()

@property NSMutableSet *onceTrustHosts;

@end

@implementation JMTrustedHostManager {
}

- (id)init {
    self = [super init];
    if (self) {
        _userDefaults = [NSUserDefaults standardUserDefaults];
        _onceTrustHosts = [[NSMutableSet alloc] init];
    }

    return self;
}

- (BOOL)shouldTrustHost:(NSString *)host {
    NSArray *trustedHosts = [self.userDefaults arrayForKey:qDefaultTrustedHostsKey];
    if ([trustedHosts containsObject:host]) {
        return YES;
    }

    if ([self.onceTrustHosts containsObject:host]) {
        [self.onceTrustHosts removeObject:host];
        return YES;
    }

    return NO;
}

- (void)permanentlyTrustHost:(NSString *)host {
    NSMutableArray *trustedHosts = [NSMutableArray arrayWithArray:[self.userDefaults arrayForKey:qDefaultTrustedHostsKey]];

    if ([trustedHosts containsObject:host]) {
        return;
    }

    [trustedHosts addObject:host];
    [self.userDefaults setObject:trustedHosts forKey:qDefaultTrustedHostsKey];
}

- (void)onceTrustHost:(NSString *)host {
    [self.onceTrustHosts addObject:host];
}

@end
