//
//  LoginViewController.m
//  BugHub
//
//  Created by Randy on 12/28/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import "AppDelegate.h"

#import "LoginWindowController.h"
#import "GHAPIRequest.h"
#import "BHAnimations.h"
#import "NewRepoWindowController.h"
#import <QuartzCore/QuartzCore.h>
#import "BHUser.h"
#import "NSColor+hex.h"

@interface LoginWindowController ()
{
    GHAPIRequest *loginRequest;
    BOOL hasAnimated;
}

- (void)_animateToSpinner;
- (void)_animateBackToFields;
- (void)_shakeWindow;

- (void)_animateToRepoChooser:(NSDictionary *)username;
- (void)_animateLogos;
@end

@implementation LoginWindowController

- (void)awakeFromNib
{
    [self.window setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"Semi-Dark-Texture"]]];
    
/*
    FUCK YOU NSTextField/Cell
    NSString *placeholder = @"GitHub Username";
    NSMutableAttributedString *newPlaceholder = [[NSMutableAttributedString alloc] initWithString:placeholder];
    
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowOffset:CGSizeMake(0, -1)];
    [shadow setShadowColor:[NSColor whiteColor]];
    [shadow setShadowBlurRadius:0.0f];
    
    NSColor *textColor = [NSColor colorWithHexColorString:@"202830"];
    textColor = [textColor colorWithAlphaComponent:0.35];
    NSRange range = NSMakeRange(0, placeholder.length);
    
    [newPlaceholder addAttribute:NSForegroundColorAttributeName value:textColor range:range];
    [newPlaceholder addAttribute:NSShadowAttributeName value:shadow range:range];
    [newPlaceholder addAttribute:NSFontAttributeName value:[NSFont boldSystemFontOfSize:16.0] range:range];
    
    [[self.usernameField cell] setPlaceholderAttributedString:newPlaceholder];
 */
}

- (IBAction)cancelButtonPushed:(id)sender
{
    [self close];
}

- (IBAction)loginClicked:(id)sender
{
    // REPLACED BY OAUTH MECHANISM
//    NSString *usenameValue = [self.usernameField stringValue];
//    NSString *passwordValue = [self.passwordField stringValue];
//    if (!usenameValue || [usenameValue isEqualToString:@""])
//    {
//        CGRect viewFrame = [self.usernameField frame];
//        CAKeyframeAnimation *animation = [BHAnimations shakeAnimation:viewFrame numberOfShakes:1 durationOfShake:.25];
//        [self.usernameField setAnimations:[NSDictionary dictionaryWithObject:animation forKey:@"frameOrigin"]];
//        [[self.usernameField animator] setFrameOrigin:viewFrame.origin];
//        [self.window makeFirstResponder:self.usernameField];
//        return;
//    }
//    
//    if (!passwordValue || [passwordValue isEqualToString:@""])
//    {
//        CGRect viewFrame = [self.passwordField frame];
//        CAKeyframeAnimation *animation = [BHAnimations shakeAnimation:viewFrame numberOfShakes:1 durationOfShake:.25];
//        [self.passwordField setAnimations:[NSDictionary dictionaryWithObject:animation forKey:@"frameOrigin"]];
//        [[self.passwordField animator] setFrameOrigin:viewFrame.origin];
//        [self.window makeFirstResponder:self.passwordField];
//        return;
//    }
//    
//    [self.usernameField setEnabled:NO];
//    [self.passwordField setEnabled:NO];
//    
//    loginRequest = [GHAPIRequest requestForAuth:[self.usernameField stringValue] pass:[self.passwordField stringValue]];
//
//    __weak id controller = self;
//    
//    [loginRequest setCompletionBlock:^(GHAPIRequest *aRequest){
//        
//        if (aRequest.status == GHAPIRequestStatusComplete)
//        {
//            NSInteger statusCode = [aRequest responseStatusCode];
//            
//            if (statusCode < 200 || statusCode > 299)
//            {
//                // login failed.
//                [controller _animateBackToFields];
//                [controller _shakeWindow];
//                
//                return;
//            }
//
//            NSData *responseData = [aRequest responseData];
//            NSError *error = nil;
//            NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
//            
//            if (error)
//                ; // why the hell would there be an error? like srsly.
//            
//            
//            // set the auth string
//            [GHAPIRequest setClassAuthenticatedUser:[responseDict objectForKey:@"login"] password:passwordValue];
//            [controller _animateToRepoChooser:responseDict];
//        }
//        else
//        {
//            NSAlert *alert = [NSAlert alertWithMessageText:@"Unable to login" defaultButton:@"Okay" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Unable to login at this time. Try checking your internet connection."];
//            [controller _animateBackToFields];
//            [[controller window] makeFirstResponder:[controller usernameField]];
//            [alert runModal];
//        }
//    }];
//
//    [self _animateToSpinner];
//    
//    [loginRequest sendRequest];
}

