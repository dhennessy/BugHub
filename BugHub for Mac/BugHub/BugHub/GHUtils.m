//
//  GHUtils.m
//  BugHub
//
//  Created by Randy on 12/27/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import "GHUtils.h"

@implementation GHUtils
+ (NSDate *)dateFromGithubString:(NSString *)aString
{
    if (!aString || [aString isKindOfClass:[NSNull class]])
        return nil;
    
    // creating a formatter is expensive. cache it.
    NSDateFormatter *cachedDateFormatter = [[[NSThread currentThread] threadDictionary] objectForKey:@"GithubStringDateFormatterKey"];
    
    if (!cachedDateFormatter)
    {
        cachedDateFormatter= [[NSDateFormatter alloc] init];
        [cachedDateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        cachedDateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        cachedDateFormatter.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        cachedDateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        
        [[[NSThread currentThread] threadDictionary] setObject:cachedDateFormatter forKey:@"GithubStringDateFormatterKey"];
    }
    
    return [cachedDateFormatter dateFromString:aString];
    
}

+ (NSString *)githubDateStringFromDate:(NSDate *)aDate
{
    if ([aDate isKindOfClass:[NSNull class]])
        return nil;
    
     // creating a formatter is expensive. cache it.
    NSDateFormatter *threadDateFormatter = [[[NSThread currentThread] threadDictionary] objectForKey:@"ISDateFormatter"];
    
    if (!threadDateFormatter)
    {
        threadDateFormatter = [[NSDateFormatter alloc] init];
        [threadDateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        threadDateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        threadDateFormatter.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        threadDateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        [[[NSThread currentThread] threadDictionary] setObject:threadDateFormatter forKey:@"ISDateFormatter"];
    }
    
    return [threadDateFormatter stringFromDate:aDate];
}

+ (NSString *)httpDateStringFromDate:(NSDate *)aDate
{
    if ([aDate isKindOfClass:[NSNull class]])
        return nil;
    
    // creating a formatter is expensive. cache it.
    NSDateFormatter *threadDateFormatter = [[[NSThread currentThread] threadDictionary] objectForKey:@"BHHTTPDateFormatter"];
    
    if (!threadDateFormatter)
    {
        //Thu, 05 Jul 2012 15:31:30 GMT
        threadDateFormatter = [[NSDateFormatter alloc] init];
        [threadDateFormatter setDateFormat:@"EEE, d MMM yyyy HH:mm:ss zzz"];
        threadDateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        threadDateFormatter.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        threadDateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        [[[NSThread currentThread] threadDictionary] setObject:threadDateFormatter forKey:@"BHHTTPDateFormatter"];
    }
    
    return [threadDateFormatter stringFromDate:aDate];
}

@end
