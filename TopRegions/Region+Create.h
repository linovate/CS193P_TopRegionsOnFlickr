//
//  Region+Create.h
//  TopRegions
//
//  Created by Viet Trinh on 1/23/15.
//  Copyright (c) 2015 Viet Trinh. All rights reserved.
//

#import "Region.h"
#import "Photographer.h"
@interface Region (Create)
+(Region*)regionWithName:(NSString*)name inManagedObjectContext:(NSManagedObjectContext *)context;
+(void)photoAtRegion:(NSString*)name TakenByPhotographer:(Photographer*)photographer inManagedObjectContext:(NSManagedObjectContext *)context;
@end
