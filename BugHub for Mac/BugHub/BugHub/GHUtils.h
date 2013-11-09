//
//  GHUtils.h
//  BugHub
//
//  Created by Randy on 12/27/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GHUtils : NSObject

+ (NSDate *)dateFromGithubString:(NSString *)aString;
+ (NSString *)githubDateStringFromDate:(NSDate *)aDate;
+ (NSString *)httpDateStringFromDate:(NSDate *)aDate;
@end
