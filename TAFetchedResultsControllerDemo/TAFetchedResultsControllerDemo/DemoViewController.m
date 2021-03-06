//
//  DemoViewController.m
//  TAFetchedResultsControllerDemo
//
//  Created by Timothy Armes on 20/06/2012.
//  Copyright (c) 2012 Timothy Armes. All rights reserved.
//

#import "DemoViewController.h"

#import "Section.h"
#import "Item.h"

#define kLabelTag 1000

@interface DemoViewController ()

@property (weak, nonatomic) Section *mostRecentlyCreatedSection;
@property (strong, nonatomic) TAFetchedResultsController *taFetchedResultsController;
@property (strong, nonatomic) NSMutableArray *sectionViewIndexMapping;
@property (strong, nonatomic) UIButton *dummyView;
@property (nonatomic) BOOL inManualReorder;
@property (nonatomic) BOOL sectionsDeletionsPending;

- (void)configureView;

@end

@implementation DemoViewController

@synthesize tableView = _tableView;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize taFetchedResultsController = _taFetchedResultsController;
@synthesize sectionViewIndexMapping = _buttonIndexMapping;
@synthesize dummyView = _dummyView;
@synthesize mostRecentlyCreatedSection = _mostRecentlyCreatedSection;
@synthesize inManualReorder = _inManualReorder;
@synthesize sectionsDeletionsPending = _sectionsDeletionsPending;

#pragma mark - Managing the detail item

- (void)configureView
{
    // This shgould happen automatically once TAFetchedResultsController is finished
    [self.taFetchedResultsController updateSections];
    
    // Set up the table
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // Do any additional setup after loading the view, typically from a nib.
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    self.sectionViewIndexMapping = [[NSMutableArray alloc] initWithCapacity:20];
    self.dummyView = [[UIButton alloc] init];
    self.sectionsDeletionsPending = NO;
    
    [self configureView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.taFetchedResultsController = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Detail", @"Detail");
    }
    return self;
}

-(void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];
}

#pragma mark - Table View

- (Item *)itemAtIndexPath:(NSIndexPath *)indexPath
{
    NSManagedObject *object = [self.taFetchedResultsController objectAtIndexPath:indexPath];
    return (Item *)object;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // This is handled as for NSFetchedResultsController, but we must be careful to access 'sections' and not 'sections'.
    
    NSUInteger numSections = [[self.taFetchedResultsController sections] count];    
    return numSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // This is handled as for NSFetchedResultsController, but we must be careful to access 'sections' and not 'sections'.
    
    id <TAFetchedResultsSectionInfo> sectionInfo = [[self.taFetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

// Customize the appearance of table view cells.

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ItemCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.showsReorderControl = YES;
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

// Customize the appearence of the header sections 

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // Create the parent view that will hold header's label
    
    UIView* customView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 44.0)];
    customView.backgroundColor = [UIColor grayColor];
    
    // Create a text label
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, tableView.bounds.size.width - 60 - 60 - 10, 44.0)];
    label.text = [tableView.dataSource tableView:tableView titleForHeaderInSection:section];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont boldSystemFontOfSize:14];
    label.textColor = [UIColor whiteColor];
    label.tag = kLabelTag;
    [customView addSubview:label];
    
    // Create the 'delete' button object
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(tableView.bounds.size.width - 60, 6, 50, 30.0)];
    button.backgroundColor = [UIColor redColor];
    button.opaque = YES;
    button.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    [button setTitle:@"Delete" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(deleteSection:) forControlEvents:UIControlEventTouchUpInside];
    [customView addSubview:button];
    
    // Create the 'empty' button object
    
    button = [[UIButton alloc] initWithFrame:CGRectMake(tableView.bounds.size.width - 60 - 60, 6, 50, 30.0)];
    button.backgroundColor = [UIColor redColor];
    button.opaque = YES;
    button.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    [button setTitle:@"Empty" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(emptySection:) forControlEvents:UIControlEventTouchUpInside];
    [customView addSubview:button];

    // Create the 'update' button object
    
    button = [[UIButton alloc] initWithFrame:CGRectMake(tableView.bounds.size.width - 60 - 60 - 60, 6, 50, 30.0)];
    button.backgroundColor = [UIColor blueColor];
    button.opaque = YES;
    button.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    [button setTitle:@"Update" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(updateSection:) forControlEvents:UIControlEventTouchUpInside];
    [customView addSubview:button];

    // Store this button in the mapping array - first make sure that we have an object to replace
    
    while ([self.sectionViewIndexMapping count] <= section)
        [self.sectionViewIndexMapping addObject:_dummyView];
    
    // Now replace the object at that index
    
    [self.sectionViewIndexMapping replaceObjectAtIndex:section withObject:customView];
    
    return customView;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 44.0;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (editingStyle) {
        case UITableViewCellEditingStyleDelete:
        {
            [self.managedObjectContext deleteObject:[self.taFetchedResultsController objectAtIndexPath:indexPath]];
            
            NSError *error = nil;
            if (![self.managedObjectContext save:&error]) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }
        }
            break;
            
        default:   
            break;
    }   
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // In this demo we allow rows to be moved, but only between sections. Order within a section is always alphabetical....
    return YES;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    // In this demo we allow rows to be moved, but only between sections. Order within a section is always alphabetical....
    
    // If the sections are the same, don't allow the move since it's already in order
    
    if (sourceIndexPath.section == proposedDestinationIndexPath.section)
        return sourceIndexPath;
    
    // If they're not the same, place it in the right (alphabetical) position....
    
    Item *itemToMove = [self itemAtIndexPath:sourceIndexPath];
    
    id <TAFetchedResultsSectionInfo> sectionInfo = [[self.taFetchedResultsController sections] objectAtIndex:proposedDestinationIndexPath.section];
    NSArray *items = [sectionInfo objects];
    NSUInteger idx = 0;
    for (Item *itemInSection in items) {
        NSComparisonResult res = [itemInSection.name compare:itemToMove.name options:NSCaseInsensitiveSearch];
        if (res == NSOrderedDescending)
            break;
        
        idx++;
    }
    
    return [NSIndexPath indexPathForRow:idx inSection:proposedDestinationIndexPath.section];
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    self.inManualReorder = YES;
    
    Item *item = [self itemAtIndexPath:fromIndexPath];
    id <TAFetchedResultsSectionInfo> sectionInfo = [[self.taFetchedResultsController sections] objectAtIndex:toIndexPath.section];
    Section *newSection = (Section *)sectionInfo.theManagedObject;
    
    // Assign the item to the new section
    
    if (item.section != newSection)
        item.section = newSection;
    
    // Save the managed context
    
    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    self.inManualReorder = NO;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    id <TAFetchedResultsSectionInfo> sectionInfo = [[self.taFetchedResultsController sections] objectAtIndex:section];
    Section *sectionObject = (Section *)sectionInfo.theManagedObject;
    return sectionObject.name;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Item *item = [self itemAtIndexPath:indexPath];
    cell.textLabel.text = item.name;
}   

