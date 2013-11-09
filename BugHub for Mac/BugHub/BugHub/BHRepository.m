//
//  BHRepository.m
//  BugHub
//
//  Created by Randy on 12/26/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import "BHRepository.h"
#import "BHIssue.h"
#import "BHIssueFilter.h"
#import "BHUser.h"
#import "GHAPIRequest.h"
#import "BHLabel.h"
#import "BHMilestone.h"
#import "BHEvent.h"
#import "GHUtils.h"

#import "NSColor+hex.h"
#import "NSNull+Additions.h"
#import "NSURL+GHExtentions.h"

#import <math.h>

static NSMutableDictionary *AllRepositories = nil;
static NSObject<OS_dispatch_queue> *RepositoryParseQueue = nil;

@interface BHRepository ()
{
    
    GHAPIRequest *_newIssuesRequest;
    GHAPIRequest *_newClosedIssuesRequest;

    GHAPIRequest *_downloadRequest;
    GHAPIRequest *_labelsRequest;
    GHAPIRequest *_milestonesRequest;
    GHAPIRequest *_assigneesRequest;

    NSMutableSet *_allIssues;
    NSMutableSet *_milestones;
    NSMutableSet *_labels;
    NSMutableSet *_assignees;
    
    // only used when the issues haven't been downloaded.
    BOOL _shouldDownloadOpenIssues;
    BOOL _shouldDownloadClosedIssues;
    NSInteger _openIssueCount;
    NSInteger _closedIssueCount;
    
    NSMutableSet *_activeRequests;
}

@property(strong) NSDate *dateOfLastUpdate;

//@property(setter=_setHasLoadedOpenIssues:) BOOL _hasLoadedOpenIssues;
//@property(setter=_setHasLoadedClosedIssues:) BOOL _hasLoadedClosedIssues;
@property(setter=_setHasLoadedAssignees:) BOOL _hasLoadedAssignees;
@property(setter=_setHasLoadedMilestones:) BOOL _hasLoadedMilestones;
@property(setter=_setHasLoadedLabels:) BOOL _hasLoadedLabels;

- (void)_parseRawIssues:(NSData *)newIssues;
- (void)_addIssues:(NSArray *)newIssues;

- (void)_loadLabels;
- (void)_loadMilestones;
- (void)_loadAssignees;
- (void)_loadClosedIssuesForPages:(NSInteger)numberOfPages;

- (void)_setDictValues:(NSDictionary *)dictValues;
- (void)setIdentifier:(NSString *)anIdentifier;

- (void)_didFinishLoadingUpdateRequest:(GHAPIRequest *)aRequest withChanges:(BOOL)aFlag callback:(void(^)(BOOL hadChanges))aCallback;

@end

@implementation BHRepository

+ (void)initialize
{
    RepositoryParseQueue = dispatch_queue_create("com.rclconcepts.repoParseQueue", NULL);
}

+ (id)repositoryWithIdentifier:(NSString *)anIdentifier dictionaryValues:(NSDictionary *)dictValues
{
    // NORMALIZEEEEEEEEEEEEEE
    anIdentifier = [anIdentifier lowercaseString];
    
    if (!AllRepositories)
        AllRepositories = [NSMutableDictionary dictionaryWithCapacity:3];
    
    BHRepository *repo = [AllRepositories objectForKey:anIdentifier];

    BOOL validID = [self isValidIdentifier:anIdentifier];
    
    if (!repo && validID)
    {
        repo = [[self alloc] init];
        [repo setIdentifier:anIdentifier];

        [AllRepositories setObject:repo forKey:anIdentifier];

        if (dictValues)
            [repo _setDictValues:dictValues];
        else
        {
            [repo loadRepo];
        }
    }
    else if (repo && [repo isLoaded] != BHRepoLoaded && dictValues)
        [repo _setDictValues:dictValues];

    return repo;
}

+ (BOOL)isValidIdentifier:(NSString *)anId
{
    NSArray *components = [anId componentsSeparatedByString:@"/"];
    return [components count] == 2 && ![[components objectAtIndex:0] isEqualToString:@""] && ![[components objectAtIndex:1] isEqualToString:@""];
}

