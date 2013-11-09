//
//  BHIssue.m
//  BugHub
//
//  Created by Randy on 12/26/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import "BHIssue.h"
#import "BHUser.h"
#import "BHMilestone.h"
#import "BHLabel.h"
#import "BHRepository.h"
#import "BHComment.h"

#import "NSNull+Additions.h"
#import "GHUtils.h"
#import "GHAPIRequest.h"
#import "NSColor+hex.h"
#import "NSDate+Strings.h"
#import <math.h>

@interface BHIssue ()
{
    GHAPIRequest *_downloadRequest;
    GHAPIRequest *_commentDownloadRequest;

    GHAPIRequest *_updateIssueRequest;
    BOOL _milestoneIsDirty;
    BOOL _titleIsDirty;
    BOOL _labelsAreDirty;
    BOOL _assigneeIsDirty;
    BOOL _bodyIsDirty;
    BOOL _stateIsDirty;

    NSMutableOrderedSet *_comments;
    dispatch_queue_t _commentParsingQueue;
    NSMutableSet *_activeRequests;
}

@property BOOL shouldDownloadCommentsWhenReady;
@property BOOL shouldReload;

- (void)_downloadCommentsIfNeededAtPage:(NSInteger)aPage;
- (void)_validateUpdateWithKeys:(NSArray *)updatedKeys results:(NSDictionary *)aDict;
@end

@implementation BHIssue

- (id)init
{
    self = [super init];
    
    if (self)
    {
        self.shouldReload = YES;
        self.state = BHUnknownState;
        self.labels = [NSSet set];
        _comments = [NSMutableOrderedSet orderedSetWithCapacity:0];
        _activeRequests = [NSMutableSet setWithCapacity:0];
        _commentParsingQueue = dispatch_queue_create("com.rclconcepts.BugHub.commentParser", NULL);
        
        _milestoneIsDirty = NO;
        _titleIsDirty = NO;
        _bodyIsDirty = NO;
        _assigneeIsDirty = NO;
        _stateIsDirty = NO;
        _labelsAreDirty = NO;
    }
    
    return self;
}

- (BOOL)isEqual:(id)object
{
    return [object isKindOfClass:[self class]] && [object repository] == self.repository && [object number] == self.number;
}

- (NSUInteger)hash
{
    return self.number;
}

- (BHPermissionType)permissionsForAuthentictedUser
{
    BHUser *authenticateduser = [BHUser userWithLogin:[GHAPIRequest authenticatedUserLogin] dictionaryValues:nil];
    
    if (self.creator == authenticateduser)
        return BHPermissionReadWrite;
    
    return [self.repository permissionsForUser:authenticateduser];
}

