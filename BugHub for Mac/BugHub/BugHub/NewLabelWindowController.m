//
//  NewLabelWindowController.m
//  BugHub
//
//  Created by Randy on 3/23/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "NewLabelWindowController.h"
#import "GHAPIRequest.h"
#import "NSColor+hex.h"
#import "BHRepository.h"
#import "BHLabel.h"

@interface NewLabelWindowController ()
{
    GHAPIRequest *_request;
}

- (void)setLoading:(BOOL)aFlag;
@end

@implementation NewLabelWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)closeWindow:(id)sender
{
    [NSApp endSheet:self.window returnCode:0];
    [self close];
}

- (IBAction)createLabel:(id)sender
{
    if ([[self.nameField stringValue] length] == 0)
    {
        NSBeep();
        [self.window makeFirstResponder:self.nameField];
        return;
    }
    
    __weak typeof(self) welf = self;

    _request = [GHAPIRequest requestForNewLabel:[self.nameField stringValue] color:[self.colorWell color] repositoryIdentifier:[self.repo identifier]];
    [_request setCompletionBlock:^(GHAPIRequest *aRequest){
        [welf setLoading:NO];
        
        __strong typeof(welf) strongSelf = welf;
        if (welf)
            strongSelf->_request = nil;
        
        NSInteger statusCode = [aRequest responseStatusCode];
        NSData *responseData = [aRequest responseData];
        NSError *error = nil;
        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
        
        if (statusCode < 300 && statusCode > 199)
        {
            NSData *responseData = [aRequest responseData];
            NSError *error = nil;
            NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
            
            welf.label = [[BHLabel alloc] init];
            [welf.label setDictionaryValues:responseDict];
            [welf.repo addLabel:welf.label];

            [NSApp endSheet:welf.window returnCode:1];
            [welf close];
        }
        else
        {
            NSLog(@"Label creation error: %@", responseDict);
            NSAlert *alert = [NSAlert alertWithMessageText:@"Unable to create label" defaultButton:@"Okay" alternateButton:nil otherButton:nil informativeTextWithFormat:@"BugHub was unable to create a label at this time. Please make sure you have premission to create labels on this repository."];
            [alert beginSheetModalForWindow:welf.window modalDelegate:welf didEndSelector:@selector(alertDidEnd:responseCode:context:) contextInfo:NULL];
        }
    }];
    
    [self setLoading:YES];
    [_request sendRequest];
}

- (void)setLoading:(BOOL)aFlag
{
    if (aFlag)
        [self.spinner startAnimation:nil];
    else
        [self.spinner stopAnimation:nil];
}

- (void)alertDidEnd:(NSAlert *)anAlert responseCode:(NSInteger)aCodez context:(void *)someContextYo
{
    // I really don't fucking care what the user did... something fucked up and there's nothing we can do about it.
    // :'( about it.
}

@end
