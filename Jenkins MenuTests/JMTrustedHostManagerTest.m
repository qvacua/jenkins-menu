/**
 * Jenkins Menu
 * https://github.com/qvacua/jenkins-menu
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <objc/runtime.h>
#import "JMBaseTestCase.h"
#import "JMJenkinsJob.h"
#import "JMTrustedHostManager.h"

@interface JMTrustedHostManagerTest : JMBaseTestCase
@end

@implementation JMTrustedHostManagerTest {
    JMTrustedHostManager *trustedHostManager;
    NSUserDefaults *userDefaults;

    Method originalMethod;
    IMP originalImpl;
}

- (void)setUp {
    [super setUp];

    [self exchangeSystemStatusBarClassMethod];

    userDefaults = mock([NSUserDefaults class]);

    trustedHostManager = [[JMTrustedHostManager alloc] init];
    trustedHostManager.userDefaults = userDefaults;
}

- (void)tearDown {
    method_setImplementation(originalMethod, originalImpl);

    [super tearDown];
}

- (void)testInit {
    JMTrustedHostManager *manager = [[JMTrustedHostManager alloc] init];
    assertThat(manager.userDefaults, is([NSUserDefaults standardUserDefaults]));
}

- (void)testShouldTrustHost {
    [given([userDefaults arrayForKey:qDefaultTrustedHostsKey]) willReturn:@[
            @"http://some/host",
            @"http://some/other/host",
    ]];

    assertThat(@([trustedHostManager shouldTrustHost:@"http://some/other/host"]), isYes);
    assertThat(@([trustedHostManager shouldTrustHost:@"http://yet/another/host"]), isNo);
}

- (void)testTrustHost {
    [given([userDefaults arrayForKey:qDefaultTrustedHostsKey]) willReturn:@[
            @"http://some/host",
            @"http://some/other/host",
    ]];

    [trustedHostManager trustHost:@"http://yet/another/host"];

    [verify(userDefaults) setObject:@[
            @"http://some/host",
            @"http://some/other/host",
            @"http://yet/another/host"
    ] forKey:qDefaultTrustedHostsKey];
}

#pragma mark Private
- (void)exchangeSystemStatusBarClassMethod {
    Method testMethod = class_getInstanceMethod([self class], @selector(mockSystemStatusBar));
    IMP testImpl = method_getImplementation(testMethod);

    originalMethod = class_getClassMethod([NSStatusBar class], @selector(systemStatusBar));
    originalImpl = method_setImplementation(originalMethod, testImpl);
}

@end
