//============================================================
//
// Copyright (c) nCrypted Cloud, 2012. All Rights Reserved.
//
// File: MasterViewController.m
// Created By: Oleg Lavronov on 7/25/12.
//
// Description: Main application view controller
//
//===========================================================
#import "NCryptBox.h"
#import "AppDelegate.h"
#import "MasterViewController.h"
#import "HelpViewController.h"
#import "SettingsViewController.h"
#import "LocalDriveViewController.h"
#import "DropboxViewController.h"
#import "LogViewController.h"
#import "PreviewViewController.h"
#import "PreviewViewController2.h"
#import "StartViewController.h"


#define kAlertPasswordTag 200

enum 
{ 
    kDrive,
    kSettingsPage
};



@interface MasterViewController () {
    NSMutableArray *_objects;
}
@end

@implementation MasterViewController

@synthesize fileURL;
@synthesize previewFile = _previewFile;
@synthesize localDriveViewController;
@synthesize dropboxViewController;
@synthesize helpViewController;
@synthesize logViewController;
@synthesize appDelegate;
@synthesize detailViewController;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        self.title = NSLocalizedString(@"nCryptedBox", @"nCryptedBox");
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unlinkMachine:) name:kUnlinkMachine object: nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(retrieveKeys:) name:kRetrieveKeys object: nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(storeKeys:) name:kStoreKeys object: nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(webError:) name:kWebError object: nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [localDriveViewController release];
    [dropboxViewController release];
    [logViewController release];
    [helpViewController release];
    [detailViewController release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;

    UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
								   initWithTitle:@"Unlink"
								   style:UIBarButtonItemStylePlain
								   target:self
								   action:@selector(unlinkAction:)];
	self.navigationItem.rightBarButtonItem = backButton;
    [backButton release];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"%@", NSStringFromSelector(_cmd));

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if ([self.appDelegate.keyPassword length] == 0) {
        [self showEnterPassword];
    }
}

- (void)showEnterPassword
{
    /*
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Secure my keys"
                                                    message:@"Please enter password:"
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK",nil];
    alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
    alert.tag = kAlertPasswordTag;
    [[alert textFieldAtIndex:0] setPlaceholder:@"Required"];

    [alert show];
    [alert release];
     */
}

- (void)insertNewObject:(id)sender
{
    if (!_objects) {
        _objects = [[NSMutableArray alloc] init];
    }
    [_objects insertObject:[NSDate date] atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 2) {
        return [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Version", @""), [AppDelegate applicationVersion]];
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case kDrive:
            return 2;
            break;
        case kSettingsPage:
            return 3;
            break;
        case 2:
            return 0;
            break;
        default:
            break;
    }
    
    return _objects.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    }
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
	
	switch (indexPath.section) {
		case kDrive:
			switch (indexPath.row) {
				case 0:
					cell.textLabel.text = NSLocalizedString(@"My files", @"");
                    cell.imageView.image = [UIImage imageNamed:@"home.png"];
					break;
				case 1:
					cell.textLabel.text = NSLocalizedString(@"DropBox", @"");
                    cell.imageView.image = [UIImage imageNamed:@"dropbox.png"];
					break;
			}
			break;
		case kSettingsPage:
			switch (indexPath.row) {
				case 0:
					cell.textLabel.text = NSLocalizedString(@"Settings", @"");
					break;
				case 1:
					cell.textLabel.text = NSLocalizedString(@"Log file", @"");
					break;
				case 2:
					cell.textLabel.text = NSLocalizedString(@"Help", @"");
					break;
			}
		default:
			break;
	}
    
    return cell;
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

- (DropboxViewController*) dropboxViewController
{
    if (!dropboxViewController) {
        dropboxViewController = [[DropboxViewController alloc] initWithNibName:@"DropboxViewController_iPhone" bundle:nil];
    }
    return dropboxViewController;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath]; 
    UITableViewController *currentDetail = nil;
    
    switch (indexPath.section) {
         case kDrive:
            switch (indexPath.row) {
                case 0:
                    if (!self.localDriveViewController) {
                        self.localDriveViewController = [[[LocalDriveViewController alloc] initWithNibName:@"LocalDriveViewController_iPhone" bundle:nil] autorelease];
                    }
                    currentDetail = self.localDriveViewController;
                    break;
                case 1:
                    if (![[DBSession sharedSession] isLinked]) {
                        [[DBSession sharedSession] linkFromController:self];
                    } else {
                        currentDetail = self.dropboxViewController;
                    }
                    break;
                default:
                    break;
            }
            break;
        case kSettingsPage:
            switch (indexPath.row) {
				case 0:
                {
                    SettingsViewController* settingsViewController = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController_iPhone" bundle:nil];
                    [self.navigationController pushViewController:settingsViewController animated:YES];
                    [settingsViewController release];
                    currentDetail = nil;
                }
					break;
				case 1:
                    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
                        if (!self.logViewController) {
                            self.logViewController = [[LogViewController alloc] initWithNibName:@"LogViewController_iPhone" bundle:nil];
                        }
                        currentDetail = (UITableViewController*)self.logViewController;
                    } else {
                        currentDetail = nil;
                        UIViewController <SubstitutableDetailViewController> *detailView = nil;
                        LogViewController *newDetailViewController = [[LogViewController alloc] initWithNibName:@"LogViewController_iPad" bundle:nil];
                        
                        detailView = newDetailViewController;
                        
                        // Update the split view controller's view controllers array.
                        NSArray *viewControllers = [[NSArray alloc] initWithObjects:self.navigationController, detailView, nil];
                        appDelegate.splitViewController.viewControllers = viewControllers;
                        [viewControllers release];
                        
                        // Dismiss the popover if it's present.
                        if (appDelegate.popoverController != nil) {
                            [appDelegate.popoverController dismissPopoverAnimated:YES];
                        }
                        
                        // Configure the new view controller's popover button (after the view has been displayed and its toolbar/navigation bar has been created).
                        if (appDelegate.rootPopoverButtonItem != nil) {
                            [detailView showRootPopoverButtonItem:appDelegate.rootPopoverButtonItem];
                        }
                        
                        //[detailView release];
                    }
					break;
				case 2:
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.ncryptedcloud.com"]];
                    currentDetail = nil;
					break;
			}

            break;
            
        default:
            break;
    }
    
    if (currentDetail != nil) {
        [currentDetail setTitle:cell.textLabel.text];
        [self.navigationController pushViewController:currentDetail animated:YES];
    }

}

