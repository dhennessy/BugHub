//
//  GHAPIRequest.m
//  BugHub
//
//  Created by Randy on 12/25/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import "GHAPIRequest.h"
#import "AppDelegate.h"
#import "GHUtils.h"
#import "Base64.h"
#import "NSColor+hex.h"
#import "STKeychain.h"

static NSString *GHAPIRequestAuthenticatedUserLogin = nil;
static NSString *GBAPIRequestAuthenticationHeader = nil;
static NSString *GHAPIRequestPrefix = @"https://api.github.com";
static NSString * const GHAPIServerEnterpriseAPIEndpointPathComponent = @"api/v3";
static BOOL GHAPIUsesOAuth = NO;

static NSString *const BHServiceName = @"com.peerassembly.BugHub";
static NSString *const BHUserDefaultsKey = @"BHUserDefaultsKey";
NSString *BHLoginChangedNotification = @"BHLoginChangedNotification";
NSString *BHHitRateLimitNotification = @"BHHitRateLimitNotification";

GHAPIRequest *__defaultRequestForLogin;

#define AddAuthHeader(aRequest) if (GBAPIRequestAuthenticationHeader){[aRequest addHeader:GBAPIRequestAuthenticationHeader forKey:@"Authorization"];}
#define HTML_AND_TEXT_ACCEPT_HEADER @"application/vnd.github-issue.raw+json,application/vnd.github-issue.html+json"


@interface GHAPIRequest ()
{
    NSMutableData *_data;
    NSURLRequest *_request;
    NSURL *_url;
    NSURLConnection *_connection;
    NSMutableDictionary *_requestHeaders;
    //NSMutableArray *_subRequests;
}
@end

@implementation GHAPIRequest

+ (void)setAPIPrefix:(NSString *)apiPrefix {
    if (apiPrefix) {
        GHAPIRequestPrefix = [apiPrefix stringByAppendingPathComponent:GHAPIServerEnterpriseAPIEndpointPathComponent];
    } else {
        GHAPIRequestPrefix = @"https://api.github.com";
    }
}

+ (void)setUsesOAuth:(BOOL)usesOAuth {
    GHAPIUsesOAuth = usesOAuth;
    [[NSUserDefaults standardUserDefaults] setBool:usesOAuth forKey:@"UsesOAuth"];
}

+ (BOOL)initializeClassWithKeychain
{
    GHAPIUsesOAuth = [[NSUserDefaults standardUserDefaults] boolForKey:@"UsesOAuth"];
    [self setAPIPrefix:[[NSUserDefaults standardUserDefaults] stringForKey:@"APIPrefix"]];
    NSError *error = nil;
    NSString *aUsername = [[NSUserDefaults standardUserDefaults] objectForKey:BHUserDefaultsKey];
    NSString *password = nil;

    if (aUsername)
        password = [STKeychain getPasswordForUsername:aUsername andServiceName:BHServiceName error:&error];
    
    if (!password)
        return NO;
    
    if (GHAPIUsesOAuth) {
        __defaultRequestForLogin = [self requestForAuth:aUsername token:password];
    } else {
        __defaultRequestForLogin = [self requestForAuth:aUsername password:password];
    }
    [__defaultRequestForLogin setCompletionBlock:^(GHAPIRequest *aRequest){
        NSInteger statusCode = [aRequest responseStatusCode];
        
        if (statusCode < 200 || statusCode > 299)
        {
            // login failed.
            NSAlert *alert = [NSAlert alertWithMessageText:@"Unable to Authenticate" defaultButton:@"Login" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"BugHub was unable to authenticate your login creditials with GitHub."];
            NSInteger responseCode = [alert runModal];
            
            if (responseCode == 0)
                [(AppDelegate *)[NSApp delegate] login:nil];
        }
        
    }];
    [__defaultRequestForLogin sendRequest];
    
    // for the moment, let's assume it was successful.
    if (GHAPIUsesOAuth) {
        [self setClassAuthenticatedUser:aUsername token:password];
    } else {
        [self setClassAuthenticatedUser:aUsername password:password];
    }
    
    return YES;
}

