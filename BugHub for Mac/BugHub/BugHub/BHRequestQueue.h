//
//  BHRequestQueue.h
//  BugHub
//
//  Created by Randy on 1/3/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BHQueueUpdateRequest.h"

@interface BHRequestQueue : NSObject

+ (id)mainQueue;

- (void)addObject:(id<BHQueueUpdateRequest>)anUpdate;
- (NSInteger)count;

// starts the queue such that it automatically runs every 5 seconds
- (void)startQueue;

// stop the queue from automatically running
- (void)stopQueue;

// asks each object in the queue to update.
- (void)runQueue;

@end
