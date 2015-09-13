//
//  PhotoCDTVC.m
//  TopRegions
//
//  Created by Viet Trinh on 1/23/15.
//  Copyright (c) 2015 Viet Trinh. All rights reserved.
//

#import "PhotoCDTVC.h"
#import "Photo.h"
#import "ImageViewController.h"
@interface PhotoCDTVC ()

@end

@implementation PhotoCDTVC

-(void)photosAtRegion:(NSString*)name inManagedContextObject:(NSManagedObjectContext *)managedObjectContext{
    
    NSSortDescriptor* alphabeticalSort = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES selector:@selector(localizedStandardCompare:)];
    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];
    request.predicate = [NSPredicate predicateWithFormat:@"inRegion.name = %@",name];
    request.sortDescriptors = @[alphabeticalSort];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:managedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"Photo Cell"];
    Photo* photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = photo.title;
    cell.detailTextLabel.text = photo.subtitle;
    cell.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:photo.thumbnailURL]]];
    return cell;
}

#pragma mark - UITableViewDelegate for splitViewController

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    id detail = self.splitViewController.viewControllers[1];
    if ([detail isKindOfClass:[UINavigationController class]]) {
        detail = [((UINavigationController*)detail).viewControllers firstObject];
    }
    if ([detail isKindOfClass:[ImageViewController class]]) {
        [self prepareImageViewController:detail forPhoto:[self.fetchedResultsController objectAtIndexPath:indexPath]];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        NSIndexPath* indexPath = [self.tableView indexPathForCell:sender];
        if (indexPath) {
            if ([segue.identifier isEqualToString:@"Show Photo"]) {
                if ([segue.destinationViewController isKindOfClass:[ImageViewController class]]) {
                    [self prepareImageViewController:segue.destinationViewController forPhoto:[self.fetchedResultsController objectAtIndexPath:indexPath]];
                }
            }
        }
    }
}

-(void)prepareImageViewController:(ImageViewController*)ivc forPhoto:(Photo*)photo{
    ivc.title = photo.title;
    ivc.imgURL = [NSURL URLWithString:photo.imgURL];
}

@end
