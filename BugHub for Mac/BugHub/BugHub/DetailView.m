//
//  DetailView.m
//  BugHub
//
//  Created by Randy on 3/4/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "AppDelegate.h"
#import "RepositoryWindowController.h"
#import "DetailView.h"
#import "BHIssue.h"
#import "IssueDetailHeaderView.h"
#import "BHComment.h"
#import "BHRepository.h"
#import "BHMilestone.h"
#import "BHUser.h"
#import "BHLabel.h"
#import "NSObject+AssociatedObjects.h"
#import "GHAPIRequest.h"
#import "BHRequestQueue.h"
#import "NewCommentWindowController.h"
#import "NSString+Escape.h"
#import "AppDelegate.h"
#import <WebKit/WebKit.h>

@interface DetailView ()<NSTextViewDelegate>
{
    BHIssue *_representedIssue;
    
    IssueDetailHeaderView *headerView;
    WebView *_detailWebView;
    NSMutableSet *newCommentWindows;
    NSTextView *commentField;
}

- (void)rebuildMenus;
- (void)_actuallyDeleteComment:(NSAlert *)anAlert returnCode:(NSInteger)aReturnCode context:(void *)someContext;
- (void)positionCommentBox;
@end

@implementation DetailView

- (void)awakeFromNib
{
    [_detailWebView setMenu:self.contextMenu];
    [headerView setMenu:[self.menu copy]];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.isEnabled = YES;
        // Initialization code here.
        headerView = [[IssueDetailHeaderView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(frame) - 60.0, CGRectGetWidth(frame), 60)];
        [headerView setAutoresizingMask:NSViewWidthSizable|NSViewMinYMargin];
        [headerView setParentView:self];

        CGFloat y = 0;
        CGFloat height = CGRectGetHeight(frame) - CGRectGetHeight(headerView.bounds);
        _detailWebView = [[WebView alloc] initWithFrame:CGRectMake(0, y, CGRectGetWidth(frame), height)];
        [_detailWebView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [_detailWebView setPolicyDelegate:self];
        [_detailWebView setFrameLoadDelegate:self];
        [_detailWebView setUIDelegate:self];
        [_detailWebView setDrawsBackground:YES];

        newCommentWindows = [NSMutableSet setWithCapacity:0];
        
        [self addSubview:headerView];
        [self addSubview:_detailWebView];

        NSString *url = [[NSBundle mainBundle] pathForResource:@"DetailView" ofType:@"html"];
        [_detailWebView setMainFrameURL:url];
        
        commentField = [[NSTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        [commentField setRichText:NO];
        [commentField setDelegate:self];
    }

    return self;
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
    [super viewWillMoveToWindow:newWindow];
    [_detailWebView setNextResponder:newWindow];
}

- (void)deleteComment:(NSInteger)aCommentNumber
{
    NSAlert *alert = [NSAlert alertWithMessageText:@"Are you sure you want to delete this comment?" defaultButton:@"Delete" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"This action cannot be undone."];
    NSNumber *context = @(aCommentNumber);
    [alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(_actuallyDeleteComment:returnCode:context:) contextInfo:(__bridge_retained void *)context];
}

- (void)setIsEnabled:(BOOL)isEnabled
{
    _isEnabled = isEnabled;
    [[[_detailWebView mainFrame] frameView] setAllowsScrolling:isEnabled];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    [self setRepresentedIssue:_representedIssue];
}

- (void)dealloc
{
    [_representedIssue removeObserver:self forKeyPath:@"comments"];
    [_representedIssue removeObserver:self forKeyPath:@"htmlBody"];
    [_detailWebView setPolicyDelegate:nil];
    [_detailWebView setFrameLoadDelegate:nil];
    [_detailWebView setUIDelegate:nil];

}

- (void)setRepresentedIssue:(BHIssue *)anIssue
{
    [_representedIssue removeObserver:self forKeyPath:@"comments"];
    [_representedIssue removeObserver:self forKeyPath:@"htmlBody"];

    _representedIssue = anIssue;
    [headerView setRepresentedIssue:anIssue];

    [_representedIssue addObserver:self forKeyPath:@"comments" options:0 context:NULL];
    [_representedIssue addObserver:self forKeyPath:@"htmlBody" options:0 context:NULL];
    
    [_representedIssue downloadCommentsIfNeeded];
    
    BHUser *authenticatedUser = [BHUser userWithLogin:[GHAPIRequest authenticatedUserLogin] dictionaryValues:nil];
    BHPermissionType permissions = [self.representedIssue.repository permissionsForUser:authenticatedUser];

    NSString *isSuperUser = permissions == BHPermissionReadWrite ? @"true" : @"false";
    
    NSString *stringToEval = [NSString stringWithFormat:@"window.scrollTo(0,0); isSuperUser = %@; username = '%@'; setFullIssue(%@);", isSuperUser, [authenticatedUser.login uppercaseString],  [_representedIssue webViewJSON]];
    NSLog(@"%@", stringToEval);
    [_detailWebView stringByEvaluatingJavaScriptFromString:stringToEval];

    [self adjustViewHeights];
}
- (BHIssue *)representedIssue
{
    return _representedIssue;
}

- (void)adjustViewHeights
{
    CGFloat heightOfHeaderView = CGRectGetHeight(headerView.bounds);
    CGFloat newHeightOfWebview = CGRectGetHeight(self.bounds) - heightOfHeaderView;
    CGFloat currentWidth = CGRectGetWidth(self.bounds);
    
    [headerView setFrameOrigin:CGPointMake(0, newHeightOfWebview)];
    [_detailWebView setFrameSize:CGSizeMake(currentWidth, newHeightOfWebview)];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"htmlBody"])
    {
        NSString *stringToEval = [NSString stringWithFormat:@"setBody('%@');", [[_representedIssue htmlBody] stringByEscapingThings]];
        [_detailWebView stringByEvaluatingJavaScriptFromString:stringToEval];
    }
    else if ([keyPath isEqualToString:@"comments"])
    {
        NSMutableArray *JSONComments = [NSMutableArray arrayWithCapacity:[_representedIssue.comments count]];
        NSArray *currentComments = [_representedIssue.comments copy];
        for (BHComment *aComment in currentComments)
        {
            [JSONComments addObject:[aComment webViewJSONDict]];
        }
        
        NSError *error = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:JSONComments options:0 error:&error];
        NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

        NSString *stringToEval = [NSString stringWithFormat:@"addComments(%@);", jsonString];
        [_detailWebView stringByEvaluatingJavaScriptFromString:stringToEval];
    }
}

