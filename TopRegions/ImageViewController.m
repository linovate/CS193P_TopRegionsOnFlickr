//
//  ImageViewController.m
//  TopPlaces
//
//  Created by Viet Trinh on 1/8/15.
//  Copyright (c) 2015 VietTrinh. All rights reserved.
//

#import "ImageViewController.h"

@interface ImageViewController () <UIScrollViewDelegate, UISplitViewControllerDelegate>
@property (strong, nonatomic) UIImageView* imageView;
@property (strong, nonatomic) UIImage* image;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) UIPopoverController* urlPopoverController;
@end

@implementation ImageViewController

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.scrollView addSubview:self.imageView];
}

#pragma mark - Properties

-(UIImageView*)imageView{
    if (!_imageView) _imageView = [[UIImageView alloc] init];
    return _imageView;
}

-(UIImage*)image{
    return self.imageView.image;
}

-(void)setImage:(UIImage *)image{
    self.imageView.image = image;
    self.scrollView.zoomScale = 1.0;
    self.imageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    self.scrollView.contentSize = self.image ? self.image.size : CGSizeZero;
    [self.spinner stopAnimating];
}

-(void)setScrollView:(UIScrollView *)scrollView{
    _scrollView = scrollView;
    _scrollView.minimumZoomScale = 0.2;
    _scrollView.maximumZoomScale = 2.0;
    _scrollView.delegate = self;
    self.scrollView.contentSize = self.image ? self.image.size : CGSizeZero;
}

-(void)setImgURL:(NSURL *)imgURL{
    _imgURL = imgURL;
    [self downloadingImage];
}

#pragma mark - UIScrollViewDelegate

-(UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return self.imageView;
}

-(void)downloadingImage{
    self.image = nil;
    if (self.imgURL) {
        [self.spinner startAnimating];
        NSURLRequest* request = [NSURLRequest requestWithURL:self.imgURL];
        NSURLSessionConfiguration* configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        NSURLSession* session = [NSURLSession sessionWithConfiguration:configuration];
        NSURLSessionDownloadTask* task = [session downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
            if (!error) {
                if ([request.URL isEqual:self.imgURL]) {
                    UIImage* image = [UIImage imageWithData:[NSData dataWithContentsOfURL:location]];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.image = image;
                    });
                }
            }
        }];
        [task resume];
    }
}

#pragma mark - UISplitViewControllerDelegate

-(void)awakeFromNib{
    self.splitViewController.delegate = self;
}

-(void)splitViewController:(UISplitViewController *)svc willChangeToDisplayMode:(UISplitViewControllerDisplayMode)displayMode{
    if (displayMode == UISplitViewControllerDisplayModePrimaryHidden) {
        self.navigationItem.leftBarButtonItem = svc.displayModeButtonItem;
    }
}

@end
