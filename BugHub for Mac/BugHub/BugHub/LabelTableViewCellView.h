//
//  LabelTableViewCellView.h
//  BugHub
//
//  Created by Randy on 1/24/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BHLabel;

@interface LabelTableViewCellView : NSTableCellView

- (void)setRepresentedLabel:(BHLabel *)aLabel;

@end
