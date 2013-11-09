//
//  NSColor+hex.h
//  BugHub
//
//  Created by Randy on 12/27/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSColor (hex)
+ (NSColor*)colorWithHexColorString:(NSString*)inColorString;
- (NSString *)hexColor;

@end
