//
//  RepositoryWindowController.m
//  BugHub
//
//  Created by Randy on 12/28/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import "AppDelegate.h"
#import "RepositoryWindowController.h"
#import "INAppStoreWindow.h"
#import "BHRepository.h"
#import "BHUser.h"
#import "BHMilestone.h"
#import "BHLabel.h"
#import "BHIssue.h"
#import "GHAPIRequest.h"
#import "IssueListTableCellView.h"
#import "BHIssueFilter.h"
#import "IssueDetailViewController.h"
#import "IssueDetailWindowController.h"
#import "RLView.h"
#import "LabelsFilterViewController.h"
#import "MilestoneFilterViewController.h"
#import "AssigneeFilterViewController.h"
#import "SearchFilterViewController.h"
#import "NSColor+hex.h"
#import "NSObject+AssociatedObjects.h"
#import "BHRequestQueue.h"
#import "NewIssueWindowController.h"
#import "NewCommentWindowController.h"
#import "NewLabelWindowController.h"
#import "NewMilestoneWindowController.h"
#import "WindowButton.h"

#import <CoreGraphics/CoreGraphics.h>

@interface RepositoryWindowController ()
{
    BHIssueFilter *filter;

    NSView *filterView;
    NSArray *filteredIssues;
    
    NSMutableSet *openIssueWindows;
    
    NSPopover *activePopover;
    
    NSSet *_contextMenuIssues;
    
    NSMutableSet *newIssueWindows;
    
    NSMutableSet *newCommentWindows;
}

- (void)_handleFilterChangeByRemoving:(BOOL)aFlag;
- (void)_handleIssueChange;
- (void)_handleIsPrivateChange;
- (void)_handleHasLoadedChange;
- (void)_handleHasIssuesChange;
- (void)_showRepoLoadingView;
- (void)_openIssueWindowsForIndexes:(NSIndexSet *)indexes;
- (NSMutableString *)attribtuedOwnerStringForWindowTitle;
- (NSMutableString *)attribtuedStringForWindowTitle;

- (void)_pullToReloadTriggered;

@end

@implementation RepositoryWindowController

@synthesize identifier;

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if ([[menuItem title] isEqualToString:@"Comment on Issue"])
        return ![addCommentButton isHidden];
    else if ([[menuItem title] isEqualToString:@"Close Issue"])
        return [detailViewController hasClosableIssue];
    else if ([[menuItem title] isEqualToString:@"Open Issue"])
        return [detailViewController hasOpenableIssue];
    else if ([[menuItem title] isEqualToString:@"Show Closed Issues"])
        return [issueStateFilterButton selectedSegment] != 1;
    else if ([[menuItem title] isEqualToString:@"Show Open Issues"])
        return [issueStateFilterButton selectedSegment] != 0;

    return YES;
}

- (void)moveDown:(id)sender
{
    [self.window makeFirstResponder:self.issueList];
    
    NSInteger selectedRow = [self.issueList selectedRow];
    
    if (selectedRow == -1 && [self.issueList numberOfRows] > 0)
        [self.issueList selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    else if ([self.issueList numberOfRows] > 0)
        [self.issueList selectRowIndexes:[NSIndexSet indexSetWithIndex:MIN([self.issueList numberOfRows] - 1, [self.issueList selectedRow] + 1)] byExtendingSelection:NO];
    
    [self.issueList scrollRowToVisible:[self.issueList selectedRow]];

}

- (void)moveUp:(id)sender
{
    [self.window makeFirstResponder:self.issueList];
    
    NSInteger selectedRow = [self.issueList selectedRow];
    
    if (selectedRow == -1 && [self.issueList numberOfRows] > 0)
        [self.issueList selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    else if ([self.issueList numberOfRows] > 0)
        [self.issueList selectRowIndexes:[NSIndexSet indexSetWithIndex:MAX(0, [self.issueList selectedRow] - 1)] byExtendingSelection:NO];
    
    [self.issueList scrollRowToVisible:[self.issueList selectedRow]];
}

- (void)moveLeft:(id)sender
{
    [self.window makeFirstResponder:self.issueList];
    
    NSInteger selectedRow = [self.issueList selectedRow];
    
    if (selectedRow == -1 && [self.issueList numberOfRows] > 0)
        [self.issueList selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
}

- (void)moveRight:(id)sender
{
    [self.window makeFirstResponder:self.issueList];
    
    NSInteger selectedRow = [self.issueList selectedRow];
    
    if (selectedRow == -1 && [self.issueList numberOfRows] > 0)
        [self.issueList selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
}


- (id)initWithRepositoryIdentifier:(NSString *)anIdentifier
{
    self = [self initWithWindowNibName:@"RepositoryWindowController" owner:self];
    
    if (self)
    {

        self.repository = [BHRepository repositoryWithIdentifier:anIdentifier dictionaryValues:nil];
        [self.repository addObserver:self forKeyPath:@"issues" options:0 context:NULL];
        [self.repository addObserver:self forKeyPath:@"isPrivate" options:0 context:NULL];
        [self.repository addObserver:self forKeyPath:@"isLoaded" options:0 context:NULL];
        [self.repository addObserver:self forKeyPath:@"hasIssues" options:0 context:NULL];
        [self.repository addObserver:self forKeyPath:@"identifier" options:0 context:NULL];
        [self.repository addObserver:self forKeyPath:@"owner" options:0 context:NULL];

        [self setIdentifier:anIdentifier];
        [self.window setRestorationClass:self.class];
        [self.window setIdentifier:anIdentifier];


        openIssueWindows = [NSMutableSet setWithCapacity:0];
        
        filter = [[BHIssueFilter alloc] init];
        [filter addObserver:self forKeyPath:@"filterValue" options:0 context:NULL];
        
        newIssueWindows = [NSMutableSet setWithCapacity:1];
        newCommentWindows = [NSMutableSet setWithCapacity:1];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginStatusDidChange:) name:BHLoginChangedNotification object:nil];
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BHLoginChangedNotification object:nil];
    [self.repository removeObserver:self forKeyPath:@"issues"];
    [self.repository removeObserver:self forKeyPath:@"isPrivate"];
    [self.repository removeObserver:self forKeyPath:@"isLoaded"];
    [self.repository removeObserver:self forKeyPath:@"hasIssues"];
    [self.repository removeObserver:self forKeyPath:@"identifier"];
    [self.repository removeObserver:self forKeyPath:@"owner"];
    [filter removeObserver:self forKeyPath:@"filterValue"];
}

- (void)awakeFromNib
{
    NSView *rightView = [[splitview subviews] objectAtIndex:1];
    NSView *detailView = [detailViewController view];
    [detailView setFrame:[rightView bounds]];
    [rightView addSubview:[detailViewController view]];

    __weak typeof(self) welf = self;
    [issueListScrollView setRefreshBlock:^(EQSTRScrollView *theScrollView) {
        // looks weird when the connection is blazing fast. 
        [welf _pullToReloadTriggered];
    }];
    
    [filterBar setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"dark_texture_bg"]]];
    
    [self.issueList setDoubleAction:@selector(didDoubleClickIssue:)];
    [self.issueList registerNib:[[NSNib alloc] initWithNibNamed:@"IssueListTableCellView" bundle:nil] forIdentifier:@"BHIssueListCellIdentifier"];
    [self _showRepoLoadingView];
    [self.repository loadOpenIssues];
}

