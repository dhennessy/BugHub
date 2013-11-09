//
//  NSTextField+Additions.m
//  BugHub
//
//  Created by Randy on 12/30/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import "NSTextField+Additions.h"

@implementation NSTextField (Additions)

+ (id)labelWithString:(NSAttributedString *)aString
{
    NSTextField *label = [[NSTextField alloc] initWithFrame:CGRectZero];
    [label setAttributedStringValue:aString];
    [label setEditable:NO];
    [label setBezeled:NO];
    [label setSelectable:NO];
    [label setBackgroundColor:[NSColor clearColor]];
    [label sizeToFit];

    return label;
}

+ (id)labelWithFrame:(CGRect)aRect
{
    NSTextField *label = [[NSTextField alloc] initWithFrame:aRect];
    [label setEditable:NO];
    [label setBezeled:NO];
    [label setSelectable:NO];
    [label setBackgroundColor:[NSColor clearColor]];
    
    return label;
}

@end
