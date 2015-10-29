//
//  NewIssueWindowController.m
//  BugHub
//
//  Created by Randy on 1/5/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "NewIssueWindowController.h"
#import "BHRepository.h"
#import "BHIssue.h"
#import "BHLabel.h"
#import "BHMilestone.h"
#import "BHUser.h"
#import "GHAPIRequest.h"
#import "NewMilestoneWindowController.h"
#import "NewLabelWindowController.h"

const NSInteger kCloseContext = 0;
const NSInteger kSaveContext = 1;
const NSInteger kErrorContext = 2;


@interface NewIssueWindowController ()
{
    NewMilestoneWindowController *milestoneCreationController;
    NewLabelWindowController *labelCreationController;
    NSMutableSet *_newLabelsRequestObjects;
}

- (void)saveIssue;
- (void)showUpdateError;
- (void)_requestWasSuccessfulWithResponseDict:(NSDictionary *)aResponseDict;
- (void)generateNewMenus;
- (void)toggleLabel:(NSMenuItem *)anItem;
- (void)createNewMilestone:(NSMenuItem *)anItem;
- (void)createNewLabel:(NSMenuItem *)anItem;
- (void)_createBareBonesLabelWithName:(NSString *)aName;
- (void)setLoading:(BOOL)aFlag;

@property(strong) GHAPIRequest *request;

@end

@implementation NewIssueWindowController

- (void)dealloc
{
    [self.repository removeObserver:self forKeyPath:@"assignees"];
    [self.repository removeObserver:self forKeyPath:@"milestones"];
}

- (id)initWithRepository:(BHRepository *)aRepo
{
    BHUser *loggedinUser = [BHUser userWithLogin:[GHAPIRequest authenticatedUserLogin] dictionaryValues:nil];
    BHPermissionType permissions = [aRepo permissionsForUser:loggedinUser];
    
    self = [self initWithWindowNibName:permissions == BHPermissionReadWrite ? @"NewIssueWindowController" : @"NewIssueLimitedWindowController"];

    if (self)
    {
        self.repository = aRepo;
        _newLabelsRequestObjects = [NSMutableSet setWithCapacity:1];
        [aRepo addObserver:self forKeyPath:@"assignees" options:0 context:NULL];
        [aRepo addObserver:self forKeyPath:@"milestones" options:0 context:NULL];
        
        self.request = nil;
    }

    return self;
}

- (id)initWithIssue:(BHIssue *)anIssue
{
    self = [self initWithRepository:[anIssue repository]];
    
    if (self)
    {
        self.issue = anIssue;
        [self generateNewMenus];
    }
    
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"assignees"] || [keyPath isEqualToString:@"milestones"])
        [self generateNewMenus];
}

- (BOOL)windowShouldClose:(id)sender
{
    [self cancelButtonPushed:self];
    return NO;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.

    if (!self.repository)
    {
        NSLog(@"Some idiot loaded the widnow controller without setting a repo.");
    }

    if (self.issue)
    {
        [self.titleField setStringValue:[self.issue title]];
        [self.bodyField setString:[self.issue rawBody]];
        [self.saveButton setTitle:NSLocalizedString(@"Update Issue", nil)];
        [self.window setTitle:[NSString stringWithFormat:@"Update Issue # %ld For: %@", [self.issue number], [self.repository identifier]]];
    }
    else
    {
        [self.saveButton setTitle:NSLocalizedString(@"Create Issue", nil)];
        [self.window setTitle:[NSString stringWithFormat:@"New Issue For: %@", [self.repository identifier]]];
    }

    

    [self generateNewMenus];
}