- (void)_pullToReloadTriggered
{
    __weak typeof(self) welf = self;

    [self.repository loadNewIssues:^(BOOL someIssueStateDidChange){
        __strong typeof(welf) strongSelf = welf;

        if (someIssueStateDidChange)
            [welf _handleIssueChange];

        if (strongSelf)
        {
            [strongSelf->issueListScrollView performSelector:@selector(stopLoading) withObject:nil afterDelay:2.0];
            [strongSelf->issueListScrollView stopLoading];
        }
    }];
}


- (void)loginStatusDidChange:(NSNotification *)aNote
{
    [self updateIssueButtons];
}

// select an issue even if it's not in the source list
// this willl likely get called from some URI shit
- (void)forceSelectIssueWithNumber:(NSInteger)anIssueNumber
{
    NSSet *allIssues = [self.repository allIssues];

    // Thoughts:
    // Since this returns a copy of the set of issues, we can know that if
    // the issue has been downloaded it's in the set.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BHIssue *foundIssue = nil;
        
        for (BHIssue *anIssue in allIssues)
        {
            if ([anIssue number] == anIssueNumber)
            {
                foundIssue = anIssue;
                break;
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (foundIssue)
                [self selectIssue:foundIssue];
            else
            {
                [self.repository downloadIssueNumber:anIssueNumber withCallback:^(BHIssue *newIssue){
                    if (newIssue)
                    {
                        [self selectIssue:newIssue];
                        if ([newIssue state] == BHOpenState)
                            [self showOpenedIssues:nil];
                        else if ([newIssue state] == BHClosedState)
                            [self showClosedIssues:nil];
                        
                        
                        NSInteger row = [self makeSelectedIssueVisible];
                        // it never should...
                        if (row != NSNotFound)
                            [self.issueList selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
                    }
                }];
            }
        });
    });
}

