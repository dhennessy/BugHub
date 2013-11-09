//
//  MultipleSelectedDetailView.m
//  BugHub
//
//  Created by Randy on 3/31/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "MultipleSelectedDetailView.h"
#import "DetailView.h"
#import "BHIssue.h"
#import <QuartzCore/QuartzCore.h>

@interface MultipleSelectedDetailView ()
{
    NSMutableSet *_reuseQueue;
}

- (void)_enqueueDetailView:(NSBox *)aDetailView;
- (NSBox *)_dequeueDetailView;

- (NSBox *)_newDetailViewForIssue:(BHIssue *)anIssue;
- (NSBox *)_existingDetailViewForIssue:(BHIssue *)anIssue;

- (void)_animateViewOut:(NSView *)aView;
- (void)_animateViewIn:(NSView *)aView;

@end

@implementation MultipleSelectedDetailView

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    
    if (self)
    {
        displayedDetailViews = [NSMutableArray arrayWithCapacity:1];
        _reuseQueue = [NSMutableSet setWithCapacity:1];
        self.backgroundColor = [NSColor colorWithPatternImage:[NSImage imageNamed:@"lighter_linnen"]];
    }
    
    return self;
}

- (void)showNewIssues:(NSSet *)newIssues
{
    for (BHIssue *aNewIssue in newIssues)
    {
        NSBox *newView = [self _newDetailViewForIssue:aNewIssue];
        
        // translate the new view around..
        NSInteger currentCount = [displayedDetailViews count];
        CGRect currentFrame = [newView frame];
        currentFrame.origin.y -= 3 * currentCount;
        [newView setFrame:currentFrame];
        
        [self addSubview:newView];
        [displayedDetailViews addObject:newView];
        [self _animateViewIn:newView];
    }
}

- (void)removeIssues:(NSSet *)issuesToremove
{
    for (BHIssue *anIssue in issuesToremove)
    {
        NSBox *aView = [self _existingDetailViewForIssue:anIssue];
        if (aView) // FIX ME: this should never be nil...
            [self _animateViewOut:aView];
    }
}

- (void)_enqueueDetailView:(NSBox *)aDetailView
{
    if ([_reuseQueue count] > 10)
        return;
    
    [_reuseQueue addObject:aDetailView];
}

- (NSBox *)_dequeueDetailView
{
    NSBox *dequeuedObject = [_reuseQueue anyObject];
    
    if (dequeuedObject)
        [_reuseQueue removeObject:dequeuedObject];
    
    return dequeuedObject;
}

- (NSBox *)_newDetailViewForIssue:(BHIssue *)anIssue
{
    NSBox *box = [self _dequeueDetailView];
    
    if (!box)
    {
        CGRect newFrame = [self bounds];
        
        newFrame = CGRectInset(newFrame, 25, 25);

        box = [[NSBox alloc] initWithFrame:newFrame];
        [box setBorderColor:[NSColor colorWithCalibratedWhite:205.0f/255.0f alpha:1.0f]];
        [box setBorderWidth:1.0];
        [box setBorderType:NSLineBorder];
        [box setTitle:@""];
        [box setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [box setBoxType:NSBoxCustom];
        [box setContentViewMargins:CGSizeMake(0, 0)];
        
        DetailView *newView = [[DetailView alloc] initWithFrame:newFrame];
        [newView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [newView setRepresentedIssue:anIssue];
        [newView setIsEnabled:NO];
        [newView setBorderColor:[NSColor blackColor]];
        
        [box setContentView:newView];
        [box sizeToFit];
    }
    else
        [box setFrame:CGRectInset([self bounds], 25, 25)];
    
    return box;
}

- (NSBox *)_existingDetailViewForIssue:(BHIssue *)anIssue
{
    for (NSBox *aDetailView in displayedDetailViews)
    {
        if ([[aDetailView contentView] representedIssue] == anIssue)
            return aDetailView;
    }
    
    return nil;
}

- (void)_animateViewOut:(NSView *)aView
{

    NSInteger indexOfViewToRemove = [displayedDetailViews indexOfObject:aView];
    [displayedDetailViews removeObject:aView];

    if (![self superview])
        return [aView removeFromSuperview];

    [[NSAnimationContext currentContext] setDuration:0.25];
    [[NSAnimationContext currentContext] setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        CGRect aFrame = [aView frame];
        aFrame.origin.y = -aFrame.size.height;
        [[aView animator] setFrame:aFrame];
    } completionHandler:^{
        [aView removeFromSuperview];
        [self _enqueueDetailView:(NSBox *)aView];
    }];
    
    for (NSInteger i = indexOfViewToRemove; i < [displayedDetailViews count]; i++)
    {
        NSView *aView = [displayedDetailViews objectAtIndex:i];
        CGRect newRect = [aView frame];
        newRect.origin.y += 3;
        [[aView animator] setFrame:newRect];
    }
}

- (void)_animateViewIn:(NSView *)aView
{
    if (![self superview])
        return;
    
    CGRect aFrame = [aView frame];

    CGRect startPosition = CGRectMake(aFrame.origin.x, -aFrame.size.height, aFrame.size.width, aFrame.size.height);
    [aView setFrame:startPosition];

    [[NSAnimationContext currentContext] setDuration:0.25];
    [[NSAnimationContext currentContext] setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        [[aView animator] setFrame:aFrame];
    } completionHandler:^{}];
}


- (void)removeFromSuperview
{
    [_reuseQueue removeAllObjects];
    [super removeFromSuperview];
}


@end