- (id)init
{
    self = [super init];

    if (self)
    {
        _status = GHAPIRequestStatusWaiting;
        _requestHeaders = [NSMutableDictionary dictionaryWithCapacity:1];
        _responseStatusCode = -1;
        _requestMethod = @"GET";
        //_subRequests = [NSMutableArray arrayWithCapacity:0];
    }

    return self;
}

- (void)checkRateLimit
{
    NSDictionary *responseHeaders = [self responseHeaders];
    
    NSNumber *aNumber = [responseHeaders objectForKey:@"X-RateLimit-Remaining"];
    if (aNumber == nil)
        return;
    
    NSInteger number = [aNumber integerValue];
    
    if (number < 1)
        [[NSNotificationCenter defaultCenter] postNotificationName:BHHitRateLimitNotification object:nil];
}

- (NSInteger)pageOfNextRequestFromResponse
{
    NSString *lastPageLocation = nil;
    // look at the headers for the next issues to download.
    NSString *linkHeader = [self.responseHeaders objectForKey:@"Link"];
    
    NSArray *pages = [linkHeader componentsSeparatedByString:@","];
    
    for (NSString *aLink in pages)
    {
        NSRange range = [aLink rangeOfString:@"rel=\"next\"" options:NSCaseInsensitiveSearch|NSBackwardsSearch];
        
        if (range.location != NSNotFound)
        {
            NSRange start = [aLink rangeOfString:@"<"];
            NSRange end = [aLink rangeOfString:@">"];
            
            if (start.location != NSNotFound && end.location != NSNotFound)
            {
                lastPageLocation = [aLink substringWithRange:NSMakeRange(start.location + 1, end.location - start.location - 1)];
                break;
            }
        }
    }
    
    
    NSInteger locationOfPageParam = [lastPageLocation rangeOfString:@"page="].location;
    
    if (locationOfPageParam == NSNotFound)
        return NSNotFound; //abort
    
    lastPageLocation = [lastPageLocation substringFromIndex:locationOfPageParam + 5]; // 5 is length of page=
    
    NSInteger locationOfPossibleAmp = [lastPageLocation rangeOfString:@"&"].location;
    
    if (locationOfPossibleAmp != NSNotFound)
        lastPageLocation = [lastPageLocation substringToIndex:locationOfPossibleAmp];
    
    return [lastPageLocation integerValue];
}

- (NSInteger)pageOfLastRequestFromResponse
{
    NSString *lastPageLocation = nil;
    // look at the headers for the next issues to download.
    NSString *linkHeader = [self.responseHeaders objectForKey:@"Link"];
    
    NSArray *pages = [linkHeader componentsSeparatedByString:@","];
    
    for (NSString *aLink in pages)
    {
        NSRange range = [aLink rangeOfString:@"rel=\"last\"" options:NSCaseInsensitiveSearch|NSBackwardsSearch];
        
        if (range.location != NSNotFound)
        {
            NSRange start = [aLink rangeOfString:@"<"];
            NSRange end = [aLink rangeOfString:@">"];
            
            if (start.location != NSNotFound && end.location != NSNotFound)
            {
                lastPageLocation = [aLink substringWithRange:NSMakeRange(start.location + 1, end.location - start.location - 1)];
                break;
            }
        }
    }
    
    
    NSInteger locationOfPageParam = [lastPageLocation rangeOfString:@"page="].location;
    
    if (locationOfPageParam == NSNotFound)
        return NSNotFound; //abort
    
    lastPageLocation = [lastPageLocation substringFromIndex:locationOfPageParam + 5]; // 5 is length of page=
    
    NSInteger locationOfPossibleAmp = [lastPageLocation rangeOfString:@"&"].location;
    
    if (locationOfPossibleAmp != NSNotFound)
        lastPageLocation = [lastPageLocation substringToIndex:locationOfPossibleAmp];

    return [lastPageLocation integerValue];
}

