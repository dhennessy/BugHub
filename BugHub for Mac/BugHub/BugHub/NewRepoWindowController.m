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
    NSDictionary *_defaultUser;
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
        authenticatedUser = [_defaultUser objectForKey:@"login"];
    else
         authenticatedUser = [GHAPIRequest authenticatedUserLogin];

    if (!authenticatedUser)
        return;
    
    NSString* lastUsedUsername = [self usernameFromRepoIdentifier:[self lastOpenedRepository]];
    NSString* userToBeUsed = lastUsedUsername ? lastUsedUsername : authenticatedUser;
    
    [self.identifierField setStringValue:[NSString stringWithFormat:@"%@/", userToBeUsed]];
    [self loadRepos:userToBeUsed];
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

- (void)setDefaultUser:(NSDictionary *)aDict
{
    _defaultUser = aDict;
    //NSString *reposAddress = [aDict objectForKey:@"repos_url"];
    //NSString *orgsAddress = [aDict objectForKey:@"organizations_url"];
    [self loadRepos:[aDict objectForKey:@"login"]];
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

-(NSString*)usernameFromRepoIdentifier:(NSString*)repoIdentifier
{
    NSInteger indexOfSlash = [repoIdentifier rangeOfString:@"/"].location;
    
    if (indexOfSlash == NSNotFound)
        return nil;
    
    return [repoIdentifier substringToIndex:indexOfSlash];
}

- (void)controlTextDidChange:(NSNotification *)obj
{
    if ([obj object] != self.identifierField)
        return;
    
    NSString *text = [self.identifierField stringValue];
    BOOL isValidID = [BHRepository isValidIdentifier:text];
    
    NSString* username = [self usernameFromRepoIdentifier:text];
    
    if (!username)
        return;
    
    [self loadRepos:username];
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

-(NSString*)lastOpenedRepository
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"lastOpenedRepository"];
}

-(BOOL)rememberLastOpenedRepository:(NSString*)repositoryName
{
    [[NSUserDefaults standardUserDefaults]setObject:repositoryName forKey:@"lastOpenedRepository"];
    return [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)openRepo:(id)sender
{
    if (sender == self.repoListView)
    {
        NSInteger clickedRow = [self.repoListView clickedRow];
        
        if (clickedRow == NSNotFound)
            return;

        NSString* repoIdentifier = [[_filteredRepos objectAtIndex:clickedRow] identifier];
        [(AppDelegate *)[NSApp delegate] openRepoWindow:repoIdentifier];
        [self rememberLastOpenedRepository:repoIdentifier];
        [self closeWindow:nil];
        return;
    }
    
    NSString *text = [self.identifierField stringValue];
    BOOL isValidID = [BHRepository isValidIdentifier:text];
    
    if (!isValidID)
        return;

    [(AppDelegate *)[NSApp delegate] openRepoWindow:text];
    [self rememberLastOpenedRepository:text];
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
