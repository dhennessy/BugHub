//
//  RepositoryWindowController.h
//  BugHub
//
//  Created by Randy on 12/28/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BHWindowControllerIdentifier.h"
#import "IssueDetailWindowController.h"
#import "DetailViewControllerDelegate.h"
#import "EQSTRScrollView.h"

@class BHRepository, BHIssue, IssueDetailViewController, RLView;

@interface RepositoryWindowController : NSWindowController<NSWindowRestoration, BHWindowControllerIdentifier, BHIssueDetailWindowControllerDelegate, DetailViewControllerDelegate, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate, NSSplitViewDelegate, NSPopoverDelegate, NSMenuDelegate>
{
    IBOutlet NSSplitView *splitview;
    IBOutlet IssueDetailViewController *detailViewController;
    
    IBOutlet RLView *filterBar;
    IBOutlet NSButton *searchFilterButton,
                      *milestoneFilterButton,
                      *assigneeFilterButton,
                      *labelFilterButton;
    
    IBOutlet NSButton *newIssueButton;
    
    IBOutlet NSSegmentedControl *issueStateFilterButton;
    
    NSButton *addCommentButton,
             *addLabelButton,
             *addMilestoneButton,
             *addAssigneeButton,
             *closeIssueButton,
             *openIssueButton;
    
    IBOutlet NSProgressIndicator *loadingIssuesView;
    IBOutlet NSView *noIssuesToDisplayView;
    
    IBOutlet EQSTRScrollView *issueListScrollView;
    IBOutlet NSTextField *countField;
}

- (id)initWithRepositoryIdentifier:(NSString *)anIdentifier;

// If the issue is not loaded, download it dood.
- (void)forceSelectIssueWithNumber:(NSInteger)anIssueNumber;
- (void)selectIssue:(BHIssue *)anIssue;
- (IBAction)didDoubleClickIssue:(id)sender;

@property(strong) IBOutlet NSTableView *issueList;
@property(strong) BHRepository *repository;

- (IBAction)searchFilterButtonClicked:(id)sender;
- (IBAction)labelsFilterButtonClicked:(id)sender;
- (IBAction)assigneeFilterButtonClicked:(id)sender;
- (IBAction)milestoneFilterButtonClicked:(id)sender;

- (IBAction)newIssueButtonClicked:(id)sender;
- (void)editIssue:(BHIssue *)anIssue;
- (IBAction)newCommentButtonClicked:(id)sender;
- (IBAction)showClosedIssues:(id)sender;
- (IBAction)showOpenedIssues:(id)sender;
- (IBAction)mainMenuCloseIssues:(id)sender;
- (IBAction)mainMenuOpenIssues:(id)sender;


- (IBAction)issueStateFilterButtonClicked:(id)sender;
- (NSInteger)makeSelectedIssueVisible;

- (void)updateFilterHighlights;
- (void)updateIssueButtons;

- (IBAction)menuCloseIssue:(id)sender;
- (IBAction)menuOpenIssue:(id)sender;
- (IBAction)menuReloadIssue:(id)sender;
- (IBAction)menuCommentOnIssue:(id)sender;
- (IBAction)menuLabelIssue:(id)sender;
- (IBAction)menuMilestoneIssue:(id)sender;
- (IBAction)menuAssigneIssue:(id)sender;
- (IBAction)menuViewIssueOnGithub:(id)sender;

- (void)newLabelOrMilestoneSheeDidEnd:(NSWindow *)aSheet returnCode:(NSInteger)aReturnCode context:(void *)someContext;
@end
