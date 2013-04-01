/**
 * Jenkins Menu
 * https://github.com/qvacua/jenkins-menu
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>
#import "JMJenkinsDelegate.h"

@class JMTrustedHostManager;
@class JMKeychainManager;

static NSString *const qUserDefaultsUrlKey = @"jenkinsUrl";
static NSString *const qUserDefaultsIntervalKey = @"interval";
static NSString *const qUserDefaultsSecuredKey = @"fds";

@interface JMAppDelegate : NSObject <NSApplicationDelegate, NSUserInterfaceValidations, NSTableViewDataSource, NSTableViewDelegate, GrowlApplicationBridgeDelegate, JMJenkinsDelegate>

@property (weak) IBOutlet NSMenu *menu;
@property (weak) IBOutlet NSMenuItem *jobsMenuItem;
@property (weak) IBOutlet NSMenuItem *statusMenuItem;

@property (unsafe_unretained) IBOutlet NSWindow *preferencesWindow;
@property (weak) IBOutlet NSTextField *urlTextField;
@property (weak) IBOutlet NSTextField *intervalTextField;

@property (unsafe_unretained) IBOutlet NSWindow *credentialsWindow;
@property (weak) IBOutlet NSTextField *userTextField;
@property (weak) IBOutlet NSSecureTextField *passwordTextField;
@property (weak) IBOutlet NSButton *storeInKeychanCheckbox;

@property NSMutableArray *blacklistItems;
@property (unsafe_unretained) IBOutlet NSWindow *blacklistWindow;
@property (weak) IBOutlet NSTableView *blacklistTableView;
@property (weak) IBOutlet NSSegmentedControl *blacklistItemSegmentedControl;

@property NSStatusItem *statusItem;
@property NSTimer *timer;
@property NSUserDefaults *userDefaults;
@property JMKeychainManager *keychainManager;

@property JMTrustedHostManager *trustedHostManager;
@property JMJenkins *jenkins;
@property NSURL *jenkinsUrl;
@property NSURL *jenkinsXmlUrl;
@property NSTimeInterval interval;

- (IBAction)updateNowAction:(id)sender;
- (IBAction)openJenkinsUrlAction:(id)sender;
- (IBAction)openPreferencesWindowAction:(id)sender;
- (IBAction)setPreferencesAction:(id)sender;

- (IBAction)manageBlacklistAction:(id)sender;
- (IBAction)blacklistItemAction:(id)sender;
- (IBAction)blacklistOkAction:(id)sender;

- (IBAction)credentialsOkAction:(id)sender;
- (IBAction)credentialsCancelAction:(id)sender;
- (IBAction)storeInKeychainToggleAction:(id)sender;

@end
