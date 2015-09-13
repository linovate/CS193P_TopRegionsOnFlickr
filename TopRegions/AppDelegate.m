//
//  AppDelegate.m
//  TopRegions
//
//  Created by Viet Trinh on 1/16/15.
//  Copyright (c) 2015 Viet Trinh. All rights reserved.
//

#import "AppDelegate.h"
#import "PhotoDatabaseAvailability.h"
#import "FlickrFetcher.h"
#import "Photo+Create.h"
#import "Region+Create.h"

@interface AppDelegate () <NSURLSessionDownloadDelegate>
@property (strong, nonatomic) UIManagedDocument* document;
@property (strong, nonatomic) NSManagedObjectContext* photoDatabaseContext;
@property (strong, nonatomic) NSURLSession* downloadSession;
@property (copy, nonatomic) void (^downloadBackgroundURLSessionCompletionHandler)();
@end

@implementation AppDelegate

#define FLICKR_FETCH @"Flickr Fetch"

#pragma mark - Launching Application
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    [self createManagedObjectContext];
    [self startFlickrFetch];
    
    return YES;
}

#pragma mark - Properties

-(void)setDocument:(UIManagedDocument *)document{
    _document = document;
}

-(void)setPhotoDatabaseContext:(NSManagedObjectContext *)photoDatabaseContext{
    _photoDatabaseContext = photoDatabaseContext;
    
    // post notification to regions CDTVC whenever the context is updated
    NSDictionary* userInfo = self.photoDatabaseContext? @{PhotoDatabaseAvailabilityContext: self.photoDatabaseContext} : nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:PhotoDatabaseAvailabilityNotification object:self userInfo:userInfo];
}

-(NSURLSession*)downloadSession{
    if (!_downloadSession) {
        static dispatch_once_t downloadToken;
        dispatch_once(&downloadToken, ^{
            NSURLSessionConfiguration* urlSessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:FLICKR_FETCH];
            _downloadSession = [NSURLSession sessionWithConfiguration:urlSessionConfig delegate:self delegateQueue:nil];
        });
    }
    
    return _downloadSession;
}

#pragma mark - Create Core Data Document
-(void)createManagedObjectContext{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSURL* documentsDirectory = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    NSString* documentName = @"TopRegions";
    NSURL* url = [documentsDirectory URLByAppendingPathComponent:documentName];
    self.document = [[UIManagedDocument alloc] initWithFileURL:url];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
        [self.document openWithCompletionHandler:^(BOOL success) {
            if (success) [self documentIsReady];
            else NSLog(@"Couldn't open document at %@",url);
        }];
    }
    else{
        [self.document saveToURL:url forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            if (success) [self documentIsReady];
            else NSLog(@"Couldn't create document at %@",url);
        }];
    }
}

-(void)documentIsReady{
    if (self.document.documentState == UIDocumentStateNormal) {
        self.photoDatabaseContext = self.document.managedObjectContext;
    }
}

#pragma mark - Fetch Regions and Save into Core Data
-(void)startFlickrFetch{
    // URLSession Delegate functions will get called
    [self.downloadSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        if ([downloadTasks count]) {
            for (NSURLSessionDownloadTask* task in downloadTasks)
                [task resume];
        }
        else{
            NSURLSessionDownloadTask* task = [self.downloadSession downloadTaskWithURL:[FlickrFetcher URLforRecentGeoreferencedPhotos]];
            task.taskDescription = FLICKR_FETCH;
            [task resume];
        }
    }];
}

-(void)loadPhotosFromLocalURL:(NSURL*)localFile intoContext:(NSManagedObjectContext*)context andThenExecuteBlock:(void(^)())whenDone{
    if (context) {
        NSArray* photos = [self flickrPhotosAtURL:localFile];
        //NSLog(@"%@",photos);
        NSLog(@"Fetch completed. Saving into Core Data");
        [Photo loadPhotosFromFlickrArray:photos intoManagedObjectContext:context];
        if (whenDone) whenDone();
    }
    else{
        if (whenDone) whenDone();
    }
}

