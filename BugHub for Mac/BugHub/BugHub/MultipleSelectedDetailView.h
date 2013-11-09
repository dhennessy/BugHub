//
//  MultipleSelectedDetailView.h
//  BugHub
//
//  Created by Randy on 3/31/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "RLView.h"

@interface MultipleSelectedDetailView : RLView
{
    NSMutableArray *displayedDetailViews;
}

- (void)showNewIssues:(NSSet *)newIssues;
- (void)removeIssues:(NSSet *)issuesToremove;

@end
