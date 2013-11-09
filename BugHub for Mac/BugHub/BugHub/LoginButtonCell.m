//
//  LoginButtonCell.m
//  BugHub
//
//  Created by Randy on 3/23/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "LoginButtonCell.h"
#import "NSColor+hex.h"

@implementation LoginButtonCell

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView
{
    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    [context saveGraphicsState];

    NSImage *image = [NSImage imageNamed:@"big_button"];

    if ([self isHighlighted])
    {
        // A copy is required, because imagename: seems to work like a 'singleton' and thus lockingfocus
        // and fucking with the pixel colors will change it FOREVAR!!!!11!!!1
        NSImage *blackImage = [image copy];
        [blackImage lockFocus];
        [[NSColor colorWithCalibratedWhite:0.0 alpha:0.33] set];
        NSRectFillUsingOperation(frame, NSCompositeSourceAtop);
        [blackImage unlockFocus];
        image = blackImage;
    }

    [image drawInRect:frame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
    [context restoreGraphicsState];
}

- (CGRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView
{
    NSMutableAttributedString *textToDraw = [title mutableCopy];
    NSRange range = NSMakeRange(0, textToDraw.length);
    [textToDraw addAttribute:NSFontAttributeName value:[NSFont boldSystemFontOfSize:12.0] range:range];
    [textToDraw addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithHexColorString:@"e6ecf2"] range:range];
    
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowBlurRadius:0];
    [shadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.75]];
    [shadow setShadowOffset:CGSizeMake(0, 1)];
    [textToDraw addAttribute:NSShadowAttributeName value:shadow range:range];
    
    return [super drawTitle:textToDraw withFrame:frame inView:controlView];
}

@end
