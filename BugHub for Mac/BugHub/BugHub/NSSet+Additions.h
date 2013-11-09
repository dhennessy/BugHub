//
//  NSSet+Additions.h
//  BugHub
//
//  Created by Randy on 1/2/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSSet (Additions)

- (NSSet *)setByIntersectingSet:(NSSet *)aSet;
- (NSSet *)setBySubtractingSet:(NSSet *)aSet;

@end
