//
//  NSColor+hex.m
//  BugHub
//
//  Created by Randy on 12/27/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import "NSColor+hex.h"

@implementation NSColor (hex)
+ (NSColor*)colorWithHexColorString:(NSString*)inColorString
{
    NSColor* result = nil;
    unsigned colorCode = 0;
    unsigned char redByte, greenByte, blueByte;
    
    if (nil != inColorString)
    {
        NSScanner* scanner = [NSScanner scannerWithString:inColorString];
        (void) [scanner scanHexInt:&colorCode]; // ignore error
    }
    redByte = (unsigned char)(colorCode >> 16);
    greenByte = (unsigned char)(colorCode >> 8);
    blueByte = (unsigned char)(colorCode); // masks off high bits
    
    result = [NSColor
              colorWithCalibratedRed:(CGFloat)redByte / 0xff
              green:(CGFloat)greenByte / 0xff
              blue:(CGFloat)blueByte / 0xff
              alpha:1.0];
    return result;
}

- (NSString *)hexColor
{
    
    float r = [self redComponent] * 255;
    float g = [self greenComponent] * 255;
    float b = [self blueComponent] * 255;

    NSString *retStr = [NSString stringWithFormat:@"#%0.2X%0.2X%0.2X", (int)r, (int)g, (int)b];
    return retStr;
}

@end
