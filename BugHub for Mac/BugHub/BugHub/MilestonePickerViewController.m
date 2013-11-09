//
//  MilestonePickerViewController.m
//  BugHub
//
//  Created by Randy on 1/26/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "MilestonePickerViewController.h"
#import "BHRepository.h"
#import "BHIssue.h"
#import "BHMilestone.h"
#import "BHRequestQueue.h"
#import "NewMilestoneWindowController.h"
#import "NSColor+hex.h"
#import "RepositoryWindowController.h"

@interface MilestonePickerViewController ()
{
    NSArray *_cachedMilestones;
    BHRepository *_repository;
    NewMilestoneWindowController *milestoneCreationController;
}

- (BHRepository *)repository;
- (void)_updatePotentialSelection;

@end

@implementation MilestonePickerViewController

- (void)dealloc
{
    [_repository removeObserver:self forKeyPath:@"milestone"];
}

- (BHRepository *)repository
{
    return _repository;
}

- (void)setRepresentedIssues:(NSSet *)representedIssues
{
    _representedIssues = representedIssues;
    BHRepository *newRepo = [[representedIssues anyObject] repository];
    if (_repository != newRepo)
    {
        [_repository removeObserver:self forKeyPath:@"milestone"];
        _repository = newRepo;
        [newRepo addObserver:self forKeyPath:@"milestone" options:0 context:NULL];
    }
    
    [self _updatePotentialSelection];
    
}

- (void)_updatePotentialSelection
{
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    _cachedMilestones = [[[self.repository milestones] allObjects] sortedArrayUsingDescriptors:@[sort]];
    
    [self.milestoneList reloadData];
    
    if (!_cachedMilestones || !self.representedIssues || !self.milestoneList)
        return;
    
    NSInteger possibleSelectionRow = NSNotFound;
    
    for (BHIssue *issue in self.representedIssues)
    {
        if (!issue.milestone)
            continue;
        
        NSInteger indexOfAssignee = [_cachedMilestones indexOfObject:issue.milestone];
        
        if (indexOfAssignee != possibleSelectionRow && possibleSelectionRow == NSNotFound)
            possibleSelectionRow = indexOfAssignee;
        else if(indexOfAssignee != possibleSelectionRow)
        {
            possibleSelectionRow = NSNotFound;
            break;
        }
    }
    
    if (possibleSelectionRow != NSNotFound)
        [self.milestoneList selectRowIndexes:[NSIndexSet indexSetWithIndex:possibleSelectionRow] byExtendingSelection:NO];
    else
        [self.milestoneList deselectAll:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"milestones"])
        [self _updatePotentialSelection];
}

- (void)awakeFromNib
{
    [self _updatePotentialSelection];
}

- (IBAction)createNewMilestone:(id)sender
{    
    milestoneCreationController = [[NewMilestoneWindowController alloc] initWithWindowNibName:@"NewMilestoneWindowController"];
    [milestoneCreationController setRepo:self.repository];
    [NSApp beginSheet:milestoneCreationController.window
       modalForWindow:self.repoWindowController.window
        modalDelegate:self.repoWindowController
       didEndSelector:@selector(newLabelOrMilestoneSheeDidEnd:returnCode:context:) contextInfo:NULL];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [_cachedMilestones count];
}

- (void)tableView:(NSTableView *)tableView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row
{
    BHMilestone *milestoneForRow = [_cachedMilestones objectAtIndex:row];
    
    [rowView setBackgroundColor:[NSColor whiteColor]];
    
    [self.representedIssues enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, BOOL *stop) {
        if ([obj milestone] == milestoneForRow)
        {
            *stop = YES;
            [rowView setBackgroundColor:[NSColor colorWithHexColorString:@"e4ecfa"]];
        }
    }];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    static NSString *identifier = @"BHMilestoneTableCellView";
    
    NSTableCellView *cell = [tableView makeViewWithIdentifier:identifier owner:nil];
    
    BHMilestone *milestone = [_cachedMilestones objectAtIndex:row];
    
    [[cell textField] setStringValue:[milestone name]];
    
    return cell;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSInteger selectedRow = [[self.milestoneList selectedRowIndexes] firstIndex];
    
    BHMilestone *newMilestone = nil;
    if (selectedRow != NSNotFound)
        newMilestone = [_cachedMilestones objectAtIndex:selectedRow];

    [self.representedIssues makeObjectsPerformSelector:@selector(setMilestone:) withObject:newMilestone];

    for (id obj in self.representedIssues)
        [[BHRequestQueue mainQueue] addObject:obj];

    [self.containingPopover performClose:nil];
}


#pragma sheet delegate
- (void)sheetDidEnd:(NSWindow *)aSheet returnCode:(NSInteger)aReturnCode contextInfo:(void *)someContextStuffs
{
    
}

@end
