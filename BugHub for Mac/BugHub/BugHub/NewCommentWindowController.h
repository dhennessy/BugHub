//
//  NewCommentWindowController.h
//  BugHub
//
//  Created by Randy on 3/12/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BHIssue;

@interface NewCommentWindowController : NSWindowController<NSWindowDelegate>

@property(strong) IBOutlet NSTextField *titleLabel;
@property(strong) IBOutlet NSTextView *bodyField;
@property(strong) IBOutlet NSButton *submitButton;
@property(strong) IBOutlet NSProgressIndicator *spinner;

@property(strong) BHIssue *issue;
@property(strong) NSMutableSet *retainSetThing; // ugh.

- (IBAction)submitCommentButtonClicked:(id)sender;

@end
