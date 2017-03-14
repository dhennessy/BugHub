//
//  AppDelegate.m
//  BugHub
//
//  Created by Randy on 12/25/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import "AppDelegate.h"
#import "LoginWindowController.h"
//#import "WebLoginWindowController.h"
#import "RepositoryWindowController.h"
#import "BHWindowControllerIdentifier.h"
#import "BHRequestQueue.h"
#import "BHRepository.h"
#import "NewRepoWindowController.h"
#import "GHAPIRequest.h"
#import "GHUtils.h"
#import "INAppStoreWindow.h"
#import <OctoKit/OCTClient.h>

#if BUILD_DIRECT
// IMPORTANT: Set this to 0 to disable expiration
#define EXPIRE_DAYS     45
#endif

@class IdentifierWindowController;

@interface AppDelegate ()
{
    NSMutableSet *openWindowControllers;
    LoginWindowController *loginController;
//    WebLoginWindowController *loginController;
    
    GHAPIRequest *_apiStatusCheckConnection;
    
    BOOL hasAlertedUserAboutRateLimit;
    BOOL hasInitialLogin;
}

- (void)removeAPIStatusNotifications;
- (void)didHitRateLimit:(NSNotification *)aNote;
@end

@implementation AppDelegate

- (id)init
{
    self = [super init];

    if (self)
    {
        [OCTClient setUserAgent:@"BugHub"];
        [OCTClient setClientID:@"8e376e2335495e3a8e83" clientSecret:@"c2578cebd0ecc5efae69ed1f111e2d37e7b865a8"];
        _requestQueue = [[BHRequestQueue alloc] init];
        openWindowControllers = [NSMutableSet setWithCapacity:1];
        self.apiStatus = GHAPIStatusGood;
    }

    return self;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
    hasInitialLogin = [GHAPIRequest initializeClassWithKeychain];
    NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
    [appleEventManager setEventHandler:self andSelector:@selector(handleGetURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{


    [self setupDefaultValues];
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didHitRateLimit:) name:BHHitRateLimitNotification object:nil];
    
//    NSDate *experationData = [NSDate dateWithString:@"2013-06-07 10:45:32 +0600"];
//    NSDate *now = [NSDate date];
//    
//    if ([experationData compare:now] == NSOrderedAscending)
//    {
//        [[NSAlert alertWithMessageText:@"This Beta has Expired" defaultButton:@"Okay" alternateButton:nil otherButton:nil informativeTextWithFormat:@""] runModal];
//        [NSApp terminate:nil];
//        return;
//    }
    
    // The two lines following this may or may not be needed.
    CFStringRef bundleID = (__bridge CFStringRef)[[NSBundle mainBundle] bundleIdentifier];
    OSStatus httpResult = LSSetDefaultHandlerForURLScheme(CFSTR("bughub"), bundleID);

    (void)httpResult;

    if (!hasInitialLogin)
        [self login:nil];
    else
    {
        BOOL hasOpenRepoWindow = NO;
        for (NSWindowController *aController in openWindowControllers)
        {
            if ([aController isKindOfClass:[RepositoryWindowController class]])
            {
                hasOpenRepoWindow = YES;
                break;
            }
        }
        
        if (!hasOpenRepoWindow) {
            NSString* lastOpenedRepo = [[NSUserDefaults standardUserDefaults] stringForKey:@"lastOpenedRepository"];
            // If no repo windows were restored, show the repo picker window
            if(lastOpenedRepo) [self openRepoWindow:lastOpenedRepo];
            else [self openRepoChooser:nil];
        }
        
    }

    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"e03657115605ec034e073870b13120b5"];
    [[BITHockeyManager sharedHockeyManager] startManager];
    
    [self checkAPIStatus];
    [NSTimer scheduledTimerWithTimeInterval:15 * 60 target:self selector:@selector(checkAPIStatus) userInfo:nil repeats:YES];
    
#if BUILD_DIRECT
    [self checkBuildExpiry];
    if (_buildExpired) {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"This test release of BugHub has expired. Please download a new test version.", nil)
                                         defaultButton:NSLocalizedString(@"OK", nil)
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@""];
        
        //        [alert setShowsSuppressionButton:YES];
        //        alert.showsHelp = YES;
        [alert runModal];
        [NSApp terminate:nil];
    }
#endif
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [self removeAPIStatusNotifications];
}

+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString *)host {
    return YES;
}

