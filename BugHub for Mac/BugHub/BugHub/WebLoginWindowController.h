//
//  WebLoginWindowController.h
//  
//
//  Created by Denis Hennessy on 23/08/2014.
//
//

#import <Cocoa/Cocoa.h>

@interface WebLoginWindowController : NSWindowController<NSTextFieldDelegate>

@property (weak) IBOutlet NSTextField *urlTextField;
@property (weak) IBOutlet NSButton *enterpriseLoginButton;

- (IBAction)loginGitHubClicked:(id)sender;
- (IBAction)loginEnterpriseClicked:(id)sender;
- (IBAction)enterPressedInEnterpriseURL:(id)sender;

@end
