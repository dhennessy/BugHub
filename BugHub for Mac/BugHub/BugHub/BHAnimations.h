//
//  BHAnimations.h
//  BugHub
//
//  Created by Randy on 12/29/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface BHAnimations : NSObject

+ (CAKeyframeAnimation *)shakeAnimation:(NSRect)frame numberOfShakes:(NSInteger)numberOfShakes durationOfShake:(NSTimeInterval)durationOfShake;

@end