- (void)setDictValues:(NSDictionary *)aDict
{
    
    // manually do this so we don't mark it as dirty again.
    [self willChangeValueForKey:@"title"];
    _title = [aDict objectForKey:@"title"];
    [self didChangeValueForKey:@"title"];
    
    self.number = [[aDict objectForKey:@"number"] integerValue];
    
    [self willChangeValueForKey:@"rawBody"];
    if ([[aDict objectForKey:@"body"] isKindOfClass:[NSNull class]])
        _rawBody = @"";
    else
        _rawBody = [aDict objectForKey:@"body"];
    [self didChangeValueForKey:@"rawBody"];

    
    if ([[aDict objectForKey:@"body_html"] isKindOfClass:[NSNull class]])
        self.htmlBody = @"";
    else
        self.htmlBody = [aDict objectForKey:@"body_html"];
    
    if (![[aDict objectForKey:@"pull_request"] isKindOfClass:[NSNull class]])
    {
        if (![[[aDict objectForKey:@"pull_request"] objectForKey:@"html_url"] isKindOfClass:[NSNull class]])
            self.pullRequestURL = [NSURL URLWithString:[[aDict objectForKey:@"pull_request"] objectForKey:@"html_url"]];
    }

    self.apiURL = [NSURL URLWithString:[aDict objectForKey:@"url"]];
    self.htmlURL = [NSURL URLWithString:[aDict objectForKey:@"html_url"]];
    self.numberOfComments = [[aDict objectForKey:@"comments"] integerValue];

    self.dateCreated = [GHUtils dateFromGithubString:[aDict objectForKey:@"created_at"]];
    
    NSDictionary *creatorDict = [aDict objectForKey:@"user"];
    self.creator = [BHUser userWithLogin:[creatorDict objectForKey:@"login"] dictionaryValues:creatorDict];


    NSMutableSet *labelSet = [NSMutableSet setWithCapacity:0];
    NSArray *labelDicts = [aDict objectForKey:@"labels"];
    for (NSDictionary *dict in labelDicts)
    {
        BHLabel *aLabel = [self.repository labelWithName:[dict objectForKey:@"name"] dictionaryValues:dict];
        [labelSet addObject:aLabel];
    }
    
    [self willChangeValueForKey:@"labels"];
    _labels = [labelSet copy];
    [self didChangeValueForKey:@"labels"];

    NSDictionary *milestoneDict = [aDict objectForKey:@"milestone"];
    BOOL shouldSetToValue = milestoneDict && ![milestoneDict isKindOfClass:[NSNull class]];
    [self willChangeValueForKey:@"milestone"];
    _milestone = shouldSetToValue ? [self.repository milestoneWithName:[milestoneDict objectForKey:@"title"] dictionaryValues:milestoneDict] : nil;
    [self didChangeValueForKey:@"milestone"];

    NSDictionary *assigneeDict = [aDict objectForKey:@"assignee"];
    BOOL shouldSetAssigneeValue = assigneeDict && ![assigneeDict isKindOfClass:[NSNull class]];
    [self willChangeValueForKey:@"assignee"];
    _assignee = shouldSetAssigneeValue ? [BHUser userWithLogin:[assigneeDict objectForKey:@"login"] dictionaryValues:assigneeDict] : nil;
    [self didChangeValueForKey:@"assignee"];


    [self willChangeValueForKey:@"state"];
    _state = [[aDict objectForKey:@"state"] isEqual:@"open"] ? BHOpenState : BHClosedState;
    [self didChangeValueForKey:@"state"];
    
    if (self.shouldDownloadCommentsWhenReady)
        [self downloadCommentsIfNeeded];
}

- (void)downloadIfNeeded
{
    if (!self.shouldReload && ([self state] != BHUnknownState || _downloadRequest != nil))
        return;

    self.shouldReload = NO;
    
    GHAPIRequest *request = [GHAPIRequest requestForIssueNumber:[self number] repositoryIdentifier:[[self repository] identifier]];

    [request setCompletionBlock:^(GHAPIRequest *aRequest) {

        if (aRequest.status == GHAPIRequestStatusComplete)
        {
            NSInteger statusCode = [aRequest responseStatusCode];
            
            if (statusCode < 200 || statusCode > 299)
            {
                NSLog(@"Error downloading issue: %@", self.apiURL);
                _downloadRequest = nil;
                return;
            }
            
            NSData *responseData = [aRequest responseData];
            NSError *error = nil;
            NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
            
            if (error || ![responseDict isKindOfClass:[NSDictionary class]])
            {
                NSLog(@"Error parsing downloaded issues: %@", error);
                _downloadRequest = nil;
                return;
            }

            [self setDictValues:responseDict];
        }

        _downloadRequest = nil;
    }];
    
    [request sendRequest];
    
    _downloadRequest = request;
}

- (void)downloadCommentsIfNeeded
{
    [self _downloadCommentsIfNeededAtPage:1];
}

