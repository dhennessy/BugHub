//
//  NewRepoWindowController.m
//  BugHub
//
//  Created by Randy on 1/16/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "NewRepoWindowController.h"
#import "BHRepository.h"
#import "AppDelegate.h"
#import "BHUser.h"
#import "GHAPIRequest.h"

@interface NewRepoWindowController ()
{
    NSString *currentlyRequestingUser;
    NSString *_defaultUser;
    GHAPIRequest *_loadRequest;
    GHAPIRequest *_orgLoadRequest;
    NSMutableOrderedSet *_loadedRepos;
    NSMutableArray *_filteredRepos;
}

@property(strong) GHAPIRequest *request;
- (void)loadRepos:(NSString *)aUsername;
- (void)_addNewRepos:(NSArray *)newRepos;
- (void)filterRepos;
- (void)moveDownFromTextField;
@end

@implementation NewRepoWindowController

- (void)awakeFromNib
{
    [self.repoListView setTarget:self];
    [self.repoListView setDoubleAction:@selector(openRepo:)];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    _loadedRepos = [NSMutableOrderedSet orderedSetWithCapacity:10];
    _filteredRepos = [NSMutableArray arrayWithCapacity:10];
    
    NSString *authenticatedUser;
    
    if (_defaultUser)
        authenticatedUser = _defaultUser;
    else
         authenticatedUser = [GHAPIRequest authenticatedUserLogin];

    if (!authenticatedUser)
        return;

    [self.identifierField setStringValue:[NSString stringWithFormat:@"%@/", authenticatedUser]];
    [self loadRepos:authenticatedUser];
}

- (void)dealloc
{
    [_request removeObserver:self forKeyPath:@"status"];
    [_orgLoadRequest removeObserver:self forKeyPath:@"status"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"status"])
    {
        if ([_request status] == GHAPIRequestStatusLoading || [_orgLoadRequest status] == GHAPIRequestStatusLoading)
            [self.spinner startAnimation:nil];
        else
            [self.spinner stopAnimation:nil];
    }
}

- (void)moveDownFromTextField
{
    [self.window makeFirstResponder:self.repoListView];
    [self.repoListView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
}

- (void)setDefaultUser:(NSString *)username
{
    _defaultUser = [username copy];
    //NSString *reposAddress = [aDict objectForKey:@"repos_url"];
    //NSString *orgsAddress = [aDict objectForKey:@"organizations_url"];
    [self loadRepos:username];
}

- (void)_addNewRepos:(NSArray *)newRepos
{
    [_loadedRepos addObjectsFromArray:newRepos];
    [self filterRepos];
}

- (void)filterRepos
{
    NSString *searchstring = [[self.identifierField stringValue] lowercaseString];
    
    /*NSRange rangeOfSlash = [searchstring rangeOfString:@"/"];
    NSInteger indexOfSlash = -1;

    if (rangeOfSlash.length > 0)
        indexOfSlash = rangeOfSlash.location;
    
    NSString *usernameSearchString = searchstring;

    if (indexOfSlash != -1)
        usernameSearchString = [searchstring substringToIndex:indexOfSlash];*/

    [_filteredRepos removeAllObjects];
    
    for (BHRepository *aRepo in _loadedRepos)
    {
        NSString *identifier = [[aRepo identifier] lowercaseString];
        if ([identifier hasPrefix:searchstring])
            [_filteredRepos addObject:aRepo];
        /*else if(usernameSearchString)
        {
            NSSet *assignees = [aRepo assignees];
            
            for (BHUser *aUser in assignees)
            {
                if ([[[aUser login] lowercaseString] hasPrefix:usernameSearchString])
                    [_filteredRepos addObject:aRepo];
            }
        }*/
    }
    
    [self.repoListView reloadData];
}

- (void)loadRepos:(NSString *)aUsername
{
    if ([currentlyRequestingUser isEqualToString:aUsername])
        return;
    
    currentlyRequestingUser = aUsername;
    [_request removeObserver:self forKeyPath:@"status"];
    [_orgLoadRequest removeObserver:self forKeyPath:@"status"];
    _request = [GHAPIRequest requestForUsersRepositories:aUsername];
    [_request addObserver:self forKeyPath:@"status" options:0 context:NULL];

    __weak typeof(self) welf = self;
    
    [_request setCompletionBlock:^(GHAPIRequest *aRequest){
        NSInteger statusCode = [aRequest responseStatusCode];
        NSData *responseData = [aRequest responseData];
        if (responseData == nil) {
            return;
        }
        NSError *error = nil;
        NSArray *responseArray = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];

        if (error || statusCode > 299 || statusCode < 199 || ![responseArray isKindOfClass:[NSArray class]])
        {
            // user not found :(
            return;
        }

        NSMutableArray *newRepos = [NSMutableArray arrayWithCapacity:[responseArray count]];
        for (NSDictionary *aRepoDict in responseArray)
        {
            if (![[aRepoDict objectForKey:@"has_issues"] boolValue])
                continue;

            BHRepository *newRepo = [BHRepository repositoryWithIdentifier:[aRepoDict objectForKey:@"full_name"] dictionaryValues:aRepoDict];

            if ([[newRepo name] isEqualToString:@"BugHub"])
                NSLog(@"");

            [newRepos addObject:newRepo];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [welf _addNewRepos:newRepos];
        });
    }];
    
    [_request sendRequest];
    
    
    _orgLoadRequest = [GHAPIRequest requestForOrgsRepositories:aUsername];
    [_orgLoadRequest addObserver:self forKeyPath:@"status" options:0 context:NULL];
    
    
    [_orgLoadRequest setCompletionBlock:^(GHAPIRequest *aRequest){
        NSInteger statusCode = [aRequest responseStatusCode];
        NSData *responseData = [aRequest responseData];
        if (responseData == nil) {
            return;
        }
        NSError *error = nil;
        NSArray *responseArray = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
        
        if (error || statusCode > 299 || statusCode < 199 || ![responseArray isKindOfClass:[NSArray class]])
        {
            // user not found :(
            return;
        }
        
        NSMutableArray *newRepos = [NSMutableArray arrayWithCapacity:[responseArray count]];
        for (NSDictionary *aRepoDict in responseArray)
        {
            if (![[aRepoDict objectForKey:@"has_issues"] boolValue])
                continue;
            
            BHRepository *newRepo = [BHRepository repositoryWithIdentifier:[aRepoDict objectForKey:@"full_name"] dictionaryValues:aRepoDict];
            
            if ([[newRepo name] isEqualToString:@"BugHub"])
                NSLog(@"");
            
            [newRepos addObject:newRepo];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [welf _addNewRepos:newRepos];
        });
    }];
    
    [_orgLoadRequest sendRequest];
    
}

