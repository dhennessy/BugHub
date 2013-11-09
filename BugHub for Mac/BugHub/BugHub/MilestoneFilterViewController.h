//
//  MilestoneFilterViewController.h
//  BugHub
//
//  Created by Randy on 1/25/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class BHIssueFilter, BHRepository;

@interface MilestoneFilterViewController : NSViewController<NSTableViewDataSource, NSTableViewDelegate>
{
    IBOutlet NSTableView *milestonesList;
    IBOutlet NSTextField *filterLabel;
}

@property(strong, nonatomic) BHIssueFilter *currentFilter;
@property(strong, nonatomic) BHRepository *repository;

- (IBAction)tableViewDidClickRow:(id)sender;

@end