+ (NSSet *)keyPathsForValuesAffectingIdentifier
{
    return [NSSet setWithObjects:@"owner", @"owner.identifier", @"name", nil];
}

- (id)init
{
    self = [super init];

    if (self)
    {
        _closedIssueCount = -1;
        _openIssueCount = -1;

        _activeRequests = [NSMutableSet setWithCapacity:0];
        _allIssues = [NSMutableSet setWithCapacity:0];
        _milestones = [NSMutableSet setWithCapacity:0];
        _assignees = [NSMutableSet setWithCapacity:0];
        _labels = [NSMutableSet setWithCapacity:0];
    }

    return self;
}

- (NSString *)identifier
{
    if (!self.owner || !self.name)
        return @"";

    return [NSString stringWithFormat:@"%@/%@", [self.owner login], self.name];
}

- (void)setIdentifier:(NSString *)anIdentifier
{
    [self willChangeValueForKey:@"identifier"];
    NSArray *components = [anIdentifier componentsSeparatedByString:@"/"];
    if (components.count != 2)
        return;

    self.owner = [BHUser userWithLogin:[components objectAtIndex:0] dictionaryValues:nil];
    self.name = [components objectAtIndex:1];
    [self didChangeValueForKey:@"identifier"];
}


- (void)_setDictValues:(NSDictionary *)dictValues
{
    if (_downloadRequest)
    {
        [_downloadRequest stopRequest];
        _downloadRequest = nil;
    }
    
    self.name = [dictValues objectForKey:@"name"];
    
    NSDictionary *owner = [dictValues objectForKey:@"owner"];
    self.owner = [BHUser userWithLogin:[owner objectForKey:@"login"] dictionaryValues:owner];
    self.hasIssues = [[dictValues objectForKey:@"has_issues"] boolValue];
    self.isPrivate = [[dictValues objectForKey:@"private"] boolValue];

    self.htmlURL = [NSURL URLWithString:[dictValues objectForKey:@"html_url"]];
    self.apiURL = [NSURL URLWithString:[dictValues objectForKey:@"url"]];
    
    _openIssueCount = [[dictValues objectForKey:@"open_issues"] integerValue];

    // the the repo doesn't have issues, just give up.
    if (!self.hasIssues)
        return;
    
    [self _loadAssignees];
    [self _loadMilestones];
    [self _loadLabels];

    self.isLoaded = BHRepoLoaded;
    
    if (_shouldDownloadClosedIssues)
        [self loadClosedIssues];
    
    if (_shouldDownloadOpenIssues)
        [self loadOpenIssues];
}

- (BHPermissionType)permissionsForAuthentictedUser
{
    BHUser *authenticatedUser = [BHUser userWithLogin:[GHAPIRequest authenticatedUserLogin] dictionaryValues:nil];
    return [self permissionsForUser:authenticatedUser];
}

- (BHPermissionType)permissionsForUser:(BHUser *)aUser
{
    if (!aUser)
        return BHPermissionNone;

    if ([self.assignees containsObject:aUser])
        return BHPermissionReadWrite;

    return BHPermissionReadOnly;
}

- (NSSet *)labels
{
    //@synchronized(self)
    {
        if (![self _hasLoadedLabels])
            [self _loadLabels];

        return [_labels copy];
    }
}

- (NSSet *)milestones
{
    //@synchronized(self)
    {
        if (![self _hasLoadedMilestones])
            [self _loadMilestones];

        return [_milestones copy];
    }
}

- (NSSet *)assignees
{
    //@synchronized(self)
    {
        if (![self _hasLoadedAssignees])
            [self _loadAssignees];

         return [_assignees copy];
    }
}


- (void)addLabel:(BHLabel *)aLabel
{
    //@synchronized(self)
    {
        [self willChangeValueForKey:@"labels"];
        [_labels addObject:aLabel];
        [self didChangeValueForKey:@"labels"];
    }
}

- (void)addMilestone:(BHMilestone *)aMilestone
{
    //@synchronized(self)
    {
        [self willChangeValueForKey:@"milestones"];
        [_milestones addObject:aMilestone];
        [self didChangeValueForKey:@"milestones"];
    }
}

