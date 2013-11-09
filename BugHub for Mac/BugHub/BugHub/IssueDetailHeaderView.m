//
//  IssueDetailHeaderView.m
//  BugHub
//
//  Created by Randy on 3/4/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "AppDelegate.h"
#import "RepositoryWindowController.h"
#import "IssueDetailHeaderView.h"
#import "BHRepository.h"
#import "BHIssue.h"
#import "BHMilestone.h"
#import "BHLabel.h"
#import "BHUser.h"
#import "AvatarImageView.h"
#import "DetailView.h"
#import "LabelsView.h"
#import "NSColor+hex.h"
#import "NSDate+Strings.h"

@interface IssueDetailHeaderView ()
{
    BHIssue *_representedIssue;
    AvatarImageView *avatarView;
    NSTextField *titleField;
    NSTextField *metaField;
    
    AvatarImageView *assigneeAvatarView;
    NSTextField *assigneeTextField;
    
    NSImageView *milestoneImageView;
    NSTextField *milestoneTextField;
    NSProgressIndicator *milestoneProgressIndicator;
    
    NSButton *editbutton;
    
    LabelsView *labelView;
}

- (void)_handleNewUserAvatar;
- (void)_handleNewTitle;
- (void)_handleNewMeta;
- (void)_handleNewAssignee;
- (void)_handleNewMilestone;
- (void)_handleNewLabels;

- (void)_resizeAppropriately;
- (CGFloat)_heightOfText:(NSString *)aString withFont:(NSFont *)aFont inWidth:(CGFloat)aWidth;
- (void)editButtonClicked:(id)sender;
@end

