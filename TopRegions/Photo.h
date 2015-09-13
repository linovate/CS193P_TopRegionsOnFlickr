//
//  Photo.h
//  TopRegions
//
//  Created by Viet Trinh on 1/29/15.
//  Copyright (c) 2015 Viet Trinh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Photographer, Region;

@interface Photo : NSManagedObject

@property (nonatomic, retain) NSString * imgURL;
@property (nonatomic, retain) NSString * subtitle;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * unique;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSString * thumbnailURL;
@property (nonatomic, retain) Region *inRegion;
@property (nonatomic, retain) Photographer *whoTook;

@end
