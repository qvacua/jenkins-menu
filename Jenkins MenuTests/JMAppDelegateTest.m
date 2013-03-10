/**
 * Jenkins Menu
 * https://github.com/qvacua/jenkins-menu
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "JMBaseTestCase.h"
#import "JMJenkinsJob.h"
#import "JMAppDelegate.h"
#import "JMJenkins.h"
#import <objc/runtime.h>

@interface JMAppDelegateTest : JMBaseTestCase
@end

@implementation JMAppDelegateTest {
    JMAppDelegate *appDelegate;

    NSUserDefaults *userDefaults;

    Method originalMethod;
    IMP originalImpl;
}

- (void)setUp {
    [super setUp];

    [self exchangeSystemStatusBarClassMethod];

    userDefaults = mock([NSUserDefaults class]);

    appDelegate = [[JMAppDelegate alloc] init];
    appDelegate.userDefaults = userDefaults;
}

- (void)tearDown {
    method_setImplementation(originalMethod, originalImpl);

    [super tearDown];
}

- (void)testInit {
    appDelegate = [[JMAppDelegate alloc] init];

    assertThat(appDelegate.userDefaults, is([NSUserDefaults standardUserDefaults]));
    assertThat(appDelegate.jenkins, isNot(nilValue()));
    assertThat(appDelegate.trustedHostManager, isNot(nilValue()));
}

- (void)testAppDidFinishLaunching {
    JMJenkins *jenkins = appDelegate.jenkins;
    [given([userDefaults objectForKey:qUserDefaultsUrlKey]) willReturn:@"http://some/host"];
    [given([userDefaults objectForKey:qUserDefaultsIntervalKey]) willReturn:@18];

    [appDelegate applicationDidFinishLaunching:nil];

    assertThat(jenkins.delegate, is(appDelegate));
    assertThat(@(jenkins.interval), is(@18));
    assertThat(jenkins.url, is([NSURL URLWithString:@"http://some/host"]));
}

- (void)testAppDidFinishLaunchingOldXmlUrlInDefaults {
    JMJenkins *jenkins = appDelegate.jenkins;
    [given([userDefaults objectForKey:qUserDefaultsUrlKey]) willReturn:@"http://some/host/api/xml"];
    [given([userDefaults objectForKey:qUserDefaultsIntervalKey]) willReturn:@18];

    [appDelegate applicationDidFinishLaunching:nil];

    assertThat(jenkins.url, is([NSURL URLWithString:@"http://some/host"]));
}

- (void)testAppDidFinishLaunchingOldXmlUrlInDefaultsWithSlash {
    JMJenkins *jenkins = appDelegate.jenkins;
    [given([userDefaults objectForKey:qUserDefaultsUrlKey]) willReturn:@"http://some/host/api/xml/"];
    [given([userDefaults objectForKey:qUserDefaultsIntervalKey]) willReturn:@18];

    [appDelegate applicationDidFinishLaunching:nil];

    assertThat(jenkins.url, is([NSURL URLWithString:@"http://some/host"]));
}

- (void)testSetJenkinsUrl {
    [given([userDefaults objectForKey:qUserDefaultsUrlKey]) willReturn:@"http://some/host/"];
    [given([userDefaults objectForKey:qUserDefaultsIntervalKey]) willReturn:@18];
    [appDelegate applicationDidFinishLaunching:nil];

    appDelegate.jenkinsUrl = [[NSURL alloc] initWithString:@"http://other/host"];

    NSURL *url = [NSURL URLWithString:@"http://other/host"];
    NSURL *xmlUrl = [url URLByAppendingPathComponent:@"api/xml"];

    assertThat(appDelegate.jenkinsXmlUrl, is(xmlUrl));
    assertThat(appDelegate.jenkins.url, is(url));
    assertThat(appDelegate.jenkins.xmlUrl, is(xmlUrl));
    [verify(userDefaults) setObject:[url absoluteString] forKey:qUserDefaultsUrlKey];
}

- (void)testSetInterval {
    [given([userDefaults objectForKey:qUserDefaultsUrlKey]) willReturn:@"http://some/host/"];
    [given([userDefaults objectForKey:qUserDefaultsIntervalKey]) willReturn:@18];
    [appDelegate applicationDidFinishLaunching:nil];

    appDelegate.interval = 37;

    assertThat(@(appDelegate.interval), is(@37));
    assertThat(@(appDelegate.jenkins.interval), is(@37));
    [verify(userDefaults) setObject:@37 forKey:qUserDefaultsIntervalKey];
}

#pragma mark Private
- (void)exchangeSystemStatusBarClassMethod {
    Method testMethod = class_getInstanceMethod([self class], @selector(mockSystemStatusBar));
    IMP testImpl = method_getImplementation(testMethod);

    originalMethod = class_getClassMethod([NSStatusBar class], @selector(systemStatusBar));
    originalImpl = method_setImplementation(originalMethod, testImpl);
}

- (NSStatusBar *)mockSystemStatusBar {
    return nil;
}

@end
