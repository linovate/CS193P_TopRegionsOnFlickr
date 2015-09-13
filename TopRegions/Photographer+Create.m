//
//  Photographer+Create.m
//  TopRegions
//
//  Created by Viet Trinh on 1/23/15.
//  Copyright (c) 2015 Viet Trinh. All rights reserved.
//

#import "Photographer+Create.h"
#import "Region+Create.h"

@implementation Photographer (Create)

+ (Photographer *)photographerWithName:(NSString *)name inManagedObjectContext:(NSManagedObjectContext *)context{
    Photographer* photographer = nil;
    NSError* error;
    
    if ([name length]) {
        // Start fetching photographer
        NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Photographer"];
        request.predicate = [NSPredicate predicateWithFormat:@"name = %@",name];
        NSArray* matches = [context executeFetchRequest:request error:&error];
        
        // Analyze fectch request
        if (error || !matches || [matches count] > 1) {
            NSLog(@"Something went wrong with entity Photographer in Core Data");
        }
        else if ([matches count]){
            photographer = [matches firstObject];
        }
        else{
            photographer = [NSEntityDescription insertNewObjectForEntityForName:@"Photographer" inManagedObjectContext:context];
            photographer.name = name;
        }
    }
    
    return photographer;
}

@end
