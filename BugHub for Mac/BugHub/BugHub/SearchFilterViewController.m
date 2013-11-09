//
//  SearchFilterViewController.m
//  BugHub
//
//  Created by Randy on 1/26/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "SearchFilterViewController.h"
#import "BHIssueFilter.h"

@implementation SearchFilterViewController

- (void)setFilter:(BHIssueFilter *)filter
{
    _filter = filter;
    [searchField setStringValue:filter.text ? filter.text : @""];
}

- (IBAction)searchEnded:(id)sender
{
    [self.containingPopover performClose:nil];
}

- (void)awakeFromNib
{
    [searchField setStringValue:self.filter.text ? self.filter.text : @""];
}

- (void)controlTextDidChange:(NSNotification *)obj
{
    id sender = [obj object];
    [self.filter setText:[sender stringValue]];
}

@end