- (void)addAssignee:(BHUser *)anAssignee
{
    //@synchronized(self)
    {
        [self willChangeValueForKey:@"assignees"];
        [_assignees addObject:anAssignee];
        [self didChangeValueForKey:@"assignees"];
    }
}

- (BHLabel *)labelWithName:(NSString *)aName  dictionaryValues:(NSDictionary *)aDict;
{
    //@synchronized(self)
    {
        for (BHLabel *label in _labels)
            if ([[label.name lowercaseString] isEqualToString:[aName lowercaseString]])
                return label;
        
        if (aDict)
        {
            BHLabel *newLabel = [[BHLabel alloc] init];
            //newLabel.name = [aDict objectForKey:@"name"];
            //newLabel.color = [NSColor colorWithHexColorString:[aDict objectForKey:@"color"]];
            [newLabel setDictionaryValues:aDict];
            
            [self addLabel:newLabel];
            
            return newLabel;
        }

        return nil;
    }
}

- (BHMilestone *)milestoneWithName:(NSString *)aName dictionaryValues:(NSDictionary *)aDict;
{
    //@synchronized(self)
    {
        for (BHMilestone *aMilestone in _milestones)
            if ([[aMilestone.name lowercaseString] isEqualToString:[aName lowercaseString]])
                return aMilestone;

        if (aDict)
        {
            BHMilestone *newMilestone = [[BHMilestone alloc] init];
            [newMilestone setDictionaryValues:aDict];

            [self addMilestone:newMilestone];
            
            return newMilestone;
        }

        return nil;
    }
}




- (BHIssue *)issueWithURL:(NSString *)aURL
{
    NSURL *urlObj = [NSURL URLWithString:aURL];
    NSString *issueRepoID = [urlObj repositoryIdentifier];
    
    if(![issueRepoID isEqualToString:self.identifier])
    {
        NSLog(@"Attempting to download issue on the wrong repo");
        return nil;
    }

    NSInteger issueNumber = [urlObj issueNumber];
    
    if (issueNumber == NSNotFound)
    {
        NSLog(@"Attempting to download issue with invalid issue number in URL");
        return nil;
    }

    BHIssueFilter *filter = [[BHIssueFilter alloc] init];
    [filter setIndexes:[NSIndexSet indexSetWithIndex:issueNumber]];
    NSArray *issues = [self issues:nil withFilter:filter indexesRemoved:nil];
    
    if ([issues count] > 0)
        return [issues objectAtIndex:0];

    BHIssue *newIssue = [[BHIssue alloc] init];
    [newIssue setRepository:self];
    [newIssue setNumber:issueNumber];

    return newIssue;
}

- (BHIssue *)issueWithNumber:(NSInteger)aNumber
{
    for(BHIssue *anIssue in _allIssues)
    {
        if (anIssue.number == aNumber)
            return anIssue;
    }

    return nil;
}

- (NSSet *)allIssues
{
    return [_allIssues copy];
}

- (NSArray *)issues:(NSArray *)previousIssues withFilter:(BHIssueFilter *)aFilter indexesRemoved:(NSMutableIndexSet *)indexesRemoved
{
    //@synchronized(self)
    {
        id issuesToFilter = previousIssues == nil ? _allIssues : previousIssues;

        NSMutableArray *filteredIssues = [NSMutableArray arrayWithCapacity:[issuesToFilter count]];

        // FIX ME: this can possibly be done concurrently.
        // may not make a difference http://darkdust.net/writings/objective-c/nsarray-enumeration-performance#concurrent
        for (BHIssue *anIssue in issuesToFilter)
        {
            if (!aFilter || [aFilter issueMatchesFilter:anIssue])
                [filteredIssues addObject:anIssue];
            else if (previousIssues != nil)
                [indexesRemoved addIndex:[issuesToFilter indexOfObject:anIssue]];
        }

        // sort, newest first
        [filteredIssues sortUsingComparator:^NSComparisonResult(BHIssue *issue1, BHIssue *issue2) {
            NSInteger comp = [issue1 number] - [issue2 number];

            if (comp < 0)
                return NSOrderedDescending;
            else if (comp > 0)
                return NSOrderedAscending;
            else
                return NSOrderedSame;
        }];
        
        return [filteredIssues copy];
    }
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"Repository:{Identifier: %@, isPrivate: %@, milestones: %@, labels:%@, assignees:%@}", self.identifier, [NSNumber numberWithBool:self.isPrivate], self.milestones, self.labels, self.assignees];
}