- (void)selectIssue:(BHIssue *)anIssue
{
    NSInteger indexOfObj = [filteredIssues indexOfObject:anIssue];

    // if the object is in the currently displayed list, select it
    if (indexOfObj != NSNotFound)
    {
        [self.issueList selectRowIndexes:[NSIndexSet indexSetWithIndex:indexOfObj] byExtendingSelection:NO];
        // set the issue to the detail issue thingy
        [self tableViewSelectionDidChange:nil];
    }
    else
    {
        // otherwise just show it in the detail view.
        [detailViewController setRepresentedIssues:[NSSet setWithObject:anIssue]];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    static NSString *issuesKey = @"issues";
    static NSString *privateKey = @"isPrivate";
    static NSString *loadedKey = @"isLoaded";
    static NSString *hasIssuesKey = @"hasIssues";
    static NSString *identifierKey = @"identifier";
    static NSString *filterValueKey = @"filterValue";
    static NSString *ownerValuleKey = @"owner";
    static NSString *nameKey = @"name";
    
    
    if ([keyPath isEqualToString:issuesKey])
    {
        [self _handleIssueChange];
    }
    if ([keyPath isEqualToString:filterValueKey])
    {
        [self _handleFilterChangeByRemoving:[filter lastChangeWasStricter]];
    }
    else if ([keyPath isEqualToString:loadedKey])
    {
        [self _handleHasLoadedChange];
    }
    else if([keyPath isEqualToString:hasIssuesKey])
    {
        [self _handleHasIssuesChange];
    }
    else if ([keyPath isEqualToString:privateKey])
    {
        [self _handleIsPrivateChange];
    }
    else if([keyPath isEqualToString:identifierKey])
    {
        [self _handleIdentifierChange];
    }
    else if ([keyPath isEqualToString:ownerValuleKey])
    {
        //[self willChangeValueForKey:@"attribtuedOwnerStringForWindowTitle"];
        [self didChangeValueForKey:@"attribtuedOwnerStringForWindowTitle"];
    }
    else if ([keyPath isEqualToString:nameKey])
    {
        [self didChangeValueForKey:@"attribtuedStringForWindowTitle"];
    }
}


#pragma mark filters
- (void)updateFilterHighlights
{
    id activePopoverVC = nil;
    
    if(activePopover.isShown)
        activePopoverVC = [activePopover contentViewController];
    
    // search
    if (filter.text.length || [activePopoverVC isKindOfClass:[SearchFilterViewController class]])
        [searchFilterButton setState:NSOnState];
    else
        [searchFilterButton setState:NSOffState];
    
    
    // labels
    if (filter.labels.count || [activePopoverVC isKindOfClass:[LabelsFilterViewController class]])
        [labelFilterButton setState:NSOnState];
    else
        [labelFilterButton setState:NSOffState];
    
    
    // milestones
    if (filter.milestones.count || [activePopoverVC isKindOfClass:[MilestoneFilterViewController class]])
        [milestoneFilterButton setState:NSOnState];
    else
        [milestoneFilterButton setState:NSOffState];
    
    
    // assignees
    if (filter.assignedTo.count || [activePopoverVC isKindOfClass:[AssigneeFilterViewController class]])
        [assigneeFilterButton setState:NSOnState];
    else
        [assigneeFilterButton setState:NSOffState];
}

- (IBAction)searchFilterButtonClicked:(id)sender
{
    if (activePopover)
    {
        [activePopover performClose:self];
        activePopover = nil;
    }

    activePopover = [[NSPopover alloc] init];
    [activePopover setDelegate:self];
    [activePopover setBehavior:NSPopoverBehaviorTransient];
    SearchFilterViewController *vc = [[SearchFilterViewController alloc] initWithNibName:@"SearchFilterViewController" bundle:[NSBundle mainBundle]];
    vc.filter = filter;
    vc.containingPopover = activePopover;
    [activePopover setContentViewController:vc];

    [activePopover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxXEdge];
    
    [self updateFilterHighlights];
}

- (IBAction)labelsFilterButtonClicked:(id)sender
{
    if (activePopover)
    {
        [activePopover performClose:self];
        activePopover = nil;
    }

    activePopover = [[NSPopover alloc] init];
    [activePopover setDelegate:self];
    [activePopover setBehavior:NSPopoverBehaviorTransient];
    LabelsFilterViewController *vc = [[LabelsFilterViewController alloc] initWithNibName:@"LabelsFilterViewController" bundle:[NSBundle mainBundle]];
    vc.currentFilter = filter;
    vc.repository = self.repository;
    [activePopover setContentViewController:vc];

    [activePopover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxXEdge];
    
    [self updateFilterHighlights];
}

- (IBAction)assigneeFilterButtonClicked:(id)sender
{
    if (activePopover)
    {
        [activePopover performClose:self];
        activePopover = nil;
    }

    activePopover = [[NSPopover alloc] init];
    [activePopover setDelegate:self];
    [activePopover setBehavior:NSPopoverBehaviorTransient];
    AssigneeFilterViewController *vc = [[AssigneeFilterViewController alloc] initWithNibName:@"AssigneeFilterViewController" bundle:[NSBundle mainBundle]];
    vc.currentFilter = filter;
    vc.repository = self.repository;
    [activePopover setContentViewController:vc];
    
    [activePopover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxXEdge];
    
    [self updateFilterHighlights];
}

- (IBAction)milestoneFilterButtonClicked:(id)sender
{
    if (activePopover)
    {
        [activePopover performClose:self];
        activePopover = nil;
    }
    
    activePopover = [[NSPopover alloc] init];
    [activePopover setDelegate:self];
    [activePopover setBehavior:NSPopoverBehaviorTransient];
    MilestoneFilterViewController *vc = [[MilestoneFilterViewController alloc] initWithNibName:@"MilestoneFilterViewController" bundle:[NSBundle mainBundle]];
    vc.currentFilter = filter;
    vc.repository = self.repository;
    [activePopover setContentViewController:vc];
    
    [activePopover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxXEdge];
    
    [self updateFilterHighlights];
}

- (IBAction)issueStateFilterButtonClicked:(id)sender
{
    NSInteger indexSelected = [issueStateFilterButton selectedSegment];
    
    if (indexSelected == 0) // open issues
    {
        filter.shouldBeOpen = BHOpenState;
        [self.repository loadOpenIssues];
    }
    else if (indexSelected == 1) // closed issues
    {
        filter.shouldBeOpen = BHClosedState;
        [self.repository loadClosedIssues];
    }

    filteredIssues = [self.repository issues:nil withFilter:filter indexesRemoved:nil];
    [self.issueList reloadData];
    [self makeSelectedIssueVisible];
}


- (NSInteger)makeSelectedIssueVisible
{
    NSSet *selectedIssues = [detailViewController representedIssues];
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    
    for (BHIssue *anIssue in selectedIssues)
    {
        NSInteger indexOfIssue = [filteredIssues indexOfObject:anIssue];

        if (indexOfIssue == NSNotFound)
            continue;

        [self.issueList scrollRowToVisible:indexOfIssue];
        [indexSet addIndex:indexOfIssue];
    }
    
    if (indexSet.count > 0)
    {
        [self.issueList selectRowIndexes:indexSet byExtendingSelection:NO];
        return [indexSet firstIndex];
    }
    
    return NSNotFound;
}


#pragma mark issue button
- (void)editIssue:(BHIssue *)anIssue
{
    NewIssueWindowController *newIssueWindowController = [[NewIssueWindowController alloc] initWithIssue:anIssue];
    [newIssueWindows addObject:newIssueWindowController];
    [newIssueWindowController setRetainSetThingBecauseMenoryManagementSucks:newIssueWindows];
    [[newIssueWindowController window] makeKeyAndOrderFront:self];
}

- (IBAction)newIssueButtonClicked:(id)sender
{
    NewIssueWindowController *newIssueWindowController = [[NewIssueWindowController alloc] initWithRepository:self.repository];
    [newIssueWindows addObject:newIssueWindowController];
    [newIssueWindowController setRetainSetThingBecauseMenoryManagementSucks:newIssueWindows];
    [[newIssueWindowController window] makeKeyAndOrderFront:self];
}

- (IBAction)newCommentButtonClicked:(id)sender
{
    // must pass nil here otherwise, it's looking for the _contextMenuItems
    [self menuCommentOnIssue:nil];
}

- (IBAction)showClosedIssues:(id)sender
{
    [issueStateFilterButton selectSegmentWithTag:1];
    [self issueStateFilterButtonClicked:nil];
}

- (IBAction)showOpenedIssues:(id)sender
{
    [issueStateFilterButton selectSegmentWithTag:0];
    [self issueStateFilterButtonClicked:nil];
}

- (IBAction)mainMenuCloseIssues:(id)sender
{
    [self menuCloseIssue:nil];
}

- (IBAction)mainMenuOpenIssues:(id)sender
{
    [self menuOpenIssue:nil];
}

- (IBAction)mainMenuReloadIssues:(id)sender
{
    [self menuReloadIssue:nil];
}

#pragma mark changes

- (NSAttributedString *)attribtuedOwnerStringForWindowTitle
{
    NSString *format = NSLocalizedString(@"Owner: %@", nil);
    NSString *normalString = [NSString stringWithFormat:format, self.repository.owner.login];
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:normalString];
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.3]];
    [shadow setShadowOffset:CGSizeMake(0, -1)];
    
    [str addAttribute:NSShadowAttributeName value:shadow range:NSMakeRange(0, normalString.length)];
    
    NSMutableParagraphStyle *mutParaStyle= [[NSMutableParagraphStyle alloc] init];
    [mutParaStyle setAlignment:NSCenterTextAlignment];
    
    [str addAttribute:NSParagraphStyleAttributeName value:mutParaStyle range:NSMakeRange(0, normalString.length)];

    return str;
}