- (void)generateNewMenus
{
    // create menus for milestone and assignee buttons
    NSMenu *assigneeMenu = [self.assigneeButton menu];
    [assigneeMenu removeAllItems];
    NSSet *allAssignees = [self.repository assignees];

    NSMenuItem *blankItem = [[NSMenuItem alloc] initWithTitle:@"None" action:nil keyEquivalent:@""];
    [assigneeMenu addItem:blankItem];

    for (BHUser *aUser in allAssignees)
    {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[aUser login] action:nil keyEquivalent:@""];
        [assigneeMenu addItem:item];
    }

    // MILESTONE
    NSMenu *milestoneMenu = [self.milestoneButton menu];
    [milestoneMenu removeAllItems];
    NSSet *allMilestones = [self.repository milestones];

    NSMenuItem *blankItem2 = [[NSMenuItem alloc] initWithTitle:@"None" action:nil keyEquivalent:@""];
    [milestoneMenu addItem:blankItem2];

    for (BHMilestone *aMilestone in allMilestones)
    {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[aMilestone name] action:nil keyEquivalent:@""];
        [milestoneMenu addItem:item];
    }

    [milestoneMenu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *createMilestoneItem = [[NSMenuItem alloc] initWithTitle:@"Create New Milestone" action:@selector(createNewMilestone:) keyEquivalent:@""];
    [milestoneMenu addItem:createMilestoneItem];

    if (self.issue)
    {
        [self.titleField setStringValue:[self.issue title]];
        [self.bodyField setString:[self.issue rawBody]];

        NSMutableArray *currentLabels = [NSMutableArray array];

        [[self.issue labels] enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            [currentLabels addObject:[obj name]];
        }];

        [self.labelsField setObjectValue:currentLabels];

        if (self.issue.assignee)
            [self.assigneeButton selectItemWithTitle:[[self.issue assignee] login]];
        
        if (self.issue.milestone)
            [self.milestoneButton selectItemWithTitle:[[self.issue milestone] name]];
    }
}

- (IBAction)submitButtonPushed:(id)sender
{
    if ([[self.titleField stringValue] length] == 0)
    {
        [self.window makeFirstResponder:self.titleField];
        NSBeep();
        return;
    }
    
    [self saveIssue];
}

- (IBAction)cancelButtonPushed:(id)sender
{
    if (![[self.titleField stringValue] length] && ![[self.bodyField string] length])
    {
        [self close];
        [self.retainSetThingBecauseMenoryManagementSucks removeObject:self];
        return;
    }
    
    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Are You Sure?", nil)
                                     defaultButton:NSLocalizedString(@"Cancel", nil)
                                   alternateButton:NSLocalizedString(@"Close Window", nil)
                                       otherButton:nil
                         informativeTextWithFormat:NSLocalizedString(@"This issue will not be saved. Are you sure you want to close this window?", nil), nil];
    
    [alert beginSheetModalForWindow:self.window
                      modalDelegate:self
                     didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                        contextInfo:(void *)&kCloseContext];
}

- (IBAction)listLabels:(id)sender
{
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Labels"];

    NSArray *currentTokens = [self.labelsField objectValue];
    NSSet *allLabels = [self.repository labels];
    
    for (BHLabel *aLabel in allLabels)
    {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[aLabel name] action:@selector(toggleLabel:) keyEquivalent:@""];
        [item setTarget:self];
        BOOL containsLabelAlready = [currentTokens containsObject:[aLabel name]];
        [item setState:containsLabelAlready ? NSOnState : NSOffState];
        
        NSImage *image = [NSImage imageWithSize:CGSizeMake(12, 12) flipped:YES drawingHandler:^BOOL(NSRect dstRect) {
            CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
            
            [[NSColor blackColor] setStroke];
            [[aLabel color] setFill];
            
            CGContextFillEllipseInRect(context, dstRect);
            CGContextStrokeEllipseInRect(context, CGRectInset(dstRect, .5, .5));
            
            return YES;
        }];
        
        [item setImage:image];
        [menu addItem:item];
    }
    NSMenuItem *newLabel = [[NSMenuItem alloc] initWithTitle:@"New Label" action:@selector(createNewLabel:) keyEquivalent:@""];
    [newLabel setTarget:self];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:newLabel];

    [menu popUpMenuPositioningItem:nil atLocation:CGPointZero inView:sender];
}

- (void)toggleLabel:(NSMenuItem *)anItem
{
    NSString *title = [anItem title];
    NSMutableArray *currentTokens = [[self.labelsField objectValue] mutableCopy];
    
    if (anItem.state == NSOnState) // remove the label
        [currentTokens removeObject:title];
    else // add it
        [currentTokens addObject:title];
    
    [self.labelsField setObjectValue:currentTokens];
}

