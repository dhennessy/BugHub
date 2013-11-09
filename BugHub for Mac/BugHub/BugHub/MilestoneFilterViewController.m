//
//  MilestoneFilterViewController.m
//  BugHub
//
//  Created by Randy on 1/24/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "MilestoneFilterViewController.h"
#import "BHRepository.h"
#import "BHIssueFilter.h"
#import "BHMilestone.h"

static NSString *const kMilestoneObserverKey = @"milestone";
static NSString *const kCurrentFilterObserverKey = @"currentFilter";

@interface MilestoneFilterViewController ()
{
    NSArray *_cachedMilestones;
}
- (void)_handleMilestonesChanged;

@end

@implementation MilestoneFilterViewController

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

- (IBAction)tableViewDidClickRow:(id)sender
{
    NSInteger row = [milestonesList clickedRow];
    
    if (row == -1)
        return;
    
    BOOL isCurrentlySelected = [[milestonesList selectedRowIndexes] containsIndex:row];
    
    if (isCurrentlySelected)
        [milestonesList deselectRow:row];
    else
        [milestonesList selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:YES];
    
    NSArray *selectedMilestones = [_cachedMilestones objectsAtIndexes:[milestonesList selectedRowIndexes]];
    [self.currentFilter setMilestones:[NSSet setWithArray:selectedMilestones]];
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
    [self _handleMilestonesChanged];
}

- (void)setRepository:(BHRepository *)repo
{
    [self.repository removeObserver:self forKeyPath:kMilestoneObserverKey];
    _repository = repo;
    
    if (!repo)
        return;
    
    [repo addObserver:self forKeyPath:kMilestoneObserverKey options:0 context:NULL];
    
    [self _handleMilestonesChanged];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kMilestoneObserverKey] || [keyPath isEqualToString:kCurrentFilterObserverKey])
    {
        [self _handleMilestonesChanged];
    }
}

- (void)_handleMilestonesChanged
{
    static NSSortDescriptor *sortDescriptor;
    
    if (self.repository == nil || milestonesList == nil)
        return;
    
    if (!sortDescriptor)
    {
        sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES comparator:^NSComparisonResult(BHMilestone *obj1, BHMilestone *obj2) {
            if (obj1 == [BHMilestone voidMilestone])
                return NSOrderedAscending;
            
            if (obj2 == [BHMilestone voidMilestone])
                return NSOrderedDescending;
            
            return [[obj1 name] compare:[obj2 name]];
        }];
    }
    
    NSMutableSet *milestones = [[self.repository milestones] mutableCopy];
    [milestones addObject:[BHMilestone voidMilestone]];

    _cachedMilestones = [[milestones allObjects] sortedArrayUsingDescriptors:@[sortDescriptor]];
    [milestonesList reloadData];
    
    NSSet *milestonesToSelect = [self.currentFilter milestones];
    NSMutableIndexSet *rowsToSelect = [NSMutableIndexSet indexSet];
    for (BHMilestone *aMilestone in milestonesToSelect)
    {
        NSInteger index = [_cachedMilestones indexOfObject:aMilestone];

        if (index != NSNotFound)
            [rowsToSelect addIndex:index];
    }
    
    [milestonesList selectRowIndexes:rowsToSelect byExtendingSelection:NO];
}

#pragma mark tableview data

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [_cachedMilestones count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    static NSString *milestoneCellIdentifier = @"BHMilestoneCellIdentifier";
    NSTableCellView *cell = [tableView makeViewWithIdentifier:milestoneCellIdentifier owner:nil];
    
    if (!cell)
    {
        cell = [[NSTableCellView alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
        [cell setIdentifier:milestoneCellIdentifier];
    }
    
    BHMilestone *milestone = [_cachedMilestones objectAtIndex:row];
    [[cell textField] setStringValue:[milestone name]];

    return cell;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    return NO;
}

@end