- (void)_downloadCommentsIfNeededAtPage:(NSInteger)aPage
{
    if ([self.comments count] >= self.numberOfComments || _commentDownloadRequest != nil)
        return;

    
    BHComment *lastComment = [self.comments lastObject];
    
    if (lastComment)
        _commentDownloadRequest = [GHAPIRequest requestForCommentsFor:[self.repository identifier] issue:self.number sinceDate:[lastComment dateCreated] page:aPage];
    else
        _commentDownloadRequest = [GHAPIRequest requestForCommentsFor:[self.repository identifier] issue:self.number page:aPage];
    
    __weak dispatch_queue_t queue = _commentParsingQueue;
    __weak BHIssue *issueObject = self;
    
    [_commentDownloadRequest setCompletionBlock:^(GHAPIRequest *aRequest){
        if (aRequest.status == GHAPIRequestStatusComplete)
        {
            NSInteger statusCode = [aRequest responseStatusCode];
            
            if (statusCode < 200 || statusCode > 299)
            {
                NSLog(@"Request failed for downloading issue's comments");
                __strong typeof(issueObject) strongSelf = issueObject;
                if (strongSelf)
                    strongSelf->_commentDownloadRequest = nil;
                
                return;
            }

            dispatch_async(queue, ^{
                NSError *error = nil;
                NSArray *newRawComments = [NSJSONSerialization JSONObjectWithData:[aRequest responseData] options:0 error:&error];
                
                if (error || ![newRawComments isKindOfClass:[NSArray class]])
                {
                    NSLog(@"Error parsing new comments: %@", error);
                    
                    __strong typeof(issueObject) strongSelf = issueObject;
                    
                    if (strongSelf)
                        strongSelf->_commentDownloadRequest = nil;
                    
                    return;
                }

                NSMutableArray *newComments = [NSMutableArray arrayWithCapacity:[newRawComments count]];

                for (NSDictionary *commentDict in newRawComments)
                {
                    BHComment *newComment = [[BHComment alloc] init];
                    [newComment setIssue:issueObject];
                    [newComment setDictValues:commentDict];
                    [newComments addObject:newComment];
                }

                dispatch_async(dispatch_get_main_queue(), ^{
                    [issueObject addComments:newComments];
                });
            });
            
            NSInteger nextPage = [aRequest pageOfNextRequestFromResponse];
            if (nextPage != NSNotFound)
            {
                [issueObject _downloadCommentsIfNeededAtPage:nextPage];

                __strong typeof(issueObject) strongIssueObj = issueObject;
                
                if (strongIssueObj)
                    strongIssueObj->_commentDownloadRequest = nil;
                
                return;
            }
            
            __strong typeof(issueObject) strongIssueObj = issueObject;

            if (strongIssueObj)
                strongIssueObj->_commentDownloadRequest = nil;
        }
    }];

    [_commentDownloadRequest sendRequest];
}

