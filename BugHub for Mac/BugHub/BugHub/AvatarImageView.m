//
//  AvatarImageView.m
//  BugHub
//
//  Created by Randy on 3/4/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "AvatarImageView.h"
#import "DrawingHelp.h"
#import "NSColor+hex.h"

@interface AvatarImageView()

- (void)_sharedInit;

@end

@implementation AvatarImageView

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    
    if (self)
        [self _sharedInit];
    
    return self;
}

- (void)_sharedInit
{
    
    self.cornerRadius = 6;
    self.bezelSize = 4;
    self.bezelColor = [NSColor colorWithHexColorString:@"f4f4f4"];
    self.bezelStroke = [NSColor colorWithCalibratedWhite:0.0 alpha:.1];
}

- (void)awakeFromNib
{
    [self _sharedInit];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [NSGraphicsContext saveGraphicsState];
    
    //float outerRadius = self.cornerRadius + 2;
    //NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, .5, .5) xRadius:outerRadius yRadius:outerRadius];
    NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:CGRectInset(self.bounds, .5, .5)];
    //NSAffineTransform *translate = [NSAffineTransform transform];
    //[translate translateXBy:0 yBy:-1];
    //[path transformUsingAffineTransform:translate];
    
    [self.bezelStroke setFill];
    [path fill];
    
    
    //    NSBezierPath *path2 = [NSBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, 1.5, 1.5) xRadius:outerRadius yRadius:outerRadius];
    NSBezierPath *path2 = [NSBezierPath bezierPathWithOvalInRect:CGRectInset(self.bounds, 1.5, 1.5)];
    //[path transformUsingAffineTransform:translate];
    [self.bezelColor setFill];
    [self.bezelStroke setStroke];
    [path2 fill];
    
    CGRect imageFrame = CGRectInset(self.bounds, self.bezelSize, self.bezelSize);
    NSBezierPath *imagePath = [NSBezierPath bezierPathWithOvalInRect:imageFrame];
    //NSBezierPath *imagePath = [NSBezierPath bezierPathWithRoundedRect:imageFrame xRadius:self.cornerRadius yRadius:self.cornerRadius];
    [imagePath addClip];
    [self.image drawInRect:imageFrame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    [NSGraphicsContext restoreGraphicsState];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeFloat:self.cornerRadius forKey:@"BHCornerRadius"];
    [aCoder encodeFloat:self.bezelSize forKey:@"BHBezelSize"];
    
    [aCoder encodeObject:self.bezelStroke forKey:@"BHBezelStroke"];
    [aCoder encodeObject:self.bezelColor forKey:@"BHBezelColor"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
        self.cornerRadius = [aDecoder decodeFloatForKey:@"BHCornerRadius"];
        self.bezelSize = [aDecoder decodeFloatForKey:@"BHBezelSize"];
        
        self.bezelStroke = [aDecoder decodeObjectForKey:@"BHBezelStroke"];
        self.bezelColor = [aDecoder decodeObjectForKey:@"BHBezelColor"];
    }
    
    return self;
}

@end
