//
//  BHRequestQueue.m
//  BugHub
//
//  Created by Randy on 1/3/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "BHRequestQueue.h"

@interface BHRequestQueue ()
{
    NSMutableOrderedSet *_objectsToUpdate;
    NSTimer *_runTimer;
}
@end

@implementation BHRequestQueue

+ (id)mainQueue
{
    static id mainQueue = nil;
    
    if (!mainQueue)
        mainQueue = [[self alloc] init];
    
    return mainQueue;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        _objectsToUpdate = [NSMutableOrderedSet orderedSetWithCapacity:3];
    }
    
    return self;
}

- (void)addObject:(id<BHQueueUpdateRequest>)anUpdate
{
    [_objectsToUpdate addObject:anUpdate];
    [self startQueue];
}

- (NSInteger)count
{
    return [_objectsToUpdate count];
}

// starts the queue such that it automatically runs every 5 seconds
- (void)startQueue
{
    if([_runTimer isValid])
        return;

    _runTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(runQueue) userInfo:nil repeats:YES];
}

// stop the queue from automatically running
- (void)stopQueue
{
    [_runTimer invalidate];
    _runTimer = nil;
}

// asks each object in the queue to update.
- (void)runQueue
{
    NSOrderedSet *currentObjects = [_objectsToUpdate copy];
    _objectsToUpdate = [NSMutableOrderedSet orderedSetWithCapacity:[currentObjects count]];

    for (id<BHQueueUpdateRequest> object in currentObjects) {
        // calling update server data will send the request as needed
        // if it retuns NO, wait until the next cycle. 
        if (![object updateServerData])
            [_objectsToUpdate addObject:object];
    }

    if ([_objectsToUpdate count] == 0)
        [self stopQueue];
}

@end