// updates the server data if it can.
// this method may return NO if a request is pending
// usually when milestones, or labels need to be created first.
- (BOOL)updateServerData
{
    /*
     {
     "title": "Found a bug",
     "body": "I'm having a problem with this.",
     "assignee": "octocat",
     "milestone": 1,
     "state": "open",
     "labels": [
         "Label1",
         "Label2"
         ]
     }
     */

    if (_updateIssueRequest != nil)
        return NO;

    // FIX ME:
    // The following issues may happen:
    // - Milestone doesn't exist on the server yet.
    // - Label may not exist on the server yet
    
    if (_milestoneIsDirty && [[self milestone] number] == NSNotFound)
        return NO;
    
    if (_labelsAreDirty)
    {
        for (BHLabel *aLabel in [self labels])
        {
            if ([aLabel url] == nil)
                return NO;
        }
    }
    
    NSMutableDictionary *updateDictionary = [NSMutableDictionary dictionaryWithCapacity:1];

    if (_titleIsDirty)
    {
        [updateDictionary setObject:[self title] forKey:@"title"];
        _titleIsDirty = NO;
    }

    if (_bodyIsDirty)
    {
        [updateDictionary setObject:[self rawBody] forKey:@"body"];
        _bodyIsDirty = NO;
    }

    if (_milestoneIsDirty)
    {
        if ([self milestone])
            [updateDictionary setObject:@([[self milestone] number]) forKey:@"milestone"];
        else
            [updateDictionary setObject:[NSNull null] forKey:@"milestone"];
        _milestoneIsDirty = NO;
    }

    if(_assigneeIsDirty)
    {
        if ([self assignee])
            [updateDictionary setObject:[[self assignee] login] forKey:@"assignee"];
        else
            [updateDictionary setObject:[NSNull null] forKey:@"assignee"];

        _assigneeIsDirty = NO;
    }

    if(_stateIsDirty)
    {
        BHIssueState state = [self state];
        if (state != BHUnknownState)
        {
            NSString *stateString = state == BHClosedState ? @"closed" : @"open";

            [updateDictionary setObject:stateString forKey:@"state"];
            _stateIsDirty = NO;
        }
    }

    if(_labelsAreDirty)
    {
        
        NSSet *labels = [self labels];
        NSMutableArray *sendArray = [NSMutableArray arrayWithCapacity:[labels count]];

        for (BHLabel *aLabel in labels)
            [sendArray addObject:[aLabel name]];
        
        [updateDictionary setObject:sendArray forKey:@"labels"];
        _labelsAreDirty = NO;
    }
    
    __weak dispatch_queue_t parseQueue = _commentParsingQueue;    
    id updateRequest = [GHAPIRequest requestForIssueUpdate:self.number repositoryIdentifier:[self.repository identifier] updates:updateDictionary];
    
    if ([updateRequest isKindOfClass:[NSError class]])
    {
        NSLog(@"Error parsing data for issue update: %@", updateRequest);
        return NO;
    }
    
    _updateIssueRequest = updateRequest;

    
    __weak typeof(self) welf = self;
    [_updateIssueRequest setCompletionBlock:^(GHAPIRequest *aRequest){
        
        if ([aRequest status] == GHAPIRequestStatusComplete)
        {
            NSInteger statusCode = [aRequest responseStatusCode];
            if (statusCode < 200 || statusCode > 299)
            {
                NSLog(@"Error back from updating issue");
                __strong typeof(welf) strongSelf = welf;

                if (strongSelf)
                    strongSelf->_updateIssueRequest = nil;

                return;
            }

            NSArray *keysThatGotUpdated = [updateDictionary allKeys];
            dispatch_async(parseQueue, ^{
                NSError *error = nil;
                NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:[aRequest responseData] options:0 error:&error];
                
                if (error || ![responseDict isKindOfClass:[NSDictionary class]])
                {
                    NSLog(@"Unable to parse issue update response: %@", error);
                    __strong typeof(welf) strongSelf = welf;
                    
                    if (strongSelf)
                        strongSelf->_updateIssueRequest = nil;

                    return;
                }

                // woo we got far enough to try to validate this data.
                dispatch_async(dispatch_get_main_queue(), ^{
                    [welf _validateUpdateWithKeys:keysThatGotUpdated results:responseDict];
                });
            });
        }
    }];

    [_updateIssueRequest sendRequest];
    
    return YES;
}

- (void)_validateUpdateWithKeys:(NSArray *)updatedKeys results:(NSDictionary *)aDict
{
    // I dont think further validation is needed.
    // because GitHub has returned a 200 at this point
    // so if there was an error from them, we wouldn't
    // be here at this point. ... could be wrong though. 

    [self setDictValues:aDict];
    _updateIssueRequest = nil;
}


- (void)reloadIssue
{
    self.shouldReload = YES;
    [self setShouldDownloadCommentsWhenReady:YES];
    [self downloadIfNeeded];
}

- (BHComment *)commentWithIdentifier:(NSInteger)aNumber
{
    for (BHComment *aComment in _comments)
    {
        if (aComment.number == aNumber)
            return aComment;
    }
    
    return nil;
}

- (void)addComments:(NSArray *)newComments
{
    [self willChangeValueForKey:@"comments"];
    //@synchronized(self)
    {
        for (BHComment *newComment in newComments)
            [_comments addObject:newComment];
    }
    [self didChangeValueForKey:@"comments"];
}

- (NSOrderedSet *)comments
{
    return [_comments copy];
}

- (void)newCommentWithBody:(NSString *)aString user:(BHUser *)aUser
{
    BHComment *newComment = [[BHComment alloc] init];
    [newComment setUser:aUser];
    [newComment setRawBody:[aString copy]];
    [newComment setIssue:self];

    [self addComments:@[newComment]];
    [newComment updateServerData];
}

