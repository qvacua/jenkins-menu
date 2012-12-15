#import "JMAppDelegate.h"

static NSString *const DEFAULT_URL_KEY = @"jenkinsUrl";
static NSString *const DEFAULT_INTERVAL_KEY = @"interval";
static NSString *const DEFAULT_URL_VALUE = @"http://ci.jruby.org/api/xml";
static NSTimeInterval const DEFAULT_INTERVAL_VALUE = 5 * 60;
static NSString *const DEFAULT_TRUSTED_HOSTS_KEY = @"trustedURLs";

@interface JMAppDelegate ()

@property(readwrite, strong) NSStatusItem *statusItem;
@property(readwrite, strong) NSMutableDictionary *statuses;

@end

@implementation JMAppDelegate {
    NSStatusItem *_statusItem;

    NSURL *_jenkinsXmlUrl;
    NSURL *_jenkinsUrl;
    NSTimeInterval _interval;

    BOOL _trustHost;
    BOOL _successful;
    NSTimer *_timer;
    NSURLConnection *_connection;
    
    NSMutableDictionary *_statuses;
}

@synthesize window = _window;
@synthesize menu = _menu;
@synthesize statusItem = _statusItem;
@synthesize jenkinsXmlUrl = _jenkinsXmlUrl;
@synthesize urlTextField = _urlTextField;
@synthesize intervalTextField = _intervalTextField;
@synthesize interval = _interval;
@synthesize jenkinsUrl = _jenkinsUrl;
@synthesize statusMenuItem = _statusMenuItem;
@synthesize statuses = _statuses;

#pragma mark NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
    NSInteger responseStatusCode = [httpResponse statusCode];

    if (responseStatusCode < 200 || responseStatusCode >= 400) {
        NSLog(@"connection was not successful. http status code was: %ld", responseStatusCode);

        _successful = NO;
        [self showErrorStatus:[NSString stringWithFormat:NSLocalizedString(@"ErrorHttpStatus", @""), responseStatusCode]];
    } else {
        _successful = YES;
    }
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    [self connection:connection willSendRequestForAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]
        && [self shouldTrustHost:challenge.protectionSpace.host])
        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
    else if ([challenge.sender respondsToSelector:@selector(performDefaultHandlingForAuthenticationChallenge:)])
        [challenge.sender performDefaultHandlingForAuthenticationChallenge:challenge];
    else
        [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"connection to %@ failed: %@", self.jenkinsXmlUrl, error);
    
    if (error.code == -1202 && [self askWhetherToTrustHost:self.jenkinsXmlUrl.host]) {
        _trustHost = YES;
        [self makeRequest];
    } else
        [self showErrorStatus:error.localizedDescription];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (!_successful) {
        return;
    }

    NSXMLDocument *xmlDocument = [[NSXMLDocument alloc] initWithData:data options:0 error:NULL];
    NSArray *children = [[xmlDocument rootElement] children];

    if ([children count] == 0) {
        NSLog(@"The XML is empty!");

        [self showErrorStatus:NSLocalizedString(@"ErrorEmptyXML", @"")];
        return;
    }

    __block NSUInteger redCount = 0;
    __block NSUInteger yellowCount = 0;

    [children enumerateObjectsUsingBlock:^(NSXMLNode *childNode, NSUInteger index, BOOL *stop) {
        if ([[childNode name] isEqualToString:@"primaryView"]) {
            [self filterPrimaryViewUrlFromNode:childNode];
            return;
        }

        if ([[childNode name] isEqualToString:@"job"]) {
            [self filterJobFromNode:childNode redCount:&redCount yellowCount:&yellowCount];
            return;
        }
    }];

    [self setStatusWithRed:redCount yellow:yellowCount];
    [self.statusMenuItem setTitle:NSLocalizedString(@"StatusSuccess", @"")];
}

#pragma mark NSApplicationDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [GrowlApplicationBridge setGrowlDelegate:self];
    
    [self setDefaultsIfNecessary];
    [self initStatusMenu];

    [self addObserver:self forKeyPath:@"jenkinsXmlUrl" options:NSKeyValueObservingOptionOld context:NULL];
    [self addObserver:self forKeyPath:@"interval" options:NSKeyValueObservingOptionOld context:NULL];

    NSUserDefaults *const userDefaults = [NSUserDefaults standardUserDefaults];

    self.jenkinsXmlUrl = [[NSURL alloc] initWithString:[userDefaults objectForKey:DEFAULT_URL_KEY]];
    self.interval = [[userDefaults objectForKey:DEFAULT_INTERVAL_KEY] doubleValue];
}

#pragma mark NSKeyValueObserving
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

    if ([keyPath isEqualToString:@"jenkinsXmlUrl"]) {
        if ([[change objectForKey:NSKeyValueChangeOldKey] isEqual:self.jenkinsXmlUrl]) {
            return;
        }

        [[NSUserDefaults standardUserDefaults] setObject:[self.jenkinsXmlUrl absoluteString] forKey:DEFAULT_URL_KEY];
        self.jenkinsUrl = nil;
        [self.statuses removeAllObjects];
        _trustHost = NO;
        [self makeRequest];
    }

    if ([keyPath isEqualToString:@"interval"]) {
        if ([[change objectForKey:NSKeyValueChangeOldKey] doubleValue] == self.interval) {
            return;
        }

        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithDouble:self.interval] forKey:DEFAULT_INTERVAL_KEY];
        [self resetTimerWithTimeInterval:self.interval];
    }

}

