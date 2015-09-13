//
//  Photo+Create.m
//  TopRegions
//
//  Created by Viet Trinh on 1/23/15.
//  Copyright (c) 2015 Viet Trinh. All rights reserved.
//

#import "Photo+Create.h"
#import "FlickrFetcher.h"
#import "Photographer+Create.h"
#import "Region+Create.h"

@implementation Photo (Create)

+ (Photo *)photoWithFlickrInfo:(NSDictionary *)photoDictionary
        inManagedObjectContext:(NSManagedObjectContext *)context{
    Photo* photo = nil;
    NSError* error;
    
    // Start fetching photos
    NSString* photo_id = [photoDictionary valueForKeyPath:FLICKR_PHOTO_ID];
    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];
    request.predicate = [NSPredicate predicateWithFormat:@"unique = %@",photo_id];
    NSArray* matches = [context executeFetchRequest:request error:&error];
    
    // Analyze fectch request
    if (error || !matches || [matches count] > 1) {
        NSLog(@"Something went wrong with entity Photo in Core Data");
    }
    else if ([matches count]){
        photo = [matches firstObject];
    }
    else{
        photo = [NSEntityDescription insertNewObjectForEntityForName:@"Photo" inManagedObjectContext:context];
        photo.unique = photo_id;
        photo.title = [photoDictionary valueForKeyPath:FLICKR_PHOTO_TITLE];
        photo.subtitle = [photoDictionary valueForKeyPath:FLICKR_PHOTO_DESCRIPTION];
        photo.imgURL = [[FlickrFetcher URLforPhoto:photoDictionary format:FlickrPhotoFormatLarge] absoluteString];
        photo.longitude = [NSNumber numberWithDouble:[photoDictionary[FLICKR_LONGITUDE] doubleValue]];
        photo.latitude = [NSNumber numberWithDouble:[photoDictionary[FLICKR_LATITUDE] doubleValue]];
        photo.thumbnailURL = [[FlickrFetcher URLforPhoto:photoDictionary format:FlickrPhotoFormatSquare] absoluteString];
        
        NSString* photographerName = [photoDictionary valueForKeyPath:FLICKR_PHOTO_OWNER];
        photo.whoTook = [Photographer photographerWithName:photographerName inManagedObjectContext:context];
        
        NSString* regionName = [photoDictionary valueForKeyPath:REGION_NAME];
        photo.inRegion = [Region regionWithName:regionName inManagedObjectContext:context];
        
        [Region photoAtRegion:regionName TakenByPhotographer:photo.whoTook inManagedObjectContext:context];
    }
    
    return photo;
}

+ (void)loadPhotosFromFlickrArray:(NSArray *)photos // of Flickr NSDictionary
         intoManagedObjectContext:(NSManagedObjectContext *)context{
    for (NSDictionary* photo in photos) {
        [self photoWithFlickrInfo:photo inManagedObjectContext:context];
    }
}

@end
