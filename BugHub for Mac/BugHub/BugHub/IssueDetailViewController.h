//
//  IssueDetailViewController.h
//  BugHub
//
//  Created by Randy on 1/1/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DetailViewControllerDelegate.h"

@class DetailView, BHLabel, BHMilestone, BHUser, MultipleSelectedDetailView;

@interface IssueDetailViewController : NSViewController//<WebPolicyDelegate>

@property(strong) IBOutlet DetailView *singleDetailView;
@property(strong) IBOutlet MultipleSelectedDetailView *multipleDetailView;
@property(strong) IBOutlet NSView *noIssuesSelectedView;

@property(nonatomic) NSSet *representedIssues;
@property(weak) IBOutlet id<DetailViewControllerDelegate> delegate;

- (IBAction)displayAssignees:(id)sender;
- (IBAction)displayLabels:(id)sender;
- (IBAction)displayMilestones:(id)sender;

- (IBAction)addComment:(id)sender;
- (IBAction)reloadIssue:(id)sender;
- (IBAction)closeIssue:(id)sender;
- (IBAction)openIssue:(id)sender;

- (void)addLabel:(BHLabel *)aLabel;
- (void)removeLabel:(BHLabel *)aLabel;
- (void)setMilestone:(BHMilestone *)aMilestone;
- (void)setAssignee:(BHUser *)aUser;

- (BOOL)hasClosableIssue;
- (BOOL)hasOpenableIssue;


- (void)alertDidEnd:(NSAlert *)anAlert withReturnCode:(NSInteger)aReturnCode context:(void *)someContext;
@end