+ (void)setClassAuthenticatedUser:(NSString *)aUsername password:(NSString *)aPassword
{
    if (!aUsername || !aPassword)
    {
        NSError *error = nil;
        [STKeychain deleteItemForUsername:GHAPIRequestAuthenticatedUserLogin
                           andServiceName:BHServiceName
                                    error:&error];
        
        GBAPIRequestAuthenticationHeader = nil;
        GHAPIRequestAuthenticatedUserLogin = nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:BHLoginChangedNotification object:nil];
        return;
    }
    
    NSString *anAuthHeader = [NSString stringWithFormat:@"Basic %@",[Base64 encodeString:[NSString stringWithFormat:@"%@:%@", aUsername, aPassword]]];
    GBAPIRequestAuthenticationHeader = anAuthHeader;
    GHAPIRequestAuthenticatedUserLogin = [aUsername copy];
    
    [[NSUserDefaults standardUserDefaults] setObject:aUsername forKey:BHUserDefaultsKey];
    
    NSError *error = nil;
    BOOL wasSuccessful = [STKeychain storeUsername:aUsername andPassword:aPassword forServiceName:BHServiceName updateExisting:YES error:&error];
    if (!wasSuccessful)
        NSLog(@"Unsuccessful save attempt.");
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BHLoginChangedNotification object:nil];
}

+ (void)setClassAuthenticatedUser:(NSString *)username token:(NSString *)token {
    if (!username || !token) {
        NSError *error = nil;
        [STKeychain deleteItemForUsername:GHAPIRequestAuthenticatedUserLogin
                           andServiceName:BHServiceName
                                    error:&error];
        
        GBAPIRequestAuthenticationHeader = nil;
        GHAPIRequestAuthenticatedUserLogin = nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:BHLoginChangedNotification object:nil];
        return;
    }
    
    NSString *anAuthHeader = [NSString stringWithFormat:@"token %@", token];
    GBAPIRequestAuthenticationHeader = anAuthHeader;
    GHAPIRequestAuthenticatedUserLogin = [username copy];
    
    [[NSUserDefaults standardUserDefaults] setObject:username forKey:BHUserDefaultsKey];
    
    NSError *error = nil;
    BOOL wasSuccessful = [STKeychain storeUsername:username andPassword:token forServiceName:BHServiceName updateExisting:YES error:&error];
    if (!wasSuccessful)
        NSLog(@"Unsuccessful save attempt.");
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BHLoginChangedNotification object:nil];
}

+ (NSString *)authenticatedUserLogin
{
    return [GHAPIRequestAuthenticatedUserLogin copy];
}

@synthesize status = _status,
            responseData = _responseData,
            responseStatusCode = _responseStatusCode,
            completionBlock = _completionBlock,
            requestBody = _requestBody,
            requestMethod = _requestMethod,
            responseHeaders = _responseHeaders;


/*- (void)addSubRequest:(GHAPIRequest *)aSubRequest
{
    //[_subRequests addObject:aSubRequest];
}*/

- (GHAPIRequestStatus)status
{
    return _status;
}

- (NSData *)responseData
{
    return [_data copy];
}

- (NSInteger)responseStatusCode
{
    return _responseStatusCode;
}

- (NSDictionary *)responseHeaders
{
    return [_responseHeaders copy];
}

#pragma mark reqeust headers
- (void)addHeaderValues:(NSDictionary *)aDict
{
    [_requestHeaders addEntriesFromDictionary:aDict];
}

- (void)addHeader:(NSString *)aValue forKey:(NSString *)aKey
{
    [_requestHeaders setObject:aValue forKey:aKey];
}

- (NSString *)headerForKey:(NSString *)aKey
{
    return [_requestHeaders objectForKey:aKey];
}
- (NSDictionary *)headerValues
{
    return [_requestHeaders copy];
}

- (void)removeHeaderForKey:(NSString *)aKey
{
    [_requestHeaders removeObjectForKey:aKey];
}


#pragma mark manual requests
- (void)setRequestURL:(NSString *)aURLString
{
    _url = [NSURL URLWithString:aURLString];
}

