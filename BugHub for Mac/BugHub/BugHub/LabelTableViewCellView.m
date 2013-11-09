//
//  LabelTableViewCellView.m
//  BugHub
//
//  Created by Randy on 1/24/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "LabelTableViewCellView.h"
#import "BHLabel.h"
#import "DrawingHelp.h"

@interface LabelTableViewCellView ()
{
    BHLabel *_representedLabel;
}
@end

@implementation LabelTableViewCellView

- (void)setRepresentedLabel:(BHLabel *)aLabel
{
    _representedLabel = aLabel;
    [self.textField setStringValue:[aLabel name]];
    
    //    if (aLabel == [BHLabel voidLabel])
    //    [self.textField setFont:[NSFont boldSystemFontOfSize:12]];
    //else
    //    [self.textField setFont:[NSFont systemFontOfSize:12]];
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    //UIGraphicsBeginImageContextWithOptions(CGSizeMake(20, 10), NO, 0);
    CGContextRef c = [[NSGraphicsContext currentContext] graphicsPort];
    
    CGContextSaveGState(c);
    CGContextTranslateCTM(c, 5, 10);
    [[NSColor blackColor] setStroke];
    [[_representedLabel color] setFill];
    SSDrawRoundedRect(c, CGRectMake(1, 1, 18, 8), 3);
    CGContextStrokePath(c);
    CGContextRestoreGState(c);
}

@end
