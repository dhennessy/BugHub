//
//  BHLabel.m
//  BugHub
//
//  Created by Randy on 12/26/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import "BHLabel.h"
#import "NSColor+hex.h"
#import "GHAPIRequest.h"

@interface BHLabel ()

@property(strong) GHAPIRequest *saveRequest;

@end

@implementation BHLabel

+ (BHLabel *)voidLabel
{
    static BHLabel *aLabel;
    
    if (!aLabel)
    {
        aLabel = [[self alloc] init];
        [aLabel setName:@"No Labels Set"];
        [aLabel setColor:[NSColor blackColor]];
    }
    
    return aLabel;
}

- (void)setDictionaryValues:(NSDictionary *)aDict
{
    self.name = [aDict objectForKey:@"name"];
    self.color = [NSColor colorWithHexColorString:[aDict objectForKey:@"color"]];
    self.url = [aDict objectForKey:@"url"];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Label: {name: %@, url:%@}", self.name, self.url];
}

/*- (void)save
{
    if (self.saveRequest)
        return;

    if (self.url)
        return; // for editing... which we might do one day
    else
        self.saveRequest = [GHAPIRequest requestForNewLabel:self.name color:self.color repositoryIdentifier:<#(NSString *)#>]
}*/

@end
