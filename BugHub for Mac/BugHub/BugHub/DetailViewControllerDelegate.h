//
//  DetailViewControllerDelegate.h
//  BugHub
//
//  Created by Randy on 3/11/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DetailViewControllerDelegate <NSObject>

- (void)issuesDidChangeState:(NSSet *)issuesThatChanged;

@end
