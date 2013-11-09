//
//  IssueDetailViewController.m
//  BugHub
//
//  Created by Randy on 1/1/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "IssueDetailViewController.h"
#import "BHIssue.h"
#import "BHRepository.h"
#import "BHUser.h"
#import "NSSet+Additions.h"
#import "AssigneePickerViewController.h"
#import "LabelPickerViewController.h"
#import "MilestonePickerViewController.h"
#import "BHRequestQueue.h"
#import "DetailView.h"
#import "MultipleSelectedDetailView.h"

@interface IssueDetailViewController ()
{
    NSSet *_representedIssues;
    NSMutableDictionary *_viewsOfSelectedIssues;
    
    NSPopover *activePopover;
}

- (void)_displayCorrectRootView;
- (void)_addObservers:(BHIssue *)anIssue;
- (void)_removeObservers:(BHIssue *)anIssue;

@end

@implementation IssueDetailViewController

/*- (id)initWithCoder:(NSCoder *)aDecoder
{
    return [self initWithNibName:@"IssueDetailViewController" bundle:nil];
}*/

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if(self)
    {
        _representedIssues = [NSSet set];
        _viewsOfSelectedIssues = [[NSMutableDictionary alloc] initWithCapacity:1];
    }
    
    return self;
}

- (void)_addObservers:(BHIssue *)anIssue
{
    [anIssue addObserver:self forKeyPath:@"title" options:0 context:NULL];
    [anIssue addObserver:self forKeyPath:@"htmlBody" options:0 context:NULL];
    [anIssue addObserver:self forKeyPath:@"milestone" options:0 context:NULL];
    [anIssue addObserver:self forKeyPath:@"number" options:0 context:NULL];
    [anIssue addObserver:self forKeyPath:@"assignee" options:0 context:NULL];
    [anIssue addObserver:self forKeyPath:@"labels" options:0 context:NULL];
    [anIssue addObserver:self forKeyPath:@"lastUpdated" options:0 context:NULL];
    [anIssue addObserver:self forKeyPath:@"dateCreated" options:0 context:NULL];
    [anIssue addObserver:self forKeyPath:@"creator" options:0 context:NULL];
    [anIssue addObserver:self forKeyPath:@"state" options:0 context:NULL];
    [anIssue addObserver:self forKeyPath:@"comments" options:0 context:NULL];
}

- (void)_removeObservers:(BHIssue *)anIssue
{
    [anIssue removeObserver:self forKeyPath:@"title"];
    [anIssue removeObserver:self forKeyPath:@"htmlBody"];
    [anIssue removeObserver:self forKeyPath:@"milestone"];
    [anIssue removeObserver:self forKeyPath:@"number"];
    [anIssue removeObserver:self forKeyPath:@"assignee"];
    [anIssue removeObserver:self forKeyPath:@"labels"];
    [anIssue removeObserver:self forKeyPath:@"lastUpdated"];
    [anIssue removeObserver:self forKeyPath:@"dateCreated"];
    [anIssue removeObserver:self forKeyPath:@"creator"];
    [anIssue removeObserver:self forKeyPath:@"state"];
    [anIssue removeObserver:self forKeyPath:@"comments"];
}

- (void)dealloc
{
    [_representedIssues enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        [self _removeObservers:obj];
    }];
}

- (void)setRepresentedIssues:(NSSet *)newIssues
{
    if ([newIssues isEqualToSet:_representedIssues])
        return;

    // we know they're not the same.
    //NSInteger previousCount = [_representedIssues count];

    // intersection set are the issue that didnt change
    NSSet *intersection = [_representedIssues setByIntersectingSet:newIssues];
    // everything in the current set not in the intersection should be removed...
    NSSet *issuesToRemove = [_representedIssues setBySubtractingSet:intersection];
    // everything in the new issue set not the in the intersection are new!
    NSSet *issuesToAdd = [newIssues setBySubtractingSet:intersection];

    // clean up.
    [issuesToRemove enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        [self _removeObservers:obj];
    }];

    [issuesToAdd enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        [self _addObservers:obj];
    }];

    // FIX ME: animate ALL the things.
    _representedIssues = [newIssues copy];
    
    [self.multipleDetailView removeIssues:issuesToRemove];
    [self.multipleDetailView showNewIssues:issuesToAdd];
    
    // FIX ME, this be borked probably when animations start happening. 
    [self _displayCorrectRootView];
}

