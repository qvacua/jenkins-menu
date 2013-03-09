#import "JMTrustedHostManager.h"

static NSString *const qDefaultTrustedHostsKey = @"trustedURLs";

@implementation JMTrustedHostManager {
    NSUserDefaults *_userDefaults;
}

- (id)init {
    self = [super init];
    if (self) {
        _userDefaults = [NSUserDefaults standardUserDefaults];
    }

    return self;
}

- (BOOL)shouldTrustHost:(NSString *)host {
    NSArray *trustedHosts = [_userDefaults arrayForKey:qDefaultTrustedHostsKey];
    return [trustedHosts containsObject:host];
}

@end
