//
//  LoginViewController.h
//  BugHub
//
//  Created by Randy on 12/28/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LoginWindowController : NSWindowController<NSWindowDelegate>
{
    IBOutlet NSView *fieldsContainerView;
    IBOutlet NSProgressIndicator *spinnerView;
    
    IBOutlet NSImageView *nameIV;
    IBOutlet NSImageView *iconVIew;
    
    IBOutlet NSButton *goButton;
    
    IBOutlet NSImageView *fieldsUnderlay;
}

@property(strong) IBOutlet NSTextField *usernameField;
@property(strong) IBOutlet NSSecureTextField *passwordField;

- (IBAction)cancelButtonPushed:(id)sender;
- (IBAction)loginClicked:(id)sender;

@end