- (NSAttributedString *)attribtuedStringForWindowTitle
{
    NSString *normalString = [self.repository.name copy];
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:normalString];
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.5]];
    [shadow setShadowOffset:CGSizeMake(0, -1)];
    
    [str addAttribute:NSShadowAttributeName value:shadow range:NSMakeRange(0, normalString.length)];
    
    NSMutableParagraphStyle *mutParaStyle= [[NSMutableParagraphStyle alloc] init];
    [mutParaStyle setAlignment:NSCenterTextAlignment];
    [str addAttribute:NSParagraphStyleAttributeName value:mutParaStyle range:NSMakeRange(0, normalString.length)];
    
    return str;
}

- (void)_handleIdentifierChange
{
    [self.window setTitle:[[self repository] identifier]];
}

- (void)_handleFilterChangeByRemoving:(BOOL)aFlag
{
    [self updateFilterHighlights];
    
    NSMutableIndexSet *indexesToRemove = aFlag ? [NSMutableIndexSet indexSet] : nil;
    
    filteredIssues = [self.repository issues:(aFlag ? filteredIssues : nil) withFilter:filter indexesRemoved:indexesToRemove];
    
    if (indexesToRemove)
        [self.issueList removeRowsAtIndexes:indexesToRemove withAnimation:NSTableViewAnimationSlideUp];
    else
    {
        [self.issueList reloadData];
        [self makeSelectedIssueVisible];
    }
}


- (void)_handleIssueChange
{
    filteredIssues = [self.repository issues:nil withFilter:filter indexesRemoved:nil];
    [self.issueList reloadData];
    [self makeSelectedIssueVisible];
}

- (void)_handleIsPrivateChange
{
    
}

- (void)_handleHasLoadedChange
{
    if ([self.repository isLoaded] == BHRepoError)
    {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Unable to Load Repository", nil)
                                         defaultButton:@"Okay"
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@"There was an error trying to load the repository \"%@\" from GitHub.", [self.repository identifier]];
        
        [alert beginSheetModalForWindow:self.window
                          modalDelegate:self
                         didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                            contextInfo:(__bridge_retained void *)@"BHRepoNotFound"];
    }
}

- (void)_handleHasIssuesChange
{
    if ([self.repository hasIssues])
        return;

    NSAlert *noIssuesAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Repository has issues turned off", nil)
                    defaultButton:NSLocalizedString(@"Close", nil)
                  alternateButton:NSLocalizedString(@"Try Again", nil)
                      otherButton:NSLocalizedString(@"Show on GitHub", nil)
        informativeTextWithFormat:NSLocalizedString(@"This repository doesn't have issues turned on and cannot be viewed in BugHub", nil)];
    
    [noIssuesAlert beginSheetModalForWindow:self.window
                              modalDelegate:self
                             didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                                contextInfo:(__bridge_retained void *)@"BHRepositoryIssuesOff"];
}

- (void)_showRepoLoadingView
{
    [loadingIssuesView startAnimation:nil];
}

- (void)_hideRepoLoadingView
{
    [loadingIssuesView stopAnimation:nil];
}

- (void)_showNoIssuesView
{
    [noIssuesToDisplayView setHidden:NO];
}

- (void)_hideNoIssuesView
{
    [noIssuesToDisplayView setHidden:YES];
}

- (void)_openIssueWindowsForIndexes:(NSIndexSet *)indexes
{
    __block CGPoint originPoint = CGPointZero;

    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        IssueDetailWindowController *newDetailWindowController = [[IssueDetailWindowController alloc] initWithIssue:[filteredIssues objectAtIndex:idx]];
        originPoint = [[newDetailWindowController window] cascadeTopLeftFromPoint:originPoint];

        [newDetailWindowController showWindow:nil];
        [newDetailWindowController setDelegate:self];
        [openIssueWindows addObject:newDetailWindowController];
    }];
}




#pragma mark window loading

