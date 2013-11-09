//
//  NSAttributedString+GitHubMarkdownAdditions.m
//  BugHub
//
//  Created by Randy on 1/5/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "NSAttributedString+GitHubMarkdownAdditions.h"
#import "RLStack.h"

#define HEADER_TOKEN '#'
#define STAR_TOKEN '*'
#define UNDERSCORE_TOKEN '_'
#define CODE_TOKEN '`'
#define QUOTE_TOKEN '>'
#define NEW_LINE_TOKEN '\n'

@interface __GHMarkDownParseState : NSObject
@property NSInteger startPosition;
@property NSString *token;
@property NSString *closeToken;
@property NSString *attribute;
@end
@implementation __GHMarkDownParseState
@end

@implementation NSAttributedString (GitHubMarkdownAdditions)
+ (NSAttributedString *)attributedStringWithGitHubMarkdown:(NSString *)aString
{
    /*NSMutableAttributedString *output = [[NSMutableAttributedString alloc] init];
    NSMutableArray *attributes = [NSMutableArray arrayWithCapacity:0];
    RLStack *stateStack = [[RLStack alloc] init];

    for (NSInteger i = 0; i < [aString length]; i++)
    {
        unichar currentChar = [aString characterAtIndex:i];
        __GHMarkDownParseState *currentState = [stateStack topObject];

        switch (currentChar)
        {
            case HEADER_TOKEN:
                
                break;
            case STAR_TOKEN:
                break;
            case UNDERSCORE_TOKEN:
                break;
            case CODE_TOKEN:
                break;
            case QUOTE_TOKEN:
                break;
            default:
                
                break;
        }
    }
    
    return output;*/
    return nil;
}
@end
