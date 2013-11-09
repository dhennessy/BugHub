//
//  RLView.m
//  BugHub
//
//  Created by Randy on 1/24/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "RLView.h"

@implementation RLView

- (void)drawRect:(NSRect)dirtyRect
{
    if (self.backgroundColor == nil)
        return;

    // from: http://stackoverflow.com/questions/3900392/repeating-background-image-in-an-nsview
    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    [context saveGraphicsState];
    [context setPatternPhase:NSMakePoint(0,[self frame].size.height)];
    [self.backgroundColor set];
    [self.borderColor setStroke];
    CGContextFillRect([context graphicsPort], [self bounds]);
    //    CGContextStrokeRect([context graphicsPort], CGRectInset([self bounds], .5, .5));
    [context restoreGraphicsState];
}

@end
