//
//  MilestoneTableCellView.m
//  BugHub
//
//  Created by Randy on 4/7/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "MilestoneTableCellView.h"

@implementation MilestoneTableCellView

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
    [super setBackgroundStyle:backgroundStyle];
    
    if (backgroundStyle == NSBackgroundStyleDark)
        [self.imageView setImage:[NSImage imageNamed:@"milestone-icon-highlighted"]];
    else
        [self.imageView setImage:[NSImage imageNamed:@"milestone-icon"]];
}

@end
