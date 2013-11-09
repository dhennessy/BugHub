//
//  BHIssueFilter.m
//  BugHub
//
//  Created by Randy on 12/26/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import "BHIssueFilter.h"
#import "BHIssue.h"
#import "BHUser.h"
#import "BHMilestone.h"
#import "BHLabel.h"
#import "BHComment.h"



@interface BHIssueFilter ()
{
    BOOL stricterLastChange;
    NSInteger lastUpdateMask;
}
@end

@implementation BHIssueFilter

@synthesize indexes, shouldBeOpen, assignedTo, milestones, labels, text=_text, filterValue;

- (BOOL)lastChangeWasStricter
{
    return stricterLastChange;
}

- (void)setText:(NSString *)text
{
    // FIX ME: this is right, but all the other properties need to set this too before it can be used.
    //    if ([text hasPrefix:self.text])
    //  stricterLastChange = YES;

    _text = text;
    
}

+ (NSSet *)keyPathsForValuesAffectingFilterValue
{
    return [NSSet setWithObjects:@"indexes", @"shouldBeOpen", @"assignedTo", @"milestones", @"labels", @"text", nil];
}

- (BOOL)issueMatchesFilter:(BHIssue *)anIssue
{
    if (self.shouldBeOpen != BHUnknownState && [anIssue state] != self.shouldBeOpen)
        return NO;

    if ([self.indexes count] && ![self.indexes containsIndex:[anIssue number]])
        return NO;

    if ([self.assignedTo count] && ![self.assignedTo containsObject:[anIssue assignee]] && !([self.assignedTo containsObject:[BHUser voidUser]] && ![anIssue assignee]))
        return NO;
    
    if ([self.milestones count] && ![self.milestones containsObject:[anIssue milestone]] && !([self.milestones containsObject:[BHMilestone voidMilestone]] && ![anIssue milestone]))
        return NO;


    if ([self.labels count] && ![self.labels intersectsSet:[anIssue labels]] && !([self.labels containsObject:[BHLabel voidLabel]] && [[anIssue labels] count] == 0))
            return NO;

    if ([self.text length] && self.text)
    {
        NSRange titleSearch = [[anIssue title] rangeOfString:self.text options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch|NSWidthInsensitiveSearch];
        
        if (titleSearch.location == NSNotFound)
        {
            NSRange bodySearch = [[anIssue rawBody] rangeOfString:self.text options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch|NSWidthInsensitiveSearch];

            if (bodySearch.location == NSNotFound)
            {
                NSOrderedSet *comments = [anIssue comments];
                BOOL foundCommentMatch = NO;

                for (BHComment *aComment in comments)
                {
                    NSRange commentSearch = [[aComment rawBody] rangeOfString:self.text options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch|NSWidthInsensitiveSearch];
                    
                    foundCommentMatch = commentSearch.location != NSNotFound;
                    if (foundCommentMatch)
                        break;
                }
                
                return foundCommentMatch;
            }
        
        }
    }

    return YES;
}

@end