- (void)didHitRateLimit:(NSNotification *)aNote
{
    // dont bug the fuck out of the user, I guess...
    if (hasAlertedUserAboutRateLimit)
        return;
    
    NSDate *dateCreated = [NSDate date];

    NSUserNotification *note = [[NSUserNotification alloc] init];
    [note setTitle:@"Hit GitHub API Limit"];
    
    if (![GHAPIRequest authenticatedUserLogin])
        [note setInformativeText:@"You should login to avoid hitting this limit."];

    [note setDeliveryDate:dateCreated];
    [note setUserInfo:@{@"kind": @"apiRateLimit"}];
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:note];
}

- (IBAction)login:(id)sender
{
    loginController = [[LoginWindowController alloc] initWithWindowNibName:@"LoginWindowController"];

    [loginController.window center];
    [loginController.window makeKeyAndOrderFront:nil];
}

- (IBAction)logout:(id)sender
{
    [GHAPIRequest setClassAuthenticatedUser:nil token:nil];
    [self login:nil];
    [prefPane close];
    [self closeAllRepoWindows];
}

- (IBAction)quickOpen:(id)sender
{
    [quickOpenButton setEnabled:NO];
    [quickOpenTextfield setStringValue:@""];
    [quickOpenButton setEnabled:[self validateLinkText:[quickOpenTextfield stringValue]]];
    [quickOpenWindow center];
    [quickOpenWindow makeKeyAndOrderFront:nil];
}

- (IBAction)quickOpenAction:(id)sender
{
    NSString *stringValue = [quickOpenTextfield stringValue];
    BOOL isValidQuickText = [self validateLinkText:stringValue];
    BOOL didOpenLink = [self attemptToOpenGitHubURL:stringValue];
    
    if (!didOpenLink && isValidQuickText)
    {
        unichar firstChar = [stringValue characterAtIndex:0];
        
        if (firstChar == '#')
            stringValue = [stringValue substringFromIndex:1];
        
        NSInteger value = [stringValue integerValue];

        NSArray *windows = [NSApp windows];
        windows = [windows sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"orderedIndex" ascending:YES]]];
        for (NSWindow *aWindow in windows)
        {
            if ([aWindow isKindOfClass:[INAppStoreWindow class]])
            {
                RepositoryWindowController *controller = (RepositoryWindowController *)[aWindow delegate];
                [self openWindowController:controller];
                [controller forceSelectIssueWithNumber:value];
                [quickOpenWindow orderOut:nil];
                return;
            }
        }
    }
    else if (!didOpenLink)
    {
        [quickOpenWindow makeFirstResponder:quickOpenTextfield];
        NSBeep();
    }
    else
        [quickOpenWindow orderOut:sender];
}

- (BOOL)validateLinkText:(NSString *)aLink
{
    NSURL *requestedURL = [NSURL URLWithString:aLink];
    NSArray *pathComponents = [requestedURL pathComponents];
    if ([[requestedURL host] isEqualToString:@"github.com"] && [pathComponents count] > 2 && [pathComponents count] <= 5)
    {
        // now check blacklisted URLs
        NSArray *blackList = @[@"explore", @"blog", @"new", @"settings", @"logout", @"dashboard", @"stars", @"organizations", @"account", @"repositories", @"about", @"contact", @"edu", @"plans", @"site", @"security", @"search", @"notifications"];
        if (![blackList containsObject:[pathComponents objectAtIndex:1]])
        {

            // if it's just a repo name '/', 'user', 'repo'
            if ([pathComponents count] == 3)
                return YES;

            // WOO! We can probably do something with it!
            NSArray *whiteList = @[@"issues", @"pull"];
            if ([whiteList containsObject:[pathComponents objectAtIndex:3]])
                return YES;
        }
    }
    else
    {
        aLink = [aLink stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

        if (aLink.length < 1)
            return NO;
        
        unichar firstChar = [aLink characterAtIndex:0];

        if (firstChar == '#')
            aLink = [aLink substringFromIndex:1];
        
        NSInteger value = [aLink integerValue];
        NSString *checkValue = [NSString stringWithFormat:@"%ld", value];
        
        return [aLink isEqualToString:checkValue];
    }

    return NO;
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
    if ([aNotification object] != quickOpenTextfield)
        return;
    
    [quickOpenButton setEnabled:[self validateLinkText:[quickOpenTextfield stringValue]]];
}

- (BOOL)attemptToOpenGitHubURL:(NSString *)aPath
{
    if (![self validateLinkText:aPath])
        return NO;
    
    NSURL *url = [NSURL URLWithString:aPath];
    
    NSArray *pathComponents = [url pathComponents];
    
    if (![[url host] isEqualToString:@"github.com"] || [pathComponents count] < 2 || [pathComponents count] > 5)
        return NO;

    NSRange subArrayRange = NSMakeRange(1, pathComponents.count - 1);
    NSArray *subArray = [pathComponents subarrayWithRange:subArrayRange];

    NSString *uri = [NSString stringWithFormat:@"bughub://%@", [subArray componentsJoinedByString:@"/"]];

    return [self openBugHubSchemeURL:uri];
}

- (IBAction)openLinksInBugHub:(NSButton *)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:[sender state] == NSOnState forKey:@"BHShouldOpenGitHubLinksInBugHub"];
}