- (void)windowDidLoad
{
    [super windowDidLoad];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    INAppStoreWindow *aWindow = (INAppStoreWindow *)self.window;
    
    aWindow.titleBarHeight = 40.0;
    [aWindow center];
    [aWindow setTitle:[[self repository] identifier]];
    [aWindow setCenterFullScreenButton:YES];
    [aWindow setFullScreenButtonRightMargin:8.0f];
    
    NSView *titleView = [aWindow titleBarView];
    
    const CGFloat widthOfTitle = 400.0f;
    const CGFloat heightOfTitle = CGRectGetHeight(titleView.frame) / 3 * 2;
    
    NSTextField *titleLabel = [[NSTextField alloc] initWithFrame:CGRectMake(CGRectGetWidth(titleView.frame) / 2 - widthOfTitle / 2, heightOfTitle / 3, widthOfTitle, heightOfTitle)];
    [titleLabel setAlignment:NSCenterTextAlignment];
    [titleLabel setEditable:NO];
    [titleLabel setBezeled:NO];
    [titleLabel setSelectable:NO];
    [titleLabel setAutoresizingMask:NSViewMaxXMargin|NSViewMinXMargin];
    [titleLabel bind:NSValueBinding toObject:self withKeyPath:@"attribtuedStringForWindowTitle" options:nil];
    [titleLabel setBackgroundColor:[NSColor clearColor]];
    [titleLabel setTextColor:[NSColor colorWithHexColorString:@"000000"]];

    [titleView addSubview:titleLabel];
    
    NSTextField *ownerLabel = [[NSTextField alloc] initWithFrame:CGRectMake(CGRectGetWidth(titleView.frame) / 2 - widthOfTitle / 2, heightOfTitle / 3 - 16, widthOfTitle, heightOfTitle)];
    [ownerLabel setAlignment:NSCenterTextAlignment];
    [ownerLabel setFont:[NSFont fontWithName:@"Helvetica" size:10]];
    [ownerLabel setEditable:NO];
    [ownerLabel setBezeled:NO];
    [ownerLabel setSelectable:NO];
    [ownerLabel setAutoresizingMask:NSViewMaxXMargin|NSViewMinXMargin];
    [ownerLabel bind:NSValueBinding toObject:self withKeyPath:@"attribtuedOwnerStringForWindowTitle" options:nil];
    [ownerLabel setTextColor:[NSColor colorWithHexColorString:@"333333"]];
    [ownerLabel setBackgroundColor:[NSColor clearColor]];

    [titleView addSubview:ownerLabel];


    // add buttons
    CGFloat currentX = CGRectGetWidth(titleView.frame) - 40 - 23;
    CGFloat buttonY = 7;
    
    addCommentButton = [[WindowButton alloc] initWithFrame:CGRectMake(currentX, buttonY, 23, 23)];
    [addCommentButton setButtonType:NSMomentaryChangeButton];
    [addCommentButton setImage:[NSImage imageNamed:@"add_comment_button"]];
    [addCommentButton setAlternateImage:[NSImage imageNamed:@"add_comment_button_highlighted"]];
    [addCommentButton setBordered:NO];
    [addCommentButton setTarget:self];
    [addCommentButton setAction:@selector(menuCommentOnIssue:)];
    [addCommentButton setAutoresizingMask:NSViewMinXMargin];
    [addCommentButton setToolTip:NSLocalizedString(@"Comment on Issue", nil)];
    [addCommentButton setKeyEquivalent:@"N"];
    [addCommentButton setKeyEquivalentModifierMask:NSCommandKeyMask|NSShiftKeyMask];
    [titleView addSubview:addCommentButton];
    [aWindow setDelegate:self];
    
     currentX -= 45;
    
    addMilestoneButton = [[WindowButton alloc] initWithFrame:CGRectMake(currentX, buttonY, 23, 23)];
    [addMilestoneButton setButtonType:NSMomentaryChangeButton];
    [addMilestoneButton setImage:[NSImage imageNamed:@"add_milestone_button"]];
    [addMilestoneButton setAlternateImage:[NSImage imageNamed:@"add_milestone_button_highlighted"]];
    [addMilestoneButton setBordered:NO];
    [addMilestoneButton setTarget:detailViewController];
    [addMilestoneButton setAction:@selector(displayMilestones:)];
    [addMilestoneButton setAutoresizingMask:NSViewMinXMargin];
    [addMilestoneButton setToolTip:NSLocalizedString(@"Set Milestone", nil)];
    [titleView addSubview:addMilestoneButton];
    
    currentX -= 45;
    
    addAssigneeButton = [[WindowButton alloc] initWithFrame:CGRectMake(currentX, buttonY, 23, 23)];
    [addAssigneeButton setButtonType:NSMomentaryChangeButton];
    [addAssigneeButton setImage:[NSImage imageNamed:@"add_assignee_button"]];
    [addAssigneeButton setAlternateImage:[NSImage imageNamed:@"add_assignee_button_highlighted"]];
    [addAssigneeButton setBordered:NO];
    [addAssigneeButton setTarget:detailViewController];
    [addAssigneeButton setAction:@selector(displayAssignees:)];
    [addAssigneeButton setAutoresizingMask:NSViewMinXMargin];
    [addAssigneeButton setToolTip:NSLocalizedString(@"Assign Issue to User", nil)];
    [titleView addSubview:addAssigneeButton];
    currentX -= 45;
    
    addLabelButton = [[WindowButton alloc] initWithFrame:CGRectMake(currentX, buttonY, 23, 23)];
    [addLabelButton setButtonType:NSMomentaryChangeButton];
    [addLabelButton setImage:[NSImage imageNamed:@"add_label_button"]];
    [addLabelButton setAlternateImage:[NSImage imageNamed:@"add_label_button_highlighted"]];
    [addLabelButton setBordered:NO];
    [addLabelButton setTarget:detailViewController];
    [addLabelButton setAction:@selector(displayLabels:)];
    [addLabelButton setAutoresizingMask:NSViewMinXMargin];
    [addLabelButton setToolTip:NSLocalizedString(@"Set Labels for Issue", nil)];
    [titleView addSubview:addLabelButton];
    currentX -= 45;
    

    
    closeIssueButton = [[WindowButton alloc] initWithFrame:CGRectMake(currentX, buttonY, 23, 23)];
    [closeIssueButton setButtonType:NSMomentaryChangeButton];
    [closeIssueButton setImage:[NSImage imageNamed:@"close_issue_button"]];
    [closeIssueButton setAlternateImage:[NSImage imageNamed:@"close_issue_button_highlighted"]];
    [closeIssueButton setBordered:NO];
    [closeIssueButton setTarget:detailViewController];
    [closeIssueButton setAction:@selector(closeIssue:)];
    [closeIssueButton setAutoresizingMask:NSViewMinXMargin];
    [closeIssueButton setToolTip:NSLocalizedString(@"Close Selected Issue", nil)];
    [titleView addSubview:closeIssueButton];
    
    openIssueButton = [[WindowButton alloc] initWithFrame:CGRectMake(currentX, buttonY, 23, 23)];
    [openIssueButton setButtonType:NSMomentaryChangeButton];
    [openIssueButton setImage:[NSImage imageNamed:@"open_issue_button"]];
    [openIssueButton setAlternateImage:[NSImage imageNamed:@"open_issue_button_highlighted"]];
    [openIssueButton setBordered:NO];
    [openIssueButton setTarget:detailViewController];
    [openIssueButton setAction:@selector(openIssue:)];
    [openIssueButton setAutoresizingMask:NSViewMinXMargin];
    [openIssueButton setToolTip:NSLocalizedString(@"Close Open Issue", nil)];
    [titleView addSubview:openIssueButton];
    
    
    [self updateIssueButtons];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self.repository removeObserver:self forKeyPath:@"owner"];
    [self.repository removeObserver:self forKeyPath:@"issues"];
    [self.repository removeObserver:self forKeyPath:@"isPrivate"];
    [self.repository removeObserver:self forKeyPath:@"isLoaded"];
    [self.repository removeObserver:self forKeyPath:@"hasIssues"];
    [self.repository removeObserver:self forKeyPath:@"identifier"];

    self.repository = nil;
    [(AppDelegate *)[NSApp delegate] windowControllerDidClose:self];
}

- (void)issueDetailWindowControllerWillClose:(id)sender
{
    [openIssueWindows removeObject:sender];
}

