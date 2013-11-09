//
//  NSNull+Additions.h
//  BugHub
//
//  Created by Randy on 12/29/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSNull (Additions)

- (BOOL)boolValue;
- (NSInteger)integerValue;
- (id)objectForKey:(NSString *)aKey;
- (id)objectAtIndex:(NSInteger)anIndex;
@end
