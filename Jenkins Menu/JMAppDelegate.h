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

static NSString *const qUserDefaultsUrlKey = @"jenkinsUrl";
static NSString *const qUserDefaultsIntervalKey = @"interval";

@interface JMAppDelegate : NSObject <NSApplicationDelegate, NSUserInterfaceValidations, GrowlApplicationBridgeDelegate, JMJenkinsDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSMenu *menu;
@property (weak) IBOutlet NSMenuItem *statusMenuItem;
@property (weak) IBOutlet NSTextField *urlTextField;
@property (weak) IBOutlet NSTextField *intervalTextField;

@property NSStatusItem *statusItem;
@property NSTimer *timer;
@property NSUserDefaults *userDefaults;

@property JMJenkins *jenkins;
@property NSURL *jenkinsUrl;
@property NSURL *jenkinsXmlUrl;
@property NSTimeInterval interval;

- (IBAction)updateNowAction:(id)sender;
- (IBAction)openJenkinsUrlAction:(id)sender;
- (IBAction)openPreferencesWindowAction:(id)sender;
- (IBAction)setPreferencesAction:(id)sender;

@end
