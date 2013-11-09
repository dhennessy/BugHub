//
//  NewCommentWindowController.m
//  BugHub
//
//  Created by Randy on 3/12/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "NewCommentWindowController.h"
#import "BHComment.h"
#import "GHAPIRequest.h"
#import "BHIssue.h"
#import "BHRepository.h"

@interface NewCommentWindowController ()

@property(strong) GHAPIRequest *request;
- (void)setIsLoading:(BOOL)aFlag;
- (void)displaySaveError;
- (NSAttributedString *)stringValueForTitle;
@end

@implementation NewCommentWindowController

- (id)initWithWindowNibName:(NSString *)windowNibName
{
    self = [super initWithWindowNibName:windowNibName];

    if (self)
    {
        [self addObserver:self forKeyPath:@"issue.title" options:0 context:NULL];
    }

    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"issue.title"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self.titleLabel setAttributedStringValue:[self stringValueForTitle]];
}

- (IBAction)submitCommentButtonClicked:(id)sender
{
    if ([[self.bodyField string] length] == 0)
    {
        [self.window makeFirstResponder:self.bodyField];
        NSBeep();
        return;
    }

    self.request = [GHAPIRequest requestForNewCommentWithBody:[self.bodyField string]
                                         repositoryIdentifier:[[self.issue repository] identifier]
                                                  issueNumber:[self.issue number]];

    __weak typeof(self) weakSelf = self;

    [self.request setCompletionBlock:^(GHAPIRequest *aRequest) {
        NSInteger statusCode = [aRequest responseStatusCode];
        NSData *responseData = [aRequest responseData];

        if (statusCode > 299 || statusCode < 200)
        {
            [weakSelf displaySaveError];
            return;
        }

        NSError *error = nil;
        NSDictionary *newCommentDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];

        if (error)
            ;// do something, who the fuck knows? If the request is successful why the hell would we get a parse error?
        
        BHComment *newComment = [[BHComment alloc] init];
        [newComment setDictValues:newCommentDict];
        [newComment setIssue:weakSelf.issue];
        [weakSelf.issue addComments:@[newComment]];

        [weakSelf setIsLoading:NO];
        [weakSelf.retainSetThing removeObject:weakSelf];
        weakSelf.retainSetThing = nil;
        [weakSelf close];
    }];

    [self setIsLoading:YES];
    [self.request sendRequest];
}

- (NSAttributedString *)stringValueForTitle {
    NSString *commentPrefix = @"Comment on";
    NSString *issueMiddlefix = @"issue";
    NSString *fullString = [NSString stringWithFormat:@"%@ %@ %@ #%ld", commentPrefix, [[self.issue repository] identifier], issueMiddlefix, [self.issue number]];
    
    NSDictionary *attributes = @{
                                 
                                 };
    
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:fullString
                                                                           attributes:attributes];
}

- (void)awakeFromNib
{
    [self.window setMovableByWindowBackground:YES];
    [self.window setOpaque:NO];
    [self.window setStyleMask:NSBorderlessWindowMask];
    NSView *view = [self.window contentView];
    view.wantsLayer = YES;
    [[view layer] setCornerRadius:5.0];
    [[view layer] setMasksToBounds:YES];
    [self.titleLabel setAttributedStringValue:[self stringValueForTitle]];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self.retainSetThing removeObject:self];
}

- (void)displaySaveError
{
    [self setIsLoading:NO];
    
    NSAlert *alert = [NSAlert alertWithMessageText:@"Unable to create comment" defaultButton:@"Okay" alternateButton:nil otherButton:nil informativeTextWithFormat:@"BugHub was unable to create a comment for this issue at this time."];
    [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:NULL];
}

- (void)setIsLoading:(BOOL)aFlag
{
    [self.bodyField setEditable:!aFlag];
    [self.submitButton setHidden:aFlag];

    if (aFlag)
        [self.spinner startAnimation:nil];
    else
        [self.spinner stopAnimation:nil];
}

#pragma mark window restore
+ (void)restoreWindowWithIdentifier:(NSString *)identifier state:(NSCoder *)state completionHandler:(void (^)(NSWindow *, NSError *))completionHandler
{
    
}

@end
