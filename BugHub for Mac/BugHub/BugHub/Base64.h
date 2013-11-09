//
//  Base64.h
//  GithubIssues
//
//  Created by Randy on 7/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Base64 : NSObject
+ (NSString *)encode:(NSData *)plainText;
+ (NSString *)encodeString:(NSString*)aString;
@end