- (void)updateIssueButtons
{
    NSInteger selectedIssueCount = [[self.issueList selectedRowIndexes] count];
    
    BHUser *authedUser = [BHUser userWithLogin:[GHAPIRequest authenticatedUserLogin] dictionaryValues:nil];
    BHPermissionType userPermissions = [self.repository permissionsForUser:authedUser];
    
    // First make everything visisble.
    [addCommentButton setHidden:YES];
    [addMilestoneButton setHidden:YES];
    [addAssigneeButton setHidden:YES];
    [addLabelButton setHidden:YES];
    [closeIssueButton setHidden:YES];
    [openIssueButton setHidden:YES];
    [newIssueButton setHidden:YES];
    
    if (userPermissions == BHPermissionNone)
        return;
    
    
    // We can assume at the very least the user now has authenticated read access...
    [newIssueButton setHidden:NO];
    [addCommentButton setHidden:selectedIssueCount != 1];
    
    if (userPermissions == BHPermissionReadWrite && selectedIssueCount > 0)
    {
        [addMilestoneButton setHidden:NO];
        [addAssigneeButton setHidden:NO];
        [addLabelButton setHidden:NO];
        
        
        BOOL isClosable = [detailViewController hasClosableIssue];
        [closeIssueButton setHidden:!isClosable];
        [openIssueButton setHidden:isClosable];
    }
}

#pragma mark alert delegate
- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    id context = (__bridge_transfer id)contextInfo;

    // Context for when the user double clicks lots of selected issues
    if ([context isKindOfClass:[NSIndexSet class]])
    {
        // cancel
        if (returnCode == 0)
            return;

        // yes, open the windows
        [self _openIssueWindowsForIndexes:context];
        return;
    }

    // If the repo turned off issues somehow :(
    if ([context isEqual:@"BHRepositoryIssuesOff"])
    {
        if (returnCode == 0)
        {
            // try again
            [self _showRepoLoadingView];
            [self.repository loadRepo];
        }
        else if (returnCode == 1)
        {
            // close
            [self windowWillClose:nil];
            [self.window close];
        }
        else if (returnCode == -1)
        {
            NSString *authedUser = [GHAPIRequest authenticatedUserLogin];
            NSString *settingsURL = [[self.repository htmlURL] absoluteString];

            // take the user to the settings page if they own the repo
            if ([authedUser isEqualToString:[[self.repository owner] login]])
                settingsURL = [settingsURL stringByAppendingString:@"/settings"];

            [self windowWillClose:nil];
            [self.window close];
            // show on github
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:settingsURL]];
        }

        return;
    }
    
    // Can't find the repo brah.
    if ([context isEqual:@"BHRepoNotFound"])
    {
        [self windowWillClose:nil];
        [self close];
        return;
    }
}

- (void)newLabelOrMilestoneSheeDidEnd:(NSWindow *)aSheet returnCode:(NSInteger)aReturnCode context:(void *)someContext
{
    if (aReturnCode == 1)
    {
        id controller = [aSheet delegate];
        
        if ([controller isKindOfClass:[NewLabelWindowController class]])
        {
            BHLabel *newLabel = [(NewLabelWindowController *)controller label];
            [detailViewController addLabel:newLabel];
        }
        else if ([controller isKindOfClass:[NewMilestoneWindowController class]])
        {
            BHMilestone *newMilestone = [(NewMilestoneWindowController *)controller milestone];
            [detailViewController setMilestone:newMilestone];
        }
    }
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex
{
    if (dividerIndex == 0)
        return 330.0f;

    return 0;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex
{
    if (dividerIndex == 0)
        return 500.0f;
    
    return 0;
}

#pragma mark table view data source

- (void)issuesDidChangeState:(NSSet *)issuesThatChanged
{
    BHIssueState state = [filter shouldBeOpen];
    // if we're viewing all issues, who really cares? Not me, that's for sure.
    if (state == BHUnknownState)
        return;

    NSMutableIndexSet *indexesToRemove = [NSMutableIndexSet indexSet];
    filteredIssues = [self.repository issues:filteredIssues withFilter:filter indexesRemoved:indexesToRemove];
    [self.issueList removeRowsAtIndexes:indexesToRemove withAnimation:NSTableViewAnimationSlideUp];
}

- (void)didDoubleClickIssue:(id)sender
{
    NSIndexSet *selectedRows = [self.issueList selectedRowIndexes];
    
    if ([selectedRows count] > 4)
    {
        // are you sure you want to open 5+ windows?
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Are You Sure?", nil)
                                         defaultButton:NSLocalizedString(@"Open Windows", nil)
                                       alternateButton:NSLocalizedString(@"Cancel", nil)
                                           otherButton:nil
                             informativeTextWithFormat:NSLocalizedString(@"Are you sure you want to open %d windows? Each issue will appear in its own window", nil), [selectedRows count]];
        
        [alert beginSheetModalForWindow:self.window
                          modalDelegate:self
                         didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                            contextInfo:(__bridge_retained void *)selectedRows];
    }
    else
    {
        // open each issue in a new window
        [self _openIssueWindowsForIndexes:selectedRows];
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    NSInteger count = [filteredIssues count];
    
    BHIssueState expectedState = filter.shouldBeOpen;
    BHRepoLoadedStatus openLoadedState = [self.repository hasLoadedOpenIssues];
    BHRepoLoadedStatus closedLoadedState = [self.repository hasLoadedClosedIssues];
    
    if (count > 0)
    {
        [self _hideRepoLoadingView];
        [self _hideNoIssuesView];
    }
    else
    {
        if (expectedState == BHOpenState &&  (openLoadedState == BHRepoLoading || openLoadedState == BHRepoNotLoaded))
        {
            [self _showRepoLoadingView];
            [self _hideNoIssuesView];
        }
        else if (expectedState == BHClosedState &&  (closedLoadedState == BHRepoLoading || closedLoadedState == BHRepoNotLoaded))
        {
            [self _showRepoLoadingView];
            [self _hideNoIssuesView];
        }
        else
        {
            [self _hideRepoLoadingView];
            [self _showNoIssuesView];
        }
    }
    return count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    static NSString *issueCellIdentifier = @"BHIssueListCellIdentifier";
    NSTableCellView *cell = [tableView makeViewWithIdentifier:issueCellIdentifier owner:nil];

    BHIssue *issue = [filteredIssues objectAtIndex:row];
    [cell setObjectValue:issue];

    return cell;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSIndexSet *selectedIndexes = [self.issueList selectedRowIndexes];
    NSMutableSet *selectedIssues = [NSMutableSet setWithCapacity:[selectedIndexes count]];

    [selectedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [selectedIssues addObject:[filteredIssues objectAtIndex:idx]];
    }];

    [detailViewController setRepresentedIssues:selectedIssues];
    [self updateIssueButtons];
}

- (NSString *)tableView:(NSTableView *)tableView typeSelectStringForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    BHIssue *anIssue = [filteredIssues objectAtIndex:row];
    return [NSString stringWithFormat:@"%ld", [anIssue number]];
}


