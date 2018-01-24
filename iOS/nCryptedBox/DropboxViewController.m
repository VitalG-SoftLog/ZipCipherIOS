//============================================================
//
// Copyright (c) nCrypted Cloud, 2012. All Rights Reserved.
//
// File: DropboxViewController.m
// Created By: Oleg Lavronov on 7/25/12.
//
// Description: Dropbox view controller
//
//===========================================================
#import "Log.h"
#import "NCryptBox.h"
#import "MBProgressHUD.h"
#import "DropboxViewController.h"
#import "DetailViewController.h"
#import "PreviewViewController.h"
#import "PreviewViewController2.h"

@interface DropboxViewController () <DBRestClientDelegate>

- (void)setWorking:(BOOL)isWorking;

@property (nonatomic, readonly) DBRestClient* restClient;

@end

@implementation DropboxViewController

@synthesize activityIndicator;
@synthesize documentURLs = _documentURLs;
@synthesize sharedFolders = _sharedFolders;
@synthesize activityView;
@synthesize activityWheel;
@synthesize pathName = _pathName;
@synthesize appDelegate = _appDelegate;
@synthesize sharedFolderKey;
@synthesize filePath;
@synthesize fileURL;
@synthesize modalStyle;
@synthesize delegate;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        sharedFolderKey =@"";
        modalStyle = NO;
        _pathName = @"/";
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshList) name:kNotifyDropboxDeleted object:nil];
    }
    return self;
}


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        sharedFolderKey = @"";
        modalStyle = NO;
        _pathName = @"/";
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshList) name:kNotifyDropboxDeleted object:nil];
    }
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[_documentURLs release];
	[_sharedFolders release];
	[super dealloc];
}


- (void)setPathName:(NSString *)newPathName
{
    if (_pathName != newPathName) {
        _pathName = newPathName;
        // Update the view.
        //[self reloadView];
    }

    if ([newPathName compare:@"/"] == NSOrderedSame) {
        [self setTitle:@"Dropbox"];
    } else {
        [self setTitle:[newPathName lastPathComponent]];
    }
}



- (void)reloadView
{
    [self setWorking:YES];
    //[MBProgressHUD hideHUDForView:[[UIApplication sharedApplication] keyWindow] animated:YES];

    [self.documentURLs removeAllObjects];
    [self.tableView reloadData];
    NSLog(@"Dropbox path: %@", self.pathName);
    [self.restClient loadMetadata:self.pathName];// withHash:filesHash];
    //[self setWorking:NO];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    working = NO;

    if (self.documentURLs == nil)
    {
        self.documentURLs = [NSMutableArray array];
    }

    if (self.sharedFolders == nil)
    {
        self.sharedFolders = [NSMutableDictionary dictionary];
    }

    self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;

    if (modalStyle) {
        // right side of nav bar
        //UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 106, 44)];
        NSMutableArray *buttons = [[NSMutableArray alloc] initWithCapacity:3];

        UIBarButtonItem *deleteButton = [[UIBarButtonItem alloc]
                                         initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                         target:self
                                         action:@selector(doneAction:)];
        deleteButton.style = UIBarButtonItemStyleBordered;
        [buttons addObject:deleteButton];
        [deleteButton release];

        UIBarButtonItem *spacer = [[UIBarButtonItem alloc]
                                   initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                   target:nil
                                   action:nil];
        [buttons addObject:spacer];
        [spacer release];

        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]
                                         initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                         target:self
                                         action:@selector(cancelAction:)];
        cancelButton.style = UIBarButtonItemStylePlain;
        [buttons addObject:cancelButton];
        [cancelButton release];
        
        [self.navigationController setToolbarHidden:NO];
        [self setToolbarItems:buttons];
//        toolbar.barStyle = -1;
        [buttons release];
        
//        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:toolbar];
//        [toolbar release];



    } else {
        [self.navigationController setToolbarHidden:YES];
        UIBarButtonItem *btnUnlink = [[[UIBarButtonItem alloc] initWithTitle:@"Unlink"
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:self
                                                                      action:@selector(buttonUnlink:)]autorelease];
        self.navigationItem.rightBarButtonItem = btnUnlink;
    }

}

- (void)viewDidUnload
{
    [super viewDidUnload];

    self.activityIndicator = nil;

    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    // [super viewWillAppear:animated];
    [self reloadView];
}