- (void)sendRequest
{
    if (!_url)
    {
        NSLog(@"Trying to send request with no url set.");
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_url];
    [request setAllHTTPHeaderFields:_requestHeaders];

    if (_requestBody)
        [request setHTTPBody:_requestBody];

    [request setHTTPMethod:_requestMethod];

    _request = [request copy];
    _connection = [NSURLConnection connectionWithRequest:_request delegate:self];
    [_connection start];
    
    [self willChangeValueForKey:@"status"];
    _status = GHAPIRequestStatusLoading;
    [self didChangeValueForKey:@"status"];
    
    //NSLog(@"Sending request: %@", _request);

}

- (void)stopRequest
{
    if (self.status == GHAPIRequestStatusLoading)
    {
        [_connection cancel];
        [self willChangeValueForKey:@"status"];
        _status = GHAPIRequestStatusCanceled;
        [self didChangeValueForKey:@"status"];
    }
}


#pragma mark automatic request

+ (id)requestForAuth:(NSString *)aUsername token:(NSString *)token
{
    id request = [[self alloc] init];
    
    if (request)
    {
        [self setClassAuthenticatedUser:aUsername token:token];
        AddAuthHeader(request);
        [request setRequestURL:[NSString stringWithFormat:@"%@/user", GHAPIRequestPrefix]];
        [self setClassAuthenticatedUser:nil token:nil];
    }
    
    return request;
}

+ (id)requestForAuth:(NSString *)aUsername password:(NSString *)password
{
    id request = [[self alloc] init];
    
    if (request)
    {
        [self setClassAuthenticatedUser:aUsername password:password];
        AddAuthHeader(request);
        [request setRequestURL:[NSString stringWithFormat:@"%@/user", GHAPIRequestPrefix]];
        [self setClassAuthenticatedUser:nil password:nil];
    }
    
    return request;
}

+ (id)requestForUser:(NSString *)aUsername
{
    id request = [[self alloc] init];

    if (request)
    {
        AddAuthHeader(request);
        [request setRequestURL:[NSString stringWithFormat:@"%@/users/%@", GHAPIRequestPrefix, aUsername]];
    }

    return request;
}

+ (id)requestForUsersOrganizations:(NSString *)aUsername
{
    return nil;
}

// repos
+ (id)requestForRepositoryWithID:(NSString *)aRepoIdentifier
{
    id request = [[self alloc] init];

    if (request)
    {
        AddAuthHeader(request);
        [request setRequestURL:[NSString stringWithFormat:@"%@/repos/%@", GHAPIRequestPrefix, aRepoIdentifier]];
    }

    return request;
}

+ (id)requestForUsersRepositories:(NSString *)aUsername
{
    id request = [[self alloc] init];
    
    if (request)
    {
        AddAuthHeader(request);
        if ([[aUsername lowercaseString] isEqualToString:[[[self class] authenticatedUserLogin] lowercaseString]])
            [request setRequestURL:[NSString stringWithFormat:@"%@/user/repos?per_page=100", GHAPIRequestPrefix]];
        else
            [request setRequestURL:[NSString stringWithFormat:@"%@/users/%@/repos?per_page=100", GHAPIRequestPrefix, aUsername]];
    }
    
    return request;
}

+ (id)requestForOrgsRepositories:(NSString *)aUsername
{
    id request = [[self alloc] init];
    
    if (request)
    {
        AddAuthHeader(request);
        if ([[aUsername lowercaseString] isEqualToString:[[[self class] authenticatedUserLogin] lowercaseString]])
            [request setRequestURL:[NSString stringWithFormat:@"%@/orgs/repos?per_page=100", GHAPIRequestPrefix]];
        else
            [request setRequestURL:[NSString stringWithFormat:@"%@/orgs/%@/repos?per_page=100", GHAPIRequestPrefix, aUsername]];
    }
    
    return request;
}

+ (id)requestForRepositorysMilestones:(NSString *)aRepoIdentifier
{
    id request = [[self alloc] init];
    
    if (request)
    {
        AddAuthHeader(request);
        [request setRequestURL:[NSString stringWithFormat:@"%@/repos/%@/milestones?per_page=100", GHAPIRequestPrefix, aRepoIdentifier]];
    }
    
    return request;
}

