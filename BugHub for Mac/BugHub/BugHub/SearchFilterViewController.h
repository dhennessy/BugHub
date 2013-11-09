//
//  SearchFilterViewController.h
//  BugHub
//
//  Created by Randy on 1/26/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BHIssueFilter;

@interface SearchFilterViewController : NSViewController<NSTextFieldDelegate>
{
    IBOutlet NSSearchField *searchField;
}

@property(strong, nonatomic) BHIssueFilter *filter;
@property(weak) NSPopover *containingPopover;

- (IBAction)searchEnded:(id)sender;

@end