- (NSSet *)representedIssues
{
    return [_representedIssues copy];
}

- (void)_displayCorrectRootView
{
    NSInteger currentCount = [_representedIssues count];

    if (currentCount == 0)
    {
        [self.singleDetailView removeFromSuperview];
        [self.multipleDetailView removeFromSuperview];

        [self.noIssuesSelectedView setFrame:[self.view bounds]];
        [self.view addSubview:self.noIssuesSelectedView];
    }
    else if(currentCount == 1)
    {
        [self.noIssuesSelectedView removeFromSuperview];
        [self.multipleDetailView removeFromSuperview];

        [self.singleDetailView setFrame:[self.view bounds]];
        [self.view addSubview:self.singleDetailView];

        BHIssue *issue = [_representedIssues anyObject];
        [self.singleDetailView setRepresentedIssue:issue];

    }
    else
    {
        [self.singleDetailView removeFromSuperview];
        [self.noIssuesSelectedView removeFromSuperview];

        [self.multipleDetailView setFrame:[self.view bounds]];
        [self.view addSubview:self.multipleDetailView];
    }
}

- (void)awakeFromNib
{
    [self _displayCorrectRootView];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"state"])
    {
        [self.delegate issuesDidChangeState:[NSSet setWithObject:object]];
    }
}

- (void)alertDidEnd:(NSAlert *)anAlert withReturnCode:(NSInteger)aReturnCode context:(void *)someContext
{
    if (aReturnCode == 0) // don't do action
        return;

    NSDictionary *context = (__bridge_transfer NSDictionary *)someContext;
    
    NSSet *issuesToChange = [context objectForKey:@"issues"];
    NSString *action = [context objectForKey:@"action"];
    
    if ([action isEqualToString:@"Close"] || [action isEqualToString:@"Open"])
    {
        BHIssueState newState = [action isEqualToString:@"Close"] ? BHClosedState : BHOpenState;
        for (BHIssue *anIssue in issuesToChange)
        {
            [anIssue setState:newState];
            [[BHRequestQueue mainQueue] addObject:anIssue];
        }
    }
    
    [self.delegate issuesDidChangeState:issuesToChange];
}


#pragma mark editing actions
- (IBAction)displayAssignees:(id)sender
{
    if (activePopover)
    {
        [activePopover performClose:self];
        activePopover = nil;
    }

    activePopover = [[NSPopover alloc] init];
    [activePopover setBehavior:NSPopoverBehaviorTransient];
    AssigneePickerViewController *vc = [[AssigneePickerViewController alloc] initWithNibName:@"AssigneePickerViewController" bundle:[NSBundle mainBundle]];
    vc.representedIssues = self.representedIssues;
    vc.repository = [[self.representedIssues anyObject] repository];
    vc.containingPopover = activePopover;

    [activePopover setContentViewController:vc];
    [activePopover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMinYEdge];
}

- (IBAction)displayLabels:(id)sender
{
    if (activePopover)
    {
        [activePopover performClose:self];
        activePopover = nil;
    }
    
    activePopover = [[NSPopover alloc] init];
    [activePopover setBehavior:NSPopoverBehaviorTransient];
    LabelPickerViewController *vc = [[LabelPickerViewController alloc] initWithNibName:@"LabelPickerViewController" bundle:[NSBundle mainBundle]];
    vc.representedIssues = self.representedIssues;
    vc.containingPopover = activePopover;
    [vc setRepoWindowController:(RepositoryWindowController *)self.delegate];

    [activePopover setContentViewController:vc];
    [activePopover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMinYEdge];
}

