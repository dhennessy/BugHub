//
//  NSURL+GHExtentions.h
//  BugHub
//
//  Created by Randy on 1/1/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (GHExtentions)

- (NSString *)repositoryIdentifier;
- (NSString *)repositoryOwner;
- (NSString *)repositoryName;
- (NSInteger)issueNumber;
- (NSInteger)commentNumber;

@end
