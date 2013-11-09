//
//  DetailView.h
//  BugHub
//
//  Created by Randy on 3/4/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RLView.h"

@class BHIssue;

@interface DetailView : RLView<NSMenuDelegate>

@property(strong) IBOutlet NSMenu *contextMenu;
@property(nonatomic) BOOL isEnabled;

- (void)setRepresentedIssue:(BHIssue *)anIssue;
- (BHIssue *)representedIssue;

//- (void)editIssue:(id)sender;

- (void)adjustViewHeights;
- (void)deleteComment:(NSInteger)aCommentNumber;

- (IBAction)menuCloseIssue:(id)sender;
- (IBAction)menuOpenIssue:(id)sender;
- (IBAction)menuReloadIssue:(id)sender;
- (IBAction)menuCommentOnIssue:(id)sender;
- (IBAction)menuLabelIssue:(id)sender;
- (IBAction)menuMilestoneIssue:(id)sender;
- (IBAction)menuAssigneIssue:(id)sender;
- (IBAction)menuViewIssueOnGithub:(id)sender;


@end
