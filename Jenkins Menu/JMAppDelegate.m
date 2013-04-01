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
#import "NSMenuItem+Q.h"
#import "JMKeychainManager.h"

static NSString *const DEFAULT_URL_VALUE = @"http://ci.jruby.org/api/xml";
static NSTimeInterval const qDefaultInterval = 5 * 60;
static const NSInteger qTableViewNoSelectedRow = -1;

@implementation JMAppDelegate {
}

#pragma mark NSTableViewDataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.blacklistItems.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return self.blacklistItems[(NSUInteger) row];
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    [self.blacklistItems replaceObjectAtIndex:(NSUInteger) row withObject:object];
}

#pragma mark NSTableViewDelegate
- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    if ([self.blacklistTableView selectedRow] == qTableViewNoSelectedRow) {
        [self.blacklistItemSegmentedControl setEnabled:NO forSegment:qBlacklistItemRemoveSegment];
        return;
    }

    [self.blacklistItemSegmentedControl setEnabled:YES forSegment:qBlacklistItemRemoveSegment];
}

#pragma mark NSApplicationDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [GrowlApplicationBridge setGrowlDelegate:self];
    [self initStatusMenu];

    [self setDefaultsIfNecessary];

    NSKeyValueObservingOptions observingOptions = NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld;
    [self addObserver:self forKeyPath:@"jenkinsUrl" options:observingOptions context:NULL];
    [self addObserver:self forKeyPath:@"interval" options:observingOptions context:NULL];

    NSURL *url = [self cleanedUrlFromUserDefaults];

    self.jenkins.delegate = self;
    self.jenkins.interval = self.interval;
    self.jenkins.url = url;
    self.jenkins.secured = [self.userDefaults boolForKey:qUserDefaultsSecuredKey];

    self.jenkinsUrl = url;
    self.interval = [[self.userDefaults objectForKey:qUserDefaultsIntervalKey] doubleValue];

    [self.blacklistItems addObject:@"first"];
    [self.blacklistItems addObject:@"second"];
    [self.blacklistTableView reloadData];
}

#pragma mark JMJenkinsDelegate
- (void)jenkins:(JMJenkins *)jenkins serverTrustFailedwithHost:(NSString *)host {
    [self askWhetherToTrustHost:host];
    [self updateJenkinsStatus];
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
    [self updateJobsMenuItem:self.jenkins.jobs];
    [self showNotifications];
    [self.statusMenuItem setTitle:NSLocalizedString(@"StatusSuccess", @"")];
}

- (void)jenkins:(JMJenkins *)jenkins forbidden:(id)userInfo {
    JMCredential *credential = [self.keychainManager credentialForUrl:self.jenkinsXmlUrl];

    if (credential == nil) {
        [self.credentialsWindow makeKeyAndOrderFront:self];
        [self.userTextField becomeFirstResponder];

        return;
    }

    self.jenkins.credential = credential;
    [self updateJenkinsStatus];
}

- (void)jenkins:(JMJenkins *)jenkins wrongCredential:(NSDictionary *)userInfo {
    [self.credentialsWindow makeKeyAndOrderFront:self];
    [self.userTextField becomeFirstResponder];
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
        self.jenkins.credential = nil;

        [self.userDefaults setObject:[self.jenkinsUrl absoluteString] forKey:qUserDefaultsUrlKey];
        [self updateJenkinsStatus];

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
        _keychainManager = [[JMKeychainManager alloc] init];
        _trustedHostManager = [[JMTrustedHostManager alloc] init];

        _blacklistItems = [[NSMutableArray alloc] init];

        _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];

        _jenkins = [[JMJenkins alloc] init];
        _jenkins.trustedHostManager = _trustedHostManager;
    }

    return self;
}

#pragma mark IBActions
- (IBAction)updateNowAction:(id)sender {
    [self updateJenkinsStatus];
}

- (IBAction)openJenkinsUrlAction:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:self.jenkins.viewUrl];
}

- (IBAction)openPreferencesWindowAction:(id)sender {
    NSApplication *const application = [NSApplication sharedApplication];
    [application activateIgnoringOtherApps:YES];

    [self.urlTextField setStringValue:[self.jenkinsUrl absoluteString]];
    [self.intervalTextField setIntegerValue:(NSInteger) (self.interval / 60)];

    [self.preferencesWindow makeKeyAndOrderFront:self];
    [self.preferencesWindow orderFront:self];
}