- (void)_animateToSpinner
{
    [spinnerView setAlphaValue:0.0];
    [spinnerView startAnimation:nil];
    
    CGRect frame = [[self.window contentView] frame];
    CGPoint center = CGPointMake(CGRectGetWidth(frame) / 2, CGRectGetHeight(frame) / 2);
    
    [spinnerView setFrameOrigin:CGPointMake(center.x - [spinnerView frame].size.width / 2, center.y - [spinnerView frame].size.height / 2)];
    [[self.window contentView] addSubview:spinnerView];
    
    [[NSAnimationContext currentContext] setDuration:0.15];
    [[NSAnimationContext currentContext] setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        [fieldsContainerView.animator setAlphaValue:0.0];
        [spinnerView.animator setAlphaValue:1.0];
    } completionHandler:^{
        //[fieldsContainerView removeFromSuperview];
        //[fieldsContainerView setAlphaValue:1.0];
    }];
}

- (void)_animateBackToFields
{
    [[self.window contentView] addSubview:fieldsContainerView];
    [fieldsContainerView setAlphaValue:0.0];
    
    [[NSAnimationContext currentContext] setDuration:0.15];
    [[NSAnimationContext currentContext] setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        [spinnerView.animator setAlphaValue:0.0];
        [fieldsContainerView.animator setAlphaValue:1.0];
    } completionHandler:^{
        //[spinnerView removeFromSuperview];
        //[spinnerView setAlphaValue:1.0];
        [self.usernameField setEnabled:YES];
        [self.passwordField setEnabled:YES];
        [spinnerView stopAnimation:nil];
    }];
}

- (void)_shakeWindow
{
    CGRect windowFrame = [self.window frame];
    CAKeyframeAnimation *animation = [BHAnimations shakeAnimation:windowFrame numberOfShakes:1 durationOfShake:.25];
    [self.window setAnimations:[NSDictionary dictionaryWithObject:animation forKey:@"frameOrigin"]];
    [[self.window animator] setFrameOrigin:windowFrame.origin];

    return;
}

- (void)_animateToRepoChooser:(NSDictionary *)aUserDict
{
    [[self window] close];
    //[(AppDelegate *)[NSApp delegate] openRepoWindow:@"Me1000/BugHub"];
    [(AppDelegate *)[NSApp delegate] openRepoChooser:aUserDict];
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
    // I have no idea how to make this now suck. WindowControllers are worthless.
    if (hasAnimated)
        return;
    
    hasAnimated = YES;
    [self performSelector:@selector(_animateLogos) withObject:nil afterDelay:0.25];
}

- (void)_animateLogos
{
    [nameIV setAlphaValue:0.0];
    [nameIV setHidden:NO];
    [self.usernameField setAlphaValue:0.0];
    [self.usernameField setHidden:NO];
    [self.passwordField setAlphaValue:0.0];
    [self.passwordField setHidden:NO];
    [self.usernameField setEnabled:NO];
    [self.passwordField setEnabled:NO];
    [fieldsUnderlay setAlphaValue:0.0];
    [fieldsUnderlay setHidden:NO];
    [goButton setAlphaValue:0.0];
    [goButton setHidden:NO];

    [[NSAnimationContext currentContext] setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [[NSAnimationContext currentContext] setDuration:0.45];
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        [[iconVIew animator] setFrameOrigin:CGPointMake(iconVIew.frame.origin.x, 210)];
    } completionHandler:^{
        [self performSelector:@selector(_fadeName) withObject:nil afterDelay:0.25];
    }];
}

- (void)_fadeName
{
    [[NSAnimationContext currentContext] setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    [[NSAnimationContext currentContext] setDuration:0.25];
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        [nameIV.animator setAlphaValue:1.0];
    } completionHandler:^{
        [self performSelector:@selector(_fadeFields) withObject:nil afterDelay:0.25];
    }];
}

- (void)_fadeFields
{
    [[NSAnimationContext currentContext] setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    [[NSAnimationContext currentContext] setDuration:0.25];
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        [self.usernameField.animator setAlphaValue:1.0];
        [self.passwordField.animator setAlphaValue:1.0];
        [fieldsUnderlay.animator setAlphaValue:1.0];
        [goButton.animator setAlphaValue:1.0];
    } completionHandler:^(){
        [self.usernameField setEnabled:YES];
        [self.passwordField setEnabled:YES];
        [self.window makeFirstResponder:self.usernameField];

    }];
    
    //[self.window performSelector:@selector(makeFirstResponder:) withObject:self.usernameField afterDelay:0.26];
}

@end
