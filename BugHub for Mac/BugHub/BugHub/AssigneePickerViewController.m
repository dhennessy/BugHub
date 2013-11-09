//
//  AssigneePickerViewController.m
//  BugHub
//
//  Created by Randy on 1/26/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "AssigneePickerViewController.h"
#import "AssigneeTableCellView.h"
#import "BHRepository.h"
#import "BHUser.h"
#import "BHIssue.h"
#import "BHRequestQueue.h"
#import "NSColor+hex.h"

@interface AssigneePickerViewController ()
{
    NSArray *_cachedAssignees;
    NSSet *_currentParialSelection;
}
- (void)_updatePossibleSelection;
@end

@implementation AssigneePickerViewController

- (void)dealloc
{
    [_repository removeObserver:self forKeyPath:@"assignees"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"assignees"])
        [self _updatePossibleSelection];
}

- (void)awakeFromNib
{
    [self _updatePossibleSelection];
}

- (void)setRepository:(BHRepository *)repository
{
    if (repository == _repository)
        return;

    [_repository removeObserver:self forKeyPath:@"assignees"];
    _repository = repository;
    [_repository addObserver:self forKeyPath:@"assignees" options:0 context:NULL];
    
    [self _updatePossibleSelection];
}

- (void)setRepresentedIssues:(NSSet *)representedIssues
{
    // update the selection style, maybe...
    _representedIssues = representedIssues;
    [self _updatePossibleSelection];
}

- (void)_updatePossibleSelection
{
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"login" ascending:YES];
    _cachedAssignees = [[[self.repository assignees] allObjects] sortedArrayUsingDescriptors:@[sort]];
    
    [self.assigneeList reloadData];

    if (!_cachedAssignees || !self.representedIssues || !self.assigneeList)
        return;
    
    NSInteger possibleSelectionRow = NSNotFound;

    for (BHIssue *issue in self.representedIssues)
    {
        if (!issue.assignee)
            continue;

        NSInteger indexOfAssignee = [_cachedAssignees indexOfObject:issue.assignee];
        
        if (indexOfAssignee != possibleSelectionRow && possibleSelectionRow == NSNotFound)
            possibleSelectionRow = indexOfAssignee;
        else if(indexOfAssignee != possibleSelectionRow)
        {
            possibleSelectionRow = NSNotFound;
            break;
        }
    }

    if (possibleSelectionRow != NSNotFound)
        [self.assigneeList selectRowIndexes:[NSIndexSet indexSetWithIndex:possibleSelectionRow] byExtendingSelection:NO];
    else
        [self.assigneeList deselectAll:nil];
}




- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [_cachedAssignees count];
}

- (void)tableView:(NSTableView *)tableView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row
{
    BHUser *assigneeForRow = [_cachedAssignees objectAtIndex:row];

    [rowView setBackgroundColor:[NSColor whiteColor]];
    
    [self.representedIssues enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, BOOL *stop) {
        if ([obj assignee] == assigneeForRow)
        {
            *stop = YES;
            [rowView setBackgroundColor:[NSColor colorWithHexColorString:@"e4ecfa"]];
        }
    }];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    AssigneeTableCellView *cell = [tableView makeViewWithIdentifier:@"BHAssigneeTableCell" owner:nil];
    BHUser *anAssignee = [_cachedAssignees objectAtIndex:row];
    [cell setObjectValue:anAssignee];

    return cell;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSInteger selectedRow = [[self.assigneeList selectedRowIndexes] firstIndex];
    BHUser *newAssignee = nil;
    
    if (selectedRow != NSNotFound)
         newAssignee = [_cachedAssignees objectAtIndex:selectedRow];
    
    [self.representedIssues makeObjectsPerformSelector:@selector(setAssignee:) withObject:newAssignee];
    
    for (id obj in self.representedIssues)
        [[BHRequestQueue mainQueue] addObject:obj];

    [self.containingPopover performClose:nil];
}

@end