@implementation IssueDetailHeaderView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        avatarView = [[AvatarImageView alloc] initWithFrame:CGRectMake(15, CGRectGetHeight(frame) - 55, 50, 50)];
        [avatarView setAutoresizingMask:NSViewMinYMargin];
        avatarView.bezelSize = 6;
        [self addSubview:avatarView];

        CGFloat width = CGRectGetWidth(frame) - CGRectGetMaxX(avatarView.frame) - 30;
        titleField = [[NSTextField alloc] initWithFrame:CGRectMake(CGRectGetWidth(frame) - width - 15, 0, width, 55)];
        [titleField setAutoresizingMask:NSViewWidthSizable];
        [titleField setBezeled:NO];
        [titleField setBordered:NO];
        [titleField setEditable:NO];
        [titleField setBackgroundColor:[NSColor clearColor]];
        [titleField setTextColor:[NSColor colorWithHexColorString:@"575e66"]];
        [[titleField cell] setLineBreakMode:NSLineBreakByTruncatingTail];
        [[titleField cell] setBackgroundStyle:NSBackgroundStyleRaised];

        [titleField setFont:[NSFont fontWithName:@"Helvetica Neue Bold" size:18]];
        [[titleField cell] setWraps:YES];
        [self addSubview:titleField];


        metaField = [[NSTextField alloc] initWithFrame:CGRectMake(CGRectGetWidth(frame) - width, 30, width, 18)];
        [metaField setAutoresizingMask:NSViewWidthSizable];
        [metaField setBezeled:NO];
        [metaField setBordered:NO];
        [metaField setEditable:NO];
        [metaField setBackgroundColor:[NSColor clearColor]];
        [metaField setTextColor:[NSColor colorWithHexColorString:@"a0aab1"]];
        [[metaField cell] setBackgroundStyle:NSBackgroundStyleRaised];
        [metaField setFont:[NSFont fontWithName:@"Helvetica Neue Bold" size:11]];

        [self addSubview:titleField];
        [self addSubview:metaField];

        
        assigneeAvatarView = [[AvatarImageView alloc] initWithFrame:CGRectMake(15, 0, 30, 30)];
        assigneeTextField = [[NSTextField alloc] initWithFrame:CGRectMake(CGRectGetWidth(frame) - width, 30, width, 20)];
        [assigneeTextField setAutoresizingMask:NSViewWidthSizable];
        [assigneeTextField setBezeled:NO];
        [assigneeTextField setBordered:NO];
        [assigneeTextField setEditable:NO];
        [assigneeTextField setBackgroundColor:[NSColor clearColor]];
        [assigneeTextField setTextColor:[NSColor colorWithHexColorString:@"575e66"]];
        [[assigneeTextField cell] setBackgroundStyle:NSBackgroundStyleRaised];
        [assigneeTextField setFont:[NSFont fontWithName:@"Helvetica Neue Regular" size:11]];
        
        [self addSubview:assigneeAvatarView];
        [self addSubview:assigneeTextField];
        
        milestoneImageView = [[NSImageView alloc] initWithFrame:CGRectMake(0, 0, 14, 15)];
        [milestoneImageView setImage:[NSImage imageNamed:@"milestone-icon"]];
        
        milestoneTextField = [[NSTextField alloc] initWithFrame:CGRectMake(CGRectGetMaxX(milestoneImageView.frame), 0, CGRectGetWidth(frame) - CGRectGetMaxX(milestoneImageView.frame), 20)];
        [milestoneTextField setAutoresizingMask:NSViewWidthSizable];
        [milestoneTextField setBezeled:NO];
        [milestoneTextField setBordered:NO];
        [milestoneTextField setEditable:NO];
        [milestoneTextField setBackgroundColor:[NSColor clearColor]];
        [milestoneTextField setTextColor:[NSColor colorWithHexColorString:@"575e66"]];
        [[milestoneTextField cell] setBackgroundStyle:NSBackgroundStyleRaised];
        [milestoneTextField setFont:[NSFont fontWithName:@"Helvetica Neue Regular" size:11]];
        [self addSubview:milestoneImageView];
        [self addSubview:milestoneTextField];
        
        labelView = [[LabelsView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), 20)];
        [labelView setAutoresizingMask:NSViewWidthSizable];
        [self addSubview:labelView];
        
        editbutton = [[NSButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(frame) - 70.0, 0, 70.0f, 24)];
        
        NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:@"Edit Issue"];
        [title addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithHexColorString:@"6189f7"]  range:NSMakeRange(0, title.length)];
        [editbutton setAttributedTitle:title];
        
        [editbutton setButtonType:NSMomentaryChangeButton];
        [editbutton setAutoresizesSubviews:NSViewMinXMargin|NSViewMaxYMargin];
        [editbutton setBordered:NO];
        [editbutton setTarget:self];
        [editbutton setAction:@selector(editButtonClicked:)];
        [self addSubview:editbutton];
        
        [self setPostsFrameChangedNotifications:YES];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameDidChange:) name:NSViewFrameDidChangeNotification object:self];
        
        [self _resizeAppropriately];
    }
    
    return self;
}

- (void)frameDidChange:(NSNotification *)aNote
{
    [self _resizeAppropriately];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:self];

    [_representedIssue removeObserver:self forKeyPath:@"creator"];
    [_representedIssue removeObserver:self forKeyPath:@"creator.avatar"];
    [_representedIssue removeObserver:self forKeyPath:@"dateCreated"];
    [_representedIssue removeObserver:self forKeyPath:@"title"];
    [_representedIssue removeObserver:self forKeyPath:@"labels"];
    [_representedIssue removeObserver:self forKeyPath:@"assignee"];
    [_representedIssue removeObserver:self forKeyPath:@"assignee.avatar"];
    [_representedIssue removeObserver:self forKeyPath:@"milestone"];
}

- (void)editButtonClicked:(id)sender
{
    BHRepository *repo = [_representedIssue repository];
    AppDelegate *appDel = (AppDelegate *)[NSApp delegate];
    RepositoryWindowController *windowController = [appDel windowControllerWithIdentifier:[repo identifier]];

    [windowController editIssue:_representedIssue];
}

