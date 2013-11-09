//
//  BHUser.m
//  BugHub
//
//  Created by Randy on 12/26/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import "BHUser.h"
#import "GHAPIRequest.h"
#import "RLStack.h"
#import "Base64.h"

static NSMutableDictionary *AllGitHubUsers = nil;
static NSImage *GHUserDefaultAvatar = nil;

static NSCache *BHUserAvatarCache = nil;
static RLStack *avatarRequestStack = nil;
static BOOL avatarRequestIsRunning = NO;

@interface BHUser ()
{
    GHAPIRequest *_downloadRequest;
    NSURLConnection *_avatarDownloadConnection;
}
- (void)loadUser;
- (void)_setDictValues:(NSDictionary *)aDict;
- (void)_createCacheIfNeeded;
- (void)_downloadAvatar;

+ (void)_downloadNextAvatar;

@end

@implementation BHUser

+ (BHUser *)voidUser
{
    static BHUser *aUser;
    
    if (!aUser)
    {
        aUser = [[self alloc] init];
        [aUser setLogin:@"No Assignee Set"];
    }
    
    return aUser;
}

+ (id)userWithLogin:(NSString *)aLogin dictionaryValues:(NSDictionary *)aDict
{
    if (!aLogin)
        return nil;
    
    aLogin = [aLogin lowercaseString];
    
    if (!AllGitHubUsers)
        AllGitHubUsers = [NSMutableDictionary dictionaryWithCapacity:100];

    BHUser *user = [AllGitHubUsers objectForKey:aLogin];

    if (!user)
    {
        user = [[self alloc] initWithLogin:aLogin];

        [AllGitHubUsers setObject:user forKey:aLogin];

        if (aDict)
            [user _setDictValues:aDict];
        else
            [user loadUser];
    }
    else
    {
        if (!user.isLoaded && aDict)
            [user _setDictValues:aDict];
    }

    return user;
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[BHUser class]])
        return NO;
    
    return [[self.login lowercaseString] isEqual:[[object login] lowercaseString]];
}

- (id)initWithLogin:(NSString *)aLogin
{
    self = [super init];
    
    if (self)
    {
        self.login = aLogin;
        self.userID = -1;
        self.name = @"";
        self.avatarURL = nil;
        self.isLoaded = NO;
    }
    
    return self;
}


- (NSImage *)avatar
{
    [self _createCacheIfNeeded];
    
    NSImage *avatar = [BHUserAvatarCache objectForKey:self];
    
    if (!avatar)
    {
        
        if (avatarRequestIsRunning)
            [avatarRequestStack push:self];
        else
        {
            avatarRequestIsRunning = YES;
            [self _downloadAvatar];
        }

        if (!GHUserDefaultAvatar)
            GHUserDefaultAvatar = [[NSBundle mainBundle] imageForResource:@"gravatar-40"];
        
        avatar = GHUserDefaultAvatar;
    }

    return avatar;
    
}


- (void)_createCacheIfNeeded
{
    if (!BHUserAvatarCache)
    {
        BHUserAvatarCache = [[NSCache alloc] init];
        [BHUserAvatarCache setCountLimit:200];
        
        avatarRequestStack = [[RLStack alloc] init];
    }
}

+ (void)_downloadNextAvatar
{
    BHUser *nextUser = [avatarRequestStack pop];
    [nextUser _downloadAvatar];
}

- (void)_downloadAvatar
{
    avatarRequestIsRunning = YES;

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.avatarURL]];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {
        avatarRequestIsRunning = NO;
        [[self class] _downloadNextAvatar];

        if (![response isKindOfClass:[NSHTTPURLResponse class]])
            return;
        
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        
        if (statusCode > 299 || statusCode < 200)
            return;
        
        [self _createCacheIfNeeded];
        NSImage *newImage = [[NSImage alloc] initWithData:responseData];
        [self willChangeValueForKey:@"avatar"];
        [BHUserAvatarCache setObject:newImage forKey:self];
        [self didChangeValueForKey:@"avatar"];
    }];
}

- (void)_setDictValues:(NSDictionary *)aDict
{
    if (_downloadRequest)
    {
        [_downloadRequest stopRequest];
        _downloadRequest = nil;
    }
    
    [self setUserID:[[aDict objectForKey:@"id"] integerValue]];
    [self setName:[aDict objectForKey:@"name"]];
    [self setAvatarURL:[aDict objectForKey:@"avatar_url"]];

    BOOL isOrg = [[aDict objectForKey:@"type"] isEqual:@"Organization"];
    [self setIsOrganization:isOrg];

    [self setIsLoaded:YES];
}

@synthesize login, userID, name, avatarURL, isLoaded;

- (void)loadUser
{
    if (_downloadRequest)
    {
        if ([_downloadRequest status] == GHAPIRequestStatusLoading)
            return;

        [_downloadRequest stopRequest];
    }

    _downloadRequest = [GHAPIRequest requestForUser:self.login];

    // avoid retain cycle
    __weak typeof(self) userObject = self;

    [_downloadRequest setCompletionBlock:^(GHAPIRequest *request){
        if (request.status == GHAPIRequestStatusComplete)
        {
            NSData *responseData = [request responseData];
            NSInteger statusCode = [request responseStatusCode];

            if (statusCode < 200 || statusCode > 299)
            {
                //id userDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
                
                NSLog(@"User '%@' download unsuccessful. Status code: %ld;", userObject.login, statusCode);
                return;
            }

            // FIX ME: This might need to be on a different thread.
            NSError *error = nil;
            id userDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
            
            if (error || ![userDict isKindOfClass:[NSDictionary class]])
            {
                NSLog(@"Error parsing user data: %@;", error);
                return;
            }

            [userObject _setDictValues:userDict];
            [userObject setIsLoaded:YES];
        }
    }];

    [_downloadRequest sendRequest];
}

+ (NSSet *)keyPathsForValuesAffectingAvatar
{
    return [NSSet setWithObject:@"avatarURL"];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"{login: %@, name:%@, id:%ld, avatarURL:%@}", self.login, self.name, self.userID, self.avatarURL];
}


- (NSDictionary *)webViewJSONDict
{
    NSData *data = self.avatar == GHUserDefaultAvatar ? nil : [self.avatar TIFFRepresentation];
    
    if (data)
        data = [[NSBitmapImageRep imageRepWithData:data] representationUsingType:NSPNGFileType properties:nil];

    NSDictionary *dict = @{
        @"login": self.login,
        @"name" : self.name ? self.name : [NSNull null],
        @"avatarURL": data ? [NSString stringWithFormat:@"data:image/png;base64,%@", [Base64 encode:data]] : self.avatarURL
    };
    
    return dict;
}

@end
