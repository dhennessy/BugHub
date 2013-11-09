//
//  IssueDetailWindowController.m
//  BugHub
//
//  Created by Randy on 1/1/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "IssueDetailWindowController.h"
#import "IssueDetailViewController.h"
#import "BHRepository.h"
#import "BHIssue.h"
#import "BHUser.h"
#import "BHIssueFilter.h"
#import "GHAPIRequest.h"
#import "NSURL+GHExtentions.h"

@interface IssueDetailWindowController ()
{
    IssueDetailViewController *detailViewController;
    GHAPIRequest *_downloadRequest;
}
- (id)_init;
- (void)_addObservers;

@end

@implementation IssueDetailWindowController

- (id)_init
{
    NSWindow *newWindow = [[NSWindow alloc] initWithContentRect:CGRectMake(0, 0, 545, 550)
                                                      styleMask:NSTitledWindowMask|NSClosableWindowMask|NSResizableWindowMask|NSMiniaturizableWindowMask
                                                        backing:NSBackingStoreBuffered
                                                          defer:NO];
    [newWindow center];

    self = [self initWithWindow:newWindow];
    
    if (self)
    {
        detailViewController = [[IssueDetailViewController alloc] initWithNibName:@"IssueDetailViewController" bundle:nil];
        
        [[newWindow contentView] addSubview:detailViewController.view];
        newWindow.delegate = self;
    }
    
    return self;
}

- (id)initWithIssue:(BHIssue *)anIssue
{
    self = [self _init];
    
    if (self)
    {
        self.issue = anIssue;
        [detailViewController setRepresentedIssues:[NSSet setWithObject:self.issue]];
        [self.window setTitle:[[anIssue repository] identifier]];
        [self _addObservers];
        [anIssue downloadIfNeeded];
    }
    
    return self;
}

// Init with HTML URL (not an API url)
- (id)initWithIssueURL:(NSString *)anIssueURL
{
    NSURL *urlObj = [NSURL URLWithString:anIssueURL];
    NSString *repositoryIdentifier = [urlObj repositoryIdentifier];
    NSInteger issueNumber = [urlObj issueNumber];
    
    if (issueNumber == NSNotFound)
        return nil;
    
    BHRepository *repo = [BHRepository repositoryWithIdentifier:repositoryIdentifier dictionaryValues:nil];
    BHIssue *anIssue = [repo issueWithURL:anIssueURL];
    
    return [self initWithIssue:anIssue];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [[self delegate] issueDetailWindowControllerWillClose:self];
}

- (void)_addObservers
{
    [self.issue addObserver:self forKeyPath:@"state" options:0 context:NULL];
    [self.issue addObserver:self forKeyPath:@"repository.identifier" options:0 context:NULL];
}

- (void)dealloc
{
    [self.issue removeObserver:self forKeyPath:@"state"];
    [self.issue removeObserver:self forKeyPath:@"repository.identifier"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"state"])
    {
        if ([self.issue state] == BHUnknownState)
        {
            NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Download Failed", nil)
                                             defaultButton:NSLocalizedString(@"Okay", nil)
                                           alternateButton:NSLocalizedString(@"Try Again", nil)
                                               otherButton:nil
                                 informativeTextWithFormat:NSLocalizedString(@"Unable to download issue from GitHub.", nil)];
            
            [alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
        }
    }
    else if([keyPath isEqualToString:@"repository.identifier"])
    {
        [self.window setTitle:[[self.issue repository] identifier]];
    }
}

#pragma mark alert delegate
- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == 1)
    {
        // try again.
        [self.issue downloadIfNeeded];
    }
    else
    {
        [[self delegate] issueDetailWindowControllerWillClose:self];
        [self close];
    }
}

@end
