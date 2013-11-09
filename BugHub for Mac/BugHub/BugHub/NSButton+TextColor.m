//
//  NSButton+TextColor.m
//  BugHub
//
//  Created by Randy on 3/6/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "NSButton+TextColor.h"

@implementation NSButton (TextColor)

- (NSColor *)textColor
{
    NSAttributedString *attrTitle = [self attributedTitle];
    NSInteger len = [attrTitle length];
    NSRange range = NSMakeRange(0, MIN(len, 1)); // take color from first char
    NSDictionary *attrs = [attrTitle fontAttributesInRange:range];
    NSColor *textColor = [NSColor controlTextColor];

    if (attrs)
        textColor = [attrs objectForKey:NSForegroundColorAttributeName];

    return textColor;
}

- (void)setTextColor:(NSColor *)textColor
{
    NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[self attributedTitle]];
    NSInteger len = [attrTitle length];
    NSRange range = NSMakeRange(0, len);
    [attrTitle addAttribute:NSForegroundColorAttributeName value:textColor range:range];
    [attrTitle fixAttributesInRange:range];
    [self setAttributedTitle:attrTitle];

}

@end