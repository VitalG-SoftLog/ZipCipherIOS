//============================================================
//
// Copyright (c) nCrypted Cloud, 2012. All Rights Reserved.
//
// File: DetailViewController.h
// Created By: Oleg Lavronov on 8/4/12.
//
// Description: Detail controller for iPad
//
//===========================================================
#import "DetailViewController.h"
#import "PreviewViewController.h"
#import "PreviewViewController2.h"
#import "NCryptBox.h"
#import "Log.h"


@interface DetailViewController () <DBRestClientDelegate>

@property (strong, nonatomic) UIPopoverController *masterPopoverController;

@end

@implementation DetailViewController

@synthesize appDelegate = _appDelegate;
@synthesize toolbar;
@synthesize labelStatus;
@synthesize labelFile;
@synthesize progressBar;
@synthesize filePath = _filePath;
@synthesize fileURL = _fileURL;
@synthesize sharedFolderKey;
@synthesize rootPopoverButtonItem;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        sharedFolderKey = @"";
        self.title = nil;//NSLocalizedString(@"Preview", @"Preview");
        if (_restClient == nil) {
            _restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
            _restClient.delegate = self;
        }

    }
    return self;
}

#pragma mark -
#pragma mark Managing the popover

- (DBRestClient*)restClient {
    return _restClient;
}




- (void)showRootPopoverButtonItem:(UIBarButtonItem *)barButtonItem
{
   /*
    // Add the popover button to the toolbar.
    NSMutableArray *itemsArray = [toolbar.items mutableCopy];
    [itemsArray insertObject:barButtonItem atIndex:0];
    [toolbar setItems:itemsArray animated:NO];
    [itemsArray release];
    
    self.rootPopoverButtonItem = barButtonItem;
    */
}

- (void)invalidateRootPopoverButtonItem:(UIBarButtonItem *)barButtonItem
{
    /*
    // Remove the popover button from the toolbar.
    NSMutableArray *itemsArray = [toolbar.items mutableCopy];
    [itemsArray removeObject:barButtonItem];
    [toolbar setItems:itemsArray animated:NO];
    [itemsArray release];
    self.rootPopoverButtonItem = nil;
     */
}



#pragma mark -
#pragma mark Rotation support

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark -
#pragma mark Memory management
- (void)dealloc
{
//    [_detailItem release];
//    [toolbar release];
//    [rootPopoverButtonItem  release];
    [super dealloc];
//    [_restClient release];
}

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        [_detailItem release];
        _detailItem = [newDetailItem retain];
        // Update the view.
        [self configureDownload];
    }
}

- (void)configureDownload
{
    // Update the user interface for the detail item.
    if ([self.detailItem isKindOfClass:[DBMetadata class]]) {
        DBMetadata* info = ((DBMetadata*)_detailItem);
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docDirectory = [paths objectAtIndex:0]; // Get documents directory
        NSString *filePath = [docDirectory stringByAppendingPathComponent:info.filename];

        [self.labelStatus setText:@"Downloading..."];
        [self.labelFile setText:info.filename];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.progressBar setProgress:0.0];
//        });
        [self.progressBar setHidden:NO];

        [self.restClient loadFile:info.path intoPath:filePath];
    }
}

- (void)configureUpload:(NSString*)filePath
{
    self.navigationItem.hidesBackButton = TRUE;

    if ([self.detailItem isKindOfClass:[DBMetadata class]]) {
        [self.labelStatus setText:@"Uploading..."];
        [self.labelFile setText:[filePath lastPathComponent]];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.progressBar setProgress:1.0];
//        });
        [self.progressBar setHidden:NO];

        DBMetadata* info = self.detailItem;//((DBMetadata*)_detailItem);
        [self.restClient uploadFile:[filePath lastPathComponent]
                             toPath:[info.path stringByDeletingLastPathComponent]
                      withParentRev:nil
                           fromPath:filePath];
    }

}


- (void)viewDidLoad
{
    [super viewDidLoad];
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [progressBar setProgress:0.0];
    [labelFile setText:@""];
    [self configureDownload];

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.toolbar = nil;
    self.rootPopoverButtonItem = nil;
    self.labelFile = nil;
    self.progressBar = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    //[self.navigationController setNavigationBarHidden:YES];
//    [super viewWillAppear:animated];
}

/*
- (void)viewDidAppear:(BOOL)animated {
//    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.restClient cancelAllRequests];
//    [super viewWillDisappear:animated];
}
*/

- (void)viewWillLayoutSubviews {
//    [super viewWillLayoutSubviews];
/*
    if (rootPopoverButtonItem != nil) {
        [rootPopoverButtonItem.target performSelector: rootPopoverButtonItem.action withObject: rootPopoverButtonItem];
    }
*/ 
}

- (void)viewDidLayoutSubviews {
//    [super viewDidLayoutSubviews];
}

