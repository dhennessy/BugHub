//
//  NewMilestoneWindowController.h
//  BugHub
//
//  Created by Randy on 3/12/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BHRepository, BHMilestone;

@interface NewMilestoneWindowController : NSWindowController


@property(strong) IBOutlet NSTextField *titleField;
@property(strong) IBOutlet NSDatePicker *deadlinePicker;
@property(strong) IBOutlet NSTextField *bodyField;
@property(strong) IBOutlet NSButton *clearDeadlineButton;
@property(strong) IBOutlet NSButton *setDeadlineButton;
@property(strong) IBOutlet NSButton *submitButton;
@property(strong) IBOutlet NSButton *cancelButton;
@property(strong) BHRepository *repo;
@property(strong) IBOutlet NSProgressIndicator *spinner;

@property(strong) BHMilestone *milestone;


- (IBAction)cancel:(id)sender;
- (IBAction)createMilestone:(id)sender;
- (IBAction)toggleDeadline:(id)sender;


@end
