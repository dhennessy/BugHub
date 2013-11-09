//
//  NSDate+Strings.m
//  BugHub
//
//  Created by Randy on 3/2/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "NSDate+Strings.h"

@implementation NSDate (Strings)
- (NSString *)normalDateString
{
    NSDateFormatter *threadFormatter = [[[NSThread currentThread] threadDictionary] objectForKey:@"BHStringFormatterDateThingy"];
    
    if (!threadFormatter)
    {
        threadFormatter = [[NSDateFormatter alloc] init];
        [threadFormatter setDateStyle:NSDateFormatterLongStyle];
        threadFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        threadFormatter.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        threadFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        
        [[[NSThread currentThread] threadDictionary] setObject:threadFormatter forKey:@"BHStringFormatterDateThingy"];
    }
    
    return [threadFormatter stringFromDate:self];
}
@end