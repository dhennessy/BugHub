//
//  AssigneeTableCellView.m
//  BugHub
//
//  Created by Randy on 1/26/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "AssigneeTableCellView.h"
#import "BHUser.h"


@implementation AssigneeTableCellView

- (void)setObjectValue:(id)objectValue
{
    id currentObject = [self objectValue];
    [currentObject removeObserver:self forKeyPath:@"avatar"];

    [super setObjectValue:objectValue];


    if (!objectValue)
        return;

    [objectValue addObserver:self forKeyPath:@"avatar" options:0 context:NULL];
    
    [self.textField setStringValue:[objectValue login]];
    [self.imageView setImage:[objectValue avatar]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"avatar"])
    {
        [self.imageView setImage:[self.objectValue avatar]];
    }
}


@end
