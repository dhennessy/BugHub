//
//  NSSet+Additions.m
//  BugHub
//
//  Created by Randy on 1/2/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "NSSet+Additions.h"

@implementation NSSet (Additions)

- (NSSet *)setByIntersectingSet:(NSSet *)aSet
{
    NSSet *smallestSet = [aSet count] < [self count] ? aSet : self;
    
    if (aSet == smallestSet)
        aSet = self;

    NSMutableSet *newSet = [NSMutableSet setWithCapacity:[smallestSet count]];
    
    for (id obj in smallestSet)
    {
        if ([aSet member:obj] != nil)
            [newSet addObject:obj];
    }

    return [newSet copy];
}

- (NSSet *)setBySubtractingSet:(NSSet *)aSet
{
    if ([aSet isEqualToSet:self])
        return [NSSet set];

    NSMutableSet *newSet = [NSMutableSet setWithCapacity:[self count] - [aSet count]];

    for (id obj in self)
    {
        if ([aSet member:obj] == nil)
            [newSet addObject:obj];
    }

    return [newSet copy];
}

@end