#pragma mark popover delegate
- (void)popoverDidClose:(NSNotification *)notification
{
    [self updateFilterHighlights];
}


- (void)stateChangeAlertDidEnd:(NSAlert *)anAlert withReturnCode:(NSInteger)aReturnCode context:(void *)someContext
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

    [self issuesDidChangeState:issuesToChange];
    [self updateIssueButtons];
}


#pragma mark menu delegate
- (void)menuWillOpen:(NSMenu *)menu
{
    NSIndexSet *selectedIssues = [self.issueList selectedRowIndexes];
    NSInteger *clickedRow = [self.issueList clickedRow];
    
    // If the user right clicks a selected row, the context menu is applied to ALL selected issues.
    // if the user right clicks a row that's not selected, the context menu is only applied to THAT issue.
    
    if ([selectedIssues containsIndex:clickedRow])
        _contextMenuIssues = [NSSet setWithArray:[filteredIssues objectsAtIndexes:selectedIssues]];
    else
        _contextMenuIssues = [NSSet setWithObject:[filteredIssues objectAtIndex:clickedRow]];
    
    // construct Labels, Milestone, and Assignee menus
    NSMenu *labelsMenu = [[NSMenu alloc] initWithTitle:@"Labels"];
    NSSet *labels = [self.repository labels];
    
    for (BHLabel *label in labels)
    {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[label name]  action:@selector(menuLabelIssue:) keyEquivalent:@""];
        [item setTarget:self];
        [item weaklyAssociateValue:label withKey:"represented label"];
        
        NSSet *issueContainingLabel = [_contextMenuIssues objectsPassingTest:^BOOL(BHIssue *obj, BOOL *stop) {
            return [[obj labels] containsObject:label];
        }];
        
        if ([issueContainingLabel count] == 0)
            [item setState:NSOffState];
        else if ([issueContainingLabel count] == [_contextMenuIssues count])
            [item setState:NSOnState];
        else
            [item setState:NSMixedState];
        

        NSImage *image = [NSImage imageWithSize:CGSizeMake(12, 12) flipped:YES drawingHandler:^BOOL(NSRect dstRect) {
            CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];

            [[NSColor colorWithCalibratedWhite:0.2 alpha:1.0] setStroke];
            [[label color] setFill];
            
            CGContextFillEllipseInRect(context, dstRect);
            CGContextStrokeEllipseInRect(context, CGRectInset(dstRect, 1, 1));

            return YES;
        }];

        [item setImage:image];
        [labelsMenu addItem:item];
    }

    [[menu itemWithTitle:@"Labels"] setSubmenu:labelsMenu];
    
    
    
    // MILESTONE
    NSMenu *milestonesMenu = [[NSMenu alloc] initWithTitle:@"Milestones"];
    NSSet *milestones = [self.repository milestones];
    for (BHMilestone *milestone in milestones)
    {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[milestone name] action:@selector(menuMilestoneIssue:) keyEquivalent:@""];
        [item weaklyAssociateValue:milestone withKey:"represented milestone"];

        NSSet *issuesWithMilestone = [_contextMenuIssues objectsPassingTest:^BOOL(BHIssue *obj, BOOL *stop) {
            return [[obj milestone] isEqual:milestone];
        }];

        if ([issuesWithMilestone count] == 0)
            [item setState:NSOffState];
        else if ([issuesWithMilestone count] == [_contextMenuIssues count])
            [item setState:NSOnState];
        else
            [item setState:NSMixedState];

        [milestonesMenu addItem:item];
    }

    [[menu itemWithTitle:@"Milestone"] setSubmenu:milestonesMenu];


    // ASSIGNEE
    NSMenu *assigneeMenu = [[NSMenu alloc] initWithTitle:@"Assignees"];
    NSSet *assignees = [self.repository assignees];
    for (BHUser *assignee in assignees)
    {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[assignee login] action:@selector(menuAssigneIssue:) keyEquivalent:@""];
        [item weaklyAssociateValue:assignee withKey:"represented assignee"];
        
        NSSet *issuesWithAssignee = [_contextMenuIssues objectsPassingTest:^BOOL(BHIssue *obj, BOOL *stop) {
            return [[obj assignee] isEqual:assignee];
        }];
        
        if ([issuesWithAssignee count] == 0)
            [item setState:NSOffState];
        else if ([issuesWithAssignee count] == [_contextMenuIssues count])
            [item setState:NSOnState];
        else
            [item setState:NSMixedState];
        
        // FIX ME:
        // it would be cool to show the user's avatar next to their name.
        // Problem is that the avatar might not be loaded... which means it needs to be KVO'd which gets REALLLLLLLLLLLLLLLY messy.
        // but if we passed the item object to the context it could work.
        
        [assigneeMenu addItem:item];
    }
    
    [[menu itemWithTitle:@"Assignee"] setSubmenu:assigneeMenu];
    
    
    // Now, we need to decide if we should show the open/close buttons and the "show on GitHub Button.
    NSSet *issuesThatAreClosed = [_contextMenuIssues objectsPassingTest:^BOOL(BHIssue *obj, BOOL *stop) {
        return [obj state] == BHClosedState;
    }];
    
    NSSet *issuesThatAreOpen = [_contextMenuIssues objectsPassingTest:^BOOL(BHIssue *obj, BOOL *stop) {
        return [obj state] == BHOpenState;
    }];
    
    [[menu itemWithTitle:@"Open Issue"] setEnabled:[issuesThatAreClosed count]];
    [[menu itemWithTitle:@"Close Issue"] setEnabled:!![issuesThatAreOpen count]];

    [[menu itemWithTitle:@"View on GitHub"] setEnabled:[_contextMenuIssues count] == 1];
    
    [[menu itemWithTitle:@"Comment on Issue"] setEnabled:[_contextMenuIssues count] == 1];
    
    BHUser *authedUser = [BHUser userWithLogin:[GHAPIRequest authenticatedUserLogin] dictionaryValues:nil];
    BHPermissionType userPermissions = [self.repository permissionsForUser:authedUser];
    
    BOOL shouldDisableJustAboutEverything = userPermissions != BHPermissionReadWrite;
    
    if (shouldDisableJustAboutEverything)
    {
        [[menu itemWithTitle:@"Open Issue"] setEnabled:NO];
        [[menu itemWithTitle:@"Close Issue"] setEnabled:NO];
        [[menu itemWithTitle:@"Assignee"] setEnabled:NO];
        [[menu itemWithTitle:@"Labels"] setEnabled:NO];
        [[menu itemWithTitle:@"Milestone"] setEnabled:NO];
    }
    
    if (userPermissions == BHPermissionNone)
        [[menu itemWithTitle:@"Comment on Issue"] setEnabled:NO];
}

