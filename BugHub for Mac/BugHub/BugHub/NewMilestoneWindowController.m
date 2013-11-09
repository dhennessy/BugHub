//
//  NewMilestoneWindowController.m
//  BugHub
//
//  Created by Randy on 3/12/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "NewMilestoneWindowController.h"
#import "BHMilestone.h"
#import "BHRepository.h"
#import "GHAPIRequest.h"

@interface NewMilestoneWindowController ()
{
    BOOL deadlineIsEnabled;
}
- (void)setLoading:(BOOL)aFlag;
@property(strong) GHAPIRequest *request;

@end

@implementation NewMilestoneWindowController

- (IBAction)cancel:(id)sender
{
    [NSApp endSheet:self.window returnCode:0];
    [self close];
}

- (IBAction)createMilestone:(id)sender
{
    if (self.request)
        return;
    
    if ([[self.titleField stringValue] length] == 0)
    {
        [self.window makeFirstResponder:self.titleField];
        NSBeep();
        return;
    }

    NSDate *deadline = nil;

    if (deadlineIsEnabled)
        deadline = [self.deadlinePicker dateValue];

    self.request = [GHAPIRequest requestForNewMilestone:[self.titleField stringValue] deadline:deadline description:[self.bodyField stringValue] repositoryIdentifier:[self.repo identifier]];

    __weak typeof(self) weakSelf = self;
    [weakSelf.request setCompletionBlock:^(GHAPIRequest *aRequest){
        [weakSelf setLoading:NO];
        weakSelf.request = nil;
        
        NSInteger statusCode = [aRequest responseStatusCode];
        NSData *responseData = [aRequest responseData];
        NSError *error = nil;
        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
        
        if (statusCode < 300 && statusCode > 199)
        {
            NSData *responseData = [aRequest responseData];
            NSError *error = nil;
            NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];

            weakSelf.milestone = [[BHMilestone alloc] init];
            [weakSelf.milestone setDictionaryValues:responseDict];
            [weakSelf.repo addMilestone:weakSelf.milestone];

            [NSApp endSheet:weakSelf.window returnCode:1];
            [weakSelf close];
        }
        else
        {
            NSLog(@"Milestone creation error: %@", responseDict);
            NSAlert *alert = [NSAlert alertWithMessageText:@"Unable to create milestone" defaultButton:@"Okay" alternateButton:nil otherButton:nil informativeTextWithFormat:@"BugHub was unable to create a milestone at this time. Please make sure you have premission to create milestones on this repository."];
            [alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(alertDidEnd:responseCode:context:) contextInfo:NULL];
        }
    }];

    [self.request sendRequest];
    [self setLoading:YES];
}

- (IBAction)toggleDeadline:(id)sender
{
    deadlineIsEnabled = !deadlineIsEnabled;

    [self.setDeadlineButton setHidden:deadlineIsEnabled];
    [self.clearDeadlineButton setHidden:!deadlineIsEnabled];
    [self.deadlinePicker setHidden:!deadlineIsEnabled];
}

- (void)setLoading:(BOOL)aFlag
{
    [self.titleField setEnabled:!aFlag];
    [self.bodyField setEnabled:!aFlag];
    [self.deadlinePicker setEnabled:!aFlag];
    [self.setDeadlineButton setEnabled:!aFlag];
    [self.clearDeadlineButton setEnabled:!aFlag];
    [self.submitButton setEnabled:!aFlag];
    [self.cancelButton setEnabled:!aFlag];

    if (aFlag)
        [self.spinner startAnimation:nil];
    else
        [self.spinner stopAnimation:nil];
}


#pragma mark alert stuff
- (void)alertDidEnd:(NSAlert *)anAlert responseCode:(NSInteger)aCode context:(void *)someContextStuffs
{
    // I really dont think we care what happens in here.
}

@end
