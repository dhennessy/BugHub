//
//  RLStack.m
//  BugHub
//
//  Created by Randy on 12/31/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import "RLStack.h"

@interface RLStack ()
{
    NSMutableOrderedSet *_items;
}

@end

@implementation RLStack

- (id)init
{
    self = [super init];
    
    if (self)
        _items = [NSMutableOrderedSet orderedSetWithCapacity:10];
    
    return self;
}

- (NSInteger)count
{
    return [_items count];
}

- (void)push:(id)anObject
{
    @synchronized(self)
    {
        [_items addObject:anObject];
    }
}

- (id)pop
{

    if ([self count] < 1)
        return nil;

    id lastObj = nil;
    @synchronized(self)
    {
        lastObj = [_items lastObject];
        [_items removeObjectAtIndex:[self count] - 1];
    }

    return lastObj;
}

- (id)topObject
{
    return [_items lastObject];
}
@end
