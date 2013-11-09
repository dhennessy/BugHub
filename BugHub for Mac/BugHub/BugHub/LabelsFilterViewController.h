//
//  LabelsFilterViewController.h
//  BugHub
//
//  Created by Randy on 1/24/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BHIssueFilter, BHRepository;

@interface LabelsFilterViewController : NSViewController<NSTableViewDataSource, NSTableViewDelegate>
{
    IBOutlet NSTableView *labelsList;
    IBOutlet NSTextField *filterLabel;
}

@property(strong, nonatomic) BHIssueFilter *currentFilter;
@property(strong, nonatomic) BHRepository *repository;

- (IBAction)tableViewWasClicked:(id)sender;

@end
