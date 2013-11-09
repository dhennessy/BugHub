//
//  BHComment.h
//  BugHub
//
//  Created by Randy on 12/30/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BHQueueUpdateRequest.h"

@class BHUser, BHIssue;

@interface BHComment : NSObject<BHQueueUpdateRequest>

@property(strong) BHUser *user;
@property(strong) BHIssue *issue;
@property(strong) NSDate *dateCreated;
@property(strong) NSDate *lastUpdated;
@property(strong) NSString *htmlBody; // for displaying
@property(strong) NSString *rawBody; // for editing
@property(strong) NSURL *url;
@property NSInteger number;

- (void)setDictValues:(NSDictionary *)dictValues;
- (NSDictionary *)webViewJSONDict;
@end
