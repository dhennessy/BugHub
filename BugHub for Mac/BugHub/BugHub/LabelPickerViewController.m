//
//  LabelPickerViewController.m
//  BugHub
//
//  Created by Randy on 1/26/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "LabelPickerViewController.h"
#import "BHLabel.h"
#import "BHRepository.h"
#import "BHIssue.h"
#import "NSColor+hex.h"
#import "LabelTableViewCellView.h"
#import "NSSet+Additions.h"
#import "BHRequestQueue.h"
#import "NewLabelWindowController.h"
#import "RepositoryWindowController.h"

@interface LabelPickerViewController ()
{
    BHRepository *_repository;
    NSArray *_cachedLabels;
    NewLabelWindowController *labelCreationWindowController;
}

- (BHRepository *)repository;
- (void)_updatePossibleSelection;
- (void)_modifyIssuesWithLabels:(NSSet *)labelsToChange shouldAdd:(BOOL)shouldAdd;

@end

@implementation LabelPickerViewController

- (void)dealloc
{
    if (_repository)
    {
        [_repository removeObserver:self forKeyPath:@"labels"];
        _repository = nil;
    }
}

- (IBAction)tableViewWasClicked:(id)sender
{
    NSInteger row = [self.labelList clickedRow];

    if (row == -1)
        return;

    NSIndexSet *selectedRows = [self.labelList selectedRowIndexes];
    NSMutableIndexSet *newSelectedRows = [selectedRows mutableCopy];
    BOOL isCurrentlySelected = [selectedRows containsIndex:row];

    if (isCurrentlySelected)
        [newSelectedRows removeIndex:row];
    else
        [newSelectedRows addIndex:row];

    [self.labelList selectRowIndexes:newSelectedRows byExtendingSelection:NO];
    [self.labelList setNeedsDisplay:YES];
    [[self.labelList rowViewAtRow:row makeIfNecessary:NO] setNeedsDisplay:YES];

    [self _modifyIssuesWithLabels:[NSSet setWithObject:[_cachedLabels objectAtIndex:row]] shouldAdd:!isCurrentlySelected];
}

- (void)_modifyIssuesWithLabels:(NSSet *)labelsToChange shouldAdd:(BOOL)shouldAdd
{
    SEL selector = shouldAdd ? @selector(addLabel:) : @selector(removeLabel:);

    for (BHLabel *label in labelsToChange)
        [self.representedIssues makeObjectsPerformSelector:selector withObject:label];
    
    for (id obj in self.representedIssues)
        [[BHRequestQueue mainQueue] addObject:obj];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"labels"])
        [self _updatePossibleSelection];
}

- (void)awakeFromNib
{
    [self _updatePossibleSelection];
}

- (BHRepository *)repository
{
    return _repository;
}

- (void)setRepresentedIssues:(NSSet *)representedIssues
{
    _representedIssues = representedIssues;
    
    BHRepository *newRepo = [[representedIssues anyObject] repository];
    
    if (newRepo != _repository)
    {
        [_repository removeObserver:self forKeyPath:@"labels"];
        _repository = newRepo;
        [newRepo addObserver:self forKeyPath:@"labels" options:0 context:NULL];
    }
    
    [self _updatePossibleSelection];
}

- (void)_updatePossibleSelection
{
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    _cachedLabels = [[[self.repository labels] allObjects] sortedArrayUsingDescriptors:@[sort]];
    [self.labelList reloadData];
    
    if (!_cachedLabels || !self.representedIssues || !self.labelList)
        return;

    NSMutableSet *labelsToSelect = [[[self.representedIssues anyObject] labels] mutableCopy];
    
    for (BHIssue *anIssue in self.representedIssues)
    {
        NSSet *labels = [anIssue labels];
        [labelsToSelect intersectSet:labels];

        if ([labelsToSelect count] == 0)
            break;
    }
    
    //find indexes for those labels and select them in the tableview.
    NSIndexSet *indexesToSelect = [_cachedLabels indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
         if([labelsToSelect containsObject:obj])
         {
             [labelsToSelect removeObject:obj];
             
             if ([labelsToSelect count] == 0)
                 *stop = YES;

             return YES;
         }
        
        return NO;
    }];
    
    [self.labelList selectRowIndexes:indexesToSelect byExtendingSelection:NO];
}

- (IBAction)createNewLabel:(id)sender
{
    labelCreationWindowController = [[NewLabelWindowController alloc] initWithWindowNibName:@"NewLabelWindowController"];
    [labelCreationWindowController setRepo:self.repository];
    [NSApp beginSheet:labelCreationWindowController.window
       modalForWindow:self.repoWindowController.window
        modalDelegate:self.repoWindowController
       didEndSelector:@selector(newLabelOrMilestoneSheeDidEnd:returnCode:context:) contextInfo:NULL];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [_cachedLabels count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    static NSString *labelCellIdentifer = @"BHLabelTableViewCell";
    
    LabelTableViewCellView *cell = [tableView makeViewWithIdentifier:labelCellIdentifer owner:nil];

    if (!cell)
    {
        cell = [[LabelTableViewCellView alloc] initWithFrame:CGRectMake(0, 0, 100, 35)];
        [cell setIdentifier:labelCellIdentifer];
    }

    [cell setRepresentedLabel:[_cachedLabels objectAtIndex:row]];

    return cell;
}

- (void)tableView:(NSTableView *)tableView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row
{
    BHLabel *assigneeForRow = [_cachedLabels objectAtIndex:row];

    [rowView setBackgroundColor:[NSColor whiteColor]];
    
    [self.representedIssues enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, BOOL *stop) {
        if ([[obj labels] containsObject:assigneeForRow])
        {
            *stop = YES;
            [rowView setBackgroundColor:[NSColor colorWithHexColorString:@"e4ecfa"]];
        }
    }];
}


/*- (NSIndexSet *)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes
{
    // if the proposedSelectionIndexes has indexes not in tableview.selectedRowIndexes... add those labels to the issue set
    NSMutableIndexSet *indexesToAdd = [proposedSelectionIndexes mutableCopy];
    [indexesToAdd removeIndexes:[tableView selectedRowIndexes]];
    NSArray *labelsToAdd = [_cachedLabels objectsAtIndexes:indexesToAdd];
    
    for (BHLabel *aLabel in labelsToAdd)
        [self.representedIssues makeObjectsPerformSelector:@selector(addLabel:) withObject:aLabel];
    
    
    
    // if the tableview.selectedRowIndex has indexes not in proposedSelectionIndex... remove those labels from the issue set
    NSMutableIndexSet *indexesToRemove = [[tableView selectedRowIndexes] mutableCopy];
    [indexesToRemove removeIndexes:proposedSelectionIndexes];
    NSArray *labelsToRemove = [_cachedLabels objectsAtIndexes:indexesToRemove];



    for (BHLabel *aLabel in labelsToRemove)
        [self.representedIssues makeObjectsPerformSelector:@selector(removeLabel:) withObject:aLabel];

    [indexesToRemove enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        NSTableRowView *rowView = [tableView rowViewAtRow:idx makeIfNecessary:YES];
        [rowView setBackgroundColor:[NSColor clearColor]];
    }];
    
    for (id obj in self.representedIssues)
         [[BHRequestQueue mainQueue] addObject:obj];

    return proposedSelectionIndexes;
}*/

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    return NO;
}

#pragma sheet delegate
- (void)sheetDidEnd:(NSWindow *)aSheet returnCode:(NSInteger)aReturnCode contextInfo:(void *)someContextStuffs
{
    
}

@end
