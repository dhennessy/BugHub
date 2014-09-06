//
//  LoginWindowController.h
//  GitHubAuth
//
//  Created by Denis Hennessy on 30/08/2014.
//  Copyright (c) 2014 Peer Assembly Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GHAPIRequest.h"

@interface LoginWindowController : NSWindowController {
    NSString *_oldEnterpriseURL;
    NSArray *_codeTextFields;
    BOOL _oneTimePasswordVisible;
    GHAPIRequest *loginRequest;
}

@end
