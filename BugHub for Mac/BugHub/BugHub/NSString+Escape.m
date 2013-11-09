//
//  NSString+Escape.m
//  BugHub
//
//  Created by Randy on 3/27/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "NSString+Escape.h"

@implementation NSString (Escape)

- (NSString *)stringByEscapingThings
{
    // from http://stackoverflow.com/a/15511150/87388
    NSString *sourceString = self;
    NSMutableString *destString = [@"" mutableCopy];
    NSCharacterSet *escapeCharsSet = [NSCharacterSet characterSetWithCharactersInString:@"\n\r'\"\\"];
    
    NSScanner *scanner = [NSScanner scannerWithString:sourceString];
    while (![scanner isAtEnd]) {
        NSString *tempString;
        [scanner scanUpToCharactersFromSet:escapeCharsSet intoString:&tempString];
        if([scanner isAtEnd]){
            [destString appendString:tempString];
        }
        else {
            [destString appendFormat:@"%@\\%@", tempString, [sourceString substringWithRange:NSMakeRange([scanner scanLocation], 1)]];
            [scanner setScanLocation:[scanner scanLocation]+1];
        }
    }
    
    return [destString copy];
}

@end