+ (id)requestForRepositorysLabels:(NSString *)aRepoIdentifier
{
    id request = [[self alloc] init];
    
    if (request)
    {
        AddAuthHeader(request);
        [request setRequestURL:[NSString stringWithFormat:@"%@/repos/%@/labels?per_page=100", GHAPIRequestPrefix, aRepoIdentifier]];
    }
    
    return request;
}

+ (id)requestForRepositorysAssignees:(NSString *)aRepoIdentifier
{
    id request = [[self alloc] init];
    
    if (request)
    {
        AddAuthHeader(request);
        [request setRequestURL:[NSString stringWithFormat:@"%@/repos/%@/assignees?per_page=100", GHAPIRequestPrefix, aRepoIdentifier]];
    }
    
    return request;
}


+ (id)requestForNewMilestone:(NSString *)aName deadline:(NSDate *)aDeadline description:(NSString *)aDescription repositoryIdentifier:(NSString*)aRepoIdentifier
{
    id request = [[self alloc] init];
    
    if (request)
    {
        AddAuthHeader(request);
        [request setRequestURL:[NSString stringWithFormat:@"%@/repos/%@/milestones", GHAPIRequestPrefix, aRepoIdentifier]];
        [request setRequestMethod:@"POST"];
        
        NSDictionary *postDict = @{
                                    @"title": aName,
                                    @"description": aDescription == nil ? [NSNull null] : aDescription,
                                    @"due_on": aDeadline == nil ? [NSNull null] : [GHUtils githubDateStringFromDate:aDeadline]
                                   };
        
        NSError *error = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:postDict options:0 error:&error];
        
        if (error)
            NSLog(@"JSON encode error when creating 'new milestone' request");
        
        [request setRequestBody:data];
    }
    
    return request;
}

+ (id)requestForNewLabel:(NSString *)aName color:(NSColor *)aColor repositoryIdentifier:(NSString*)aRepoIdentifier
{
    id request = [[self alloc] init];
    
    if (request)
    {
        AddAuthHeader(request);
        NSString *urlStr = [NSString stringWithFormat:@"%@/repos/%@/labels", GHAPIRequestPrefix, aRepoIdentifier];
        [request setRequestURL:urlStr];
        [request setRequestMethod:@"POST"];
        
        NSDictionary *postDict = @{
                                   @"name": aName,
                                   @"color": aColor == nil ? @"C3D7E6" : [[aColor hexColor] substringFromIndex:1]
                                   };

        NSError *error = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:postDict options:0 error:&error];

        if (error)
            NSLog(@"JSON encode error when creating 'new label' request");
        
        [request setRequestBody:data];
    }
    
    return request;
}

// issues
+ (id)requestForReposOpenIssues:(NSString *)aRepoIdentifier page:(NSInteger)aPageNumber
{
    id request = [[self alloc] init];
    
    if (request)
    {
        AddAuthHeader(request);
        [request setRequestURL:[NSString stringWithFormat:@"%@/repos/%@/issues?state=open&per_page=100&page=%ld", GHAPIRequestPrefix, aRepoIdentifier, aPageNumber]];

        [request addHeader:HTML_AND_TEXT_ACCEPT_HEADER forKey:@"Accept"];
    }
    
    return request;
}

+ (id)requestForReposClosedIssues:(NSString *)aRepoIdentifier page:(NSInteger)aPageNumber
{
    id request = [[self alloc] init];
    
    if (request)
    {
        AddAuthHeader(request);
        [request setRequestURL:[NSString stringWithFormat:@"%@/repos/%@/issues?state=closed&per_page=100&page=%ld", GHAPIRequestPrefix, aRepoIdentifier, aPageNumber]];
        
        [request addHeader:HTML_AND_TEXT_ACCEPT_HEADER forKey:@"Accept"];
        
    }
    
    return request;
}

