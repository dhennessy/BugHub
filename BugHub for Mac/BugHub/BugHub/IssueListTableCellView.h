//
//  IssueListCellView.h
//  BugHub
//
//  Created by Randy on 12/30/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface IssueListTableCellView : NSTableCellView

@property(strong) IBOutlet NSTextField *titleField;
@property(strong) IBOutlet NSImageView *avatarView;
@property(strong) IBOutlet NSTextField *userField;
@property(strong) IBOutlet NSTextField *dateField;

@end
