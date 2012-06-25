//
//  JMAppDelegate.h
//  Jenkins Menu
//
//  Created by Tae Won Ha on 6/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface JMAppDelegate : NSObject <NSApplicationDelegate, NSURLConnectionDelegate, NSUserInterfaceValidations>

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