+ (id)requestForReposOpenIssueUpdates:(NSString *)aRepoIdentifier afterDate:(NSDate *)aDate
{
    id request = [[self alloc] init];
    
    if (request)
    {
        if (!aDate)
            aDate = [NSDate distantPast];
        
        AddAuthHeader(request);
        [request setRequestURL:[NSString stringWithFormat:@"%@/repos/%@/issues?state=open&per_page=30&sort=updated", GHAPIRequestPrefix, aRepoIdentifier]];
        [request addHeader:[GHUtils httpDateStringFromDate:aDate] forKey:@"If-Modified-Since"];
        [request addHeader:HTML_AND_TEXT_ACCEPT_HEADER forKey:@"Accept"];
        
    }
    
    return request;
}

+ (id)requestForReposClosedIssueUpdates:(NSString *)aRepoIdentifier afterDate:(NSDate *)aDate
{
    id request = [[self alloc] init];
    
    if (request)
    {
        if (!aDate)
            aDate = [NSDate distantPast];
        
        AddAuthHeader(request);
        [request setRequestURL:[NSString stringWithFormat:@"%@/repos/%@/issues?state=closed&per_page=30&sort=updated", GHAPIRequestPrefix, aRepoIdentifier]];
        [request addHeader:[GHUtils httpDateStringFromDate:aDate] forKey:@"If-Modified-Since"];
        [request addHeader:HTML_AND_TEXT_ACCEPT_HEADER forKey:@"Accept"];
        
    }
    
    return request;
}


+ (id)requestForIssueNumber:(NSInteger)aNumber repositoryIdentifier:(NSString *)anIdentifier
{
    id request = [[self alloc] init];
    
    if (request)
    {
        AddAuthHeader(request);
        [request setRequestURL:[NSString stringWithFormat:@"%@/repos/%@/issues/%ld", GHAPIRequestPrefix, anIdentifier, aNumber]];
        
        [request addHeader:HTML_AND_TEXT_ACCEPT_HEADER forKey:@"Accept"];
        
    }
    
    return request;
}

+ (id)requestForIssueUpdate:(NSInteger)aNumber repositoryIdentifier:(NSString *)aRepoIdentifier updates:(NSDictionary *)updatesDict
{
    id request = [[self alloc] init];
    
    if (request)
    {
        AddAuthHeader(request);
        [request setRequestURL:[NSString stringWithFormat:@"%@/repos/%@/issues/%ld", GHAPIRequestPrefix, aRepoIdentifier, aNumber]];
        [request setRequestMethod:@"PATCH"];
        
        NSError *error = nil;
        NSData *requestBodyData = [NSJSONSerialization dataWithJSONObject:updatesDict options:0 error:&error];

        // if there's an error, return that instead.
        if (error != nil)
            return error;

        [request setRequestBody:requestBodyData];

        [request addHeader:HTML_AND_TEXT_ACCEPT_HEADER forKey:@"Accept"];
        
    }
    
    return request;
}

+ (id)requestForNewIssue:(NSDictionary *)issueDict forRepositoryIdentifier:(NSString *)aRepoIdentifier
{
    id request = [[self alloc] init];
    
    if (request)
    {
        AddAuthHeader(request);
        [request setRequestURL:[NSString stringWithFormat:@"%@/repos/%@/issues", GHAPIRequestPrefix, aRepoIdentifier]];
        [request setRequestMethod:@"POST"];

        NSError *error = nil;
        NSData *requestBodyData = [NSJSONSerialization dataWithJSONObject:issueDict options:0 error:&error];

        // if there's an error, return that instead.
        if (error != nil)
            return error;
        
        [request setRequestBody:requestBodyData];
        
        [request addHeader:HTML_AND_TEXT_ACCEPT_HEADER forKey:@"Accept"];
        
    }
    
    return request;
}


+ (id)requestForCommentsFor:(NSString *)aRepoIdentifier issue:(NSInteger)anIssueNumber page:(NSInteger)aPageNumber
{
    id request = [[self alloc] init];
    
    if (request)
    {
        AddAuthHeader(request);
        [request setRequestURL:[NSString stringWithFormat:@"%@/repos/%@/issues/%ld/comments?page=%ld&per_page=100", GHAPIRequestPrefix, aRepoIdentifier, anIssueNumber, aPageNumber]];

        [request addHeader:HTML_AND_TEXT_ACCEPT_HEADER forKey:@"Accept"];
    }
    
    return request;
}

