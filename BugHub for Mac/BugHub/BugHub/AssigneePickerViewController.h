//
//  AssigneePickerViewController.h
//  BugHub
//
//  Created by Randy on 1/26/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BHRepository;

@interface AssigneePickerViewController : NSViewController<NSTableViewDataSource, NSTableViewDelegate>
{
    IBOutlet NSTextField *titleField;
}

@property(strong) IBOutlet NSTableView *assigneeList;
@property(strong, nonatomic) NSSet *representedIssues;
@property(strong, nonatomic) BHRepository *repository;
@property(weak) NSPopover *containingPopover;

@end
