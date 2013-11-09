//
//  NSNull+Additions.m
//  BugHub
//
//  Created by Randy on 12/29/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import "NSNull+Additions.h"

@implementation NSNull (Additions)

- (BOOL)boolValue
{
    NSLog(@"asked for BOOL value on NSNull");
    return NO;
}

- (NSInteger)integerValue
{
    NSLog(@"asked for INTEGER value on NSNull");
    return 0;
}

- (id)objectForKey:(NSString *)aKey
{
    NSLog(@"asked for OBJECT FOR KEY value on NSNull");
    return nil;
}

- (id)objectAtIndex:(NSInteger)anIndex
{
    NSLog(@"asked for OBJECT AT INDEX value on NSNull");
    return nil;
}


@end