#pragma mark - Fetched results controller

- (void)updateSectionViewMapping
{
    if (self.sectionsDeletionsPending)
    {
        NSMutableArray *newMapping = [NSMutableArray arrayWithCapacity:[[self.taFetchedResultsController sections] count]];
        
        // Add non null object to our new array
        
        for (id obj in self.sectionViewIndexMapping) {
            if (![obj isKindOfClass:[NSNull class]]) {
                [newMapping addObject:obj];
            }
        }
        
        // Use the new array from now on
        
        self.sectionViewIndexMapping = newMapping;
    }
    
    self.sectionsDeletionsPending = NO;
}

- (TAFetchedResultsController *)taFetchedResultsController
{
    if (_taFetchedResultsController != nil) {
        return _taFetchedResultsController;
    }
    
    // Prepare a fetch request for the items
    
    NSFetchRequest *itemFetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Item" inManagedObjectContext:self.managedObjectContext];
    [itemFetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    
    [itemFetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    //
    // As with NSFetchedResultsController, we first have to group into sections. For the demo we assume that
    // sections names are unique...
    //
    // We then order the items alphabetically by name within each section
    
    NSSortDescriptor *groupingDescriptor = [[NSSortDescriptor alloc] initWithKey:@"section.uuid" ascending:YES];
    NSSortDescriptor *nameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:groupingDescriptor, nameDescriptor, nil];
    
    [itemFetchRequest setSortDescriptors:sortDescriptors];
    
    // Prepare a fetch request for the Section headers 
    
    NSEntityDescription *sectionEntityDescription = [NSEntityDescription entityForName:@"Section" inManagedObjectContext:self.managedObjectContext];
    NSFetchRequest *sectionFetchRequest = [[NSFetchRequest alloc] init];
    [sectionFetchRequest setEntity:sectionEntityDescription];
    
    // For this demo, we order by timestamp
    //
    // Note that unlike for NSFetchedResultsController, TAFetchedResultsController allows us to arbitrarily order the sections.
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:YES];
    [sectionFetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    // Create the TAFetchedResultsController
    
    TAFetchedResultsController *taFetchedResultsController = [[TAFetchedResultsController alloc] initWithItemFetchRequest:itemFetchRequest
                                                                                                      sectionFetchRequest:sectionFetchRequest
                                                                                                     managedObjectContext:self.managedObjectContext
                                                                                                   sectionGroupingKeyPath:@"section.uuid"
                                                                                                                cacheName:nil];
    
    // We want to respond to model changes
    
    taFetchedResultsController.delegate = self;
    
    self.taFetchedResultsController = taFetchedResultsController;
    
    NSError *error = nil;
    if (![self.taFetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _taFetchedResultsController;
}    

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    if (!self.inManualReorder)
    {
        NSLog(@"Beginning table updates");
        [self.tableView beginUpdates];
    }
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{ 
    // We get these notifications when changes are made to the context concerning the Entity used for sections.
    //
    // Note that we get all the deletions first...
    
    switch(type) {
            
        case NSFetchedResultsChangeDelete:
            
            NSLog(@"TAFetchResultsController requesting SECTION DELETE at index %d]", sectionIndex);
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            
            // This section's been deleted, so the button will be removed.
            //
            // We can't just deleted it from the mapping because any future calls to NSFetchedResultsChangeDelete are based on the indexes at the 
            // start of this set of deleted. We mark the deletion and rember that we have to remap later
            
            [self.sectionViewIndexMapping replaceObjectAtIndex:sectionIndex withObject:[NSNull null]];
            self.sectionsDeletionsPending = YES;
            
            break;

        case NSFetchedResultsChangeInsert:
            
            NSLog(@"TAFetchResultsController requesting SECTION INSERT at index %d]", sectionIndex);
            
            // If we have already deleted sections then we need to remove them from the mapping. If we don't do this then the 
            // indexes in the mapping array will not match those passed in here.
            
            [self updateSectionViewMapping];

            // Insert the row
            
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            
            // Stick a dummy object in our mapping array - it'll be updated when UITableView calls back to get the header view.
            // We don't pass in a NSNull since that's what we do to mark deleted rows...
            
            [self.sectionViewIndexMapping insertObject:_dummyView atIndex:sectionIndex];
            
            break;

        case NSFetchedResultsChangeUpdate:
        {
            NSLog(@"TAFetchResultsController requesting SECTION UPDATE at index %d]", sectionIndex);

            // *Any* changes to the section object will cause this call back to be received.
            //
            // This includes, for example, deleting a row from the section since core data sees that as a change to the relationship.
            //
            // To avoid flickering the section title needlessly we need to check if that has changed. There's no SDK to get a section's title,
            // however our sectionViewMapping once again comes to the rescue. Ugly? Yes. but it works.            
            
            UIView *container = (UIView *)[self.sectionViewIndexMapping objectAtIndex:sectionIndex];
            
            if (container) // there really should be!
            {
                UILabel *label = (UILabel *)[container viewWithTag:kLabelTag];
                
                id <TAFetchedResultsSectionInfo> si = [[self.taFetchedResultsController sections] objectAtIndex:sectionIndex];
                Section *section = (Section *)[si theManagedObject];
                
                if (![label.text isEqualToString:section.name])
                {
                    NSLog(@"Section name changed from %@ to %@ - reloading section", label.text, section.name);
                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                }
            }
            
            break;
        }
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    // This is handled as for NSFetchedResultsController
    
    UITableView *tableView = self.tableView;
    
    if (!self.inManualReorder)
    {
        switch(type) {
            case NSFetchedResultsChangeInsert:
                NSLog(@"TAFetchResultsController requesting OBJECT INSERT at [%d, %d]", newIndexPath.section, newIndexPath.row);
                [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            case NSFetchedResultsChangeDelete:
                NSLog(@"TAFetchResultsController requesting OBJECT DELETE to [%d, %d]", indexPath.section, indexPath.row);
                [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            case NSFetchedResultsChangeUpdate:
                NSLog(@"TAFetchResultsController requesting OBJECT UPDATE to [%d, %d]", indexPath.section, indexPath.row);
                [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
                break;
                
            case NSFetchedResultsChangeMove:
                NSLog(@"TAFetchResultsController requesting OBJECT MOVE from [%d, %d] to [%d, %d]", indexPath.section, indexPath.row, newIndexPath.section, newIndexPath.row);
                NSLog(@"Updating table MOVE request");
                [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
                [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
                break;
        }
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if (!self.inManualReorder)
    {
        NSLog(@"Ending table updates");
        [self.tableView endUpdates];
    }
    
    // In there were any sections deleted during the update then this would have been noted in the button mapping. Now that's done we should
    // actually remove the nullified objects.

    [self updateSectionViewMapping];
    
}

#pragma mark - Button handling (used for testing the app)

- (IBAction)addNewSection:(id)sender {
    
    
    Section *newSection = [NSEntityDescription insertNewObjectForEntityForName:@"Section" inManagedObjectContext:self.managedObjectContext];
    
    newSection.name = [NSString stringWithFormat:@"Section %d", [[self.taFetchedResultsController sections] count] + 1];
    newSection.timeStamp = [NSDate date];
    
    // Create a unique and unchanging UUID for this sections
    
    CFUUIDRef newUniqueId = CFUUIDCreate(kCFAllocatorDefault);
    newSection.uuid = (__bridge_transfer NSString*)CFUUIDCreateString(kCFAllocatorDefault, newUniqueId);
    CFRelease(newUniqueId);
    
    // Save the context.
    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    self.mostRecentlyCreatedSection = newSection;
    
    // Note: TAFetchedResultsController will call back to update the UITableView
}

- (IBAction)addNewItem:(id)sender {
    
    // Make sure there's at least one section.
    
    if ([self.taFetchedResultsController.sections count] == 0)
        [self addNewSection:nil];
    
    // If we havn't added a section in this session, just add the item to the first one for the purposes of this demo
    
    if (!self.mostRecentlyCreatedSection)
    {
        id <TAFetchedResultsSectionInfo> si = (id <TAFetchedResultsSectionInfo>)[self.taFetchedResultsController.sections objectAtIndex:0];
        self.mostRecentlyCreatedSection = (Section *)si.theManagedObject;
    }
    
    // Create the Item
    
    NSManagedObjectContext *context = self.managedObjectContext;
    Item *newItem = [NSEntityDescription insertNewObjectForEntityForName:@"Item" inManagedObjectContext:context];
    
    // If appropriate, configure the new managed object.
    
    newItem.name = [NSString stringWithFormat:@"New Item %d", [self.taFetchedResultsController.fetchedObjects count] + 1];
    newItem.section = self.mostRecentlyCreatedSection;
    
    // Save the context
    
    NSError *error = nil;
    if (![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    // Note: TAFetchedResultsController will call back to update the UITableView
}

- (void)deleteSection:(UIButton *)button {
    
    // Delete the section from the object model.
    // 
    // TAFetchedResultsController will detect the change and call back to update the table....
    
    // We get the index of of our button by searching our array
    
    NSUInteger index = [self.sectionViewIndexMapping indexOfObject:button.superview];
    if (index == NSNotFound)
    {
        NSLog(@"Unable to find index of section from button object. Oops");
        abort();
    }
    
    id <TAFetchedResultsSectionInfo> si = [[self.taFetchedResultsController sections] objectAtIndex:index];
    [self.managedObjectContext  deleteObject:si.theManagedObject];
    
    // Save the context
    
    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

- (void)emptySection:(UIButton *)button {
    
    // Empty a section from the object model by deleting all the rows that it owns.
    // This allows us to test the deletion of multiple rows at once.
    //
    // TAFetchedResultsController will detect the change and call back to update the table....
    
    // We get the index of of our button by searching our array
    
    NSUInteger index = [self.sectionViewIndexMapping indexOfObject:button.superview];
    if (index == NSNotFound)
    {
        NSLog(@"Unable to find index of section from button object. Oops");
        abort();
    }
    
    id <TAFetchedResultsSectionInfo> si = [[self.taFetchedResultsController sections] objectAtIndex:index];
    Section *section = (Section *)si.theManagedObject;
    
    for (Item *item in section.items) {
        [self.managedObjectContext deleteObject:item];
    }
        
    // Save the context
    
    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

- (void)updateSection:(UIButton *)button {
    
    // Update the button's name just to show that TAFetchedResultsController can detect changes and pass them on
    
    // We get the index of of our button by searching our array
    
    NSUInteger index = [self.sectionViewIndexMapping indexOfObject:button.superview];
    if (index == NSNotFound)
    {
        NSLog(@"Unable to find index of section from button object. Oops");
        abort();
    }
    
    id <TAFetchedResultsSectionInfo> si = [[self.taFetchedResultsController sections] objectAtIndex:index];
    Section *section = (Section *)si.theManagedObject;
    section.name = @"Updated!";
    
    // Save the context
    
    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

// This action simulates the scenario where the model has been updated elsewhere, and
// all row entities have been removed. This means that the NSFetchedResultsController (NSFRC)
// now has zero sections, but we still need to remove our rows from the tableview...

- (IBAction)clearAllItems:(id)sender {
    
    // Create fetch request
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Item" inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];	
    
	// Execute the request
	NSError *error = nil;
	NSArray *fetchResults = [self.managedObjectContext executeFetchRequest:request error:&error];
    
	// Delete the objects returned if the results weren't nil
	if (fetchResults != nil) {
		for (NSManagedObject *manObj in fetchResults) {
			[self.managedObjectContext deleteObject:manObj];
		}
    }
    
    if (![self.managedObjectContext save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
}


@end