- (void)rebuildMenus
{
    NSSet *labels = [_representedIssue.repository labels];
    NSSet *milestones = [_representedIssue.repository milestones];
    NSSet *assignees = [_representedIssue.repository assignees];
    
    // construct Labels, Milestone, and Assignee menus
    NSMenu *labelsMenu = [[NSMenu alloc] initWithTitle:@"Labels"];
    
    for (BHLabel *label in labels)
    {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[label name]  action:@selector(menuLabelIssue:) keyEquivalent:@""];
        [item weaklyAssociateValue:label withKey:"represented label"];
        [item setTarget:self];

        BOOL issueHasLabel = [[_representedIssue labels] containsObject:label];
        [item setState: issueHasLabel ? NSOnState : NSOffState];
        
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
    
    [[self.contextMenu itemWithTitle:@"Labels"] setSubmenu:labelsMenu];
    
    
    // MILESTONE
    NSMenu *milestonesMenu = [[NSMenu alloc] initWithTitle:@"Milestones"];

    for (BHMilestone *milestone in milestones)
    {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[milestone name] action:@selector(menuMilestoneIssue:) keyEquivalent:@""];
        [item weaklyAssociateValue:milestone withKey:"represented milestone"];
        [item setTarget:self];

        BOOL hasMilestone = [[_representedIssue milestone] isEqual:milestone];
        [item setState:hasMilestone ? NSOnState : NSOffState];

        [milestonesMenu addItem:item];
    }

    [[self.contextMenu itemWithTitle:@"Milestone"] setSubmenu:milestonesMenu];

    // ASSIGNEE
    NSMenu *assigneeMenu = [[NSMenu alloc] initWithTitle:@"Assignees"];

    for (BHUser *assignee in assignees)
    {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[assignee login] action:@selector(menuAssigneIssue:) keyEquivalent:@""];
        [item weaklyAssociateValue:assignee withKey:"represented assignee"];
        [item setTarget:self];
        
        BOOL hasAssignee = [[_representedIssue assignee] isEqual:assignee];
        
        [item setState:hasAssignee ? NSOnState : NSOffState];

        // FIX ME:
        // it would be cool to show the user's avatar next to their name.
        // Problem is that the avatar might not be loaded... which means it needs to be KVO'd which gets REALLLLLLLLLLLLLLLY messy.
        // but if we passed the item object to the context it could work.
        
        [assigneeMenu addItem:item];
    }
    
    [[_contextMenu itemWithTitle:@"Assignee"] setSubmenu:assigneeMenu];
    
    
    // Now, we need to decide if we should show the open/close buttons and the "show on GitHub Button.
    BHIssueState state = [_representedIssue state];

    [[_contextMenu itemWithTitle:@"Open Issue"] setEnabled:state == BHClosedState];
    [[_contextMenu itemWithTitle:@"Close Issue"] setEnabled:state == BHOpenState];
    
    BHUser *authedUser = [BHUser userWithLogin:[GHAPIRequest authenticatedUserLogin] dictionaryValues:nil];
    BHPermissionType userPermissions = [_representedIssue.repository permissionsForUser:authedUser];

    BOOL shouldDisableJustAboutEverything = userPermissions != BHPermissionReadWrite;
    
    if (shouldDisableJustAboutEverything)
    {
        [[_contextMenu itemWithTitle:@"Open Issue"] setEnabled:NO];
        [[_contextMenu itemWithTitle:@"Close Issue"] setEnabled:NO];
        [[_contextMenu itemWithTitle:@"Assignee"] setEnabled:NO];
        [[_contextMenu itemWithTitle:@"Labels"] setEnabled:NO];
        [[_contextMenu itemWithTitle:@"Milestone"] setEnabled:NO];
    }
    
    if (userPermissions == BHPermissionNone)
        [[_contextMenu itemWithTitle:@"Comment on Issue"] setEnabled:NO];
}

