//
//  NewIssueWindowController.h
//  BugHub
//
//  Created by Randy on 1/5/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BHRepository, BHIssue;

@interface NewIssueWindowController : NSWindowController<NSAlertDelegate, NSTokenFieldDelegate, NSWindowDelegate>

- (id)initWithRepository:(BHRepository *)aRepo;
- (id)initWithIssue:(BHIssue *)anIssue;

@property(strong) IBOutlet NSTextField *titleField;
@property(strong) IBOutlet NSTokenField *labelsField;
@property(strong) IBOutlet NSPopUpButton *milestoneButton;
@property(strong) IBOutlet NSPopUpButton *assigneeButton;
@property(strong) IBOutlet NSTextView *bodyField;
@property(strong) IBOutlet NSButton *saveButton;
@property(strong) IBOutlet NSButton *cancelButton;
@property(strong) IBOutlet NSButton *labelListButton;
@property(strong) IBOutlet NSWindow *createMilestoneWindow;
@property(strong) IBOutlet NSProgressIndicator *spinner;

@property(strong) NSMutableSet *retainSetThingBecauseMenoryManagementSucks;

@property(strong) BHRepository *repository;
@property(strong) BHIssue *issue;

- (IBAction)submitButtonPushed:(id)sender;
- (IBAction)cancelButtonPushed:(id)sender;

- (IBAction)listLabels:(id)sender;
- (void)addLabelsSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
@end