- (IBAction)displayMilestones:(id)sender
{
    if (activePopover)
    {
        [activePopover performClose:self];
        activePopover = nil;
    }
    
    activePopover = [[NSPopover alloc] init];
    [activePopover setBehavior:NSPopoverBehaviorTransient];
    MilestonePickerViewController *vc = [[MilestonePickerViewController alloc] initWithNibName:@"MilestonePickerViewController" bundle:[NSBundle mainBundle]];
    vc.representedIssues = self.representedIssues;
    vc.containingPopover = activePopover;
    [vc setRepoWindowController:(RepositoryWindowController *)self.delegate];

    [activePopover setContentViewController:vc];
    [activePopover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMinYEdge];
}

- (IBAction)addComment:(id)sender
{
    // don't make much sense to comment on the set of represented issue...
    // just toss it.
}

- (IBAction)reloadIssue:(id)sender
{
    for (BHIssue *anIssue in _representedIssues)
    {
        [anIssue reloadIssue];
    }
}

- (IBAction)closeIssue:(id)sender
{
    NSString *message = nil;
    
    if (_representedIssues.count > 1)
        message = [NSString stringWithFormat:@"Are you sure you want to close %ld issues?", _representedIssues.count];
    else
        message = [NSString stringWithFormat:@"Are you sure you want to close 1 issue?"];
    
    NSString *buttonText = _representedIssues.count > 1 ? @"Close Issues" : @"Close Issue";
    
    NSAlert *alert = [NSAlert alertWithMessageText:message defaultButton:buttonText alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@""];
    
    NSDictionary *context = @{
                                @"issues": [_representedIssues copy],
                                @"action": @"Close"
                              };

    [alert beginSheetModalForWindow:[self.view window] modalDelegate:self didEndSelector:@selector(alertDidEnd:withReturnCode:context:) contextInfo:(__bridge_retained void *)context];
}

- (IBAction)openIssue:(id)sender
{
    NSString *message = nil;
    
    if (_representedIssues.count > 1)
        message = [NSString stringWithFormat:@"Are you sure you want to open %ld issues?", _representedIssues.count];
    else
        message = [NSString stringWithFormat:@"Are you sure you want to open 1 issue?"];
    
    NSString *buttonText = _representedIssues.count > 1 ? @"Open Issues" : @"Open Issue";
    
    NSAlert *alert = [NSAlert alertWithMessageText:message defaultButton:buttonText alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@""];
    
    NSDictionary *context = @{
                              @"issues": [_representedIssues copy],
                              @"action": @"Open"
                              };
    
    [alert beginSheetModalForWindow:[self.view window] modalDelegate:self didEndSelector:@selector(alertDidEnd:withReturnCode:context:) contextInfo:(__bridge_retained void *)context];
}

- (void)addLabel:(BHLabel *)aLabel
{
    [self.representedIssues makeObjectsPerformSelector:@selector(addLabel:) withObject:aLabel];

    for (BHIssue *anIssue in self.representedIssues)
        [[BHRequestQueue mainQueue] addObject:anIssue];
}

- (void)removeLabel:(BHLabel *)aLabel
{
    [self.representedIssues makeObjectsPerformSelector:@selector(removeLabel:) withObject:aLabel];
    
    for (BHIssue *anIssue in self.representedIssues)
        [[BHRequestQueue mainQueue] addObject:anIssue];
}

- (void)setMilestone:(BHMilestone *)aMilestone
{
    [self.representedIssues makeObjectsPerformSelector:@selector(setMilestone:) withObject:aMilestone];
    
    for (BHIssue *anIssue in self.representedIssues)
        [[BHRequestQueue mainQueue] addObject:anIssue];
}

- (void)setAssignee:(BHUser *)aUser
{
    [self.representedIssues makeObjectsPerformSelector:@selector(setAssignee:) withObject:aUser];
    
    for (BHIssue *anIssue in self.representedIssues)
        [[BHRequestQueue mainQueue] addObject:anIssue];
}

- (BOOL)hasClosableIssue
{
    for (BHIssue *issue in self.representedIssues) {
        if (issue.state == BHOpenState)
            return YES;
    }
    
    return NO;
}

- (BOOL)hasOpenableIssue
{
    for (BHIssue *issue in self.representedIssues) {
        if (issue.state == BHClosedState)
            return YES;
    }

    return NO;
}

@end
