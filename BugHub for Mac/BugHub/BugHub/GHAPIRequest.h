//
//  GHAPIRequest.h
//  BugHub
//
//  Created by Randy on 12/25/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OCTClient.h"

@class GHAPIRequest;

typedef void(^GHAPIRequestCompletionBlock)(GHAPIRequest *request);

typedef enum {
    GHAPIRequestStatusWaiting,
    GHAPIRequestStatusCanceled,
    GHAPIRequestStatusLoading,
    GHAPIRequestStatusComplete,
    GHAPIRequestStatusError
} GHAPIRequestStatus;

extern NSString *BHLoginChangedNotification;
extern NSString *BHHitRateLimitNotification;

@interface GHAPIRequest : NSObject<NSURLConnectionDataDelegate, NSURLConnectionDelegate>

@property(nonatomic, readonly) GHAPIRequestStatus status;
@property(nonatomic, readonly) NSData *responseData;
@property(nonatomic, readonly) NSInteger responseStatusCode;
@property(nonatomic, readonly) NSDictionary *responseHeaders;
@property(strong) GHAPIRequestCompletionBlock completionBlock;


@property(strong) NSData *requestBody;
@property(strong) NSString *requestMethod;

+ (BOOL)initializeClassWithKeychain;
+ (void)setClassAuthenticatedUser:(NSString *)aUsername token:(NSString *)token;
+ (void)setClassAuthenticatedUser:(NSString *)aUsername password:(NSString *)aPassword;
+ (void)setAPIPrefix:(NSString *)apiPrefix;
+ (void)setUsesOAuth:(BOOL)usesOAuth;
+ (NSString *)authenticatedUserLogin;

- (NSInteger)pageOfNextRequestFromResponse;
- (NSInteger)pageOfLastRequestFromResponse;

// sub requests
//- (void)addSubRequest:(GHAPIRequest *)aSubRequest;

// request headers
- (void)addHeaderValues:(NSDictionary *)aDict;
- (void)addHeader:(NSString *)aValue forKey:(NSString *)aKey;
- (NSString *)headerForKey:(NSString *)aKey;
- (NSDictionary *)headerValues;
- (void)removeHeaderForKey:(NSString *)aKey;

- (void)checkRateLimit;

//manual requests
- (void)setRequestURL:(NSString *)aURLString;
- (void)stopRequest;
- (void)sendRequest;

//automatic requests

// users
+ (id)requestForAuth:(NSString *)usename token:(NSString *)token;
+ (id)requestForAuth:(NSString *)usename password:(NSString *)password;
+ (id)requestForUser:(NSString *)aUsername;
+ (id)requestForUsersOrganizations:(NSString *)aUsername;

// repos
+ (id)requestForRepositoryWithID:(NSString *)aRepoIdentifier;
+ (id)requestForUsersRepositories:(NSString *)aUsername;
+ (id)requestForOrgsRepositories:(NSString *)aUsername;
+ (id)requestForRepositorysMilestones:(NSString *)aRepoIdentifier;
+ (id)requestForRepositorysLabels:(NSString *)aRepoIdentifier;
+ (id)requestForRepositorysAssignees:(NSString *)aRepoIdentifier;

+ (id)requestForNewMilestone:(NSString *)aName deadline:(NSDate *)aDeadline description:(NSString *)aDescription repositoryIdentifier:(NSString*)aRepoIdentifier;
+ (id)requestForNewLabel:(NSString *)aName color:(NSColor *)aColor repositoryIdentifier:(NSString*)aRepoIdentifier;

// issues
+ (id)requestForReposOpenIssues:(NSString *)aRepoIdentifier page:(NSInteger)aPageNumber;
+ (id)requestForReposClosedIssues:(NSString *)aRepoIdentifier page:(NSInteger)aPageNumber;
+ (id)requestForReposOpenIssueUpdates:(NSString *)aRepoIdentifier afterDate:(NSDate *)aDate;
+ (id)requestForReposClosedIssueUpdates:(NSString *)aRepoIdentifier afterDate:(NSDate *)aDate;
+ (id)requestForIssueNumber:(NSInteger)aNumber repositoryIdentifier:(NSString *)aRepoIdentifier;
+ (id)requestForIssueUpdate:(NSInteger)aNumber repositoryIdentifier:(NSString *)aRepoIdentifier updates:(NSDictionary *)updatesDict;
+ (id)requestForNewIssue:(NSDictionary *)issueDict forRepositoryIdentifier:(NSString *)aRepoIdentifier;

// comments
+ (id)requestForCommentsFor:(NSString *)aRepoIdentifier issue:(NSInteger)anIssueNumber page:(NSInteger)aPageNumber;
+ (id)requestForCommentsFor:(NSString *)aRepoIdentifier issue:(NSInteger)anIssueNumber sinceDate:(NSDate *)aDate page:(NSInteger)aPageNumber;
+ (id)requestForDeleteComment:(NSString *)aRepoIdentifier commentId:(NSInteger)aCommentId;

+ (id)requestForNewCommentWithBody:(NSString *)aBody repositoryIdentifier:(NSString *)anIdentifier issueNumber:(NSInteger)anIssueNumber;
+ (id)requestForUpdatedCommentWithBody:(NSString *)aBody commentURL:(NSString *)aURL;
+ (id)requestForCommentDeletion:(NSString *)aCommentURL;


// API Status
+ (id)requestForAPIStatus;
@end