- (NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring indexOfToken:(NSInteger)tokenIndex indexOfSelectedItem:(NSInteger *)selectedIndex
{
    substring = [substring lowercaseString];
    NSSet *allLabels = [self.repository labels];
    NSMutableArray *labelsToSuggest = [NSMutableArray arrayWithCapacity:[allLabels count]];
    NSArray *currentTokens = [tokenField objectValue];
    
    for (BHLabel *aLabel in allLabels)
    {
        // FIX ME: this probably doesnt work with upper/lower case fuck ups
        if (![currentTokens containsObject:[aLabel name]] && [[[aLabel name] lowercaseString] hasPrefix:substring])
            [labelsToSuggest addObject:[aLabel name]];
    }
    
    return labelsToSuggest;
}

- (NSArray *)tokenField:(NSTokenField *)tokenField shouldAddObjects:(NSArray *)tokens atIndex:(NSUInteger)index
{
    NSSet *allLabels = [self.repository labels];
    NSArray *currentTokens = [tokenField objectValue];
    NSMutableArray *currentTokenNames = [NSMutableArray arrayWithCapacity:currentTokens.count];
    
    for (NSString *someLabel in currentTokens)
        [currentTokenNames addObject:[someLabel lowercaseString]];

    NSMutableArray *labelsToAddToIssue = [NSMutableArray arrayWithCapacity:tokens.count];
    NSMutableArray *labelsThatMightGetAddedToRepo = [NSMutableArray arrayWithCapacity:1];
    
    // decide which array to add the new label(s) to.
    for (NSString *aToken in tokens)
    {
        NSString *lowecaseString = [aToken lowercaseString];
        
        // if the token already exists in the token field, ignore is
        //if ([currentTokenNames containsObject:aToken])
        //    continue;
        
        // Figure out if the label actually exists in the repo already
        // because case sensativeity we need loop over all the tokens :(
        NSSet *matchingObject = [allLabels objectsPassingTest:^BOOL(BHLabel *aLabel, BOOL *stop) {
            if ([[[aLabel name] lowercaseString] isEqualToString:lowecaseString])
            {
                *stop = YES;
                return YES;
            }
            return NO;
        }];
        
        // if the label exits in the repo, just add it to the token field, otherwise we gonna prompt da user.
        BHLabel *matchingLabel = [matchingObject anyObject]; // count will always be 1 or 0
        if (matchingLabel)
            [labelsToAddToIssue addObject:[matchingLabel name]];
        else
            [labelsThatMightGetAddedToRepo addObject:aToken];
    }
    
    // seee... PROMPTS!
    NSAlert *alert = nil;
    if (labelsThatMightGetAddedToRepo.count == 1)
        alert = [NSAlert alertWithMessageText:@"Unknown Label Entered" defaultButton:@"Add Label" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"The label '%@' was not found in the '%@' repository, would you like to create it?", [labelsThatMightGetAddedToRepo objectAtIndex:0], self.repository.identifier];
    else if (labelsThatMightGetAddedToRepo.count > 2)
        alert = [NSAlert alertWithMessageText:@"Unknown Labels Entered" defaultButton:@"Add Labels" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"The labels '%@' were not found in the '%@' repository, would you like to create them?", [labelsThatMightGetAddedToRepo componentsJoinedByString:@"', '"], self.repository.identifier];

    if (alert)
    {
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:self.window
                          modalDelegate:self
                         didEndSelector:@selector(addLabelsSheetDidEnd:returnCode:contextInfo:)
                            contextInfo:(__bridge_retained void *)labelsThatMightGetAddedToRepo];
    }
    
    return labelsToAddToIssue;
}