#pragma mark loading

// FUCK this sucks.
- (void)_didFinishLoadingUpdateRequest:(GHAPIRequest *)aRequest withChanges:(BOOL)aFlag callback:(void(^)(BOOL hadChanges))aCallback
{
    if (aRequest == _newIssuesRequest)
        _newIssuesRequest = nil;

    if (aRequest == _newClosedIssuesRequest)
        _newClosedIssuesRequest = nil;

    if (_newIssuesRequest == nil && _newClosedIssuesRequest == nil)
        aCallback(aFlag);
}
                                                                                                  

// JESUS FUCKING CHRIST THIS SUCKS!
// some documentation on what the fuck is going on here.
// basically we send of two requests for new issues and new closed issues
// these request only return something if modified since the last modified date.
// When the requests finish each call _didFinishLoadingUpdateRequest:withCahnges:callback:
// this method will update all issues already loaded, and discard issues that are NOT loaded
- (void)loadNewIssues:(void(^)(BOOL someIssueStateDidChange))aCallback
{
    // load events since date...
    _newIssuesRequest = [GHAPIRequest requestForReposOpenIssueUpdates:self.identifier afterDate:self.dateOfLastUpdate];
    _newClosedIssuesRequest = [GHAPIRequest requestForReposClosedIssueUpdates:self.identifier afterDate:self.dateOfLastUpdate];

    __block BOOL somethingWasModified = NO;
    
    GHAPIRequestCompletionBlock requestCompletionBlock = ^(GHAPIRequest *aRequest) {
        NSInteger statusCode = [aRequest responseStatusCode];
        NSData *responseData = [aRequest responseData];
        NSError *error = nil;
        NSArray *responseArray = nil;

        if (responseData)
            responseArray = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
        
        if (statusCode < 200 || statusCode > 299 || error != nil || ![responseArray isKindOfClass:[NSArray class]])
        {
            // error of some sort... also might be because no updates
            if (statusCode != 304) // 304: Not Modified
                NSLog(@"Some kinda error in loadNewIssues");

            // fire some completeion block thing to make the damn table view stop spinning
            [self _didFinishLoadingUpdateRequest:aRequest withChanges:NO callback:aCallback];
            return;
        }
        
        for (NSDictionary *aDict in responseArray)
        {
            // find the current issue with this number...
            id number = [aDict objectForKey:@"number"];
            if ([number isKindOfClass:[NSNull class]])
                continue;
            
            NSInteger issueNumber = [number integerValue];
            BHIssue *anIssue = [self issueWithNumber:issueNumber];

            if (!anIssue)
            {
                // create a new issue!
                anIssue = [[BHIssue alloc] init];
                [anIssue setRepository:self];
                [anIssue setDictValues:aDict];
                [self addNewIssue:anIssue];
            }
            else // update the existing issue
                [anIssue setDictValues:aDict];

            somethingWasModified = YES;
        }
        
        [self _didFinishLoadingUpdateRequest:aRequest withChanges:somethingWasModified callback:aCallback];
    };

    [_newIssuesRequest setCompletionBlock:requestCompletionBlock];
    [_newIssuesRequest sendRequest];

    [_newClosedIssuesRequest setCompletionBlock:requestCompletionBlock];
    [_newClosedIssuesRequest sendRequest];
}