+ (id)requestForCommentsFor:(NSString *)aRepoIdentifier issue:(NSInteger)anIssueNumber sinceDate:(NSDate *)aDate page:(NSInteger)aPageNumber
{
    id request = [[self alloc] init];
    
    if (request)
    {
        AddAuthHeader(request);
        [request setRequestURL:[NSString stringWithFormat:@"%@/repos/%@/issues/%ld/comments?page=%ld&since=%@&per_page=100", GHAPIRequestPrefix, aRepoIdentifier, anIssueNumber, aPageNumber, [GHUtils githubDateStringFromDate:aDate]]];

        [request addHeader:HTML_AND_TEXT_ACCEPT_HEADER forKey:@"Accept"];
        
    }
    
    return request;
}

+ (id)requestForNewCommentWithBody:(NSString *)aBody repositoryIdentifier:(NSString *)anIdentifier issueNumber:(NSInteger)anIssueNumber
{
    id request = [[self alloc] init];
    
    if (request)
    {
        AddAuthHeader(request);
        [request setRequestURL:[NSString stringWithFormat:@"%@/repos/%@/issues/%ld/comments", GHAPIRequestPrefix, anIdentifier, anIssueNumber]];
        [request setRequestMethod:@"POST"];
        
        NSDictionary *requestDict = @{@"body":aBody};
        NSError *error = nil;
        NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestDict options:0 error:&error];
        [request setRequestBody:requestData];

        [request addHeader:HTML_AND_TEXT_ACCEPT_HEADER forKey:@"Accept"];
        
    }
    
    return request;
}

+ (id)requestForUpdatedCommentWithBody:(NSString *)aBody commentURL:(NSString *)aURL
{
    id request = [[self alloc] init];
    
    if (request)
    {
        AddAuthHeader(request);
        [request setRequestURL:aURL];
        [request setRequestMethod:@"PATCH"];

        NSDictionary *requestDict = @{@"body":aBody};
        NSError *error = nil;
        NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestDict options:0 error:&error];
        [request setRequestBody:requestData];

        [request addHeader:HTML_AND_TEXT_ACCEPT_HEADER forKey:@"Accept"];
        
    }
    
    return request;
}

+ (id)requestForDeleteComment:(NSString *)aRepoIdentifier commentId:(NSInteger)aCommentId
{
    return [self requestForCommentDeletion:[NSString stringWithFormat:@"%@/repos/%@/issues/comments/%ld", GHAPIRequestPrefix, aRepoIdentifier, aCommentId]];
}

+ (id)requestForCommentDeletion:(NSString *)aCommentURL
{
    id request = [[self alloc] init];
    
    if (request)
    {
        AddAuthHeader(request);
        [request setRequestURL:aCommentURL];
        [request setRequestMethod:@"DELETE"];
    }
    
    return request;
}

// API Status
+ (id)requestForAPIStatus
{
    // https://status.github.com/api/status.json
    id request = [[self alloc] init];
    
    if (request)
    {
        AddAuthHeader(request);
        [request setRequestURL:@"https://status.github.com/api/last-message.json"];
        [request setRequestMethod:@"GET"];
    }
    
    return request;
}


#pragma mark connection delegate
//- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ([response isKindOfClass:[NSHTTPURLResponse class]])
    {
        [self willChangeValueForKey:@"responseStatusCode"];
        _responseStatusCode = [(NSHTTPURLResponse *)response statusCode];
        _responseHeaders = [(NSHTTPURLResponse *)response allHeaderFields];
        [self didChangeValueForKey:@"responseStatusCode"];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (!_data)
        _data = [NSMutableData dataWithCapacity:[data length]];

    [_data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self willChangeValueForKey:@"status"];
    _status = GHAPIRequestStatusComplete;
    [self didChangeValueForKey:@"status"];

    if (self.completionBlock)
        self.completionBlock(self);

    [self checkRateLimit];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self willChangeValueForKey:@"status"];
    _status = GHAPIRequestStatusError;
    [self didChangeValueForKey:@"status"];

    if (self.completionBlock)
        self.completionBlock(self);
}


@end