#pragma mark webview delegate
/*- (id)webView:(WebView *)sender identifierForInitialRequest:(NSURLRequest *)request fromDataSource:(WebDataSource *)dataSource
 {
 
 }*/


- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation
        request:(NSURLRequest *)request
          frame:(WebFrame *)frame
decisionListener:(id < WebPolicyDecisionListener >)listener
{

    NSUInteger actionType = [[actionInformation objectForKey:WebActionNavigationTypeKey] unsignedIntValue];
    
    if (actionType == WebNavigationTypeLinkClicked)
    {
        NSURL *url = [request URL];

        if ([[url scheme] isEqualToString:@"bughub-x"])
        {
            if ([[url host] isEqualToString:@"removeComment"])
            {
                NSArray *path = [url pathComponents];
                if ([path count] == 2)
                {
                    NSInteger commentToDelete = [[path lastObject] integerValue];
                    if ([[NSString stringWithFormat:@"%ld", commentToDelete] isEqualToString:[path lastObject]])
                        [self deleteComment:commentToDelete];
                }
            }

            [listener ignore];
        }
        else if ([[NSApp delegate] shouldOpenLinksInBugHub] && [[NSApp delegate] attemptToOpenGitHubURL:[url absoluteString]])
            [listener ignore];
        else
        {
            [[NSWorkspace sharedWorkspace] openURL:[request URL]];
            [listener ignore];
        }
    }
    else
        [listener use];

    
}
- (BOOL)validateMenuItem:(NSMenuItem *)item
{
    return [item isEnabled];
}

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems
{
    [self rebuildMenus];
    NSArray *oldItems = [_contextMenu itemArray];
    NSMutableArray *newMenuItems = [NSMutableArray arrayWithCapacity:[oldItems count]];
    

    for (NSMenuItem *item in oldItems)
    {
        NSMenuItem *itemCopy = [item copy];
        [newMenuItems addObject:itemCopy];
    }
    
    if ([defaultMenuItems count] > 1)
    {
        [newMenuItems addObject:[NSMenuItem separatorItem]];
        [newMenuItems addObjectsFromArray:defaultMenuItems];
    }

    return newMenuItems;
}

- (NSView *)hitTest:(NSPoint)aPoint
{
    if (self.isEnabled)
        return [super hitTest:aPoint];

    return nil;
}

- (void)menuWillOpen:(NSMenu *)menu
{
    [self rebuildMenus];
}

- (void)alertDidEnd:(NSAlert *)anAlert withReturnCode:(NSInteger)aReturnCode context:(void *)someContext
{
    if (aReturnCode == 0) // don't do action
        return;
    
    NSDictionary *context = (__bridge_transfer NSDictionary *)someContext;
    
    BHIssue *issueToChange = [context objectForKey:@"issue"];
    NSString *action = [context objectForKey:@"action"];
    
    if ([action isEqualToString:@"Close"] || [action isEqualToString:@"Open"])
    {
        BHIssueState newState = [action isEqualToString:@"Close"] ? BHClosedState : BHOpenState;
        [issueToChange setState:newState];
        [[BHRequestQueue mainQueue] addObject:issueToChange];
    }
}

