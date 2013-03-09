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

@interface JMAppDelegate : NSObject <NSApplicationDelegate, NSURLConnectionDelegate, NSUserInterfaceValidations, GrowlApplicationBridgeDelegate, JMJenkinsDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSMenu *menu;
@property (assign) IBOutlet NSMenuItem *statusMenuItem;
@property (assign) IBOutlet NSTextField *urlTextField;
@property (assign) IBOutlet NSTextField *intervalTextField;

@property (readwrite, strong) NSURL *jenkinsXmlUrl;
@property (readwrite, strong) NSURL *jenkinsUrl;
@property (readwrite, assign) NSTimeInterval interval;

- (IBAction)updateNowAction:(id)sender;
- (IBAction)openJenkinsUrlAction:(id)sender;
- (IBAction)openPreferencesWindowAction:(id)sender;
- (IBAction)setPreferencesAction:(id)sender;

@end
