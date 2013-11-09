//
//  NSAttributedString+GitHubMarkdownAdditions.h
//  BugHub
//
//  Created by Randy on 1/5/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSAttributedString (GitHubMarkdownAdditions)

+ (NSAttributedString *)attributedStringWithGitHubMarkdown:(NSString *)aString;

@end
