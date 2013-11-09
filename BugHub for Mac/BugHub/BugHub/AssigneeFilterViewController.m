//
//  AssigneeFilterViewController.m
//  BugHub
//
//  Created by Randy on 1/24/13.
//  Copyright (c) 2013 RCLConcepts. All rights reserved.
//

#import "AssigneeFilterViewController.h"
#import "BHRepository.h"
#import "BHIssueFilter.h"
#import "BHUser.h"
#import "BHRequestQueue.h"

static NSString *const kAssigneeObserverKey = @"assignee";
static NSString *const kCurrentFilterObserverKey = @"currentFilter";

@interface AssigneeFilterViewController ()
{
    NSArray *_cachedAssignee;
}
- (void)_handleAssigneesChanged;
@end

@implementation AssigneeFilterViewController

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

- (IBAction)tableViewWasClicked:(id)sender
{
    NSInteger row = [assigneeList clickedRow];
    
    if (row == -1)
        return;
    
    BOOL isCurrentlySelected = [[assigneeList selectedRowIndexes] containsIndex:row];
    
    if (isCurrentlySelected)
        [assigneeList deselectRow:row];
    else
        [assigneeList selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:YES];
    
    NSArray *selectedAssignees = [_cachedAssignee objectsAtIndexes:[assigneeList selectedRowIndexes]];
    [self.currentFilter setAssignedTo:[NSSet setWithArray:selectedAssignees]];
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
    [self _handleAssigneesChanged];
}

- (void)setRepository:(BHRepository *)repo
{
    [self.repository removeObserver:self forKeyPath:kAssigneeObserverKey];
    _repository = repo;

    if (!repo)
        return;

    [repo addObserver:self forKeyPath:kAssigneeObserverKey options:0 context:NULL];

    [self _handleAssigneesChanged];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kAssigneeObserverKey] || [keyPath isEqualToString:kCurrentFilterObserverKey])
    {
        [self _handleAssigneesChanged];
    }
}

- (void)_handleAssigneesChanged
{
    static NSSortDescriptor *sortDescriptor;
    
    if (self.repository == nil || assigneeList == nil)
        return;
    
    if (!sortDescriptor)
    {
        sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES comparator:^NSComparisonResult(BHUser *obj1, BHUser *obj2) {
            if (obj1 == [BHUser voidUser])
                return NSOrderedAscending;
            
            if (obj2 == [BHUser voidUser])
                return NSOrderedDescending;
            
            return [[obj1 login] compare:[obj2 login]];
        }];
    }

    NSMutableSet *assignees = [[self.repository assignees] mutableCopy];
    [assignees addObject:[BHUser voidUser]];

    _cachedAssignee = [[assignees allObjects] sortedArrayUsingDescriptors:@[sortDescriptor]];
    [assigneeList reloadData];
    
    NSSet *assigneesToSelect = [self.currentFilter assignedTo];
    NSMutableIndexSet *rowsToSelect = [NSMutableIndexSet indexSet];
    for (BHUser *aUser in assigneesToSelect)
    {
        NSInteger index = [_cachedAssignee indexOfObject:aUser];
        
        if (index != NSNotFound)
            [rowsToSelect addIndex:index];
    }
    
    [assigneeList selectRowIndexes:rowsToSelect byExtendingSelection:NO];
}

#pragma mark tableview data

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [_cachedAssignee count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    static NSString *assigneeCellIdentifier = @"BHAssigneeCellIdentifier";
    NSTableCellView *cell = [tableView makeViewWithIdentifier:assigneeCellIdentifier owner:nil];
    
    if (!cell)
    {
        cell = [[NSTableCellView alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
        [cell setIdentifier:assigneeCellIdentifier];
    }
    
    BHUser *user = [_cachedAssignee objectAtIndex:row];
    [cell setObjectValue:user];
    
    return cell;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    return NO;
}

@end
