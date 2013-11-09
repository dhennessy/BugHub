//
//  IssueListCellView.m
//  BugHub
//
//  Created by Randy on 12/30/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import "IssueListTableCellView.h"
#import "NSTextField+Additions.h"
#import "BHIssue.h"
#import "BHUser.h"
#import "BHIssueFilter.h"
#import "NSColor+hex.h"

@interface IssueListTableCellView ()
{
    BOOL isAwake;
}
- (void)_updateTitle;
- (void)_updateCreator;
- (NSSet *)_titleStringAttribtues;
- (NSSet *)_dateStringAttribtuesWithString:(NSAttributedString *)aString;
@end

@implementation IssueListTableCellView

- (void)dealloc
{
    if (!isAwake)
        return;
    
    isAwake = NO;
    
    [self removeObserver:self forKeyPath:@"objectValue.title"];
    [self removeObserver:self forKeyPath:@"objectValue.creator"];
    [self removeObserver:self forKeyPath:@"objectValue.number"];
    [self removeObserver:self forKeyPath:@"objectValue.creator.avatar"];
}

- (void)awakeFromNib
{
    [self addObserver:self forKeyPath:@"objectValue.title" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"objectValue.creator" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"objectValue.number" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"objectValue.creator.avatar" options:0 context:NULL];
    isAwake = YES;
}

/*- (void)setObjectValue:(id)objectValue
{
    [super setObjectValue:objectValue];
}*/

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    static NSString *titleKey = @"objectValue.title";
    static NSString *creatorKey = @"objectValue.creator";
    static NSString *numberKey = @"objectValue.number";
    static NSString *creatorURL = @"objectValue.creator.avatar";
    
    if ([keyPath isEqualToString:titleKey] || [keyPath isEqualToString:numberKey])
    {
        [self _updateTitle];
    }
    else if([keyPath isEqualToString:creatorKey] || [keyPath isEqualToString:creatorURL])
    {
        [self _updateCreator];
    }
}


- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
    [super setBackgroundStyle:backgroundStyle];
    
    [self _updateTitle];
    [self _updateCreator];
}


- (void)_updateTitle
{
    if (!self.objectValue)
        return;

    NSString *rawTitle = [NSString stringWithFormat:@"#%ld %@", [self.objectValue number], [self.objectValue title]];
    NSMutableAttributedString *newTitle = [[NSMutableAttributedString alloc] initWithString:rawTitle];
    
    NSSet *attributes = [self _titleStringAttribtues];
    
    for (NSArray *attribute in attributes)
        [newTitle addAttribute:attribute[0] value:attribute[1] range:[attribute[2] rangeValue]];
    
    [self.titleField setAttributedStringValue:newTitle];
}

- (void)_updateCreator
{
    if (!self.objectValue)
        return;

    
    NSImage *avatarImage = [[[self objectValue] creator] avatar];

    [self.avatarView setImage:avatarImage];
    [self.userField setStringValue:[[[self objectValue] creator] login]];
    
    if ([self backgroundStyle] == NSBackgroundStyleLight)
    {
        [self.userField setTextColor:[NSColor colorWithHexColorString:@"85898c"]];
        NSShadow *userShadow = [[NSShadow alloc] init];
        [userShadow setShadowOffset:CGSizeMake(0, -1)];
        [userShadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:1.0]];
        [self.userField setShadow:userShadow];
    }
    else if ([self backgroundStyle] == NSBackgroundStyleDark)
    {
        [self.userField setTextColor:[NSColor colorWithHexColorString:@"b8c8d9"]];
        NSShadow *userShadow = [[NSShadow alloc] init];
        [userShadow setShadowOffset:CGSizeMake(0, -1)];
        [userShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.35]];
        [self.userField setShadow:userShadow];
    }

    NSString *createdDate = [NSDateFormatter localizedStringFromDate:[self.objectValue dateCreated] dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterNoStyle];
    NSMutableAttributedString *createdDateString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Created %@", nil), createdDate]];
    
    NSSet *attributes = [self _dateStringAttribtuesWithString:createdDateString];
    
    for (NSArray *attribute in attributes)
        [createdDateString addAttribute:attribute[0] value:attribute[1] range:[attribute[2] rangeValue]];
    
    
    
    [self.dateField setAttributedStringValue:createdDateString];
}