#pragma mark -
#pragma mark Rotation support
/*
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}
*/

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


- (void)splitViewController:(UISplitViewController*)svc
     willHideViewController:(UIViewController *)aViewController
          withBarButtonItem:(UIBarButtonItem*)barButtonItem
       forPopoverController:(UIPopoverController*)pc
{
    
    // Keep references to the popover controller and the popover button, and tell the detail view controller to show the button.
    barButtonItem.title = @"nCryptedBox";

    appDelegate.popoverController = pc;
    appDelegate.rootPopoverButtonItem = barButtonItem;
    UIViewController <SubstitutableDetailViewController> *detailView = [appDelegate.splitViewController.viewControllers objectAtIndex:1];
    [detailView showRootPopoverButtonItem:appDelegate.rootPopoverButtonItem];
//    [pc setPopoverLayoutMargins:UIEdgeInsetsMake(100, 100, 200, 200)];
}

- (void)splitViewController:(UISplitViewController*)svc
     willShowViewController:(UIViewController *)aViewController
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {

    // Nil out references to the popover controller and the popover button, and tell the detail view controller to hide the button.
    UIViewController <SubstitutableDetailViewController> *detailView = [appDelegate.splitViewController.viewControllers objectAtIndex:1];
    [detailView invalidateRootPopoverButtonItem:appDelegate.rootPopoverButtonItem];
    appDelegate.popoverController = nil;
    appDelegate.rootPopoverButtonItem = nil;
 
}

