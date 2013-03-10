/**
 * Jenkins Menu
 * https://github.com/qvacua/jenkins-menu
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "JMAppDelegate.h"
#import "JMJenkins.h"
#import "JMLog.h"
#import "JMJenkinsJob.h"
#import "JMTrustedHostManager.h"

static NSString *const DEFAULT_URL_VALUE = @"http://ci.jruby.org/api/xml";
static NSTimeInterval const qDefaultInterval = 5 * 60;
static NSString *const qDefaultTrustedHostsKey = @"trustedURLs";

@implementation JMAppDelegate {
}

@synthesize window = _window;
@synthesize menu = _menu;
@synthesize statusItem = _statusItem;
@synthesize urlTextField = _urlTextField;
@synthesize intervalTextField = _intervalTextField;
@synthesize statusMenuItem = _statusMenuItem;

@synthesize userDefaults = _userDefaults;

@synthesize trustedHostManager = _trustedHostManager;
@synthesize jenkins = _jenkins;
@synthesize jenkinsUrl = _jenkinsUrl;
@synthesize jenkinsXmlUrl = _jenkinsXmlUrl;
@synthesize interval = _interval;
@synthesize timer = _timer;

#pragma mark NSApplicationDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [GrowlApplicationBridge setGrowlDelegate:self];
    [self initStatusMenu];

    [self setDefaultsIfNecessary];

    NSKeyValueObservingOptions observingOptions = NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld;
    [self addObserver:self forKeyPath:@"jenkinsUrl" options:observingOptions context:NULL];
    [self addObserver:self forKeyPath:@"interval" options:observingOptions context:NULL];

    NSURL *url = [self cleanedUrlFromUserDefaults];

    self.jenkinsUrl = url;
    self.interval = [[self.userDefaults objectForKey:qUserDefaultsIntervalKey] doubleValue];

    self.jenkins.delegate = self;
    self.jenkins.interval = self.interval;
    self.jenkins.url = url;

    [self makeRequest];
}

#pragma mark JMJenkinsDelegate
- (void)jenkins:(JMJenkins *)jenkins serverTrustFailedwithHost:(NSString *)host {
    [self askWhetherToTrustHost:host];
    [self makeRequest];
}

- (void)jenkins:(JMJenkins *)jenkins updateStarted:(NSDictionary *)userInfo {
    [self showConnectingStatus];
}

- (void)jenkins:(JMJenkins *)jenkins updateFailed:(NSDictionary *)userInfo {
    NSInteger connectionState = self.jenkins.connectionState;

    if (connectionState == JMJenkinsConnectionStateConnectionFailure) {
        [self showErrorStatus:NSLocalizedString(@"ErrorCouldNotConnect", @"")];
        return;
    }

    if (connectionState == JMJenkinsConnectionStateHttpFailure) {
        [self showErrorStatus:[NSString stringWithFormat:NSLocalizedString(@"ErrorHttpStatus", @""), userInfo[qJenkinsHttpResponseErrorKey]]];
        return;
    }

    if (connectionState == JMJenkinsConnectionStateFailure) {
        [self showErrorStatus:[userInfo[qJenkinsConnectionErrorKey] localizedDescription]];
    }
}

- (void)jenkins:(JMJenkins *)jenkins updateFinished:(NSDictionary *)userInfo {
    log4Debug(@"jobs: %@", jenkins.jobs);

    [self setStatusWithRed:[self.jenkins countOfRedJobs] yellow:[self.jenkins countOfYellowJobs]];
    [self showNotifications];
    [self.statusMenuItem setTitle:NSLocalizedString(@"StatusSuccess", @"")];
}

#pragma mark NSKeyValueObserving
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
    id newValue = [change objectForKey:NSKeyValueChangeNewKey];

    if ([keyPath isEqualToString:@"jenkinsUrl"]) {
        if ([oldValue isEqual:newValue]) {
            return;
        }

        self.jenkinsXmlUrl = [newValue URLByAppendingPathComponent:@"api/xml"];
        self.jenkins.url = newValue;

        [self.userDefaults setObject:[self.jenkinsUrl absoluteString] forKey:qUserDefaultsUrlKey];

        return;
    }

    if ([keyPath isEqualToString:@"interval"]) {
        if ([oldValue doubleValue] == self.interval) {
            return;
        }

        self.jenkins.interval = [newValue doubleValue];

        [self.userDefaults setObject:[NSNumber numberWithDouble:self.interval] forKey:qUserDefaultsIntervalKey];
        [self resetTimerWithTimeInterval:self.interval];

        return;
    }
}

#pragma mark NSObject
- (id)init {
    self = [super init];
    if (self) {
        _userDefaults = [NSUserDefaults standardUserDefaults];
        _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
        _jenkins = [[JMJenkins alloc] init];
        _trustedHostManager = [[JMTrustedHostManager alloc] init];
    }

    return self;
}

#pragma mark IBActions
- (IBAction)updateNowAction:(id)sender {
    [self makeRequest];
}

- (IBAction)openJenkinsUrlAction:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:self.jenkins.viewUrl];
}

- (IBAction)openPreferencesWindowAction:(id)sender {
    NSApplication *const application = [NSApplication sharedApplication];
    [application activateIgnoringOtherApps:YES];

    [self.urlTextField setStringValue:[self.jenkinsUrl absoluteString]];
    [self.intervalTextField setIntegerValue:(NSInteger) (self.interval / 60)];

    [self.window makeKeyAndOrderFront:self];
    [self.window orderFront:self];
}

- (IBAction)setPreferencesAction:(id)sender {
    NSURL *newUrl = [[NSURL alloc] initWithString:[self.urlTextField stringValue]];
    self.jenkinsUrl = newUrl;
    self.interval = [self.intervalTextField doubleValue] * 60;

    [self.window orderOut:self];
}

#pragma mark NSUserInterfaceValidations
- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item {
    if ([item action] == @selector(openPreferencesWindowAction:)) {
        return YES;
    }

    if ([item action] == @selector(updateNowAction:)) {
        return YES;
    }

    if ([item action] == @selector(openJenkinsUrlAction:)) {
        return (self.jenkins.viewUrl != nil);
    }

    return NO;
}

#pragma mark GrowlApplicationBridgeDelegate
- (void)growlNotificationWasClicked:(id)clickContext {
    [self openJenkinsUrlAction:nil];
}

#pragma mark Private
- (void)showInitialStatus {
    [self setTitle:@"" image:@"disconnect.png"];
}

- (void)initStatusMenu {
    [self.statusItem setHighlightMode:YES];
    [self.statusItem setMenu:self.menu];

    [self showInitialStatus];
}

- (void)showConnectingStatus {
    [self setTitle:@"" image:@"disconnect.png"];
    [self.statusMenuItem setTitle:NSLocalizedString(@"StatusUpdating", @"")];
}

- (void)makeRequest {
    [self.jenkins update];
}

- (void)setTitle:(NSString *)title image:(NSString *)imageName {
    [self.statusItem setTitle:title];
    [self.statusItem setImage:[[NSBundle bundleForClass:[self class]] imageForResource:imageName]];
}

- (void)showErrorStatus:(NSString *)error {
    [self setTitle:@"" image:@"disconnect.png"];
    [self.statusMenuItem setTitle:NSLocalizedString(@"StatusError", @"")];

    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"NotifyMessageError", @""), self.jenkinsXmlUrl, error];
    [GrowlApplicationBridge notifyWithTitle:NSLocalizedString(@"NotifyTitleError", @"") description:message notificationName:@"Error" iconData:nil priority:1 isSticky:NO clickContext:nil];
}

- (void)setDefaultsIfNecessary {
    NSUserDefaults *const userDefaults = [NSUserDefaults standardUserDefaults];

    if ([userDefaults objectForKey:qUserDefaultsUrlKey] == nil) {
        [userDefaults setObject:DEFAULT_URL_VALUE forKey:qUserDefaultsUrlKey];
    }

    if ([userDefaults objectForKey:qUserDefaultsIntervalKey] == nil) {
        [userDefaults setObject:[NSNumber numberWithDouble:qDefaultInterval] forKey:qUserDefaultsIntervalKey];
    }
}

- (void)resetTimerWithTimeInterval:(NSTimeInterval)anInterval {
    [_timer invalidate];
    _timer = nil;
    _timer = [NSTimer timerWithTimeInterval:anInterval target:self selector:@selector(timerFireMethod:) userInfo:nil repeats:YES];

    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop addTimer:_timer forMode:NSDefaultRunLoopMode];
}

- (void)timerFireMethod:(NSTimer *)theTimer {
    [self makeRequest];
}

- (void)setStatusWithRed:(NSUInteger)redCount yellow:(NSUInteger)yellowCount {
    NSString *templateNumber = @"<span style=\"font-family: Lucida Grande; font-size: 9pt; color: %@;\">%lu</span>";
    NSString *templateText = @"<span style=\"font-family: Lucida Grande; font-size: 9pt; color: %@;\">%@</span>";
    NSMutableString *htmlAsString = [[NSMutableString alloc] init];
    NSString *imageName = @"thumb_up.png";

    if (yellowCount > 0) {
        imageName = @"weather_lightning.png";
        [htmlAsString appendFormat:templateNumber, @"orange", yellowCount];
    }

    if (redCount > 0) {

        if (yellowCount > 0) {
            [htmlAsString appendFormat:templateText, @"gray", @":"];
        }

        [htmlAsString appendFormat:templateNumber, @"red", redCount];
        imageName = @"fire.png";
    }

    NSData *htmlAsData = [[NSData alloc] initWithBytes:[htmlAsString UTF8String] length:[htmlAsString lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
    NSAttributedString *titleAttrString = [[NSAttributedString alloc] initWithHTML:htmlAsData documentAttributes:NULL];

    [self.statusItem setAttributedTitle:titleAttrString];
    [self.statusItem setImage:[[NSBundle bundleForClass:[self class]] imageForResource:imageName]];
}

- (void)showNotifications {
    for (JMJenkinsJob *job in self.jenkins.jobs) {

        JMJenkinsJobState lastState = job.lastState;
        JMJenkinsJobState currentState = job.state;

        if (lastState == currentState) {
            continue;
        }

        if (lastState == JMJenkinsJobStateUnknown) {
            continue;
        }

        NSString *name = job.name;

        BOOL building = job.running;
        BOOL isBroken = currentState == JMJenkinsJobStateRed;
        BOOL isUnstable = currentState == JMJenkinsJobStateYellow;
        BOOL isGood = currentState == JMJenkinsJobStateGreen;
        BOOL wasBroken = lastState == JMJenkinsJobStateRed;
        BOOL wasUnstable = lastState == JMJenkinsJobStateYellow;
        BOOL wasGood = lastState == JMJenkinsJobStateGreen;

        if (building)
            [self showBuildNotificationOfType:@"Began" forBuild:name];
        else if (isBroken) {
            if (wasBroken)
                [self showBuildNotificationOfType:@"StillBroken" forBuild:name];
            else
                [self showBuildNotificationOfType:@"Broken" forBuild:name];
        } else if (isUnstable) {
            if (wasUnstable)
                [self showBuildNotificationOfType:@"StillUnstable" forBuild:name];
            else
                [self showBuildNotificationOfType:@"Unstable" forBuild:name];
        } else if (isGood) {
            if (wasGood)
                [self showBuildNotificationOfType:@"Succeeded" forBuild:name];
            else
                [self showBuildNotificationOfType:@"Fixed" forBuild:name];
        }
    }
}

- (void)showBuildNotificationOfType:(NSString *)type forBuild:(NSString *)buildName {
    NSString *title = [NSString stringWithFormat:@"NotifyTitle%@", type];
    title = NSLocalizedString(title, @"");
    NSString *message = [NSString stringWithFormat:@"NotifyMessage%@", type];
    message = NSLocalizedString(message, @"");
    message = [NSString stringWithFormat:message, buildName];
    [GrowlApplicationBridge notifyWithTitle:title description:message notificationName:type iconData:nil priority:0 isSticky:NO clickContext:[self.jenkinsXmlUrl absoluteString]];
}

- (BOOL)askWhetherToTrustHost:(NSString *)host {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:NSLocalizedString(@"ButtonTrust", @"Trust")];
    [alert addButtonWithTitle:NSLocalizedString(@"ButtonCancel", @"Cancel")];
    [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"MessageTrustServer", @""), host]];
    [alert setInformativeText:NSLocalizedString(@"MessageTrustInformation", @"")];
    [alert setShowsSuppressionButton:YES];
    [alert.suppressionButton setTitle:NSLocalizedString(@"MessageAlwaysTrust", @"")];

    NSInteger response = [alert runModal];

    if (response == NSAlertFirstButtonReturn && alert.suppressionButton.state == NSOnState)
        [self trustHost:host];
    return response == NSAlertFirstButtonReturn;
}

- (BOOL)shouldTrustHost:(NSString *)host {
    return [self.trustedHostManager shouldTrustHost:host];
}

- (void)trustHost:(NSString *)host {
    [self.trustedHostManager trustHost:host];
}

- (NSURL *)cleanedUrlFromUserDefaults {
    NSString *urlString = [self.userDefaults objectForKey:qUserDefaultsUrlKey];

    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\/api\\/xml\\/*?$" options:NSRegularExpressionCaseInsensitive error:NULL];
    NSString *cleanedUrlString = [regex stringByReplacingMatchesInString:urlString options:0 range:NSMakeRange(0, [urlString length]) withTemplate:@""];

    return [[NSURL alloc] initWithString:cleanedUrlString];
}

@end
