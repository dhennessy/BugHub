//
//  BHIssue.h
//  BugHub
//
//  Created by Randy on 12/26/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BHQueueUpdateRequest.h"
#import "BHRepository.h"

@class BHUser, BHMilestone, BHLabel, BHRepository, BHComment;

typedef enum {
    BHOpenState,
    BHClosedState,
    BHUnknownState
} BHIssueState;

@interface BHIssue : NSObject<BHQueueUpdateRequest>

@property(nonatomic) BHIssueState state;
@property(strong, nonatomic) NSString *title;
@property(strong) BHUser *creator;
@property(strong) NSDate *dateCreated;
@property(strong) NSDate *lastUpdated;

// for editing
@property(strong, nonatomic) NSString *rawBody;
// for searching
//@property(strong) NSString *textBody;
// for displaying
@property(strong) NSString *htmlBody;

@property(strong) NSURL *apiURL;
@property(strong) NSURL *htmlURL;

@property(strong, nonatomic) BHUser *assignee;
@property(strong, nonatomic) BHMilestone *milestone;
@property(strong) NSSet *labels;
@property NSInteger number;
@property NSInteger numberOfComments;
@property(strong, readonly) NSOrderedSet *comments;

@property(strong) BHRepository *repository;
@property(strong) NSURL *pullRequestURL;


- (BHPermissionType)permissionsForAuthentictedUser;

- (void)setDictValues:(NSDictionary *)aDict;
- (void)downloadIfNeeded;
- (void)downloadCommentsIfNeeded;
- (void)reloadIssue;

- (void)addLabel:(BHLabel *)aLabel;
- (void)removeLabel:(BHLabel *)aLabel;

- (void)addComments:(NSArray *)newComments;
- (void)newCommentWithBody:(NSString *)aString user:(BHUser *)aUser;
- (void)deleteComment:(BHComment *)aComment;
- (BHComment *)commentWithIdentifier:(NSInteger)aNumber;

- (NSString *)webViewJSON;

@end