- (IBAction)setPreferencesAction:(id)sender {
    NSURL *newUrl = [[NSURL alloc] initWithString:[self.urlTextField stringValue]];
    self.jenkinsUrl = newUrl;
    self.interval = [self.intervalTextField doubleValue] * 60;

    [self.preferencesWindow orderOut:self];
}

- (IBAction)manageBlacklistAction:(id)sender {
    [NSApp beginSheet:self.blacklistWindow modalForWindow:self.preferencesWindow modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:NULL];
}

- (IBAction)blacklistItemAction:(id)sender {
    NSInteger selectedButton = [sender selectedSegment];
    log4Debug(@"%d", selectedButton);

    if (selectedButton == qBlacklistItemRemoveSegment) {
        [self.blacklistItems removeObjectAtIndex:(NSUInteger) [self.blacklistTableView selectedRow]];
        [self.blacklistTableView reloadData];
        return;
    }

    [self.blacklistItems addObject:@""];
    [self.blacklistTableView reloadData];
    [self.blacklistTableView editColumn:0 row:([self.blacklistItems count] - 1) withEvent:nil select:YES];
}

- (IBAction)blacklistOkAction:(id)sender {
    [NSApp endSheet:self.blacklistWindow];
}

- (IBAction)credentialsOkAction:(id)sender {
    BOOL usernameOk = NO;
    BOOL passwordOk = NO;

    if ([[self.userTextField stringValue] length] > 0) {
        usernameOk = YES;
    }

    if ([[self.passwordTextField stringValue] length] > 0) {
        passwordOk = YES;
    }

    if (!usernameOk || !passwordOk) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:NSLocalizedString(@"WarningEnterCredential", @"You have to enter User and Password.")];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:self.credentialsWindow modalDelegate:self didEndSelector:NULL contextInfo:nil];

        return;
    }

    JMCredential *credential = [[JMCredential alloc] initWithUsername:self.userTextField.stringValue password:self.passwordTextField.stringValue];
    self.jenkins.credential = credential;

    if ([self.storeInKeychanCheckbox state] == NSOffState) {
        [self clearAndOrderOutCredentialWindow:self];
        [self updateJenkinsStatus];
        return;
    }

    BOOL success = [self.keychainManager storeCredential:credential forUrl:self.jenkinsXmlUrl];
    if (!success) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"Storing the Credential Failed"];
        [alert setInformativeText:self.keychainManager.lastErrorMessage];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:self.credentialsWindow modalDelegate:self didEndSelector:NULL contextInfo:nil];
    }

    [self updateJenkinsStatus];
    [self clearAndOrderOutCredentialWindow:self];
}

- (IBAction)credentialsCancelAction:(id)sender {
    [self clearAndOrderOutCredentialWindow:sender];

    [self showForbiddenStatus];
}

- (IBAction)storeInKeychainToggleAction:(id)sender {
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
- (void)clearAndOrderOutCredentialWindow:(id)sender {
    [self.userTextField setStringValue:@""];
    [self.passwordTextField setStringValue:@""];

    [self.credentialsWindow orderOut:sender];
}

- (void)showInitialStatus {
    [self setTitle:@"" image:@"disconnect"];
}

- (void)showForbiddenStatus {
    [self setTitle:@"" image:@"disconnect"];
    [self.statusMenuItem setTitle:NSLocalizedString(@"JenkinsSecuredStatus", @"The Jenkins CI server is secured")];
}

- (void)initStatusMenu {
    [self.statusItem setHighlightMode:YES];
    [self.statusItem setMenu:self.menu];

    [self showInitialStatus];
}

- (void)showConnectingStatus {
    [self setTitle:@"" image:@"disconnect"];
    [self.statusMenuItem setTitle:NSLocalizedString(@"StatusUpdating", @"")];
}

- (void)updateJenkinsStatus {
    [self.jenkins update];
}

- (void)setTitle:(NSString *)title image:(NSString *)imageName {
    [self.statusItem setTitle:title];
    [self.statusItem setImage:[NSImage imageNamed:imageName]];
}

- (void)showErrorStatus:(NSString *)error {
    [self setTitle:@"" image:@"disconnect"];
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
    [self.timer invalidate];
    self.timer = nil;
    self.timer = [NSTimer timerWithTimeInterval:anInterval target:self selector:@selector(timerFireMethod:) userInfo:nil repeats:YES];

    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop addTimer:self.timer forMode:NSDefaultRunLoopMode];
}