- (void)controlTextDidChange:(NSNotification *)obj
{
    if ([obj object] != self.identifierField)
        return;
    
    NSString *text = [self.identifierField stringValue];
    BOOL isValidID = [BHRepository isValidIdentifier:text];
    
    NSInteger indexOfSlash = [text rangeOfString:@"/"].location;
    
    if (indexOfSlash == NSNotFound)
        return;
    
    [self loadRepos:[text substringToIndex:indexOfSlash]];
    [self filterRepos];
    
    [self.openButton setEnabled:isValidID];
}

- (IBAction)closeWindow:(id)sender
{
    [self close]; //calls windowWillClose
}

- (void)windowWillClose:(NSNotification *)notification
{
    [(AppDelegate *)[NSApp delegate] windowControllerDidClose:self];
}

- (IBAction)openRepo:(id)sender
{
    if (sender == self.repoListView)
    {
        NSInteger clickedRow = [self.repoListView clickedRow];
        
        if (clickedRow == NSNotFound)
            return;

        [(AppDelegate *)[NSApp delegate] openRepoWindow:[[_filteredRepos objectAtIndex:clickedRow] identifier]];
        [self closeWindow:nil];
        return;
    }
    
    NSString *text = [self.identifierField stringValue];
    BOOL isValidID = [BHRepository isValidIdentifier:text];
    
    if (!isValidID)
        return;

    [(AppDelegate *)[NSApp delegate] openRepoWindow:text];
    [self closeWindow:nil];
}

- (void)showWindow:(id)sender
{
    [self.window center];
    [super showWindow:sender];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [_filteredRepos count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    RepoTableCellView *cell = [tableView makeViewWithIdentifier:@"BHRepoView" owner:self];
    
    BHRepository *repo = [_filteredRepos objectAtIndex:row];
    [cell setRepresentedRepo:repo];
    [cell setBackgroundStyle:[cell backgroundStyle]]; // force redisplay
    
    return cell;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSInteger selectedRowIndex = [self.repoListView selectedRow];
    
    [self.openButton setEnabled:selectedRowIndex != NSNotFound];
    
    if (selectedRowIndex == NSNotFound)
        return;
    
    BHRepository *selectedRepo = [_filteredRepos objectAtIndex:selectedRowIndex];
    [self.identifierField setStringValue:[selectedRepo identifier]];
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)commandSelector
{
    if(commandSelector == @selector(moveDown:))
    {
        [self moveDownFromTextField];
        return YES;
    }

    return NO;
}
@end


@implementation RepoTableCellView

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
    [super setBackgroundStyle:backgroundStyle];

    BOOL isSelected = backgroundStyle == NSBackgroundStyleDark;

    if (isSelected)
        [[self imageView] setImage:[self.representedRepo isPrivate] ? [NSImage imageNamed:@"repo_tab_lock_selected"] : [NSImage imageNamed:@"repo_icon_small_selected"]];
    else
        [[self imageView] setImage:[self.representedRepo isPrivate] ? [NSImage imageNamed:@"repo_tab_lock"] : [NSImage imageNamed:@"repo_icon_small"]];

    [[self textField] setStringValue:[self.representedRepo identifier]];
}

@end
