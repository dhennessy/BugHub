//
//  LabelPickerViewController.h
//  BugHub
//
//  Created by Randy on 1/26/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RepositoryWindowController;

@interface LabelPickerViewController : NSViewController<NSTableViewDataSource, NSTableViewDelegate>

@property(strong) IBOutlet NSTableView *labelList;
@property(strong) IBOutlet NSTextField *filterLabel;
@property(strong, nonatomic) NSSet *representedIssues;
@property(weak) NSPopover *containingPopover;
@property(weak) RepositoryWindowController *repoWindowController;


- (IBAction)tableViewWasClicked:(id)sender;
- (IBAction)createNewLabel:(id)sender;

@end
