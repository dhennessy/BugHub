//
//  BHLabel.h
//  BugHub
//
//  Created by Randy on 12/26/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BHLabel : NSObject

@property(strong) NSString *name;
@property(strong) NSColor *color;
@property(strong) NSString *url;

- (void)setDictionaryValues:(NSDictionary *)aDict;

+ (BHLabel *)voidLabel;

@end