- (void)loadOpenIssues
{
    if (self.isLoaded != BHRepoLoaded)
    {
        _shouldDownloadOpenIssues = YES;
        return;
    }
    
    if ([self hasLoadedOpenIssues] == BHRepoLoaded || [self hasLoadedOpenIssues] == BHRepoLoading)
        return;

    [self setHasLoadedOpenIssues:BHRepoLoading];
    
    NSInteger totalRequests = ceil(((double)_openIssueCount / 100.0));
    
    if (totalRequests == 0)
    {
        [self setHasLoadedOpenIssues:BHRepoLoaded];
        [self willChangeValueForKey:@"issues"];
        [self didChangeValueForKey:@"issues"];
    }
    
    // Load them backwards because the newest issues are shown first...
    for (NSInteger i = totalRequests; i > 0 ; i--)
    {
        __weak typeof(self) repoObject = self;
        GHAPIRequest *request = [GHAPIRequest requestForReposOpenIssues:self.identifier page:i];
        [_activeRequests addObject:request];

        [request setCompletionBlock:^(GHAPIRequest *aRequest){
            [repoObject setHasLoadedOpenIssues:BHRepoLoaded];
            if (aRequest.status == GHAPIRequestStatusComplete)
            {
                NSInteger statusCode = [aRequest responseStatusCode];
                
                if (statusCode < 200 || statusCode > 299)
                {
                    NSLog(@"Error downloading open issues for '%@' page %ld", [repoObject identifier], i);
                    return;
                }

                [self _parseRawIssues:[aRequest responseData]];
            }

            __strong typeof(repoObject) strongSelf = repoObject;
            if (strongSelf)
                [strongSelf->_activeRequests removeObject:aRequest];
        }];
        
        [request sendRequest];
    }
}

- (void)loadClosedIssues
{
    if (self.isLoaded != BHRepoLoaded)
    {
        _shouldDownloadClosedIssues = YES;
        return;
    }

    if ([self hasLoadedClosedIssues] == BHRepoLoaded || [self hasLoadedClosedIssues] == BHRepoLoading)
        return;

    [self setHasLoadedClosedIssues:BHRepoLoading];

    if (_closedIssueCount == -1)
    {
        GHAPIRequest *request = [GHAPIRequest requestForReposClosedIssues:self.identifier page:1];
        
        [_activeRequests addObject:request];
        
        __weak id repoObject = self;

        [request setCompletionBlock:^(GHAPIRequest *aRequest) {
            [repoObject setHasLoadedClosedIssues:BHRepoLoaded];
            if (aRequest.status == GHAPIRequestStatusComplete)
            {
                NSInteger statusCode = [aRequest responseStatusCode];
                
                if (statusCode < 200 || statusCode > 299)
                {
                    NSLog(@"Error downloading open issues for '%@' page %d", [repoObject identifier], 1);
                    return;
                }
                [self _parseRawIssues:[aRequest responseData]];
                
                
                NSInteger lastPage = [aRequest pageOfLastRequestFromResponse];
                [self _loadClosedIssuesForPages:lastPage];
            }
            
            // WARNING: CYCLE!!
            [_activeRequests removeObject:aRequest];
        }];
        
        [request sendRequest];
    }
}

// this method starts at Page 2 and goes until page n.
- (void)_loadClosedIssuesForPages:(NSInteger)numberOfPages
{
    for (NSInteger i = 2; i <= numberOfPages; i++)
    {
        __weak id repoObject = self;
        GHAPIRequest *request = [GHAPIRequest requestForReposClosedIssues:self.identifier page:i];
        [_activeRequests addObject:request];
        
        [request setCompletionBlock:^(GHAPIRequest *aRequest){
            if (aRequest.status == GHAPIRequestStatusComplete)
            {
                NSInteger statusCode = [aRequest responseStatusCode];
                
                if (statusCode < 200 || statusCode > 299)
                {
                    NSLog(@"Error downloading open issues for '%@' page %ld", [repoObject identifier], i);
                    return;
                }
                
                [self _parseRawIssues:[aRequest responseData]];
            }
            
            // WARNING: CYCLE!!
            [_activeRequests removeObject:aRequest];
        }];
        
        [request sendRequest];
    }
}

- (void)_parseRawIssues:(NSData *)responseData
{
    dispatch_async(RepositoryParseQueue, ^{
        NSError *error = nil;
        NSArray *newIssuesRaw = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
        
        if (error || ![newIssuesRaw isKindOfClass:[NSArray class]])
        {
            NSLog(@"Error parsing new issues for '%@': %@", [self identifier], error);
            return;
        }
        
        NSMutableArray *newIssues = [NSMutableArray arrayWithCapacity:[newIssuesRaw count]];
        
        for(NSDictionary *dict in newIssuesRaw)
        {
            BHIssue *newIssue = [[BHIssue alloc] init];
            [newIssue setRepository:self];
            [newIssue setDictValues:dict];
            [newIssues addObject:newIssue];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _addIssues:newIssues];
        });
    });
}


