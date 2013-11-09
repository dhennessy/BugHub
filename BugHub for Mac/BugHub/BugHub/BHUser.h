//
//  BHUser.h
//  BugHub
//
//  Created by Randy on 12/26/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import <Foundation/Foundation.h>


/*
 {
 "login": "octocat",
 "id": 1,
 "avatar_url": "https://github.com/images/error/octocat_happy.gif",
 "gravatar_id": "somehexcode",
 "url": "https://api.github.com/users/octocat",
 "name": "monalisa octocat",
 "company": "GitHub",
 "blog": "https://github.com/blog",
 "location": "San Francisco",
 "email": "octocat@github.com",
 "hireable": false,
 "bio": "There once was...",
 "public_repos": 2,
 "public_gists": 1,
 "followers": 20,
 "following": 0,
 "html_url": "https://github.com/octocat",
 "created_at": "2008-01-14T04:33:35Z",
 "type": "User"
 }
*/

@interface BHUser : NSObject

+ (id)userWithLogin:(NSString *)aLogin dictionaryValues:(NSDictionary *)aDict;

- (id)initWithLogin:(NSString *)aLogin;

@property BOOL isLoaded;

@property(strong) NSString *login;
@property(strong) NSString *name;
@property(strong) NSString *avatarURL;
@property(weak, nonatomic) NSImage *avatar;
@property NSInteger userID;
@property BOOL isOrganization;


- (NSDictionary *)webViewJSONDict;

+ (BHUser *)voidUser;

@end
