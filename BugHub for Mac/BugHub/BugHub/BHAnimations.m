//
//  BHAnimations.m
//  BugHub
//
//  Created by Randy on 12/29/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import "BHAnimations.h"

@implementation BHAnimations

+ (CAKeyframeAnimation *)shakeAnimation:(NSRect)frame numberOfShakes:(NSInteger)numberOfShakes durationOfShake:(NSTimeInterval)durationOfShake
{
    
    //static int numberOfShakes = 4;
    //static float durationOfShake = .5f;
    const float vigourOfShake = 0.025f;
    
    CAKeyframeAnimation *shakeAnimation = [CAKeyframeAnimation animation];
    
    CGMutablePathRef shakePath = CGPathCreateMutable();
    CGPathMoveToPoint(shakePath, NULL, NSMinX(frame), NSMinY(frame));
    int index;
    for (index = 0; index < numberOfShakes; ++index)
    {
        CGPathAddLineToPoint(shakePath, NULL, NSMinX(frame) - frame.size.width * vigourOfShake, NSMinY(frame));
        CGPathAddLineToPoint(shakePath, NULL, NSMinX(frame) + frame.size.width * vigourOfShake, NSMinY(frame));
    }
    CGPathCloseSubpath(shakePath);
    shakeAnimation.path = shakePath;
    shakeAnimation.duration = durationOfShake;
    CFRelease(shakePath);
    return shakeAnimation;
}

@end
