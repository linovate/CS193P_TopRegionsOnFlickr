//
//  PhotoCDTVC.h
//  TopRegions
//
//  Created by Viet Trinh on 1/23/15.
//  Copyright (c) 2015 Viet Trinh. All rights reserved.
//

#import "CoreDataTableViewController.h"

@interface PhotoCDTVC : CoreDataTableViewController
-(void)photosAtRegion:(NSString*)name inManagedContextObject:(NSManagedObjectContext *)managedObjectContext;
@end