- (BOOL)shouldOpenLinksInBugHub
{   
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"BHShouldOpenGitHubLinksInBugHub"];
}

- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    //http://stackoverflow.com/questions/49510/how-do-you-set-your-cocoa-application-as-the-default-web-browser
    // Get the URL
    NSString *urlStr = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    if ([urlStr hasPrefix:@"bhgithub://oauth"]) {
        [OCTClient completeSignInWithCallbackURL:[NSURL URLWithString:urlStr]];
    } else {
        [self openBugHubSchemeURL:urlStr];
    }
}

- (void)checkAPIStatus
{
    _apiStatusCheckConnection = [GHAPIRequest requestForAPIStatus];
    
    __weak typeof(self) welf = self;
    
    [_apiStatusCheckConnection setCompletionBlock:^(GHAPIRequest *aRequest){
        NSInteger statusCode = [aRequest responseStatusCode];
        if (statusCode < 200 || statusCode > 299)
        {
            //error..
            return ;
        }
        
        NSData *responseData = [aRequest responseData];
        NSError *error = nil;
        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
        
        if (error || ![responseDict isKindOfClass:[NSDictionary class]])
        {
            // error...
        }
        
        // now, check the actual status...
        /*{
            "status": "major",
            "body": "We are currently taking a DDoS attack and are working to mitigate. The site may be slow to respond, and you may struggle to pull/push code via SSH - we apologise for any inconvenience.",
            "created_on": "2013-03-23T22:47:46Z"
        }*/
        
        [welf removeAPIStatusNotifications];

        GHCurrentAPIStatus previousStatus = [welf apiStatus];
        
        NSString *statusStr = [responseDict objectForKey:@"status"];
        if ([statusStr isEqualToString:@"good"])
            [welf setApiStatus:GHAPIStatusGood];
        else if ([statusStr isEqualToString:@"minor"])
            [welf setApiStatus:GHAPIStatusMinor];
        else if ([statusStr isEqualToString:@"major"])
            [welf setApiStatus:GHAPIStatusMajor];

        if ([welf apiStatus] != previousStatus || ![statusStr isEqualToString:@"good"])
        {
            NSDate *dateCreated = [GHUtils dateFromGithubString:[responseDict objectForKey:@"created_on"]];
            
            NSUserNotification *note = [[NSUserNotification alloc] init];
            [note setTitle:@"GitHub API Status"];
            [note setSubtitle:[NSString stringWithFormat:@"(%@)", statusStr]];
            [note setInformativeText:[responseDict objectForKey:@"body"]];
            [note setDeliveryDate:dateCreated];
            [note setUserInfo:@{@"kind": @"apiStatus"}];
            
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:note];
        }
    }];
    
    [_apiStatusCheckConnection sendRequest];
}

- (IBAction)openRepoChooser:(id)sender
{
    NewRepoWindowController *wc = [[NewRepoWindowController alloc] initWithWindowNibName:@"NewRepoWindowController"];
//    if ([sender isKindOfClass:[NSString class]])
//        [wc setDefaultUser:sender];
    
    [self openWindowController:wc];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if ([[menuItem title] isEqualToString:@"New Issue"])
        return NO;
    else if ([[menuItem title] isEqualToString:@"Login"])
        return [GHAPIRequest authenticatedUserLogin] == nil;
    else if ([[menuItem title] isEqualToString:@"Logout"])
        return [GHAPIRequest authenticatedUserLogin] != nil;

    return YES;
}

- (BOOL)openBugHubSchemeURL:(NSString *)aString
{
    aString = [aString substringFromIndex:[@"bughub://" length]];
    NSArray *pathComponents = [aString componentsSeparatedByString:@"/"];

    // Path cmponent at index one is equal to the repository owner's login username
    NSInteger pathComponentCount = [pathComponents count];
    NSString *username = nil;
    NSString *repoName = nil;
    NSInteger issueNumber = NSNotFound;
    
    if (pathComponentCount > 0)
        username = [pathComponents objectAtIndex:0];
    
    if (pathComponentCount > 1)
        repoName = [pathComponents objectAtIndex:1];
    
    if (pathComponentCount > 3)
    {
        if ([[pathComponents objectAtIndex:2] isEqualToString:@"issues"])
            issueNumber = [[pathComponents objectAtIndex:3] integerValue];
        else
            return NO;
    }

    RepositoryWindowController *controller = nil;
    NSString *identifier = [NSString stringWithFormat:@"%@/%@", username, repoName];

    if (repoName != nil)
        controller = [self openRepoWindow:identifier];

    if (issueNumber != NSNotFound)
    {
        // open the issue
        [controller forceSelectIssueWithNumber:issueNumber];
        return YES;
    }
    else
        return NO;
}

