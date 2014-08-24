//
//  NewRepoWindowController.h
//  BugHub
//
//  Created by Randy on 1/16/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NewRepoWindowController : NSWindowController<NSTextFieldDelegate, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property(strong) IBOutlet NSButton *openButton;
@property(strong) IBOutlet NSTextField *identifierField;
@property(strong) IBOutlet NSTableView *repoListView;
@property(strong) IBOutlet NSProgressIndicator *spinner;

- (IBAction)openRepo:(id)sender;
- (IBAction)closeWindow:(id)sender;

- (void)setDefaultUser:(NSString *)username;

@end


@class BHRepository;

@interface RepoTableCellView : NSTableCellView

@property(strong) BHRepository *representedRepo;

@end