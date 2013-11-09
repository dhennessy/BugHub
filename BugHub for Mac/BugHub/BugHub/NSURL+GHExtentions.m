//
//  NSURL+GHExtentions.m
//  BugHub
//
//  Created by Randy on 1/1/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "NSURL+GHExtentions.h"

// https://api.github.com/repos/octocat/Hello-World/issues/1
// https://github.com/octocat/Hello-World/issues/1
// https://api.github.com/repos/octocat/Hello-World/issues/comments/1
#define API_PREFIX @"api."
#define REPO_PART @"repos"
#define IS_API_URL [[self host] hasPrefix:API_PREFIX]
#define IS_API_URL_PARTS(pathComponents) [[self host] hasPrefix:API_PREFIX] && [pathComponents count] > 1 && [[pathComponents objectAtIndex:1] isEqualToString:REPO_PART]
#define ISSUE_PART @"issues"
#define COMMENT_PART @"comments"

#define API_USERNAME_INDEX 2
#define API_REPONAME_INDEX 3
#define API_ISSUEPART_INDEX 4
#define API_ISSUENUM_INDEX 5
 // fix me, possibly wrong...
#define API_COMMENTPART_INDEX 5
#define API_COMMENT_INDEX 6

#define HTML_USERNAME_INDEX 1
#define HTML_REPONAME_INDEX 2
#define HTML_ISSUEPART_INDEX 3
#define HTML_ISSUENUM_INDEX 4



@implementation NSURL (GHExtentions)
- (NSString *)repositoryIdentifier
{
    NSArray *pathComponets = [self pathComponents];

    if (IS_API_URL)
    {
        if (IS_API_URL_PARTS(pathComponets) && [pathComponets count] > API_REPONAME_INDEX)
            return [NSString stringWithFormat:@"%@/%@", [pathComponets objectAtIndex:API_USERNAME_INDEX], [pathComponets objectAtIndex:API_REPONAME_INDEX]];
    }
    else
    {
        if ([pathComponets count] > HTML_REPONAME_INDEX)
            return [NSString stringWithFormat:@"%@/%@", [pathComponets objectAtIndex:HTML_USERNAME_INDEX], [pathComponets objectAtIndex:HTML_REPONAME_INDEX]];
    }
    
    return nil;
}

- (NSString *)repositoryOwner
{
    NSArray *pathComponets = [self pathComponents];
    
    if (IS_API_URL)
    {
        if (IS_API_URL_PARTS(pathComponets) && [pathComponets count] > API_USERNAME_INDEX)
            return [pathComponets objectAtIndex:API_USERNAME_INDEX];
    }
    else
    {
        if ([pathComponets count] > HTML_USERNAME_INDEX)
            return [pathComponets objectAtIndex:HTML_USERNAME_INDEX];
    }
    
    return nil;
}

- (NSString *)repositoryName
{
    NSArray *pathComponets = [self pathComponents];
    
    if (IS_API_URL)
    {
        if (IS_API_URL_PARTS(pathComponets) && [pathComponets count] > API_REPONAME_INDEX)
            return [pathComponets objectAtIndex:API_REPONAME_INDEX];
    }
    else
    {
        if ([pathComponets count] > HTML_REPONAME_INDEX)
            return [pathComponets objectAtIndex:HTML_REPONAME_INDEX];
    }
    
    return nil;
}
- (NSInteger)issueNumber
{
    NSArray *pathComponets = [self pathComponents];
    
    if (IS_API_URL)
    {
        if (IS_API_URL_PARTS(pathComponets) && [pathComponets count] > API_ISSUENUM_INDEX && [[pathComponets objectAtIndex:API_ISSUEPART_INDEX] isEqualToString:ISSUE_PART])
            return [[pathComponets objectAtIndex:API_ISSUENUM_INDEX] integerValue];
    }
    else
    {
        if ([pathComponets count] > HTML_ISSUENUM_INDEX && [[pathComponets objectAtIndex:HTML_ISSUEPART_INDEX] isEqualToString:ISSUE_PART])
            return [[pathComponets objectAtIndex:HTML_REPONAME_INDEX] integerValue];
    }
    
    return NSNotFound;
}

- (NSInteger)commentNumber
{
    NSArray *pathComponets = [self pathComponents];
    
    if (IS_API_URL)
    {
        if (IS_API_URL_PARTS(pathComponets) && [pathComponets count] > API_COMMENT_INDEX && [[pathComponets objectAtIndex:API_COMMENTPART_INDEX] isEqualToString:COMMENT_PART])
            return [[pathComponets objectAtIndex:API_COMMENT_INDEX] integerValue];
    }

    return NSNotFound;
}
@end
