//
//  IssueDetailHeaderView.h
//  BugHub
//
//  Created by Randy on 3/4/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BHIssue, DetailView;

@interface IssueDetailHeaderView : NSView

@property(weak) DetailView *parentView;

- (void)setRepresentedIssue:(BHIssue *)anIssue;

@end
