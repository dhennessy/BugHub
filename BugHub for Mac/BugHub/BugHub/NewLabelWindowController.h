//
//  NewLabelWindowController.h
//  BugHub
//
//  Created by Randy on 3/23/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BHLabel, BHRepository;

@interface NewLabelWindowController : NSWindowController

@property(strong) IBOutlet NSTextField *nameField;
@property(strong) IBOutlet NSColorWell *colorWell;
@property(strong) IBOutlet NSProgressIndicator *spinner;

@property(strong) BHRepository *repo;
@property(strong) BHLabel *label;

- (IBAction)closeWindow:(id)sender;
- (IBAction)createLabel:(id)sender;


@end