- (IBAction)menuCloseIssue:(id)sender
{
    NSString *message = nil;
    
    if (_contextMenuIssues.count > 1)
        message = [NSString stringWithFormat:@"Are you sure you want to close %ld issues?", _contextMenuIssues.count];
    else
        message = [NSString stringWithFormat:@"Are you sure you want to close 1 issue?"];
    
    NSString *buttonText = _contextMenuIssues.count > 1 ? @"Close Issues" : @"Close Issue";
    
    NSAlert *alert = [NSAlert alertWithMessageText:message defaultButton:buttonText alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@""];
    
    NSSet *issuesToUse = [sender isKindOfClass:[NSMenuItem class]] ? [_contextMenuIssues copy] : [NSSet setWithArray:[filteredIssues objectsAtIndexes:[self.issueList selectedRowIndexes]]];

    NSDictionary *context = @{
                              @"issues": issuesToUse,
                              @"action": @"Close"
                              };
    
    [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(stateChangeAlertDidEnd:withReturnCode:context:) contextInfo:(__bridge_retained void *)context];
}

- (IBAction)menuOpenIssue:(id)sender
{
    NSLog(@"open action");
    NSString *message = nil;
    
    if (_contextMenuIssues.count > 1)
        message = [NSString stringWithFormat:@"Are you sure you want to open %ld issues?", _contextMenuIssues.count];
    else
        message = [NSString stringWithFormat:@"Are you sure you want to open 1 issue?"];
    
    NSString *buttonText = _contextMenuIssues.count > 1 ? @"Open Issues" : @"Open Issue";
    
    NSAlert *alert = [NSAlert alertWithMessageText:message defaultButton:buttonText alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@""];
    
    NSSet *issuesToUse = [sender isKindOfClass:[NSMenuItem class]] ? [_contextMenuIssues copy] : [NSSet setWithArray:[filteredIssues objectsAtIndexes:[self.issueList selectedRowIndexes]]];
    
    NSDictionary *context = @{
                              @"issues": issuesToUse,
                              @"action": @"Open"
                              };
    
    [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(stateChangeAlertDidEnd:withReturnCode:context:) contextInfo:(__bridge_retained void *)context];
}

- (IBAction)menuReloadIssue:(id)sender
{
    [_contextMenuIssues makeObjectsPerformSelector:@selector(reloadIssue)];
}

- (IBAction)menuCommentOnIssue:(id)sender
{
    BHIssue *issue = nil;

    if ([sender isKindOfClass:[NSMenuItem class]])
        issue = [_contextMenuIssues anyObject];
    else
        issue = [filteredIssues objectAtIndex:[self.issueList selectedRow]];

    NewCommentWindowController *newCommentController = [[NewCommentWindowController alloc] initWithWindowNibName:@"NewCommentWindowController"];
    [newCommentController setIssue:issue];
    [newCommentController setRetainSetThing:newCommentWindows];
    [newCommentWindows addObject:newCommentController];

    [newCommentController showWindow:nil];
}

- (IBAction)menuLabelIssue:(NSMenuItem *)sender
{
    NSInteger state = [sender state];
    BHLabel *label = [sender associatedValueForKey:"represented label"];
    
    if (state == NSMixedState || state == NSOffState)
    {
        // add to all issue
        [_contextMenuIssues makeObjectsPerformSelector:@selector(addLabel:) withObject:label];
    }
    else if (state == NSOnState)
    {
        // remove from all issue
        [_contextMenuIssues makeObjectsPerformSelector:@selector(removeLabel:) withObject:label];
    }
    
    for (BHIssue *anIssue in _contextMenuIssues)
        [[BHRequestQueue mainQueue] addObject:anIssue];
}

- (IBAction)menuMilestoneIssue:(NSMenuItem *)sender
{
    NSInteger state = [sender state];
    BHMilestone *milestone = [sender associatedValueForKey:"represented milestone"];
    
    if (state == NSMixedState || state == NSOffState)
    {
        // add to all issue
        [_contextMenuIssues makeObjectsPerformSelector:@selector(setMilestone:) withObject:milestone];
    }
    else if (state == NSOnState)
    {
        // remove from all issue
        [_contextMenuIssues makeObjectsPerformSelector:@selector(setMilestone:) withObject:nil];
    }
    
    for (BHIssue *anIssue in _contextMenuIssues)
        [[BHRequestQueue mainQueue] addObject:anIssue];
}

- (IBAction)menuAssigneIssue:(NSMenuItem *)sender
{
    NSInteger state = [sender state];
    BHUser *assignee = [sender associatedValueForKey:"represented assignee"];
    
    if (state == NSMixedState || state == NSOffState)
    {
        // add to all issue
        [_contextMenuIssues makeObjectsPerformSelector:@selector(setAssignee:) withObject:assignee];
    }
    else if (state == NSOnState)
    {
        // remove from all issue
        [_contextMenuIssues makeObjectsPerformSelector:@selector(setAssignee:) withObject:nil];
    }
    
    for (BHIssue *anIssue in _contextMenuIssues)
        [[BHRequestQueue mainQueue] addObject:anIssue];
}

- (IBAction)menuViewIssueOnGithub:(id)sender
{
    BHIssue *issue = [_contextMenuIssues anyObject];
    NSString *url = [NSString stringWithFormat:@"https://github.com/%@/issues/%ld", [[issue repository] identifier], [issue number]];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}

#pragma mark resotre windows
+ (void)restoreWindowWithIdentifier:(NSString *)identifier state:(NSCoder *)state completionHandler:(void (^)(NSWindow *, NSError *))completionHandler
{
    RepositoryWindowController *controller = [(AppDelegate *)[NSApp delegate] openRepoWindow:identifier];

    completionHandler(controller.window, nil);
}

@end