- (void)_addIssues:(NSArray *)anArray
{
    //@synchronized(self)
    {
        [self willChangeValueForKey:@"issues"];
        [_allIssues addObjectsFromArray:anArray];
        [self didChangeValueForKey:@"issues"];
    }
}

- (void)addNewIssue:(BHIssue *)anIssue
{
    [self _addIssues:@[anIssue]];
}

- (void)downloadIssueNumber:(NSInteger)anIssueNumber withCallback:(CallbackBlock)aCallback
{
    GHAPIRequest *issueRequest = [GHAPIRequest requestForIssueNumber:anIssueNumber repositoryIdentifier:self.identifier];
    
    __weak typeof(self) welf = self;
    
    [issueRequest setCompletionBlock:^(GHAPIRequest *aRequest){
        __strong typeof(welf) strongSelf = welf;

        NSInteger statusCode = [aRequest responseStatusCode];
        NSError *error = nil;
        NSData *responseData = [aRequest responseData];
        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
        
        if (statusCode < 200 || statusCode > 299 || error || ![responseDict isKindOfClass:[NSDictionary class]])
        {
            NSLog(@"error downloading specific issue... %ld for %@", anIssueNumber, [strongSelf identifier]);
            return;
        }

        BHIssue *newIssue = [[BHIssue alloc] init];
        [newIssue setRepository:strongSelf];
        [newIssue setDictValues:responseDict];
        [strongSelf addNewIssue:newIssue];

        aCallback(newIssue);
    }];
    
    [_activeRequests addObject:issueRequest];
    [issueRequest sendRequest];
}

- (void)loadRepo
{
    if (_downloadRequest)
    {
        if ([_downloadRequest status] == GHAPIRequestStatusLoading)
            return;

        [_downloadRequest stopRequest];
    }
    
    _downloadRequest = [GHAPIRequest requestForRepositoryWithID:self.identifier];
    
    __weak typeof(self) repoObject = self;

    [_downloadRequest setCompletionBlock:^(GHAPIRequest *aRequest) {
        
        if (aRequest.status == GHAPIRequestStatusComplete)
        {
            NSInteger statusCode = [aRequest responseStatusCode];
            
            if (statusCode > 299 || statusCode < 200)
            {
                NSLog(@"Request failed for repo '%@' with status code: %ld", [repoObject identifier], statusCode);
                NSLog(@"%@", [aRequest responseHeaders]);
                [repoObject setIsLoaded:BHRepoError];
                return;
            }
            [repoObject setDateOfLastUpdate:[NSDate date]];
            NSData *responseData = [aRequest responseData];
            
            dispatch_async(RepositoryParseQueue, ^{
                
                NSError *error = nil;
                id responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
                
                if (error || ![responseDict isKindOfClass:[NSDictionary class]])
                {
                    NSLog(@"Error parsing repos '%@' data.", [repoObject identifier]);
                    return;
                }
                // set values on the main thread.
                dispatch_async(dispatch_get_main_queue(), ^{
                    [repoObject _setDictValues:responseDict];
                });
            });
            
        }
    }];
    
    [_downloadRequest sendRequest];
}