- (void)createNewMilestone:(NSMenuItem *)anItem
{
    milestoneCreationController = [[NewMilestoneWindowController alloc] initWithWindowNibName:@"NewMilestoneWindowController"];
    [milestoneCreationController setRepo:self.repository];
    [NSApp beginSheet:milestoneCreationController.window modalForWindow:self.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
    [self.milestoneButton selectItemAtIndex:0];
}

- (void)createNewLabel:(NSMenuItem *)anItem
{
    labelCreationController = [[NewLabelWindowController alloc] initWithWindowNibName:@"NewLabelWindowController"];
    [labelCreationController setRepo:self.repository];
    [NSApp beginSheet:labelCreationController.window modalForWindow:self.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

/*
 FIX ME: this code makes me sad... this shit should just be done in the models and stuff.
 */
- (void)_createBareBonesLabelWithName:(NSString *)aName
{
    GHAPIRequest *newRequest = [GHAPIRequest requestForNewLabel:aName color:nil repositoryIdentifier:[self.repository identifier]];
    
    __weak typeof(self) welf = self;
    
    [newRequest setCompletionBlock:^(GHAPIRequest *aRequest){
        // recapture welf, brah..
        __strong typeof(welf) strongSelf = welf;
        NSInteger statusCode = [aRequest responseStatusCode];
        NSData *responseData  = [aRequest responseData];
        NSError *error = nil;
        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
        
        if (statusCode < 200 || statusCode > 299 || error || ![responseDict isKindOfClass:[NSDictionary class]])
        {
            // something fucked up.
            // remove the label name from the token field
            // alert the user.
            // cry a bit inside.
            NSMutableArray *tokens = [[welf.labelsField objectValue] mutableCopy];
            [tokens removeObject:aName];
            [welf.labelsField setObjectValue:tokens];

            return;
        }

        BHLabel *newLabel = [[BHLabel alloc] init];
        [newLabel setDictionaryValues:responseDict];
        [welf.repository addLabel:newLabel];

        if (strongSelf)
            [strongSelf->_newLabelsRequestObjects removeObject:aRequest];
    }];
    
    [_newLabelsRequestObjects addObject:newRequest];
    [newRequest sendRequest];
}

- (void)saveIssue
{
    NSInteger mask = ~NSClosableWindowMask & [[self window] styleMask];
    [[self window] setStyleMask:mask];
    
    BHMilestone *milestone = nil;
    NSArray *labels = nil;
    NSString *assigneeLogin = nil;
    
    if ([self.milestoneButton indexOfSelectedItem] != 0) // 0 === none
    {
        NSString *titleOfMilestone = [self.milestoneButton titleOfSelectedItem];
        NSSet *allMilestones = [self.repository milestones];
        milestone = [[allMilestones objectsPassingTest:^BOOL(BHMilestone *obj, BOOL *stop) {
            if ([[obj name] isEqualToString:titleOfMilestone])
            {
                *stop = YES;
                return YES;
            }
            return NO;
        }] anyObject];
    }
    
    if ([self.assigneeButton indexOfSelectedItem] != 0)
        assigneeLogin = [self.assigneeButton titleOfSelectedItem];
    
    if ([[self.labelsField objectValue] count] != 0)
        labels = [self.labelsField objectValue];
    
    NSMutableDictionary *updates = [NSMutableDictionary dictionaryWithDictionary:@{
        @"title": [self.titleField stringValue],
        @"body": [self.bodyField string],
        @"milestone": milestone == nil ? [NSNull null] : @(milestone.number), // milestone number
        @"labels": labels == nil ? @[] : labels, // label names array
        @"assignee": assigneeLogin == nil ? [NSNull null] : assigneeLogin // assignee login
    }];

    [self setLoading:YES];
    
    if (self.issue)
    {
        // update the existing issue
        GHAPIRequest *request = [GHAPIRequest requestForIssueUpdate:[self.issue number]
                                               repositoryIdentifier:[[self.issue repository] identifier]
                                                            updates:updates];
        
        [request setCompletionBlock:^(GHAPIRequest *aRequest){
            if (aRequest.status == GHAPIRequestStatusComplete)
            {
                NSInteger statusCode = [aRequest responseStatusCode];

                if (statusCode < 200 || statusCode > 299)
                {
                    NSLog(@"Error with issue update: %@", [[NSString alloc] initWithData:aRequest.responseData encoding:NSUTF8StringEncoding]);
                    [self showUpdateError];
                    return;
                }

                NSError *error = nil;
                NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:[aRequest responseData]
                                                                             options:0
                                                                               error:&error];
                
                if (error || ![responseDict isKindOfClass:[NSDictionary class]])
                {
                    NSLog(@"Error parsing response dict, %@", error);
                    [self showUpdateError];
                    return;
                }
                
                [self _requestWasSuccessfulWithResponseDict:responseDict];
            }
        }];
        
        self.request = request;
    }
    else
    {
        // create a new issue
        GHAPIRequest *request = [GHAPIRequest requestForNewIssue:updates forRepositoryIdentifier:[self.repository identifier]];

        [request setCompletionBlock:^(GHAPIRequest *aRequest){
            if (aRequest.status == GHAPIRequestStatusComplete)
            {
                NSInteger statusCode = [aRequest responseStatusCode];
                
                if (statusCode < 200 || statusCode > 299)
                {
                    NSLog(@"Error with issue update: %@", self.issue);
                    [self showUpdateError];
                    return;
                }
                
                NSError *error = nil;
                NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:[aRequest responseData]
                                                                             options:0
                                                                               error:&error];
                
                if (error || ![responseDict isKindOfClass:[NSDictionary class]])
                {
                    NSLog(@"Error parsing response dict, %@", error);
                    [self showUpdateError];
                    return;
                }
                
                [self _requestWasSuccessfulWithResponseDict:responseDict];
            }
        }];
        
        self.request = request;
    }
    [self.request sendRequest];
}

- (void)_requestWasSuccessfulWithResponseDict:(NSDictionary *)aResponseDict
{
    self.request = nil;
    NSInteger mask = NSClosableWindowMask | [[self window] styleMask];
    [[self window] setStyleMask:mask];
    
    if (self.issue)
    {
        [self.issue setDictValues:aResponseDict];
    }
    else
    {
        BHIssue *newIssue = [[BHIssue alloc] init];
        [newIssue setRepository:self.repository];
        [newIssue setDictValues:aResponseDict];
        [self.repository addNewIssue:newIssue];
    }

    [self setLoading:NO];
    [self close];
}


- (void)setLoading:(BOOL)aFlag
{
    if (aFlag)
        [self.spinner startAnimation:nil];
    else
        [self.spinner stopAnimation:nil];
    
    [self.titleField setEnabled:!aFlag];
    [self.labelListButton setEnabled:!aFlag];
    [self.labelsField setEnabled:!aFlag];
    [self.assigneeButton setEnabled:!aFlag];
    [self.milestoneButton setEnabled:!aFlag];
    [self.bodyField setEditable:!aFlag];
    [self.saveButton setEnabled:!aFlag];
}

- (void)showUpdateError
{
    self.request = nil;
    [self setLoading:NO];
    NSInteger mask = NSClosableWindowMask | [[self window] styleMask];
    [[self window] setStyleMask:mask];
    
    NSString *titleString = nil;
    NSString *detailString = nil;
    
    if (self.issue)
    {
        titleString = NSLocalizedString(@"Unable to Update Issue", nil);
        detailString = NSLocalizedString(@"There was an error communicating with GitHub, the issue could not be updated.", nil);
    }
    else
    {
        titleString = NSLocalizedString(@"Unable to Create New Issue", nil);
        detailString = NSLocalizedString(@"There was an error communicating with GitHub, the issue could not be saved.", nil);
    }
    
    NSAlert *alert = [NSAlert alertWithMessageText:titleString
                                   defaultButton:NSLocalizedString(@"Try Again", nil)
                                 alternateButton:NSLocalizedString(@"Cancel", nil)
                                     otherButton:nil
                       informativeTextWithFormat:detailString, nil];
    
    [alert beginSheetModalForWindow:self.window
                      modalDelegate:self
                     didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                        contextInfo:(void *)&kErrorContext];
}

- (void)addLabelsSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    NSArray *context = (__bridge_transfer NSArray *)contextInfo;
    
    if (returnCode == 0)
    {
        // DONT ADD IT, BROOOO!
        return;
    }
    else
    {
        NSMutableArray *currentTokens = [[self.labelsField objectValue] mutableCopy];
        // add the new labels...
        // nifty thing here, since we won't let the user change the color of the label (yet, at least)
        // we can just go ahead and create dummy labels
        for (NSString *aNewLabelName in context)
        {
            [self _createBareBonesLabelWithName:aNewLabelName];
            [currentTokens addObject:aNewLabelName];
        }
        
        [self.labelsField setObjectValue:currentTokens];
    }
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == 0)
        return;

    if (sheet == milestoneCreationController.window)
    {
        BHMilestone *newMilestone = [milestoneCreationController milestone];
        [self generateNewMenus];
        [self.milestoneButton selectItemWithTitle:[newMilestone name]];
    }
    else if (sheet == labelCreationController.window)
    {
        BHLabel *newLabel = [labelCreationController label];
        NSMutableArray *allLabels = [[self.labelsField objectValue] mutableCopy];
        [allLabels addObject:[newLabel name]];
        [self.labelsField setObjectValue:allLabels];
    }
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    NSInteger context = *(NSInteger *)contextInfo;

    switch (context) {
        case kCloseContext:
            if (returnCode == 0)
            {
                [self close];
                [self.retainSetThingBecauseMenoryManagementSucks removeObject:self];
            }
            break;

        case kErrorContext:
            if (returnCode == 1)
                [self saveIssue];
            break;
    }
}

@end