- (void)viewWillDisappear:(BOOL)animated
{
  //  [self.restClient cancelAllRequests];
    //    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.documentURLs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (!cell)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier] autorelease];
    }
    cell.accessoryType = UITableViewCellAccessoryNone;


    DBMetadata* info = [self.documentURLs objectAtIndex:indexPath.row];

    if ([NCryptBox checkExtension:info.filename]) {
        cell.textLabel.text  = [[info.path lastPathComponent] stringByDeletingPathExtension];
    } else {
        cell.textLabel.text = [info.path lastPathComponent];
    }

    UIImage* icon = [UIImage imageNamed:[NSString stringWithFormat:@"%@48.gif", info.icon]];
    UIImage* iconCrypt = [UIImage imageNamed:@"crypt2.png"];
    if (icon == nil) {
        icon = [UIImage imageNamed:@"page_white48.gif"];
    }

    UIGraphicsBeginImageContext(CGSizeMake(36,36));
    [icon drawInRect:CGRectMake(0, 0, 36, 36)];

    if ([NCryptBox checkExtension:info.filename])
    {
        [iconCrypt drawInRect:CGRectMake(0, 0, 18, 18)];
    }

    if (!info.isDirectory) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@", info.humanReadableSize,
                                     [NSDateFormatter localizedStringFromDate:info.lastModifiedDate
                                                                    dateStyle:kCFDateFormatterMediumStyle
                                                                    timeStyle:NSDateFormatterShortStyle]];

    } else {
        cell.detailTextLabel.text = @"";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        NSString* isSharedFolder = [self.sharedFolders objectForKey:info.path];
        if (([isSharedFolder length] != 0) || ([sharedFolderKey length] != 0)) {
            cell.detailTextLabel.text = @"nCryptedBox shared folder";
            [iconCrypt drawInRect:CGRectMake(0, 0, 18, 18)];
        }
    }

    cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    [cell setAccessoryView:nil];
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DBMetadata* info = [self.documentURLs objectAtIndex:indexPath.row];
    self.detailItem = info;

    if (info.isDirectory) {
        NSLog(@"Opening path %@", info.path);
        DropboxViewController* detailViewController = [[[DropboxViewController alloc] initWithNibName:@"DropboxViewController_iPhone" bundle:nil] autorelease];
        detailViewController.sharedFolderKey = [NSString stringWithString:self.sharedFolderKey];
        detailViewController.modalStyle = self.modalStyle;
        detailViewController.delegate = self.delegate;
        [detailViewController setPathName:info.path];
        [self.navigationController pushViewController:detailViewController animated:YES];
    } else {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docDirectory = [paths objectAtIndex:0]; // Get documents directory
        NSString *file = [docDirectory stringByAppendingPathComponent:info.filename];

        HUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] keyWindow] animated:YES];
        HUD.mode = MBProgressHUDModeDeterminate;
        HUD.delegate = self;
        HUD.labelText = @"Loading ...";

        [self.restClient loadFile:info.path intoPath:file];
        // Dismiss the popover if it's present.
        if (self.appDelegate.popoverController != nil) {
            [self.appDelegate.popoverController dismissPopoverAnimated:YES];
        }

        // Configure the new view controller's popover button (after the view has been displayed and its toolbar/navigation bar has been created).
        if (self.appDelegate.rootPopoverButtonItem != nil) {
        }
    }
}