- (void)deleteComment:(BHComment *)aComment
{
    [self willChangeValueForKey:@"comments"];
    [_comments removeObject:aComment];
    [self didChangeValueForKey:@"comments"];


    GHAPIRequest *request = [GHAPIRequest requestForCommentDeletion:[[aComment url] absoluteString]];
    [_activeRequests addObject:request];
    
    [request setCompletionBlock:^(GHAPIRequest *aRequest){
        
        //if ([aRequest status] != GHAPIRequestStatusComplete)
        //    [self addComments:@[aComment]];

        [_activeRequests removeObject:aComment];
    }];

    [request sendRequest];
}



#pragma mark manually updating stufffffff

- (void)setTitle:(NSString *)title
{
    if ([_title isEqualToString:title])
        return;
    
    _title = [title copy];
    _titleIsDirty = YES;
}

- (void)setRawBody:(NSString *)rawBody
{
    if ([_rawBody isEqualToString:rawBody])
        return;
    
    _rawBody = [rawBody copy];
    _bodyIsDirty = YES;
}

- (void)setState:(BHIssueState)state
{
    if (_state == state)
        return;
    
    _state = state;
    _stateIsDirty = YES;
}

- (void)setAssignee:(BHUser *)assignee
{
    if (assignee == _assignee)
        return;
    
    _assignee = assignee;
    _assigneeIsDirty = YES;
}

- (void)setMilestone:(BHMilestone *)milestone
{
    if (_milestone == milestone)
        return;
    
    _milestone = milestone;
    _milestoneIsDirty = YES;
}

- (void)addLabel:(BHLabel *)aLabel
{
    // From a data standpoint, this check isn't needed
    // but we need to mark it as dirty if the set changes
    // which we can't easily do after the fact.
    if ([self.labels member:aLabel])
        return;
    
    [self willChangeValueForKey:@"labels"];

    NSMutableSet *set = [NSMutableSet setWithSet:self.labels];
    [set addObject:aLabel];

    self.labels = [set copy];
    _labelsAreDirty = YES;

    [self didChangeValueForKey:@"labels"];
}

- (void)removeLabel:(BHLabel *)aLabel
{
    if (![self.labels member:aLabel])
        return;
    
    [self willChangeValueForKey:@"labels"];

    NSMutableSet *set = [NSMutableSet setWithSet:self.labels];
    [set removeObject:aLabel];

    self.labels = [set copy];
        _labelsAreDirty = YES;

    [self didChangeValueForKey:@"labels"];
}

- (NSString *)webViewJSON
{
    NSMutableArray *JSONLabels = [NSMutableArray arrayWithCapacity:self.labels.count];
    NSSet *labels = self.labels;
    
    for (BHLabel *aLabel in labels)
    {
        [JSONLabels addObject:@{
            @"name": aLabel.name,
            @"color": [aLabel.color hexColor]
         }];
    }
    
    NSMutableArray *JSONComments = [NSMutableArray arrayWithCapacity:[self.comments count]];
    NSArray *currentComments = [self.comments copy];
    for (BHComment *aComment in currentComments)
    {
        [JSONComments addObject:[aComment webViewJSONDict]];
    }
    
    
    NSDictionary *jsonDict = @{
                                @"author" : [self.creator webViewJSONDict],
                                @"dateCreated": [self.dateCreated normalDateString],
                                @"title": self.title,
                                @"body": [self.htmlBody stringByReplacingOccurrencesOfString:@"target=\"_blank\"" withString:@""],
                                @"milestone": self.milestone ? [self.milestone webViewJSONDict] : [NSNull null],
                                @"assignee":  self.assignee ? [self.assignee webViewJSONDict] : [NSNull null],
                                @"pullRequestURL": self.pullRequestURL ? [self.pullRequestURL absoluteString] : [NSNull null],
                                @"labels": JSONLabels,
                                @"comments": JSONComments,
                                @"commentsAreLoaded": @([self.comments count] <= self.numberOfComments)
                            };
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:&error];

    if (error)
        NSLog(@"Error parsing JSON: %@", error);

    NSString *output = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    //NSLog(@"%@", output);
    return output;
}



@end
