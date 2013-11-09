//
//  BHRepository.h
//  BugHub
//
//  Created by Randy on 12/26/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 {
 "id": 1296269,
 "owner": {
     "login": "octocat",
     "id": 1,
     "avatar_url": "https://github.com/images/error/octocat_happy.gif",
     "gravatar_id": "somehexcode",
     "url": "https://api.github.com/users/octocat"
     },
 "name": "Hello-World",
 "full_name": "octocat/Hello-World",
 "description": "This your first repo!",
 "private": false,
 "fork": false,
 "url": "https://api.github.com/repos/octocat/Hello-World",
 "html_url": "https://github.com/octocat/Hello-World",
 "clone_url": "https://github.com/octocat/Hello-World.git",
 "git_url": "git://github.com/octocat/Hello-World.git",
 "ssh_url": "git@github.com:octocat/Hello-World.git",
 "svn_url": "https://svn.github.com/octocat/Hello-World",
 "mirror_url": "git://git.example.com/octocat/Hello-World",
 "homepage": "https://github.com",
 "language": null,
 "forks": 9,
 "forks_count": 9,
 "watchers": 80,
 "watchers_count": 80,
 "size": 108,
 "master_branch": "master",
 "open_issues": 0,
 "pushed_at": "2011-01-26T19:06:43Z",
 "created_at": "2011-01-26T19:01:12Z",
 "updated_at": "2011-01-26T19:14:43Z",
 "organization": {
     "login": "octocat",
     "id": 1,
     "avatar_url": "https://github.com/images/error/octocat_happy.gif",
     "gravatar_id": "somehexcode",
     "url": "https://api.github.com/users/octocat",
     "type": "Organization"
 },
 "parent": {
     "id": 1296269,
     "owner": {
         "login": "octocat",
         "id": 1,
         "avatar_url": "https://github.com/images/error/octocat_happy.gif",
         "gravatar_id": "somehexcode",
         "url": "https://api.github.com/users/octocat"
     },
     "name": "Hello-World",
     "full_name": "octocat/Hello-World",
     "description": "This your first repo!",
     "private": false,
     "fork": false,
     "url": "https://api.github.com/repos/octocat/Hello-World",
     "html_url": "https://github.com/octocat/Hello-World",
     "clone_url": "https://github.com/octocat/Hello-World.git",
     "git_url": "git://github.com/octocat/Hello-World.git",
     "ssh_url": "git@github.com:octocat/Hello-World.git",
     "svn_url": "https://svn.github.com/octocat/Hello-World",
     "mirror_url": "git://git.example.com/octocat/Hello-World",
     "homepage": "https://github.com",
     "language": null,
     "forks": 9,
     "forks_count": 9,
     "watchers": 80,
     "watchers_count": 80,
     "size": 108,
     "master_branch": "master",
     "open_issues": 0,
     "pushed_at": "2011-01-26T19:06:43Z",
     "created_at": "2011-01-26T19:01:12Z",
     "updated_at": "2011-01-26T19:14:43Z"
     },
     "source": {
         "id": 1296269,
         "owner": {
             "login": "octocat",
             "id": 1,
             "avatar_url": "https://github.com/images/error/octocat_happy.gif",
             "gravatar_id": "somehexcode",
             "url": "https://api.github.com/users/octocat"
         },
         "name": "Hello-World",
         "full_name": "octocat/Hello-World",
         "description": "This your first repo!",
         "private": false,
         "fork": false,
         "url": "https://api.github.com/repos/octocat/Hello-World",
         "html_url": "https://github.com/octocat/Hello-World",
         "clone_url": "https://github.com/octocat/Hello-World.git",
         "git_url": "git://github.com/octocat/Hello-World.git",
         "ssh_url": "git@github.com:octocat/Hello-World.git",
         "svn_url": "https://svn.github.com/octocat/Hello-World",
         "mirror_url": "git://git.example.com/octocat/Hello-World",
         "homepage": "https://github.com",
         "language": null,
         "forks": 9,
         "forks_count": 9,
         "watchers": 80,
         "watchers_count": 80,
         "size": 108,
         "master_branch": "master",
         "open_issues": 0,
         "pushed_at": "2011-01-26T19:06:43Z",
         "created_at": "2011-01-26T19:01:12Z",
         "updated_at": "2011-01-26T19:14:43Z"
     },
     "has_issues": true,
     "has_wiki": true,
     "has_downloads": true
 }
*/

/*
    This filter is applied by ANDing all non-nil members
*/

@class BHIssueFilter, BHUser, BHLabel, BHMilestone, BHIssue;

typedef void (^CallbackBlock)(id returnObject);

typedef enum {
    BHRepoError = -1,
    BHRepoNotLoaded = 0,
    BHRepoLoaded = 1,
    BHRepoLoading = 2
} BHRepoLoadedStatus;

typedef enum {
    BHPermissionNone, // can't do ANYTHING!
    BHPermissionReadOnly, // can only comment and add new issues.
    BHPermissionReadWrite // can add labels/milestones/assignees/open issues/close issues
} BHPermissionType;

@interface BHRepository : NSObject

// an ID is :user/:repo
+ (id)repositoryWithIdentifier:(NSString *)anIdentifier  dictionaryValues:(NSDictionary *)dictValues;
+ (BOOL)isValidIdentifier:(NSString *)aString;

- (void)loadRepo;

@property(strong) NSString *name;
@property(readonly) NSString *identifier;
@property(strong) NSURL *apiURL;
@property(strong) NSURL *htmlURL;
@property(strong) BHUser *owner;
@property BOOL isPrivate;
@property BHRepoLoadedStatus isLoaded;
@property BOOL hasIssues;
@property(readonly) NSSet *milestones;
@property(readonly) NSSet *labels;
@property(readonly) NSSet *assignees;

@property BHRepoLoadedStatus hasLoadedClosedIssues;
@property BHRepoLoadedStatus hasLoadedOpenIssues;

- (BHPermissionType)permissionsForUser:(BHUser *)aUser;
- (BHPermissionType)permissionsForAuthentictedUser;

// milestones and assignees
- (void)addMilestone:(BHMilestone *)aMilestone;
- (void)addAssignee:(BHUser *)anAssignee;

// labels
- (void)addLabel:(BHLabel *)aLabel;
- (BHLabel *)labelWithName:(NSString *)aName dictionaryValues:(NSDictionary *)aDict;
- (BHMilestone *)milestoneWithName:(NSString *)aName dictionaryValues:(NSDictionary *)aDict;


// issues
- (BHIssue *)issueWithURL:(NSString *)aURL;
- (NSArray *)issues:(NSArray *)previousIssues withFilter:(BHIssueFilter *)aFilter indexesRemoved:(NSMutableIndexSet *)indexesRemoved;
// this returns a set because even if it were an array in order, we can't assume isue #4 is at index 3. (deletions)
- (NSSet *)allIssues;
- (BHIssue *)issueWithNumber:(NSInteger)aNumber;
- (void)loadOpenIssues;
- (void)loadClosedIssues;
- (void)loadNewIssues:(void(^)(BOOL someIssueStateDidChange))aCallback;

- (void)addNewIssue:(BHIssue *)anIssue;

- (void)downloadIssueNumber:(NSInteger)anIssueNumber withCallback:(CallbackBlock)aCallback;


@end