#pragma mark NSObject
- (id)init {
    self = [super init];

    if (self) {
        _trustHost = NO;
        self.statuses = [[NSMutableDictionary alloc] init];
        _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    }

    return self;
}

#pragma mark IBActions
- (IBAction)updateNowAction:(id)sender {
    [self makeRequest];
}

- (IBAction)openJenkinsUrlAction:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:self.jenkinsUrl];
}

- (IBAction)openPreferencesWindowAction:(id)sender {
    NSApplication *const application = [NSApplication sharedApplication];
    [application activateIgnoringOtherApps:YES];

    [self.urlTextField setStringValue:[self.jenkinsXmlUrl absoluteString]];
    [self.intervalTextField setIntegerValue:(NSInteger) (self.interval / 60)];

    [self.window makeKeyAndOrderFront:self];
    [self.window orderFront:self];
}

- (IBAction)setPreferencesAction:(id)sender {
    NSURL *newUrl = [[NSURL alloc] initWithString:[self.urlTextField stringValue]];
    self.jenkinsXmlUrl = newUrl;
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
        return (self.jenkinsUrl != nil);
    }

    return NO;
}

#pragma mark GrowlApplicationBridgeDelegate

- (void) growlNotificationWasClicked:(id)clickContext {
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
}

- (void)makeRequest {
    [_connection cancel];
    [self showConnectingStatus];

    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:self.jenkinsXmlUrl cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5];
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];

    if (_connection == nil) {
        NSLog(@"connection to %@ failed!", self.jenkinsXmlUrl);
        [self showErrorStatus:NSLocalizedString(@"ErrorCouldNotConnect", @"")];
    }

    NSLog(@"connecting to %@ ...", self.jenkinsXmlUrl);
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

    if ([userDefaults objectForKey:DEFAULT_URL_KEY] == nil) {
        [userDefaults setObject:DEFAULT_URL_VALUE forKey:DEFAULT_URL_KEY];
    }

    if ([userDefaults objectForKey:DEFAULT_INTERVAL_KEY] == nil) {
        [userDefaults setObject:[NSNumber numberWithDouble:DEFAULT_INTERVAL_VALUE] forKey:DEFAULT_INTERVAL_KEY];
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

- (void)filterPrimaryViewUrlFromNode:(NSXMLNode *)node {
    [[node children] enumerateObjectsUsingBlock:^(id childNode, NSUInteger index, BOOL *stop) {

        if ([[childNode name] isEqualToString:@"url"]) {
            self.jenkinsUrl = [[NSURL alloc] initWithString:[childNode stringValue]];
            *stop = YES;
        }

    }];
}

- (void)filterJobFromNode:(NSXMLNode *)node redCount:(NSUInteger *)redCount yellowCount:(NSUInteger *)yellowCount {
    __block NSString *name = nil;
    [[node children] enumerateObjectsUsingBlock:^(id childNode, NSUInteger index, BOOL *stop) {

        if ([[childNode name] isEqualToString:@"name"]) {
            name = [childNode stringValue];
        } else if ([[childNode name] isEqualToString:@"color"]) {
            NSString *const color = [childNode stringValue];

            if ([color hasPrefix:@"red"]) {
                (*redCount)++;
            } else if ([color hasPrefix:@"yellow"]) {
                (*yellowCount)++;
            }

            NSString *previousColor = [self.statuses objectForKey:name];
            if (previousColor && ![color isEqualToString:previousColor]) {

                BOOL building = [color hasSuffix:@"_anime"];
                BOOL isBroken = [color hasPrefix:@"red"];
                BOOL isUnstable = [color hasPrefix:@"yellow"];
                BOOL isGood = [color hasPrefix:@"blue"];
                BOOL wasBroken = [previousColor hasPrefix:@"red"];
                BOOL wasUnstable = [previousColor hasPrefix:@"yellow"];
                BOOL wasGood = [previousColor hasPrefix:@"blue"];

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
            [self.statuses setObject:color forKey:name];

            *stop = YES;
        }

    }];
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
    if (_trustHost)
        return YES;
    NSArray *trustedHosts = [[NSUserDefaults standardUserDefaults] arrayForKey:DEFAULT_TRUSTED_HOSTS_KEY];
    return [trustedHosts containsObject:host];
}

- (void)trustHost:(NSString *)host {
    NSMutableSet *trustedHosts = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:DEFAULT_TRUSTED_HOSTS_KEY]];
    if (![trustedHosts containsObject:host]) {
        [trustedHosts addObject:host];
        [[NSUserDefaults standardUserDefaults] setObject:trustedHosts forKey:DEFAULT_TRUSTED_HOSTS_KEY];
    }
}

@end