- (NSSet *)_titleStringAttribtues
{
    NSMutableSet *attributes = [NSMutableSet setWithCapacity:5];
    
    NSString *numberString = [NSString stringWithFormat:@"#%ld ", [self.objectValue number]];
    NSString *rawTitle = [numberString stringByAppendingString:[self.objectValue title]];
    
    NSColor *numberColor = nil;
    NSColor *titleColor = nil;
    
    NSShadow *numberShadow = nil;
    NSShadow *titleShadow = nil;
    //NSColor *bodyColor = nil;
    
    if (self.backgroundStyle == NSBackgroundStyleLight)
    {
        numberColor = [NSColor colorWithHexColorString:@"9da2a6"];
        titleColor = [NSColor colorWithHexColorString:@"606b73"];
        
        numberShadow = [[NSShadow alloc] init];
        [numberShadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:1.0]];
        [numberShadow setShadowOffset:CGSizeMake(0, -1)];

        titleShadow = [[NSShadow alloc] init];
        [titleShadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:1.0]];
        [titleShadow setShadowOffset:CGSizeMake(0, -1)];
        
        //numberShadowColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.3];
        //titleShadowColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.3];
    }
    else if (self.backgroundStyle == NSBackgroundStyleDark)
    {
        numberColor = [NSColor colorWithHexColorString:@"c3d4e5"];
        titleColor = [NSColor colorWithHexColorString:@"f2f9ff"];
        //bodyColor = [NSColor colorWithHexColorString:@"dae6f2"];

        numberShadow = [[NSShadow alloc] init];
        [numberShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.3]];
        [numberShadow setShadowOffset:CGSizeMake(0, -1)];
        
        titleShadow = [[NSShadow alloc] init];
        [titleShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.3]];
        [titleShadow setShadowOffset:CGSizeMake(0, -1)];

        //numberShadowColor = [NSColor colorWithCalibratedWhite:0.0 alpha:0.3];
        //titleShadowColor = [NSColor colorWithCalibratedWhite:0.0 alpha:0.3];
    }
    
    NSValue *fullRange = [NSValue valueWithRange:NSMakeRange(0, rawTitle.length)];
    NSValue *numberRange = [NSValue valueWithRange:NSMakeRange(0, numberString.length)];
    NSValue *titleRange = [NSValue valueWithRange:NSMakeRange(numberString.length, rawTitle.length - numberString.length)];
    

    NSArray *one = @[NSFontAttributeName, [NSFont fontWithName:@"Helvetica Bold" size:12.0], fullRange];
    NSArray *two = @[NSForegroundColorAttributeName, numberColor, numberRange];
    NSArray *tre = @[NSForegroundColorAttributeName, titleColor, titleRange];
    NSArray *fou = @[NSShadowAttributeName, numberShadow, numberRange];
    NSArray *fiv = @[NSShadowAttributeName, titleShadow, titleRange];
    
    [attributes addObject:one];
    [attributes addObject:two];
    [attributes addObject:tre];
    [attributes addObject:fou];
    [attributes addObject:fiv];
    
    return attributes;
}

