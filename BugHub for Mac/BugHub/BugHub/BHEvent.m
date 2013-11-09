//
//  BHEvent.m
//  BugHub
//
//  Created by Randy on 4/3/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "BHEvent.h"
#import "BHIssue.h"
#import "BHUser.h"
#import "BHRepository.h"

@implementation BHEvent

- (id)initWithDict:(NSDictionary *)aDict
{
    self = [self init];
    
    if (self)
    {
        // this implementation will largely depend on whether or not I end up hitting the
        // :user/:repo/events endpoint or the :user/:repo/issues/events
    }
    
    return self;
}

@end