- (void)timerFireMethod:(NSTimer *)theTimer {
    [self updateJenkinsStatus];
}

- (void)setStatusWithRed:(NSUInteger)redCount yellow:(NSUInteger)yellowCount {
    NSString *templateNumber = @"<span style=\"font-family: Lucida Grande; font-size: 9pt; color: %@;\">%lu</span>";
    NSString *templateText = @"<span style=\"font-family: Lucida Grande; font-size: 9pt; color: %@;\">%@</span>";
    NSMutableString *htmlAsString = [[NSMutableString alloc] init];
    NSString *imageName = @"thumb_up";

    if (yellowCount > 0) {
        imageName = @"weather_lightning";
        [htmlAsString appendFormat:templateNumber, @"orange", yellowCount];
    }

    if (redCount > 0) {

        if (yellowCount > 0) {
            [htmlAsString appendFormat:templateText, @"gray", @":"];
        }

        [htmlAsString appendFormat:templateNumber, @"red", redCount];
        imageName = @"fire";
    }

    NSData *htmlAsData = [[NSData alloc] initWithBytes:[htmlAsString UTF8String] length:[htmlAsString lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
    NSAttributedString *titleAttrString = [[NSAttributedString alloc] initWithHTML:htmlAsData documentAttributes:NULL];

    [self.statusItem setAttributedTitle:titleAttrString];
    [self.statusItem setImage:[NSImage imageNamed:imageName]];
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

    if (response != NSAlertFirstButtonReturn) {
        return NO;
    }

    if (alert.suppressionButton.state == NSOnState) {
        [self.trustedHostManager permanentlyTrustHost:host];
    } else {
        [self.trustedHostManager onceTrustHost:host];
    }

    return YES;
}

- (NSURL *)cleanedUrlFromUserDefaults {
    NSString *urlString = [self.userDefaults objectForKey:qUserDefaultsUrlKey];

    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\/api\\/xml\\/*?$" options:NSRegularExpressionCaseInsensitive error:NULL];
    NSString *cleanedUrlString = [regex stringByReplacingMatchesInString:urlString options:0 range:NSMakeRange(0, [urlString length]) withTemplate:@""];

    return [[NSURL alloc] initWithString:cleanedUrlString];
}

- (void)updateJobsMenuItem:(NSArray *)jobs {
    [self.jobsMenuItem setSubmenu:nil];

    NSMenu *submenu = [[NSMenu alloc] init];
    for (JMJenkinsJob *job in jobs) {

        NSString *menuTitle = [NSString stringWithFormat:@"%@", job.name];
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:menuTitle action:NULL keyEquivalent:@""];
        [menuItem setImage:[self imageForJobState:job.state]];
        [menuItem setBlockAction:^(id sender) {
            NSString *jobUrlComponent = [NSString stringWithFormat:@"job/%@", job.name];
            [[NSWorkspace sharedWorkspace] openURL:[self.jenkins.url URLByAppendingPathComponent:jobUrlComponent]];
        }];

        [submenu addItem:menuItem];
    }

    [self.jobsMenuItem setSubmenu:submenu];
}

- (NSImage *)imageForJobState:(JMJenkinsJobState)state {
    switch (state) {
        case JMJenkinsJobStateGreen:
            return [self imageWithFileName:@"thumb_up"];

        case JMJenkinsJobStateYellow:
            return [self imageWithFileName:@"weather_lightning"];

        case JMJenkinsJobStateRed:
            return [self imageWithFileName:@"fire"];

        default:
            return [self imageWithFileName:@"disconnect"];
    }
}

- (NSImage *)imageWithFileName:(NSString *)fileName {
    return [NSImage imageNamed:fileName];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
}

@end