#pragma mark -
#pragma mark Dropbox
- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)destPath
{
    [self.labelStatus setText:@"Downloaded"];

    [self.progressBar setHidden:YES];
    TRACE(@"File loaded %@", destPath);
    self.filePath = [NSString stringWithString:destPath];

    PreviewViewController *previewController = [[PreviewViewController alloc] init];
//    previewController.dataSource = previewController;
//    previewController.delegate = previewController;
    previewController.isRemoteStorage = YES;
    previewController.detailItem = self.detailItem;
    previewController.sharedFolderKey = [NSString stringWithString:self.sharedFolderKey];
    // start previewing the document at the current section index
    previewController.currentPreviewItemIndex = 0;


    @try {
        self.fileURL = [self.appDelegate decryptFile:self.filePath];
    }
    @catch (NSException *exception) {
        [[[[UIAlertView alloc]
		   initWithTitle:[exception name] message:[exception reason]
		   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
		  autorelease]
		 show];
        return;
    }

    if (self.fileURL == nil) {
        self.fileURL = [[NSURL alloc] initFileURLWithPath:self.filePath];
    } else {
        previewController.sourceFile = [NSString stringWithString:self.filePath];
    }

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        // Navigation logic may go here. Create and push another view controller.
        UINavigationController* navigationController = self.navigationController;

        [navigationController pushViewController:previewController animated:YES];
        //[previewController release];
    } else {
//        previewController.fileURL = [[NSURL alloc] initFileURLWithPath:[self.fileURL path]];

//        _restClient.delegate = nil;
        [self dismissViewControllerAnimated:NO completion:^{
            [self.appDelegate.splitViewController  presentModalViewController:previewController animated:YES];
        }];
    }
}

/*
- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)destPath contentType:(NSString*)contentType metadata:(DBMetadata*)metadata
{
    [self.progressBar setHidden:YES];

}
*/

- (void)restClient:(DBRestClient*)client loadProgress:(CGFloat)progress forFile:(NSString*)destPath
{
    [self.progressBar setProgress:progress];
}

- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error
{
    TRACE(@"Download error %@", [error localizedDescription]);
    [[[[UIAlertView alloc]
       initWithTitle:[error domain] message:[error localizedDescription]
       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
      autorelease]
     show];
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)restClient:(DBRestClient*)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath
{
//    [self.navigationController popViewControllerAnimated:YES];

    [self.labelStatus setText:@"Uploaded"];

    TRACE(@"Uploaded File %@", srcPath);
    [self.progressBar setHidden:YES];
    if ([self.detailItem isKindOfClass:[DBMetadata class]]) {
        //DBMetadata* info = ((DBMetadata*)_detailItem);
        [self.restClient deletePath:[self.detailItem path]];
    }

}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError *)error
{
    self.navigationItem.hidesBackButton = NO;

    TRACE(@"Upload error %@", [error localizedDescription]);
    [[[[UIAlertView alloc]
       initWithTitle:[error domain] message:[error localizedDescription]
       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
      autorelease]
     show];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress forFile:(NSString *)destPath from:(NSString *)srcPath
{
    [self.progressBar setProgress:1.0-progress];
}

- (void)restClient:(DBRestClient*)client deletedPath:(NSString *)path
{
//    self.navigationItem.hidesBackButton = NO;
    TRACE(@"Dropbox delete: %@", path);
//    [self.navigationController popViewControllerAnimated:YES];

    UIViewController* controller = self.navigationController.topViewController;

    if (controller) {

    }


    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyDropboxDeleted object:self];


    if (self.rootPopoverButtonItem != nil) {
        [self.rootPopoverButtonItem.target performSelector:self.rootPopoverButtonItem.action
                                                withObject:self.rootPopoverButtonItem];
    }
}

- (void)restClient:(DBRestClient*)client deletePathFailedWithError:(NSError*)error
{
    self.navigationItem.hidesBackButton = NO;

    TRACE(@"Delete error %@", [error localizedDescription]);
    [[[[UIAlertView alloc]
       initWithTitle:[error domain] message:[error localizedDescription]
       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
      autorelease]
     show];
    [self.navigationController popViewControllerAnimated:YES];

    UIViewController* controller = self.navigationController.topViewController;

    if (controller) {

    }

}


#pragma mark -
#pragma mark QLPreviewControllerDataSource

// Returns the number of items that the preview controller should preview
- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)previewController
{
    return 1;
}

- (void)previewControllerDidDismiss:(QLPreviewController *)controller
{
    // if the preview dismissed (done button touched), use this method to post-process previews
}

// returns the item that the preview controller should preview
- (id)previewController:(QLPreviewController *)previewController previewItemAtIndex:(NSInteger)idx
{
    return self.fileURL;
}

#pragma mark -
#pragma mark SplitViewConroller
- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"nCryptedBox", @"nCryptedBox");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}



@end
