//
//  LabelsFilterViewController.m
//  BugHub
//
//  Created by Randy on 1/24/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "LabelsFilterViewController.h"
#import "BHRepository.h"
#import "LabelTableViewCellView.h"
#import "BHIssueFilter.h"
#import "BHLabel.h"

static NSString *const kLabelsObserverKey = @"labels";
static NSString *const kCurrentFilterObserverKey = @"currentFilter";

@interface LabelsFilterViewController ()
{
    NSArray *_cachedLabels;
}
- (void)_handleLabelsChanged;
@end

@implementation LabelsFilterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Initialization code here.
        [self addObserver:self forKeyPath:kCurrentFilterObserverKey options:0 context:NULL];
    }
    
    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:kCurrentFilterObserverKey];
    [self setRepository:nil];
}

/*- (void)awakeFromNib
{
    [labelsList registerNib:[[NSNib alloc] initWithNibNamed:@"LabelTableViewCellView" bundle:[NSBundle mainBundle]] forIdentifier:@"BHLabelListCellIdentifier"];
}*/

- (void)awakeFromNib
{
    [self _handleLabelsChanged];
}

- (void)setRepository:(BHRepository *)repo
{
    [self.repository removeObserver:self forKeyPath:kLabelsObserverKey];
    _repository = repo;
    
    if (!repo)
        return;
    
    [repo addObserver:self forKeyPath:kLabelsObserverKey options:0 context:NULL];
    
    [self _handleLabelsChanged];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kLabelsObserverKey] || [keyPath isEqualToString:kCurrentFilterObserverKey])
    {
        [self _handleLabelsChanged];
    }
}

- (void)_handleLabelsChanged
{
    static NSSortDescriptor *sortDescriptor;
    
    if (self.repository == nil || labelsList == nil)
        return;

    if (!sortDescriptor)
    {
        sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES comparator:^NSComparisonResult(BHLabel *obj1, BHLabel *obj2) {
            if (obj1 == [BHLabel voidLabel])
                return NSOrderedAscending;

            if (obj2 == [BHLabel voidLabel])
                return NSOrderedDescending;

            return [[obj1 name] compare:[obj2 name]];
        }];
    }
    
    NSMutableSet *labels = [[self.repository labels] mutableCopy];
    [labels addObject:[BHLabel voidLabel]];
    
    _cachedLabels = [[labels allObjects] sortedArrayUsingDescriptors:@[sortDescriptor]];
    [labelsList reloadData];
    
    NSSet *labelsToSelect = [self.currentFilter labels];
    NSMutableIndexSet *rowsToSelect = [NSMutableIndexSet indexSet];
    for (BHLabel *aLabel in labelsToSelect)
    {
        NSInteger index = [_cachedLabels indexOfObject:aLabel];

        if (index != NSNotFound)
            [rowsToSelect addIndex:index];
    }
    
    [labelsList selectRowIndexes:rowsToSelect byExtendingSelection:NO];
}

#pragma mark tableview data

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [_cachedLabels count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    static NSString *labelCellIdentifier = @"BHLabelListCellIdentifier";
    LabelTableViewCellView *cell = [tableView makeViewWithIdentifier:labelCellIdentifier owner:nil];
    
    if (!cell)
    {
        cell = [[LabelTableViewCellView alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
        [cell setIdentifier:labelCellIdentifier];
    }
    
    BHLabel *label = [_cachedLabels objectAtIndex:row];
    [cell setRepresentedLabel:label];
    
    return cell;

}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    return NO;
}

- (IBAction)tableViewWasClicked:(id)sender
{
    NSInteger row = [labelsList clickedRow];
    
    if (row == -1)
        return;
    
    BOOL isCurrentlySelected = [[labelsList selectedRowIndexes] containsIndex:row];
    
    if (isCurrentlySelected)
        [labelsList deselectRow:row];
    else
        [labelsList selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:YES];
    
    NSArray *selectedLabels = [_cachedLabels objectsAtIndexes:[labelsList selectedRowIndexes]];
    [self.currentFilter setLabels:[NSSet setWithArray:selectedLabels]];
}

@end
