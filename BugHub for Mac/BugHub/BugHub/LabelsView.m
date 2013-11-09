//
//  LabelsView.m
//  BugHub
//
//  Created by Randy on 3/5/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "LabelsView.h"
#import "BHLabel.h"
#import "NSColor+hex.h"
#import "NSButton+TextColor.h"

const CGFloat kPadding = 5;

@protocol LabelTokenChange <NSObject>

- (void)tokenDidChangeWidth:(LabelToken *)aToken;
- (void)userClickedRemoveButton:(LabelToken *)aToken;

@end


@interface LabelsView ()
{
    NSMutableArray *allTokens;
}
@end

@implementation LabelsView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        allTokens = [NSMutableArray arrayWithCapacity:0];
    }

    return self;
}

- (void)tokenDidChangeWidth:(LabelToken *)aToken
{
    NSInteger tokenIndex = [allTokens indexOfObject:aToken];
    
    CGFloat currentX = CGRectGetMaxX(aToken.frame) + kPadding;
    
    for (; tokenIndex < [allTokens count]; tokenIndex++)
    {
        LabelToken *currentToken = [allTokens objectAtIndex:tokenIndex];
        [currentToken setFrameOrigin:CGPointMake(currentX, 0)];
        currentX += CGRectGetWidth(currentToken.frame) + kPadding;
    }
}

- (void)userClickedRemoveButton:(LabelToken *)aToken
{
    
}

- (void)setLabels:(NSArray *)newLabels
{
    // remove all the labels
    [allTokens makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [allTokens removeAllObjects];

    // add new labels
    CGFloat currentX = 0;
    for (BHLabel *aLabel in newLabels)
    {
        LabelToken *newLabelView = [[LabelToken alloc] initWithLabel:aLabel];
        [newLabelView setFrameOrigin:CGPointMake(currentX, 0)];
        currentX += CGRectGetWidth(newLabelView.frame) + kPadding;

        [self addSubview:newLabelView];
        [allTokens addObject:newLabelView];
    }
}

- (void)removeLabel:(BHLabel *)aLabel
{
    NSInteger tokenIndex = [allTokens indexOfObjectPassingTest:^BOOL(LabelToken *obj, NSUInteger idx, BOOL *stop) {
        if ([obj representsLabel:aLabel])
        {
            *stop = YES;
            return YES;
        }
        
        return NO;
    }];
    
    if (tokenIndex == NSNotFound)
        return;
    
    LabelToken *aToken = [allTokens objectAtIndex:tokenIndex];
    [aToken removeFromSuperview];
    [allTokens removeObjectAtIndex:tokenIndex];

    CGFloat currentX = CGRectGetMinX(aToken.frame) + kPadding;
    
    for (; tokenIndex < [allTokens count]; tokenIndex++)
    {
        LabelToken *currentToken = [allTokens objectAtIndex:tokenIndex];
        [currentToken setFrameOrigin:CGPointMake(currentX, 0)];
        currentX += CGRectGetWidth(currentToken.frame) + kPadding;
    }
}

- (void)addNewLabel:(BHLabel *)newLabel
{
    LabelToken *aToken = [allTokens lastObject];
    NSInteger tokenIndex = [allTokens indexOfObject:aToken];
    [aToken removeFromSuperview];
    [allTokens removeObjectAtIndex:tokenIndex];
    
    CGFloat currentX = CGRectGetMinX(aToken.frame) + kPadding;
    LabelToken *newLabelView = [[LabelToken alloc] initWithLabel:newLabel];
    [newLabelView setFrameOrigin:CGPointMake(currentX, 0)];
    [self addSubview:newLabelView];
    [allTokens addObject:newLabelView];
}

@end















@interface LabelToken ()
{
    BOOL mouseOver;
    BHLabel *_representedLabel;
    NSButton *_xButton;
    
    NSTrackingRectTag trackingRect;
}
- (void)_updateTitle;
- (NSColor *)_labelColor;
- (NSColor *)_strokeColor;
- (NSColor *)_xButtonColor;

- (void)xButtonWasPressed:(id)sender;
@end

@implementation LabelToken

- (id)initWithLabel:(BHLabel *)aLabel
{
    self = [super initWithFrame:CGRectZero];
    
    if (self)
    {
        [aLabel addObserver:self forKeyPath:@"name" options:0 context:NULL];
        [aLabel addObserver:self forKeyPath:@"color" options:0 context:NULL];
        _representedLabel = aLabel;
        
        nameField = [[NSTextField alloc] initWithFrame:CGRectMake(15, 1, 100, 15)];
        [nameField setEditable:NO];
        [nameField setBordered:NO];
        [nameField setBezeled:NO];
        [nameField setBackgroundColor:[NSColor clearColor]];
        [nameField setTextColor:[self _labelColor]];
        [nameField setFont:[NSFont fontWithName:@"Helvetica Bold" size:10]];
        [self _updateTitle];
        
        _xButton = [[NSButton alloc] initWithFrame:CGRectMake(3, 0, 13, 14)];
        [_xButton setTitle:@"x"];
        [_xButton setBordered:NO];
        [_xButton setFont:[NSFont fontWithName:@"Helvetica Bold" size:10]];
        [_xButton setTextColor:[self _xButtonColor]];
        [_xButton setHidden:YES];
        [_xButton setTarget:self];
        [_xButton setAction:@selector(xButtonWasPressed:)];
        [_xButton setButtonType:NSMomentaryChangeButton];
        [self addSubview:_xButton];
        
        [self addSubview:nameField];
    }
    
    return self;
}

- (void)xButtonWasPressed:(id)sender
{
    
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    //    mouseOver = YES;
    //    [self setNeedsDisplay:YES];
    [_xButton setHidden:NO];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    mouseOver = NO;
    [self setNeedsDisplay:YES];
    [_xButton setHidden:YES];
}

- (void)_updateTitle
{
    if (trackingRect)
        [self removeTrackingRect:trackingRect];
    
    [nameField setStringValue:_representedLabel.name];
    [nameField sizeToFit];
    
    const CGFloat xButtonWidth = 15;
    const CGFloat kRightPadding = 15;
    [self setFrameSize:CGSizeMake(CGRectGetWidth(nameField.frame) + xButtonWidth + kRightPadding, 15)];
    
    // FIX ME: Add this one day...
    //trackingRect = [self addTrackingRect:self.bounds owner:self userData:NULL assumeInside:NO];
    
}

- (void)dealloc
{
    [_representedLabel removeObserver:self forKeyPath:@"name"];
    [_representedLabel removeObserver:self forKeyPath:@"color"];
    
    if (trackingRect)
        [self removeTrackingRect:trackingRect];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"name"])
    {
        [self _updateTitle];
        [((id<LabelTokenChange>)[self superview]) tokenDidChangeWidth:self];
    }
    else if ([keyPath isEqualToString:@"color"])
    {
        [nameField setTextColor:[self _labelColor]];
        [_xButton setTextColor:[self _xButtonColor]];
        [self setNeedsDisplay:YES];
    }
}