- (void)_loadLabels
{
    if (_labelsRequest)
    {
        if ([_labelsRequest status] == GHAPIRequestStatusLoading)
            return;

        [_labelsRequest stopRequest];
    }
    
    
    _labelsRequest = [GHAPIRequest requestForRepositorysLabels:self.identifier];
    __weak id repoObject = self;

    [_labelsRequest setCompletionBlock:^(GHAPIRequest *aRequest){
        if ([aRequest status] == GHAPIRequestStatusComplete)
        {
            NSInteger statusCode = [aRequest responseStatusCode];

            if (statusCode < 200 || statusCode > 299)
            {
                NSLog(@"Request failed for repo '%@' labels with status code: %ld", [repoObject identifier], statusCode);
                return;
            }

            NSData *responseData = [aRequest responseData];

            dispatch_async(RepositoryParseQueue, ^{
                NSError *error = nil;
                id responseArray = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];

                if (error || ![responseArray isKindOfClass:[NSArray class]])
                {
                    NSLog(@"Error parsing repo '%@' labels data.", [repoObject identifier]);
                    return;
                }

                // set values on the main thread.
                dispatch_async(dispatch_get_main_queue(), ^{
                    for (NSDictionary *aLabelDict in responseArray)
                    {
                        NSString *labelName = [aLabelDict objectForKey:@"name"];
                        [repoObject labelWithName:labelName dictionaryValues:aLabelDict];
                    }
                    
                    [repoObject _setHasLoadedLabels:YES];
                });
            });
        }
    }];
    
    [_labelsRequest sendRequest];
}

- (void)_loadMilestones
{
    if (_milestonesRequest)
    {
        if ([_milestonesRequest status] == GHAPIRequestStatusLoading)
            return;
        
        [_milestonesRequest stopRequest];
    }
    
    
    _milestonesRequest = [GHAPIRequest requestForRepositorysMilestones:self.identifier];
    __weak id repoObject = self;
    
    [_milestonesRequest setCompletionBlock:^(GHAPIRequest *aRequest){
        if ([aRequest status] == GHAPIRequestStatusComplete)
        {
            NSInteger statusCode = [aRequest responseStatusCode];
            
            if (statusCode < 200 || statusCode > 299)
            {
                NSLog(@"Request failed for repo '%@' milestones with status code: %ld", [repoObject identifier], statusCode);
                return;
            }
            
            NSData *responseData = [aRequest responseData];
            
            dispatch_async(RepositoryParseQueue, ^{
                NSError *error = nil;
                id responseArray = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
                
                if (error || ![responseArray isKindOfClass:[NSArray class]])
                {
                    NSLog(@"Error parsing repo '%@' milestones data.", [repoObject identifier]);
                    return;
                }
                
                // set values on the main thread.
                dispatch_async(dispatch_get_main_queue(), ^{
                    for (NSDictionary *aMilestoneDict in responseArray)
                    {
                        NSString *milestoneName = [aMilestoneDict objectForKey:@"title"];
                        [repoObject milestoneWithName:milestoneName dictionaryValues:aMilestoneDict];
                    }

                    [repoObject _setHasLoadedMilestones:YES];
                });
            });
        }
    }];
    
    [_milestonesRequest sendRequest];
}

- (void)_loadAssignees
{
    if (_assigneesRequest)
    {
        if ([_assigneesRequest status] == GHAPIRequestStatusLoading)
            return;
        
        [_assigneesRequest stopRequest];
    }
    
    
    _assigneesRequest = [GHAPIRequest requestForRepositorysAssignees:self.identifier];
    __weak typeof(self) repoObject = self;
    
    [_assigneesRequest setCompletionBlock:^(GHAPIRequest *aRequest){
        if ([aRequest status] == GHAPIRequestStatusComplete)
        {
            NSInteger statusCode = [aRequest responseStatusCode];
            
            if (statusCode < 200 || statusCode > 299)
            {
                NSLog(@"Request failed for repo '%@' assignees with status code: %ld", repoObject.identifier, statusCode);
                return;
            }

            NSData *responseData = [aRequest responseData];

            dispatch_async(RepositoryParseQueue, ^{
                NSError *error = nil;
                id responseArray = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
                
                if (error || ![responseArray isKindOfClass:[NSArray class]])
                {
                    NSLog(@"Error parsing repo '%@' assignee data.", [repoObject identifier]);
                    return;
                }

                // set values on the main thread.
                dispatch_async(dispatch_get_main_queue(), ^{
                    for (NSDictionary *aUserDict in responseArray)
                    {
                        NSString *userName = [aUserDict objectForKey:@"login"];
                        BHUser *newAssignee = [BHUser userWithLogin:userName dictionaryValues:aUserDict];
                        [repoObject addAssignee:newAssignee];
                    }
                    
                    [repoObject _setHasLoadedAssignees:YES];
                });
            });
        }
    }];
    
    [_assigneesRequest sendRequest];
}

@end

