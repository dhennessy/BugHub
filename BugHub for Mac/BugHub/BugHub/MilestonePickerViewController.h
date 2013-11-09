//
//  MilestonePickerViewController.h
//  BugHub
//
//  Created by Randy on 1/26/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RepositoryWindowController;

@interface MilestonePickerViewController : NSViewController<NSTableViewDelegate, NSTableViewDataSource>

@property(strong) IBOutlet NSTableView *milestoneList;
@property(strong) IBOutlet NSTextField *filterLabel;
@property(strong, nonatomic) NSSet *representedIssues;
@property(weak) NSPopover *containingPopover;
@property(weak) RepositoryWindowController *repoWindowController;

- (IBAction)createNewMilestone:(id)sender;

@end
