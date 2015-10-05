//
//  LoginWindowController.m
//  GitHubAuth
//
//  Created by Denis Hennessy on 30/08/2014.
//  Copyright (c) 2014 Peer Assembly Ltd. All rights reserved.
//

#import "LoginWindowController.h"
#import <OctoKit/OCTClient.h>
#import <OctoKit/OCTServer.h>
#import <OctoKit/OCTUser.h>
#import <ReactiveCocoa/RACScheduler.h>
#import <ReactiveCocoa/RACSignal.h>
#import "AppDelegate.h"

@interface LoginWindowController ()

@property (weak) IBOutlet NSMatrix *service;
@property (weak) IBOutlet NSButtonCell *radio;
@property (weak) IBOutlet NSButtonCell *githubComService;
@property (weak) IBOutlet NSButtonCell *githubEnterpriseService;
@property (weak) IBOutlet NSTextField *urlLabel;
@property (weak) IBOutlet NSTextField *urlTextField;
@property (weak) IBOutlet NSTextField *usernameTextField;
@property (weak) IBOutlet NSSecureTextField *passwordTextField;
@property (weak) IBOutlet NSTextField *errorLabel;
@property (weak) IBOutlet NSButton *loginButton;

@property (strong) IBOutlet NSPanel *oneTimePasswordSheet;
@property (weak) IBOutlet NSTextField *code0TextField;
@property (weak) IBOutlet NSTextField *code1TextField;
@property (weak) IBOutlet NSTextField *code2TextField;
@property (weak) IBOutlet NSTextField *code3TextField;
@property (weak) IBOutlet NSTextField *code4TextField;
@property (weak) IBOutlet NSTextField *code5TextField;
@property (weak) IBOutlet NSTextField *oneTimeErrorLabel;
@property (weak) IBOutlet NSButton *oneTimePasswordLoginButton;

@end

@implementation LoginWindowController

- (void)windowDidLoad {
    [super windowDidLoad];

    _codeTextFields = @[
                        _code0TextField, _code1TextField, _code2TextField,
                        _code3TextField, _code4TextField, _code5TextField
                        ];
    [_service setSelectionFrom:0 to:0 anchor:0 highlight:NO];
    _urlTextField.stringValue = @"https://github.com";
    _errorLabel.stringValue = @"";
    _oldEnterpriseURL = @"";
    [self enableUserInteraction:YES];
    [self configureLoginButton];
}

- (IBAction)loginClicked:(id)sender {
    [self enableUserInteraction:NO];
    NSString *oneTimePassword = nil;
    if (_oneTimePasswordVisible) {
        oneTimePassword = [self getOneTimePassword];
    }
    NSString *username = _usernameTextField.stringValue;
    NSString *password = _passwordTextField.stringValue;
    
    NSURL *serverURL = nil;
    if (_service.selectedCell == _githubEnterpriseService) {
        serverURL = [NSURL URLWithString:_urlTextField.stringValue];
        [GHAPIRequest setAPIPrefix:_urlTextField.stringValue];
        loginRequest = [GHAPIRequest requestForAuth:username password:password];
        __weak LoginWindowController *weakSelf = self;
        [loginRequest setCompletionBlock:^(GHAPIRequest *aRequest) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (aRequest.status == GHAPIRequestStatusComplete) {
                    NSInteger statusCode = [aRequest responseStatusCode];
                    if (statusCode < 200 || statusCode > 299) {
                        weakSelf.errorLabel.stringValue = @"Login failed";
                        [weakSelf enableUserInteraction:YES];
                        return;
                    }

                    NSData *responseData = [aRequest responseData];
                    NSError *error = nil;
                    NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
                    NSString *login = [responseDict objectForKey:@"login"];
                    [[NSUserDefaults standardUserDefaults] setObject:weakSelf.urlTextField.stringValue forKey:@"APIPrefix"];
                    [GHAPIRequest setAPIPrefix:[[NSUserDefaults standardUserDefaults] stringForKey:@"APIPrefix"]];
                    [GHAPIRequest setUsesOAuth:NO];
                    [GHAPIRequest setClassAuthenticatedUser:login password:password];
                    weakSelf.passwordTextField.stringValue = @"";
                    [weakSelf close];
                    [(AppDelegate *)[NSApp delegate] openRepoChooser:login];
                } else {
                    NSAlert *alert = [NSAlert alertWithMessageText:@"Unable to login" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Unable to login at this time. Try checking your internet connection."];
                    weakSelf.errorLabel.stringValue = @"Login failed";
                    [weakSelf enableUserInteraction:YES];
                    [alert runModal];
                }
            });
        }];

        [loginRequest sendRequest];
    } else {
        OCTUser *user = [OCTUser userWithRawLogin:username server:[OCTServer serverWithBaseURL:serverURL]];
        RACSignal *request = [OCTClient signInAsUser:user
                                            password:password
                                     oneTimePassword:oneTimePassword
                                              scopes:OCTClientAuthorizationScopesRepository
                                                note:@"BugHub"
                                             noteURL:nil
                                         fingerprint:nil];
        [request subscribeNext:^(OCTClient *authenticatedClient) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (_oneTimePasswordVisible) {
                    [self hideOneTimePasswordSheet];
                }
                if (_service.selectedCell == _githubComService) {
                    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"APIPrefix"];
                } else {
                    [[NSUserDefaults standardUserDefaults] setObject:_urlTextField.stringValue forKey:@"APIPrefix"];
                }
                [GHAPIRequest setAPIPrefix:[[NSUserDefaults standardUserDefaults] stringForKey:@"APIPrefix"]];
                [GHAPIRequest setUsesOAuth:YES];
                [GHAPIRequest setClassAuthenticatedUser:authenticatedClient.user.rawLogin token:authenticatedClient.token];
                _passwordTextField.stringValue = @"";
                [self close];
                [(AppDelegate *)[NSApp delegate] openRepoChooser:authenticatedClient.user.rawLogin];
            });
        } error:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
