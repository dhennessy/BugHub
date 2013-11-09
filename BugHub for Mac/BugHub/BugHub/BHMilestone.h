//
//  BHMilestone.h
//  BugHub
//
//  Created by Randy on 12/26/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BHMilestone : NSObject

@property NSInteger number;
@property(strong) NSString *name;
@property(strong) NSDate *deadline;

@property NSInteger openIssueCount;
@property NSInteger closedIssueCount;

@property(strong) NSString *descriptionText;

- (void)setDictionaryValues:(NSDictionary *)aDict;
- (NSDictionary *)webViewJSONDict;

+ (BHMilestone *)voidMilestone;

@end
