//
//  BHEvent.h
//  BugHub
//
//  Created by Randy on 4/3/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BHRepository, BHIssue, BHUser, BHMilestone, BHLabel;

typedef enum {
    BHEventTypeIssue,
    BHEventTypeComment
} BHEventType;

typedef enum {
    BHEventActionIssueOpened = 1,
    BHEventActionIssueClosed = 2,
    BHEventActionIssueReopened =3 
} BHEventAction;

@interface BHEvent : NSObject

- (id)initWithDict:(NSDictionary *)aDict;

@property BHEventType type;
@property BHEventAction action;
@property(strong) NSDictionary *issueDict;



@end
