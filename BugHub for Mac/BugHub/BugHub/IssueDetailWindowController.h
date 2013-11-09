//
//  IssueDetailWindowController.h
//  BugHub
//
//  Created by Randy on 1/1/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol BHIssueDetailWindowControllerDelegate <NSObject>

- (void)issueDetailWindowControllerWillClose:(id)sender;

@end

@class BHIssue;

@interface IssueDetailWindowController : NSWindowController<NSWindowDelegate, NSAlertDelegate>

@property(strong) BHIssue *issue;
@property(weak) id<BHIssueDetailWindowControllerDelegate> delegate;

- (id)initWithIssue:(BHIssue *)anIssue;

// Init with HTML URL (not an API url)
- (id)initWithIssueURL:(NSString *)anIssueURL;

@end
