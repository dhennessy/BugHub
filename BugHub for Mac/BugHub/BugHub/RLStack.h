//
//  RLStack.h
//  BugHub
//
//  Created by Randy on 12/31/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RLStack : NSObject

- (NSInteger)count;
- (void)push:(id)anObject;
- (id)pop;
// topObject just returns the object, doesn't pop it off the stack.
- (id)topObject;

@end
