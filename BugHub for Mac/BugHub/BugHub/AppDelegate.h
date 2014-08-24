//
//  AppDelegate.h
//  BugHub
//
//  Created by Randy on 12/25/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BHRequestQueue;

typedef enum {
        GHAPIStatusGood,
        GHAPIStatusMajor,
        GHAPIStatusMinor
} GHCurrentAPIStatus;

@interface AppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate, NSUserNotificationCenterDelegate, NSTextFieldDelegate>
{
    IBOutlet NSPanel *prefPane;
    IBOutlet NSTextField *loginTextField;
    IBOutlet NSButton *logoutButton;
    
    // quick open
    IBOutlet NSWindow *quickOpenWindow;
    IBOutlet NSTextField *quickOpenTextfield;
    IBOutlet NSButton *quickOpenButton;
}

@property(strong) BHRequestQueue *requestQueue;
@property GHCurrentAPIStatus apiStatus;

- (IBAction)login:(id)sender;
- (IBAction)logout:(id)sender;
- (IBAction)openLinksInBugHub:(id)sender;
- (IBAction)showPrefsWindow:(id)sender;

// quick open
- (IBAction)quickOpen:(id)sender;
- (IBAction)quickOpenAction:(id)sender;
- (BOOL)validateLinkText:(NSString *)aString;

- (BOOL)shouldOpenLinksInBugHub;
- (BOOL)openBugHubSchemeURL:(NSString *)aString;
- (BOOL)attemptToOpenGitHubURL:(NSString *)aPath;

- (IBAction)openRepoChooser:(id)sender;
- (void)closeAllRepoWindows;

- (id)openRepoWindow:(NSString *)aRepoIdentifier;
- (void)openWindowController:(NSWindowController *)aWindowController;
- (void)windowControllerDidClose:(NSWindowController *)aWindowController;
- (id)windowControllerWithIdentifier:(NSString *)anIdentifier;

- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent;

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem;

- (void)checkAPIStatus;

- (void)setupDefaultValues;

@end