- (IBAction)menuCloseIssue:(id)sender
{
    NSString *message = nil;
    
    message = [NSString stringWithFormat:@"Are you sure you want to close 1 issue?"];

    NSString *buttonText = @"Close Issue";
    
    NSAlert *alert = [NSAlert alertWithMessageText:message defaultButton:buttonText alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@""];
    
    NSDictionary *context = @{
                              @"issue": _representedIssue,
                              @"action": @"Close"
                              };
    
    [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(alertDidEnd:withReturnCode:context:) contextInfo:(__bridge_retained void *)context];
}

- (IBAction)menuOpenIssue:(id)sender
{
    NSString *message = nil;
    
    message = [NSString stringWithFormat:@"Are you sure you want to open 1 issue?"];
    
    NSString *buttonText = @"Open Issue";
    
    NSAlert *alert = [NSAlert alertWithMessageText:message defaultButton:buttonText alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@""];
    
    NSDictionary *context = @{
                              @"issue": _representedIssue,
                              @"action": @"Open"
                              };
    
    [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(alertDidEnd:withReturnCode:context:) contextInfo:(__bridge_retained void *)context];
}

- (IBAction)menuReloadIssue:(id)sender
{
    [_representedIssue reloadIssue];
}

- (IBAction)menuCommentOnIssue:(id)sender
{    
    NewCommentWindowController *newCommentController = [[NewCommentWindowController alloc] initWithWindowNibName:@"NewCommentWindowController"];
    [newCommentController setIssue:_representedIssue];
    [newCommentController setRetainSetThing:newCommentWindows];
    [newCommentWindows addObject:newCommentController];
    
    [newCommentController showWindow:nil];
}

- (IBAction)menuLabelIssue:(NSMenuItem *)sender
{
    NSInteger state = [sender state];
    BHLabel *label = [sender associatedValueForKey:"represented label"];
    
    if (state == NSMixedState || state == NSOffState)
        [_representedIssue addLabel:label];
    else if (state == NSOnState)
        [_representedIssue removeLabel:label];
    
    [[BHRequestQueue mainQueue] addObject:_representedIssue];
}

- (IBAction)menuMilestoneIssue:(NSMenuItem *)sender
{
    NSInteger state = [sender state];
    BHMilestone *milestone = [sender associatedValueForKey:"represented milestone"];
    
    if (state == NSMixedState || state == NSOffState)
        [_representedIssue setMilestone:milestone];
    else if (state == NSOnState)
        [_representedIssue setMilestone:nil];
    
    
    [[BHRequestQueue mainQueue] addObject:_representedIssue];
}

- (IBAction)menuAssigneIssue:(NSMenuItem *)sender
{
    NSInteger state = [sender state];
    BHUser *assignee = [sender associatedValueForKey:"represented assignee"];
    
    if (state == NSOffState)
        [_representedIssue setAssignee:assignee];
    else if (state == NSOnState)
        [_representedIssue setAssignee:nil];

    [[BHRequestQueue mainQueue] addObject:_representedIssue];
}

- (IBAction)menuViewIssueOnGithub:(id)sender
{
    BHIssue *issue = _representedIssue;
    NSString *url = [NSString stringWithFormat:@"https://github.com/%@/issues/%ld", [[issue repository] identifier], [issue number]];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}

- (void)_actuallyDeleteComment:(NSAlert *)anAlert returnCode:(NSInteger)aReturnCode context:(void *)someContext
{
    NSNumber *context = (__bridge_transfer NSNumber *)someContext;
    NSInteger commentNumber = [context integerValue];
    
    if (aReturnCode == 1)
    {
        BHComment *aComment = [self.representedIssue commentWithIdentifier:commentNumber];
        [self.representedIssue deleteComment:aComment];

        NSString *stringToEval = [NSString stringWithFormat:@"deleteComment(%ld);", commentNumber];
        [_detailWebView stringByEvaluatingJavaScriptFromString:stringToEval];
    }
}

#pragma mark - NSTextViewDelegate
- (void)textDidChange:(NSNotification *)notification {
    // resize the textfield.
}

@end
