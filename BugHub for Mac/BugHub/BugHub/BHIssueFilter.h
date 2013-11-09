//
//  BHIssueFilter.h
//  BugHub
//
//  Created by Randy on 12/26/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BHIssue.h"

@interface BHIssueFilter : NSObject

@property(readonly) id filterValue;

@property(strong) NSIndexSet *indexes;
@property BHIssueState shouldBeOpen;
@property(strong) NSSet *assignedTo;
@property(strong) NSSet *milestones;
@property(strong) NSSet *labels;

@property(strong, nonatomic) NSString *text;

- (BOOL)lastChangeWasStricter;

- (BOOL)issueMatchesFilter:(BHIssue *)anIssue;

@end
