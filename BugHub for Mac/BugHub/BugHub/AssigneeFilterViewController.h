//
//  AssigneeFilterViewController.h
//  BugHub
//
//  Created by Randy on 1/26/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BHRepository, BHIssueFilter;

@interface AssigneeFilterViewController : NSViewController<NSTableViewDelegate, NSTableViewDataSource>
{
    IBOutlet NSTableView *assigneeList;
    IBOutlet NSTextField *filterLabel;
}

@property(strong, nonatomic) BHIssueFilter *currentFilter;
@property(strong, nonatomic) BHRepository *repository;

- (IBAction)tableViewWasClicked:(id)sender;

@end