- (CGFloat)_heightOfText:(NSString *)aString withFont:(NSFont *)aFont inWidth:(CGFloat)aWidth
{
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithString:aString];
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:CGSizeMake(aWidth, FLT_MAX)];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];

    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];
    
    [textStorage addAttribute:NSFontAttributeName value:aFont range:NSMakeRange(0, [textStorage length])];
    [textContainer setLineFragmentPadding:0.0];
    
    (void) [layoutManager glyphRangeForTextContainer:textContainer];
    return [layoutManager usedRectForTextContainer:textContainer].size.height;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"creator.avatar"])
    {
        [self _handleNewUserAvatar];
    }
    else if ([keyPath isEqualToString:@"title"])
    {
        [self _handleNewTitle];
    }
    else if ([keyPath isEqualToString:@"creator"] || [keyPath isEqualToString:@"dateCreated"])
    {
        [self _handleNewMeta];
    }
    else if ([keyPath isEqualToString:@"assignee"] || [keyPath isEqualToString:@"assignee.avatar"])
    {
        [self _handleNewAssignee];
    }
    else if ([keyPath isEqualToString:@"milestone"])
    {
        [self _handleNewMilestone];
    }
    else if ([keyPath isEqualToString:@"labels"])
    {
        [self _handleNewLabels];
    }
    
    [self _resizeAppropriately];
}

- (void)_resizeAppropriately
{
    // layout from the bottom up...
    const CGFloat kPadding = 4;
    CGFloat currentY = 0;

    // add the edit button if we should...
    BHPermissionType editPermissions = [_representedIssue permissionsForAuthentictedUser];
    
    if (editPermissions == BHPermissionNone || editPermissions == BHPermissionReadOnly)
        [editbutton setHidden:YES];
    else
        [editbutton setHidden:NO];
    
    CGPoint editButtonOrigin = CGPointMake(CGRectGetWidth(self.bounds) - CGRectGetWidth(editbutton.bounds), 0);
    [editbutton setFrameOrigin:editButtonOrigin];
    
    CGFloat width = CGRectGetWidth(titleField.frame);
    CGFloat x = CGRectGetMinX(titleField.frame);

    // layout assignee if applicable
    if ([_representedIssue.labels count])
    {
        currentY += kPadding;
        [labelView setFrameOrigin:CGPointMake(15, currentY)];
        currentY += CGRectGetHeight(labelView.frame);
    }

    
    // layout assignee if applicable
    if (_representedIssue.milestone)
    {
        CGFloat milestoneX = _representedIssue.assignee == nil ? 82 : 94;
        CGFloat milestoneTextPadding = _representedIssue.assignee == nil ? 3 : 7;
        currentY += kPadding;
        [milestoneImageView setFrameOrigin:CGPointMake(milestoneX, currentY)];
        [milestoneTextField setFrameOrigin:CGPointMake(CGRectGetMaxX(milestoneImageView.frame) + milestoneTextPadding, currentY - 5)];
        currentY += CGRectGetHeight(milestoneImageView.frame);
    }

    
    // layout assignee if applicable
    if (_representedIssue.assignee)
    {
        currentY += kPadding;
        [assigneeAvatarView setFrameOrigin:CGPointMake(85, currentY)];
        [assigneeTextField setFrameOrigin:CGPointMake(CGRectGetMaxX(assigneeAvatarView.frame), currentY + 2)];
        currentY += CGRectGetHeight(assigneeAvatarView.frame);
    }
    
    // layout meta field
    currentY += kPadding;
    currentY += kPadding; // FIX ME... justify this line somehow. Unicorns?
    [metaField setFrameOrigin:CGPointMake(x, currentY)];
    currentY = CGRectGetMaxY(metaField.frame);
    
    // layout title field
    CGFloat newHeight = [self _heightOfText:titleField.stringValue withFont:titleField.font inWidth:width];
    [titleField setFrame:CGRectMake(x, currentY, width, newHeight)];
    currentY = CGRectGetMaxY(titleField.frame);

    // resize self and notify DetailView.
    currentY += kPadding;
    [self setFrameSize:CGSizeMake(self.frame.size.width, MAX(currentY, CGRectGetHeight(avatarView.frame) + 10))];
    [self.parentView adjustViewHeights];
}

