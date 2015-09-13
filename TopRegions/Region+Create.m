//
//  Region+Create.m
//  TopRegions
//
//  Created by Viet Trinh on 1/23/15.
//  Copyright (c) 2015 Viet Trinh. All rights reserved.
//

#import "Region+Create.h"

@implementation Region (Create)

+(Region*)regionWithName:(NSString*)name inManagedObjectContext:(NSManagedObjectContext *)context{
    Region* region = nil;
    NSError* error;
    
    if ([name length]) {
        // Start fetching region
        NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Region"];
        request.predicate = [NSPredicate predicateWithFormat:@"name = %@",name];
        NSArray* matches = [context executeFetchRequest:request error:&error];
        
        // Analyze fectch request
        if (error || !matches || [matches count] > 1) {
            NSLog(@"Something went wrong with entity Region in Core Data");
        }
        else if ([matches count]){
            region = [matches firstObject];
        }
        else{
            region = [NSEntityDescription insertNewObjectForEntityForName:@"Region" inManagedObjectContext:context];
            region.name = name;
        }
    }
    
    return region;
}

+(void)photoAtRegion:(NSString*)name TakenByPhotographer:(Photographer*)photographer inManagedObjectContext:(NSManagedObjectContext *)context{
    NSError* error;
    
    if ([name length]) {
        // Start fetching region
        NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Region"];
        request.predicate = [NSPredicate predicateWithFormat:@"name = %@",name];
        NSArray* matches = [context executeFetchRequest:request error:&error];
        
        // Analyze fectch request
        if (error || !matches || [matches count] > 1) {
            NSLog(@"Couln't bind photographer with region in Core Data");
        }
        else if ([matches count]){
            Region* region = [matches firstObject];
            BOOL existed = NO;
            NSMutableArray* photographers = [[region.photographers allObjects] mutableCopy];
            if (!photographers) {
                photographers = [[NSMutableArray alloc] init];
            }
            for (Photographer* existedPhotographer in photographers) {
                if([existedPhotographer.name isEqualToString:photographer.name]) {
                    existed = YES;
                    break;
                }
            }
            if (!existed) {
                [photographers addObject:photographer];
                region.photographers = [NSSet setWithArray:photographers];
                region.popularity = [NSNumber numberWithInt:(int)[photographers count]];
            }
        }
    }
}

@end
