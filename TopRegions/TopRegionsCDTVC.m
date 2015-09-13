//
//  TopRegionsCDTVC.m
//  TopRegions
//
//  Created by Viet Trinh on 1/20/15.
//  Copyright (c) 2015 Viet Trinh. All rights reserved.
//

#import "TopRegionsCDTVC.h"
#import "Region.h"
#import "PhotoDatabaseAvailability.h"
#import "PhotoCDTVC.h"

@interface TopRegionsCDTVC ()

@end

@implementation TopRegionsCDTVC

-(void)awakeFromNib{
    [[NSNotificationCenter defaultCenter] addObserverForName:PhotoDatabaseAvailabilityNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      self.managedObjectContext = note.userInfo[PhotoDatabaseAvailabilityContext];
                                                }];
}

-(void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext{
    _managedObjectContext = managedObjectContext;
    
    NSSortDescriptor* popularitySort = [NSSortDescriptor sortDescriptorWithKey:@"popularity" ascending:NO];
    NSSortDescriptor* alphabeticalSort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedStandardCompare:)];
    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Region"];
    request.predicate = nil;
    request.sortDescriptors = @[popularitySort, alphabeticalSort];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:managedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"Region Cell"];
    Region* region = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = region.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d photographers, %d photos",[region.popularity intValue],(int)[region.photos count]];
    return cell;
}

#pragma mark - UITableViewDelegate for splitViewController

/*
 * If iPad version, the detail view is ImageVCEmbedMapVC that is updated
 */
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    id detail = self.splitViewController.viewControllers[1];
    if ([detail isKindOfClass:[UINavigationController class]]) {
        detail = [((UINavigationController*)detail).viewControllers firstObject];
    }
}

 #pragma mark - Navigation

/*
 * If iPhone version, this function gets called and segue is fired
 * If iPad version, this function still gets called but no segue is fired
 */
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
     if ([sender isKindOfClass:[UITableViewCell class]]) {
         NSIndexPath* indexPath = [self.tableView indexPathForCell:sender];
         if (indexPath) {
             Region* region = [self.fetchedResultsController objectAtIndexPath:indexPath];
             if ([segue.identifier isEqualToString:@"List Photos"]) {
                 if ([segue.destinationViewController isKindOfClass:[PhotoCDTVC class]]) {
                     PhotoCDTVC* pvc = (PhotoCDTVC*)segue.destinationViewController;
                     pvc.title = region.name;
                     [pvc photosAtRegion:region.name inManagedContextObject:self.managedObjectContext];
                 }
             }
         }
     }

 }

@end
