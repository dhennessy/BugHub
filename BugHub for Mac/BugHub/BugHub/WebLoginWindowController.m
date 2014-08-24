//
//  WebLoginWindowController.m
//  
//
//  Created by Denis Hennessy on 23/08/2014.
//
//

#import "WebLoginWindowController.h"
#import "OCTClient.h"
#import "OCTServer.h"
#import "OCTUser.h"
#import "RACSignal.h"
#import "AppDelegate.h"
#import "GHAPIRequest.h"

@implementation WebLoginWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)loginGitHubClicked:(id)sender {
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"APIPrefix"];
    [self startWebLoginWithURL:nil];
}

- (IBAction)loginEnterpriseClicked:(id)sender {
    [[NSUserDefaults standardUserDefaults] setObject:_urlTextField.stringValue forKey:@"APIPrefix"];
    NSURL *url = [NSURL URLWithString:_urlTextField.stringValue];
    if ([url.scheme isEqualToString:@"https"]) {
        [self startWebLoginWithURL:url];
    } else {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Unsupported URL format", nil) defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"GitHub Enterprise login URLs should start with 'http://' or 'https://'", nil)];
        [alert runModal];
    }
}

- (IBAction)enterPressedInEnterpriseURL:(id)sender {
    if (_enterpriseLoginButton.enabled) {
        [self loginEnterpriseClicked:_enterpriseLoginButton];
    }
}

- (void)controlTextDidChange:(NSNotification *)aNotification {
    NSString *url = _urlTextField.stringValue;
    if (url.length > 0) {
        _enterpriseLoginButton.enabled = YES;
        [self.window setDefaultButtonCell:_enterpriseLoginButton.cell];
    } else {
        _enterpriseLoginButton.enabled = NO;
    }
}

#pragma mark - Implementation

- (void)startWebLoginWithURL:(NSURL *)url {
    OCTServer *server = [OCTServer serverWithBaseURL:url];
    [[OCTClient signInToServerUsingWebBrowser:server scopes:OCTClientAuthorizationScopesRepository]
     subscribeNext:^(OCTClient *authenticatedClient) {
         NSLog(@"Successful authentication by %@", authenticatedClient.user.rawLogin);
         dispatch_async(dispatch_get_main_queue(), ^{
             [GHAPIRequest setAPIPrefix:[[NSUserDefaults standardUserDefaults] stringForKey:@"APIPrefix"]];
             [GHAPIRequest setClassAuthenticatedUser:authenticatedClient.user.rawLogin token:authenticatedClient.token];
             [[self window] close];
             [(AppDelegate *)[NSApp delegate] openRepoChooser:authenticatedClient.user.rawLogin];
         });
     } error:^(NSError *error) {
         NSAlert *alert = [NSAlert alertWithError:error];
         [alert runModal];
     }];
}

@end
