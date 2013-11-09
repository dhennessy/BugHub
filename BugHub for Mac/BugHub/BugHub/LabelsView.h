//
//  LabelsView.h
//  BugHub
//
//  Created by Randy on 3/5/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BHLabel;

@interface LabelsView : NSControl

- (void)setLabels:(NSArray *)newLabels;
- (void)removeLabel:(BHLabel *)aLabel;
- (void)addNewLabel:(BHLabel *)newLabel;

@end


@interface LabelToken : NSView
{
    NSTextField *nameField;
}
- (id)initWithLabel:(BHLabel *)aLabel;
- (BOOL)representsLabel:(BHLabel *)aLabel;
@end