// Return an array of photo dictionary including region and its photographers information
-(NSArray*)flickrPhotosAtURL:(NSURL*)url{
    NSMutableArray* photosWithRegions = [[NSMutableArray alloc] init];
    NSData* JSONData = [NSData dataWithContentsOfURL:url];
    if (JSONData){
        NSDictionary* photoPropertyList = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:NULL];
        NSArray* photos = [photoPropertyList valueForKeyPath:FLICKR_RESULTS_PHOTOS];
        NSArray* regions = [self regionsForPhotos:photos];
        for (NSDictionary* photo in photos) {
            NSMutableDictionary *mutablePhoto = [photo mutableCopy];
            NSString* placeID = [photo valueForKeyPath:FLICKR_PHOTO_PLACE_ID];
            for (NSDictionary* region in regions) {
                if ([placeID isEqualToString:[region valueForKeyPath:FLICKR_PHOTO_PLACE_ID]]) {
                    [mutablePhoto setObject:[region objectForKey:REGION_NAME] forKey:REGION_NAME];
                    [mutablePhoto setObject:[region objectForKey:PHOTOGRAPHERS] forKey:PHOTOGRAPHERS];
                    [photosWithRegions addObject:mutablePhoto];
                }
            }
        }
    }
    
    // sort the returning region array according to which region has the most photographers taking photos
    [photosWithRegions sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        int photographerList1 = (int)[[obj1 objectForKey:PHOTOGRAPHERS] count];
        int photographerList2 = (int)[[obj2 objectForKey:PHOTOGRAPHERS] count];
        return photographerList2 - photographerList1;
    }];
    
    return photosWithRegions;
}

// Return an array of region sorted with the most photographers
-(NSArray*)regionsForPhotos:(NSArray*)photos{
    NSMutableArray * regions = [[NSMutableArray alloc] init];
    dispatch_group_t fetchRegionsQueue = dispatch_group_create();

    for (NSDictionary* photo in photos) {
        NSString* placeID = [photo valueForKeyPath:FLICKR_PHOTO_PLACE_ID];
        if (placeID) {
            /* Create a single thread for fetching region information
             * and register that thread with the group thread
             */
            dispatch_queue_t fetchRegionEvent = dispatch_queue_create("fetch region name", NULL);
            dispatch_group_async(fetchRegionsQueue, fetchRegionEvent, ^{
                NSURL* urlPlaceID = [FlickrFetcher URLforInformationAboutPlace:placeID];
                NSData* JSONResults = [NSData dataWithContentsOfURL:urlPlaceID];
                NSDictionary* regionPropertyList = [NSJSONSerialization JSONObjectWithData:JSONResults options:0 error:NULL];
                NSString* regionName = [FlickrFetcher extractRegionNameFromPlaceInformation:regionPropertyList];
                /*
                 * If region name exists, add or update that region information
                 */
                if (regionName) {
                    NSString* photographer = [photo valueForKeyPath:FLICKR_PHOTO_OWNER];
                    NSUInteger index = -1;
                    if ([self isRegion:regionName existedIn:regions atIndex:&index]) {
                        NSMutableArray*  photographerList = [[regions objectAtIndex:index] objectForKey:PHOTOGRAPHERS];
                        if (![self isPhotographer:photographer existedIn:photographerList]) {
                            [photographerList addObject:photographer];
                        }
                    }else{
                        NSMutableDictionary* newRegion = [[NSMutableDictionary alloc] init];
                        NSMutableArray* newPhotographerList = [[NSMutableArray alloc] initWithObjects:photographer, nil];
                        [newRegion setObject:regionName forKey:REGION_NAME];
                        [newRegion setObject:newPhotographerList forKey:PHOTOGRAPHERS];
                        [newRegion setObject:placeID forKey:FLICKR_PHOTO_PLACE_ID];
                        [regions addObject:newRegion];
                    }
                }
            });
        }
    }
    
    // waiting for all threads to finish
    dispatch_group_wait(fetchRegionsQueue, DISPATCH_TIME_FOREVER);
    return regions;
}

-(BOOL)isRegion:(NSString*)name existedIn:(NSArray*)regions atIndex:(NSUInteger*)index{
    for (NSDictionary* region in regions){
        NSString* regionName = [region valueForKeyPath:REGION_NAME];
        if ([regionName isEqualToString:name]){
            *index = [regions indexOfObject:region];
            return true;
        }
    }
    return false;
}

-(BOOL)isPhotographer:(NSString*)photographer existedIn:(NSArray*)photographerList{
    for (NSString* existedPhotographer in photographerList) {
        if ([existedPhotographer isEqualToString:photographer]) {
            return true;
        }
    }
    return false;
}

#pragma mark - NSURLSessionDownloadDelegate
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)localFile{
    if ([downloadTask.taskDescription isEqualToString:FLICKR_FETCH]) {
        [self loadPhotosFromLocalURL:localFile
                          intoContext:self.photoDatabaseContext
                  andThenExecuteBlock:^{
                      [self downloadTasksMightBeComplete];
        }];
    }
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    if (error && (session == self.downloadSession)) {
        NSLog(@"Background Download Session has failed: %@",error.localizedDescription);
        [self downloadTasksMightBeComplete];
    }
}

-(void)downloadTasksMightBeComplete{
    if (self.downloadBackgroundURLSessionCompletionHandler) {
        NSLog(@"Download tasks might be completed");
    }
}
@end