- (void)drawRect:(NSRect)dirtyRect
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    
    [[NSColor colorWithCalibratedWhite:242.0/255.0 alpha:1.0] setFill];
    CGContextFillRect(context, self.bounds);
    
    [[NSColor colorWithCalibratedWhite:230.0/255.0 alpha:1.0] setStroke];
    
    const CGPoint bottomPoints[] = {
        CGPointMake(0, .5),
        CGPointMake(CGRectGetWidth(self.bounds), .5)
    };
    
    CGContextStrokeLineSegments(context, bottomPoints, 2);
}


- (void)setRepresentedIssue:(BHIssue *)anIssue
{
    [_representedIssue removeObserver:self forKeyPath:@"creator"];
    [_representedIssue removeObserver:self forKeyPath:@"creator.avatar"];
    [_representedIssue removeObserver:self forKeyPath:@"dateCreated"];
    [_representedIssue removeObserver:self forKeyPath:@"title"];
    [_representedIssue removeObserver:self forKeyPath:@"labels"];
    [_representedIssue removeObserver:self forKeyPath:@"assignee"];
    [_representedIssue removeObserver:self forKeyPath:@"assignee.avatar"];
    [_representedIssue removeObserver:self forKeyPath:@"milestone"];
    
    _representedIssue = anIssue;
    
    if (!anIssue)
        return;
    
    [_representedIssue addObserver:self forKeyPath:@"creator" options:0 context:NULL];
    [_representedIssue addObserver:self forKeyPath:@"creator.avatar" options:0 context:NULL];
    [_representedIssue addObserver:self forKeyPath:@"dateCreated" options:0 context:NULL];
    [_representedIssue addObserver:self forKeyPath:@"title" options:0 context:NULL];
    [_representedIssue addObserver:self forKeyPath:@"labels" options:0 context:NULL];
    [_representedIssue addObserver:self forKeyPath:@"assignee" options:0 context:NULL];
    [_representedIssue addObserver:self forKeyPath:@"assignee.avatar" options:0 context:NULL];
    [_representedIssue addObserver:self forKeyPath:@"milestone" options:0 context:NULL];
    
    [self _handleNewUserAvatar];
    [self _handleNewTitle];
    [self _handleNewMeta];
    [self _handleNewAssignee];
    [self _handleNewMilestone];
    [self _handleNewLabels];

    [self _resizeAppropriately];
}

#pragma mark changes
- (void)_handleNewUserAvatar
{
    [avatarView setImage:_representedIssue.creator.avatar];
}

- (void)_handleNewTitle
{
    [titleField setStringValue:_representedIssue.title];
}

- (void)_handleNewMeta
{
    NSString *newMetaString = [NSString stringWithFormat:NSLocalizedString(@"Submitted by %@ %@", nil), _representedIssue.creator.login, [_representedIssue.dateCreated normalDateString]];
    [metaField setStringValue:newMetaString];
}

- (void)_handleNewAssignee
{
    if (!_representedIssue.assignee)
    {
        [assigneeAvatarView setHidden:YES];
        [assigneeTextField setHidden:YES];
        return;
    }

    [assigneeAvatarView setHidden:NO];
    [assigneeTextField setHidden:NO];


    NSString *newMetaString = [NSString stringWithFormat:NSLocalizedString(@"Assigned to: %@", nil), _representedIssue.assignee.login];
    [assigneeTextField setStringValue:newMetaString];
    [assigneeAvatarView setImage:_representedIssue.assignee.avatar];
}

- (void)_handleNewMilestone
{
    if (!_representedIssue.milestone)
    {
        [milestoneTextField setHidden:YES];
        [milestoneImageView setHidden:YES];
        [milestoneProgressIndicator setHidden:YES];
        return;
    }

    [milestoneTextField setHidden:NO];
    [milestoneImageView setHidden:NO];
    [milestoneProgressIndicator setHidden:NO];

    
    NSString *newMetaString = [NSString stringWithFormat:NSLocalizedString(@"Milestone: %@", nil), _representedIssue.milestone.name];
    [milestoneTextField setStringValue:newMetaString];

}

- (void)_handleNewLabels
{
    if (!_representedIssue.labels || _representedIssue.labels.count == 0)
    {
        [labelView setHidden:YES];
        return;
    }

    [labelView setHidden:NO];
    
    [labelView setLabels:[_representedIssue.labels allObjects]];
}

@end
