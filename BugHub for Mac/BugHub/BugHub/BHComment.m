//
//  BHComment.m
//  BugHub
//
//  Created by Randy on 12/30/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

/*
 {
 "id": 1,
 "url": "https://api.github.com/repos/octocat/Hello-World/issues/comments/1",
 "body": "Me too",
 "user": {
     "login": "octocat",
     "id": 1,
     "avatar_url": "https://github.com/images/error/octocat_happy.gif",
     "gravatar_id": "somehexcode",
     "url": "https://api.github.com/users/octocat"
 },
 "created_at": "2011-04-14T16:00:49Z",
 "updated_at": "2011-04-14T16:00:49Z"
 }
 
 
 */

#import "BHComment.h"
#import "BHRepository.h"
#import "BHIssue.h"
#import "BHUser.h"
#import "GHUtils.h"
#import "GHAPIRequest.h"
#import "BHRequestQueue.h"
#import "AppDelegate.h"
#import "NSDate+Strings.h"

@interface BHComment ()
{
    GHAPIRequest *_updateRequest;
}

@end

@implementation BHComment

- (void)setDictValues:(NSDictionary *)dictValues
{
    self.url = [NSURL URLWithString:[dictValues objectForKey:@"url"]];
    self.dateCreated = [GHUtils dateFromGithubString:[dictValues objectForKey:@"created_at"]];
    self.lastUpdated = [GHUtils dateFromGithubString:[dictValues objectForKey:@"updated_at"]];
    
    NSDictionary *rawUser = [dictValues objectForKey:@"user"];
    self.user = [BHUser userWithLogin:[rawUser objectForKey:@"login"] dictionaryValues:rawUser];

    self.rawBody = [dictValues objectForKey:@"body"];
    self.htmlBody = [dictValues objectForKey:@"body_html"];
    
    self.number = [[dictValues objectForKey:@"id"] integerValue];
}

- (BOOL)isEqual:(BHComment *)object
{
    if (![object isKindOfClass:[BHComment class]])
        return NO;

    return self == object || [self.url isEqual:object.url] || ([self.issue isEqual:object.issue] && self.number == object.number);
}

- (BOOL)updateServerData
{
    if (_updateRequest != nil)
        return NO;

    if (self.url != nil)
    {
        // update
        _updateRequest = [GHAPIRequest requestForUpdatedCommentWithBody:self.rawBody commentURL:[self.url absoluteString]];
    }
    else
    {
        // create
        NSString *repoID = [[self.issue repository] identifier];
        _updateRequest = [GHAPIRequest requestForNewCommentWithBody:self.rawBody repositoryIdentifier:repoID issueNumber:[self.issue number]];
    }
    
    __weak typeof(self) commentObject = self;
    
    [_updateRequest setCompletionBlock:^(GHAPIRequest *aRequest){
        
        if ([aRequest status] == GHAPIRequestStatusComplete)
        {
            NSInteger statusCode = [aRequest responseStatusCode];
            
            if (statusCode < 200 | statusCode > 299)
            {
                NSLog(@"Error with comment update request...");
                
                __strong typeof(commentObject) strongSelf = commentObject;
                
                if (strongSelf)
                    strongSelf->_updateRequest = nil;

                return;
            }
            
            NSData *responseData = [aRequest responseData];
            NSError *error = nil;
            NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
            
            if (error || ![responseDict isKindOfClass:[NSDictionary class]])
            {
                NSLog(@"Error parsing comment update response data.. %@", error);
                __strong typeof(commentObject) strongSelf = commentObject;
                
                if (strongSelf)
                    strongSelf->_updateRequest = nil;

                return;
            }

            [commentObject setDictValues:responseDict];

            __strong typeof(commentObject) strongSelf = commentObject;
            
            if (strongSelf)
                strongSelf->_updateRequest = nil;
        }
    }];

    [_updateRequest sendRequest];
    
    return YES;
}

- (NSDictionary *)webViewJSONDict
{
    return @{
        @"user": [self.user webViewJSONDict],
        @"createdAt": [self.dateCreated normalDateString],
        @"body": [self.htmlBody stringByReplacingOccurrencesOfString:@"target=\"_blank\"" withString:@""],
        @"id": @(self.number)
    };
}

@end