- (NSSet *)_dateStringAttribtuesWithString:(NSAttributedString *)aString
{
    NSMutableSet *attributes = [NSMutableSet setWithCapacity:3];
    
    NSValue *fullRange = [NSValue valueWithRange:NSMakeRange(0, aString.length)];
    NSUInteger lengthOfPrefix = NSLocalizedString(@"Created %@", nil).length - 2;
    
    NSValue *prefixRange = [NSValue valueWithRange:NSMakeRange(0, lengthOfPrefix)];
    NSValue *dateRange = [NSValue valueWithRange:NSMakeRange(lengthOfPrefix, aString.length - lengthOfPrefix)];
    
    NSFont *prefixFont = [NSFont systemFontOfSize:11];
    NSFont *dateFont = [NSFont boldSystemFontOfSize:11];
    NSColor *textColor = nil;
    NSShadow *shadow = [[NSShadow alloc] init];;
    [shadow setShadowOffset:CGSizeMake(0, -1)];
    if ([self backgroundStyle] == NSBackgroundStyleLight)
    {
        textColor = [NSColor colorWithHexColorString:@"85898c"];
        [shadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:1.0]];
        
    }
    else if ([self backgroundStyle] == NSBackgroundStyleDark)
    {
        textColor = [NSColor colorWithHexColorString:@"b8c8d9"];
        [shadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:.35]];
    }
    

    NSArray *one = @[NSFontAttributeName, prefixFont, prefixRange];
    NSArray *two = @[NSFontAttributeName, dateFont, dateRange];

    
    NSArray *thr = @[NSForegroundColorAttributeName, textColor, fullRange];
    NSArray *fou = @[NSShadowAttributeName, shadow, fullRange];

    NSMutableParagraphStyle *mutParaStyle= [[NSMutableParagraphStyle alloc] init];
    [mutParaStyle setAlignment:NSCenterTextAlignment];

    NSArray *fiv = @[NSParagraphStyleAttributeName, mutParaStyle, fullRange];
    
    [attributes addObject:one];
    [attributes addObject:two];
    [attributes addObject:thr];
    [attributes addObject:fou];
    [attributes addObject:fiv];
    
    return attributes;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];

    CGContextSaveGState(context);
    
    if ([self backgroundStyle] == NSBackgroundStyleDark)
    {
        /*// draw top line
        const CGPoint bottomPoints[] = {
            CGPointMake(0, 0.5),
            CGPointMake(CGRectGetWidth(self.frame), 0.5)
        };
        
        [[NSColor colorWithHexColorString:@"37383a"] setStroke];
        CGContextStrokeLineSegments(context, bottomPoints, 1);*/
        CGContextRestoreGState(context);
        return;
    }

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CFMutableArrayRef colors = (CFMutableArrayRef)CFBridgingRetain([NSMutableArray arrayWithCapacity:2]);
    
    NSColor *topColor = [NSColor colorWithCalibratedWhite:255.0/255.0 alpha:1.0];
    //NSColor *topColor = [NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    CFArrayInsertValueAtIndex(colors, 0, topColor.CGColor);
    NSColor *bottomColor = [NSColor colorWithCalibratedWhite:246.0/255.0 alpha:1.0];
    //NSColor *bottomColor = [NSColor colorWithCalibratedRed:0.0 green:1.0 blue:0.0 alpha:1.0];
    CFArrayInsertValueAtIndex(colors, 1, bottomColor.CGColor);
    
    CGFloat locations[] = {1.0, 0.0};
    
    CGGradientRef shadow = CGGradientCreateWithColors(colorSpace, colors, locations);
    CGContextDrawLinearGradient(context, shadow, CGPointMake(0, 0), CGPointMake(0, self.bounds.size.height), 0);
    
    CFRelease(colors);
    CFRelease(colorSpace);
    CFRelease(shadow);
    
    // draw top line
    const CGPoint topPoints[] = {
        CGPointMake(0, CGRectGetHeight(self.frame) + 1),
        CGPointMake(CGRectGetWidth(self.frame), CGRectGetHeight(self.frame) + 1)
    };
    [[NSColor colorWithCalibratedWhite:240.0/255.0 alpha:1.0] setStroke];
    CGContextStrokeLineSegments(context, topPoints, 1);
    CGContextRestoreGState(context);
}

@end