- (void)drawRect:(NSRect)dirtyRect
{
    const CGFloat radius = 7;
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, .5, .5) xRadius:radius yRadius:radius];
    
    if (![_representedLabel color])
        [[NSColor colorWithHexColorString:@"c3d7e6"] setFill];
    
    [[_representedLabel color] setFill];
    [[self _strokeColor] setStroke];
    [path fill];
    [path stroke];
}

- (NSColor *)_xButtonColor
{
    NSColor *color = [_representedLabel color];
    CGFloat brightness = [color brightnessComponent] * 100;
    
    if (brightness < 20)
        brightness *= 15;
    else if (brightness > 80)
        brightness *= .3;
    else
        brightness *= 4;
    
    brightness /= 100;
    
    return [NSColor colorWithCalibratedHue:[color hueComponent] saturation:[color saturationComponent] brightness:brightness alpha:1.0];
}

- (NSColor *)_strokeColor
{
    NSColor *color = [_representedLabel color];
    CGFloat brightness = [color brightnessComponent] * 100;
    
    if (brightness < 20)
        brightness *= 10;
    else if (brightness > 80)
        brightness *= .4;
    else
        brightness *= 6;
    
    brightness /= 100;
    
    return [NSColor colorWithCalibratedHue:[color hueComponent] saturation:[color saturationComponent] brightness:brightness alpha:0.15];
}

- (NSColor *)_labelColor
{
    NSColor *color = [_representedLabel color];
    CGFloat brightness = [color brightnessComponent] * 100;
    
    if (brightness < 20)
        brightness *= 10;
    else if (brightness > 80)
        brightness *= .4;
    else
        brightness *= 6;
    
    brightness /= 100;
    
    return [NSColor colorWithCalibratedHue:[color hueComponent] saturation:[color saturationComponent] brightness:brightness alpha:1.0];
}

- (BOOL)representsLabel:(BHLabel *)aLabel
{
    return _representedLabel == aLabel || [_representedLabel isEqual:aLabel];
}

@end