- (void)displayError {
    [[[[UIAlertView alloc]
       initWithTitle:@"Error Loading file" message:@"There was an error loading your file."
       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
      autorelease]
     show];
}

- (void)setWorking:(BOOL)isWorking {
    if (working == isWorking) return;
    working = isWorking;

    if (working) {
        /*
         [activityIndicator startAnimating];

         self.activityView = [[[UIView alloc] initWithFrame: CGRectMake(0, 0, self.view.window.bounds.size.width, self.view.window.bounds.size.height)] autorelease];
         activityView.backgroundColor = [UIColor blackColor];
         activityView.alpha = 0.5;

         self.activityWheel = [[[UIActivityIndicatorView alloc] initWithFrame: CGRectMake(self.view.window.bounds.size.width / 2 - 12, self.view.window.bounds.size.height / 2 - 12, 24, 24)] autorelease];
         activityWheel.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
         activityWheel.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
         UIViewAutoresizingFlexibleRightMargin |
         UIViewAutoresizingFlexibleTopMargin |
         UIViewAutoresizingFlexibleBottomMargin);
         [activityView addSubview:activityWheel];
         [self.tableView.window addSubview: activityView];
         [[[activityView subviews] objectAtIndex:0] startAnimating];
         */

    } else {
        /*
         [activityIndicator stopAnimating];
         [activityWheel removeFromSuperview];
         [activityView removeFromSuperview];
         self.activityWheel = nil;
         self.activityView = nil;
         */
    }
}



- (DBRestClient*)restClient {
    if (_restClient == nil) {
        _restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        _restClient.delegate = self;
    }
    return _restClient;
}


#pragma mark DBRestClientDelegate methods
- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata
{
    [self setWorking:NO];

    if ([metadata.path isEqualToDropboxPath:self.pathName]) {
        NSLog(@"restClient:loadedMetadata %@", self.pathName);
        [self.documentURLs removeAllObjects];
        [self.sharedFolders removeAllObjects];

        [filesHash release];
        filesHash = [metadata.hash retain];

        for (DBMetadata* info in metadata.contents) {
            if (info.isDeleted) {
                continue;
            }
            if (info.isDirectory) {
                [self.restClient loadMetadata:[NSString stringWithFormat:@"%@/%@/.nCryptedBox", [metadata.path normalizedDropboxPath], info.filename]];
                NSLog(@"%@", [NSString stringWithFormat:@"%@/%@/.nCryptedBox", [metadata.path normalizedDropboxPath], info.filename]);
            }

            if ([info.filename isEqualToString:kNCryptedBoxFile]) {
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *docDirectory = [paths objectAtIndex:0]; // Get documents directory
                NSString *file = [docDirectory stringByAppendingPathComponent:info.filename];
                [self.restClient loadFile:info.path intoPath:file];
            } else {
                if (modalStyle) {
                    if (info.isDirectory) {
                        [self.documentURLs addObject:info];
                    }
                } else {
                    [self.documentURLs addObject:info];
                }
            }
        }
        [self.tableView reloadData];
    } else if ((!metadata.isDeleted) && [[metadata.filename lastPathComponent] isEqualToString:kNCryptedBoxFile]) {
        [self.sharedFolders setObject:kNCryptedBoxFile forKey:[metadata.path stringByDeletingLastPathComponent]];
        [self.tableView reloadData];
    }

    NSLog(@"%@", metadata.filename);
}

- (void)restClient:(DBRestClient*)client metadataUnchangedAtPath:(NSString*)path
{
}

- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error
{
    if ([error code] != 404) {
        NSLog(@"restClient:loadMetadataFailedWithError: %@", [error localizedDescription]);
        if ([[DBSession sharedSession] isLinked])
        {
            [self displayError];
        }
        [self setWorking:NO];
    }
}

- (void)restClient:(DBRestClient*)client loadedThumbnail:(NSString*)destPath
{
    [self setWorking:NO];
}

- (void)restClient:(DBRestClient*)client loadThumbnailFailedWithError:(NSError*)error
{
    NSLog(@"restClient:loadThumbnailFailedWithError: %@", [error localizedDescription]);
    [self setWorking:NO];
    if ([[DBSession sharedSession] isLinked])
    {
        [self displayError];
    }
}

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath
          metadata:(DBMetadata*)metadata
{
 [self setWorking:NO];   
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [self reloadView];
}

- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress
           forFile:(NSString*)destPath from:(NSString*)srcPath
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}


- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)destPath
{
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), destPath);
    if ([[destPath lastPathComponent] isEqualToString:kNCryptedBoxFile] ) {
        sharedFolderKey = [self.appDelegate.nCryptBox loadNCryptBoxFile:destPath];
        [self.tableView reloadData];
    } else {
        [MBProgressHUD hideHUDForView:[[UIApplication sharedApplication] keyWindow] animated:YES];
        if (self.appDelegate.popoverController != nil) {
            [self.appDelegate.popoverController dismissPopoverAnimated:YES];
        }

        self.filePath = [NSString stringWithString:destPath];

        PreviewViewController2 *previewController = [[PreviewViewController2 alloc] init];
        previewController.dataSource = self;
        previewController.delegate = self;
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
//            UINavigationController* navigationController = self.navigationController;
            [self.navigationController presentModalViewController:previewController animated:NO];
//            [navigationController pushViewController:previewController animated:YES];
        } else {
            [self.appDelegate.splitViewController  presentModalViewController:previewController animated:NO];
        }

    }
}

- (void)restClient:(DBRestClient*)client loadProgress:(CGFloat)progress forFile:(NSString*)destPath
{
    if (HUD) {
        HUD.progress = progress;
    }
}

- (void)doneAction:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
    [[self delegate] processSuccessful:self.pathName sharedKey:self.sharedFolderKey];
}

- (void)cancelAction:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];

}


- (IBAction)buttonUnlink:(id)sender
{
    TRACE(@"Unlink from Dropbox");
    [self.navigationController popToRootViewControllerAnimated:YES];

    [[DBSession sharedSession] unlinkAll];
    [_documentURLs removeAllObjects];
    _pathName = @"/";

    [[[[UIAlertView alloc]
       initWithTitle:@"Account Unlinked!" message:@"Your dropbox account has been unlinked"
       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
      autorelease]
     show];
}


- (void)refreshList {
    @synchronized(self) {
        [self.tableView reloadData];
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

- (id)previewController:(QLPreviewController *)previewController previewItemAtIndex:(NSInteger)idx
{
    return self.fileURL;
}

#pragma mark -
#pragma mark MBProgressHUD delegate

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    if (hud == HUD) {
        HUD = nil;
    }
}



@end
