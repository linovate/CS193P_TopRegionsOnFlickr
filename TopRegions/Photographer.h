//
//  Photographer.h
//  TopRegions
//
//  Created by Viet Trinh on 1/23/15.
//  Copyright (c) 2015 Viet Trinh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Photo, Region;

@interface Photographer : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *photos;
@property (nonatomic, retain) NSSet *takePhotoAtRegion;
@end

@interface Photographer (CoreDataGeneratedAccessors)

- (void)addPhotosObject:(Photo *)value;
- (void)removePhotosObject:(Photo *)value;
- (void)addPhotos:(NSSet *)values;
- (void)removePhotos:(NSSet *)values;

- (void)addTakePhotoAtRegionObject:(Region *)value;
- (void)removeTakePhotoAtRegionObject:(Region *)value;
- (void)addTakePhotoAtRegion:(NSSet *)values;
- (void)removeTakePhotoAtRegion:(NSSet *)values;

@end
