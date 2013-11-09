//
//  BHMilestone.m
//  BugHub
//
//  Created by Randy on 12/26/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import "BHMilestone.h"
#import "GHUtils.h"

@implementation BHMilestone

+ (BHMilestone *)voidMilestone
{
    static BHMilestone *aMilestone;
    
    if (!aMilestone)
    {
        aMilestone = [[self alloc] init];
        [aMilestone setName:@"No Milestone Set"];
    }
    
    return aMilestone;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        _number = NSNotFound;
        self.name = @"";
        self.descriptionText = @"";
    }
    
    return self;
}

- (void)setDictionaryValues:(NSDictionary *)aDict
{
    self.number = [[aDict objectForKey:@"number"] integerValue];
    self.name = [aDict objectForKey:@"title"];
    self.deadline = [GHUtils dateFromGithubString:[aDict objectForKey:@"due_on"]];
    
    self.openIssueCount = [[aDict objectForKey:@"open_issues"] integerValue];
    self.closedIssueCount = [[aDict objectForKey:@"closed_issues"] integerValue];
    self.descriptionText = [aDict objectForKey:@"description"];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Milestone: {name: %@}", self.name];
}

- (NSDictionary *)webViewJSONDict
{
    return @{
        @"name": self.name,
        /*@"deadlineDate": self.deadline.*/
        @"openIssueCount": @(self.openIssueCount),
        @"closedIssueCount": @(self.closedIssueCount)
    };
}

@end
