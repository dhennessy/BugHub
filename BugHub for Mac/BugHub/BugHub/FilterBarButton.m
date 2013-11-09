//
//  FilterBarButton.m
//  BugHub
//
//  Created by Randy on 2/15/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "FilterBarButton.h"
#import "NSColor+hex.h"

@implementation FilterBarButton

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView
{
    /*NSInteger state = [self state];
    BOOL isHighlighted = [self isHighlighted];
    
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];

    // light top line
    const CGPoint topPoints[] = {
        CGPointMake(0, CGRectGetHeight(frame) - 1.5),
        CGPointMake(CGRectGetWidth(frame), CGRectGetHeight(frame) - 1.5)
    };
    
    // dark bottom line
    const CGPoint bottomPoints[] = {
        CGPointMake(0, CGRectGetHeight(frame) - 0.5),
        CGPointMake(CGRectGetWidth(frame), CGRectGetHeight(frame) - 0.5)
    };
    
    //[[NSColor colorWithHexColorString:@"313131"] setStroke]; // WTFBBQ this is not the right color, but photoshop says it it
    [[NSColor colorWithCalibratedWhite:34.0/255.0 alpha:1.0] setStroke]; // WTFBBQ this is the right color
    CGContextStrokeLineSegments(context, topPoints, 2);
    
    // dont draw the top line if it's highlighted
    if (!isHighlighted && state != NSOnState)
    {
        //NSLog(@"isHighlighted: %@", isHighlighted ? @"Yes" : @"No");
        [[NSColor colorWithHexColorString:@"555555"] setStroke];
        CGContextStrokeLineSegments(context, bottomPoints, 2);
    }
    else
    {
        //NSLog(@"isHighlighted: %@", isHighlighted ? @"Yes" : @"No");
        // The dark overlay rect
        [[NSColor colorWithCalibratedWhite:0.0 alpha:0.25] setFill];
        CGContextFillRect(context, frame);
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        CFMutableArrayRef colors = (CFMutableArrayRef)CFBridgingRetain([NSMutableArray arrayWithCapacity:2]);
        
        NSColor *topColor = [NSColor colorWithCalibratedWhite:0.0 alpha:0.25];
        //NSColor *topColor = [NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:1.0];
        CFArrayInsertValueAtIndex(colors, 0, topColor.CGColor);
        NSColor *bottomColor = [NSColor colorWithCalibratedWhite:0.0 alpha:0.0];
        //NSColor *bottomColor = [NSColor colorWithCalibratedRed:0.0 green:1.0 blue:0.0 alpha:1.0];
        CFArrayInsertValueAtIndex(colors, 1, bottomColor.CGColor);
        
        CGFloat locations[] = {0.0, 1.0};
        
        CGGradientRef shadow = CGGradientCreateWithColors(colorSpace, colors, locations);
        CGContextDrawLinearGradient(context, shadow, CGPointMake(0, 0), CGPointMake(0, 5.0), 0);

        CFRelease(colors);
    }*/
}

- (void)drawImage:(NSImage *)image withFrame:(NSRect)frame inView:(NSView *)controlView
{
    [image drawInRect:CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame))
             fromRect:frame
            operation:NSCompositeSourceOver
             fraction:1.0
       respectFlipped:YES
                hints:nil];
}

- (NSRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView
{
    return CGRectZero;
}

@end