#pragma mark - Table view delegate
- (void) previewFile:(NSString*) fileName {

    [self.fileURL release];
    self.fileURL = [[NSURL alloc] initFileURLWithPath:fileName];
    self.previewFile = fileName;

    TRACE(@"Open URL: %@", self.fileURL);

    if ([appDelegate.nCryptBox isEncryptedFile:fileName]) {
        [self.fileURL release];
        @try {
            self.fileURL = [appDelegate decryptFile:fileName];
        }
        @catch (NSException *exception) {
            [[[[UIAlertView alloc]
               initWithTitle:[exception name] message:[exception reason]
               delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil]
              autorelease]
             show];
            return;
        }
        
        PreviewViewController2 *previewController = [[[PreviewViewController2 alloc] init] autorelease];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            // Navigation logic may go here. Create and push another view controller.
            previewController.dataSource = self;
            previewController.delegate = self;
            
            // start previewing the document at the current section index
            previewController.currentPreviewItemIndex = 0;
            [[self navigationController] pushViewController:previewController animated:YES];
        } else {
            UIViewController<SubstitutableDetailViewController> *detailView = nil;
            
            UINavigationController *wrapperNavigationController = [[[UINavigationController alloc] initWithRootViewController:previewController] autorelease];
            
            detailView = (UIViewController<SubstitutableDetailViewController>*)previewController;
            
            // Update the split view controller's view controllers array.
            NSArray *viewControllers = [[NSArray alloc] initWithObjects:self.navigationController, wrapperNavigationController, nil];
            
            previewController.dataSource = self;
            previewController.delegate = self;

            // start previewing the document at the current section index
            previewController.currentPreviewItemIndex = 0;
            
            appDelegate.splitViewController.viewControllers = viewControllers;
            [viewControllers release];
            
            // Dismiss the popover if it's present.
            if (appDelegate.popoverController != nil) {
                [appDelegate.popoverController dismissPopoverAnimated:YES];
            }

            // Configure the new view controller's popover button (after the view has been displayed and its toolbar/navigation bar has been created).
            if (appDelegate.rootPopoverButtonItem != nil) {
                [detailView showRootPopoverButtonItem:appDelegate.rootPopoverButtonItem];
            }
        }
    } else {
        if ([self.appDelegate.keyDefault length] == 0)
        {
            [[[[UIAlertView alloc] initWithTitle:@"Error"
                                         message:@"Oops! You haven't security keys."
                                        delegate:nil
                               cancelButtonTitle:@"OK"
                               otherButtonTitles:nil]
              autorelease]
             show];
            return;
        }

        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *zipFile = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.zip",[fileName lastPathComponent]]];

        [appDelegate  encryptFile:fileName intoFile:zipFile sharedFolderKey:@""];

        if (!self.localDriveViewController) {
            self.localDriveViewController = [[LocalDriveViewController alloc] initWithNibName:@"LocalDriveViewController_iPhone" bundle:nil];
        }
        [self.localDriveViewController setTitle:[zipFile lastPathComponent]];

        if ([self.navigationController topViewController] != self.localDriveViewController) {
            [self.navigationController pushViewController:self.localDriveViewController animated:YES];
        }

        [self.localDriveViewController directoryDidChange:nil];
        [self.localDriveViewController previewDocument:zipFile];
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
#pragma mark AlertView delegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kAlertPasswordTag) {
        [appDelegate setKeyPassword:[[alertView textFieldAtIndex:0] text]];
        if ([appDelegate.keyPassword length] == 0) {
            [self showEnterPassword];
        }
        return;
    }

    if (buttonIndex == 1) {
        NSUInteger count = [self.appDelegate.nCryptBox loadKeysFile:_previewFile password:[alertView textFieldAtIndex:0].text];

        if (count) {
            [self.appDelegate saveKeys];
            [[[[UIAlertView alloc] initWithTitle:@"Import"
                                         message:[NSString stringWithFormat:@"%d keys loaded.", count]
                                        delegate:nil
                               cancelButtonTitle:@"OK"
                               otherButtonTitles:nil]
              autorelease]
             show];
        } else {
            [[[[UIAlertView alloc] initWithTitle:@"Error"
                                         message:@"Keys file is wrong or bad password."
                                        delegate:nil
                               cancelButtonTitle:@"OK"
                               otherButtonTitles:nil]
              autorelease]
             show];
        }
    }
}

- (void)unlinkAction:(id)sender
{
    TRACE(@"Unlink machine");
    [appDelegate unlinkMachine];
}

- (void)startController
{
    StartViewController *controller = [[StartViewController alloc] initWithNibName:@"StartViewController" bundle:nil];
    controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:controller];
    [self.navigationController presentModalViewController:navController animated:YES];
    [navController release];
    [controller release];
}

- (void) unlinkMachineOnMainThread {
    [appDelegate terminateActivityView];
    [self startController];
}

- (void) webErrorOnMainThread:(NSError*)error {
    [appDelegate terminateActivityView];
    if (error.code == kWebINVALID_AUTH_TOKEN) {
        [self.appDelegate clearKeys];
        [self startController];
    }
}

- (void) retrieveKeysOnMainThread {
    [appDelegate terminateActivityView];
//    [self.navigationController popViewControllerAnimated:YES];
}

- (void) storeKeysOnMainThread {
    [appDelegate terminateActivityView];
    //    [self.navigationController popViewControllerAnimated:YES];
}


- (void) retrieveKeys:(NSNotification *)notification {
	[self performSelectorOnMainThread:@selector(retrieveKeysOnMainThread) withObject: nil waitUntilDone: NO];
}

- (void) storeKeys:(NSNotification *)notification {
	[self performSelectorOnMainThread:@selector(storeKeysOnMainThread) withObject: nil waitUntilDone: NO];
}


- (void) unlinkMachine:(NSNotification *)notification {
	[self performSelectorOnMainThread:@selector(unlinkMachineOnMainThread) withObject: nil waitUntilDone: NO];
}


- (void) webError:(NSNotification *)notification {
	[self performSelectorOnMainThread:@selector(webErrorOnMainThread:) withObject:notification.object waitUntilDone: NO];
}



@end