- (void)removeAPIStatusNotifications
{
    // remove the current status notifications from the center..
    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
    NSArray *shownNotes = [center deliveredNotifications];
    for (NSUserNotification *aNote in shownNotes)
    {
        NSDictionary *userDict = [aNote userInfo];
        if ([[userDict objectForKey:@"kind"] isEqualToString:@"apiStatus"] || [[userDict objectForKey:@"kind"] isEqualToString:@"apiRateLimit"])
            [center removeDeliveredNotification:aNote];
    }
}


- (id)openRepoWindow:(NSString *)aRepoIdentifier
{
    RepositoryWindowController *controller = [self windowControllerWithIdentifier:aRepoIdentifier];
    
    if (!controller)
        controller = [[RepositoryWindowController alloc] initWithRepositoryIdentifier:aRepoIdentifier];

    [self openWindowController:controller];
    
    return controller;
}

- (void)closeAllRepoWindows {
    for (NSWindowController *aController in openWindowControllers) {
        if ([aController isKindOfClass:[RepositoryWindowController class]]) {
            [aController.window close];
        }
    }
}

- (IBAction)showPrefsWindow:(id)sender
{
    [prefPane center];
    
    NSString *loginName = [GHAPIRequest authenticatedUserLogin];
    [loginTextField setStringValue:loginName ? loginName : @""];
    [logoutButton setEnabled:loginName != nil];

    [prefPane makeKeyAndOrderFront:nil];
}

- (void)openWindowController:(NSWindowController *)aWindowController
{
    [openWindowControllers addObject:aWindowController];
    [aWindowController showWindow:nil];
}

- (void)windowControllerDidClose:(NSWindowController *)aWindowController
{
    [openWindowControllers removeObject:aWindowController];
}

- (id)windowControllerWithIdentifier:(NSString *)anIdentifier
{
    NSString *searchString = [anIdentifier lowercaseString];
    
    NSSet *controllers = [openWindowControllers objectsPassingTest:^BOOL(id obj, BOOL *stop){
        
        if (![obj conformsToProtocol:@protocol(BHWindowControllerIdentifier)])
            return NO;

        NSString *objIdentifier = [[obj identifier] lowercaseString];

        if ([objIdentifier isEqualToString:searchString])
        {
            *stop = YES;
            return YES;
        }

        return NO;
    }];

    return [controllers anyObject];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    NSDictionary *dict = [notification userInfo];
    
    if ([[dict objectForKey:@"kind"] isEqualToString:@"apiStatus"])
    {
        NSURL *urlToOpen = [NSURL URLWithString:@"https://status.github.com/"];
        [[NSWorkspace sharedWorkspace] openURL:urlToOpen];
    }
    else if ([[dict objectForKey:@"kind"] isEqualToString:@"apiRateLimit"])
    {
        [self login:nil];
    }
}

- (void)setupDefaultValues
{
    const float versionNumber = 0.1;
    
    NSUserDefaults *sharedDefaults = [NSUserDefaults standardUserDefaults];
    float version = [sharedDefaults floatForKey:@"BHUserDefaultsVersion"];
    
    if (version <  versionNumber)
    {
        [sharedDefaults setBool:YES forKey:@"BHShouldOpenGitHubLinksInBugHub"];
    }
    
}

#if BUILD_DIRECT
- (void)checkBuildExpiry {
#if EXPIRE_DAYS
    NSString *buildDateString = @"" __DATE__;       // @"Dec 24 2014"
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    dateFormatter.dateFormat = @"MMM dd yyyy";
    NSDate *buildDate = [dateFormatter dateFromString:buildDateString];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *dateComps = [[NSDateComponents alloc] init];
    dateComps.day = EXPIRE_DAYS;
    NSDate *expiryDate = [gregorian dateByAddingComponents:dateComps toDate:buildDate options:0];
    if ([[NSDate date] compare:expiryDate] > 0) {
        _buildExpired = YES;
    }
    NSLog(@"Build Date: %@ -> %@, Expiry: %@", buildDateString, buildDate, expiryDate);
    // TODO: It would be best to check if the new version is actually available
#endif
}
#endif

@end
