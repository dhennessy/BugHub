//
//  LoginTextFieldCell.m
//  BugHub
//
//  Created by Randy on 3/23/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "LoginTextFieldCell.h"
#import "NSColor+hex.h"

@implementation LoginTextFieldCell

- (void)awakeFromNib
{
    /*NSString *placeholder = [self placeholderString];
    NSMutableAttributedString *newPlaceholder = [[NSMutableAttributedString alloc] initWithString:placeholder];
    
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowOffset:CGSizeMake(0, -1)];
    [shadow setShadowColor:[NSColor whiteColor]];
    [shadow setShadowBlurRadius:0.0f];
    
    NSColor *textColor = [NSColor colorWithHexColorString:@"202830"];
    textColor = [textColor colorWithAlphaComponent:0.35];
    NSRange range = NSMakeRange(0, placeholder.length);

    [newPlaceholder addAttribute:NSForegroundColorAttributeName value:textColor range:range];
    [newPlaceholder addAttribute:NSShadowAttributeName value:shadow range:range];
    [newPlaceholder addAttribute:NSFontAttributeName value:[NSFont boldSystemFontOfSize:16.0] range:range];

    [self setPlaceholderAttributedString:newPlaceholder];*/
}



/*- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    CGRect rect = [self drawingRectForBounds:cellFrame];
    NSString *text = [self stringValue];
    
    BOOL isUsingPlaceholder = NO;
    
    if (text.length == 0)
    {
        isUsingPlaceholder = YES;
        text = [self placeholderString];
    }
    
    NSMutableAttributedString *stringToDraw = [[NSMutableAttributedString alloc] initWithString:text];
    NSRange range = NSMakeRange(0, text.length);
    
    if (isUsingPlaceholder)
    {
        NSShadow *shadow = [[NSShadow alloc] init];
        [shadow setShadowOffset:CGSizeMake(0, -1)];
        [shadow setShadowColor:[NSColor whiteColor]];
        [shadow setShadowBlurRadius:0.0f];
        
        NSColor *textColor = [NSColor colorWithHexColorString:@"202830"];
        textColor = [textColor colorWithAlphaComponent:0.35];
        
        [stringToDraw addAttribute:NSForegroundColorAttributeName value:textColor range:range];
        [stringToDraw addAttribute:NSShadowAttributeName value:shadow range:range];
        [stringToDraw addAttribute:NSFontAttributeName value:[NSFont boldSystemFontOfSize:16.0] range:range];
        //[self setPlaceholderAttributedString:stringToDraw];
    }
    else
    {
        NSShadow *shadow = [[NSShadow alloc] init];
        [shadow setShadowOffset:CGSizeMake(0, -1)];
        [shadow setShadowColor:[NSColor whiteColor]];
        [shadow setShadowBlurRadius:0.0f];

        [stringToDraw addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithHexColorString:@"202830"] range:range];
        [stringToDraw addAttribute:NSShadowAttributeName value:shadow range:range];
        [stringToDraw addAttribute:NSFontAttributeName value:[NSFont boldSystemFontOfSize:16.0] range:range];
        //[self setAttributedStringValue:stringToDraw];
    }
    
    [stringToDraw drawInRect:rect];
}*/

@end