//                NSLog(@"Login error: %@", error.userInfo);
                if ([error.domain isEqual:OCTClientErrorDomain] && error.code == OCTClientErrorTwoFactorAuthenticationOneTimePasswordRequired) {
                    if (_oneTimePasswordVisible) {
                        _oneTimeErrorLabel.stringValue = NSLocalizedString(@"Incorrect auth code", nil);
                    } else {
                        [self showOneTimePasswordSheet];
                    }
                } else {
                    _errorLabel.stringValue = error.localizedDescription;
                }
                [self enableUserInteraction:YES];
            });
        }];
    }
}

- (IBAction)cancelClicked:(id)sender {
    if (_oneTimePasswordVisible) {
        [self hideOneTimePasswordSheet];
    } else {
        _passwordTextField.stringValue = @"";
        [self close];
    }
}

- (IBAction)serviceChanged:(id)sender {
    if (_service.selectedCell == _githubComService) {
        _oldEnterpriseURL = [_urlTextField.stringValue copy];
        [_usernameTextField becomeFirstResponder];
        _urlTextField.enabled = NO;
        _urlTextField.stringValue = @"https://github.com";
    } else {
        _urlLabel.enabled = YES;
        _urlTextField.enabled = YES;
        _urlTextField.stringValue = _oldEnterpriseURL;
        [_urlTextField becomeFirstResponder];
    }
    [self configureLoginButton];
}

- (void)controlTextDidChange:(NSNotification *)aNotification {
    if (_oneTimePasswordVisible) {
        _oneTimeErrorLabel.stringValue = @"";
        NSInteger iDigit = 0;
        for (NSInteger i=0;i<6;i++) {
            NSTextField *field = _codeTextFields[i];
            if (aNotification.object == field) {
                iDigit = i;
            }
        }
        NSTextField *nextField = _codeTextFields[(iDigit+1)%6];
        [nextField becomeFirstResponder];
    } else {
        _errorLabel.stringValue = @"";
    }
    [self configureLoginButton];
}

- (void)configureLoginButton {
    BOOL enable = YES;
    if (_oneTimePasswordVisible) {
        for (NSTextField *field in _codeTextFields) {
            if (field.stringValue.length == 0) {
                enable = NO;
            }
        }
        _oneTimePasswordLoginButton.enabled = enable;
    } else {
        if (_service.selectedCell == _githubEnterpriseService) {
            enable &= _urlTextField.stringValue.length > 0;
        }
        enable &= _usernameTextField.stringValue.length > 0;
        enable &= _passwordTextField.stringValue.length > 0;
        
        _loginButton.enabled = enable;
    }
}

- (void)enableUserInteraction:(BOOL)enabled {
    _service.enabled = enabled;
    if (_service.selectedCell == _githubComService) {
        _urlTextField.enabled = NO;
    } else {
        _urlTextField.enabled = enabled;
    }
    _usernameTextField.enabled = enabled;
    _passwordTextField.enabled = enabled;
    _loginButton.enabled = enabled;
    if (enabled) {
        [_usernameTextField becomeFirstResponder];
    }
}

- (NSString *)getOneTimePassword {
    NSMutableString *password = [[NSMutableString alloc] init];
    for (NSTextField *field in _codeTextFields) {
        [password appendString:field.stringValue];
    }
    return password;
}

- (void)hideOneTimePasswordSheet {
    [self.window endSheet:_oneTimePasswordSheet];
}

- (void)showOneTimePasswordSheet {
    _oneTimePasswordVisible = YES;
    _oneTimeErrorLabel.stringValue = @"";
    for (NSTextField *field in _codeTextFields) {
        field.stringValue = @"";
    }
    [_code0TextField becomeFirstResponder];
    [self configureLoginButton];
    [self.window beginSheet:_oneTimePasswordSheet completionHandler:^(NSModalResponse returnCode) {
        _oneTimePasswordVisible = NO;
        [self enableUserInteraction:YES];
    }];
}

@end
