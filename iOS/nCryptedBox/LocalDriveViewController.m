//============================================================
//
// Copyright (c) nCrypted Cloud, 2012. All Rights Reserved.
//
// File: LocalDriveViewController.h
// Created By: Oleg Lavronov on 7/25/12.
//
// Description: Local drive view controller 
//
//============================================================
#import "LocalDriveViewController.h"
#import "PreviewViewController.h"
#import "PreviewViewController2.h"

@implementation LocalDriveViewController

@synthesize docWatcher;
@synthesize documentURLs;
@synthesize documentController;
@synthesize appDelegate = _appDelegate;
@synthesize fileURL = _fileURL;
@synthesize filePath = _filePath;


- (DBRestClient*)restClient {
    if (_restClient == nil) {
        _restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        _restClient.delegate = self;
    }
    return _restClient;
}


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem *btnCancel = [[[UIBarButtonItem alloc] initWithTitle:@"Delete all"
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:self
                                                                  action:@selector(deleteAllClicked:)]autorelease];
    self.navigationItem.rightBarButtonItem = btnCancel;

    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.docWatcher = [DirectoryWatcher watchFolderWithPath:[self applicationDocumentsDirectory] delegate:self];
    self.documentURLs = [NSMutableArray array];

    // scan for existing documents
    [self directoryDidChange:self.docWatcher];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
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
    NSLog(@"File count: %d", documentURLs.count);
    return documentURLs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier] autorelease];

    }
    NSString* info = [self.documentURLs objectAtIndex:indexPath.row];

    if ([NCryptBox checkExtension:info]) {
        cell.textLabel.text  = [[info lastPathComponent] stringByDeletingPathExtension];
    } else {
        cell.textLabel.text = [info lastPathComponent];
    }

    UIImage* icon = [UIImage imageNamed:[NSString stringWithFormat:@"%@48.gif", info]];
    UIImage* iconCrypt = [UIImage imageNamed:@"crypt2.png"];
    if (icon == nil) {
        icon = [UIImage imageNamed:@"page_white48.gif"];
    }

    UIGraphicsBeginImageContext(CGSizeMake(36,36));
    [icon drawInRect:CGRectMake(0, 0, 36, 36)];

    if ([NCryptBox checkExtension:info])
    {
        [iconCrypt drawInRect:CGRectMake(0, 0, 18, 18)];
    }

    cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    [cell setAccessoryView:nil];

    BOOL isDirectory;
    BOOL fileExistsAtPath = [[NSFileManager defaultManager] fileExistsAtPath:info
                                                                 isDirectory:&isDirectory];

    if (fileExistsAtPath && !isDirectory) {
        NSError* attributesError;
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:info
                                                                                        error:&attributesError];

        NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
        long long fileSize = [fileSizeNumber longLongValue];
        NSDate *fileModificationDate = [fileAttributes objectForKey:NSFileModificationDate];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@", [AppDelegate formattedFileSize:fileSize],
                                     [NSDateFormatter localizedStringFromDate:fileModificationDate
                                                                    dateStyle:kCFDateFormatterMediumStyle
                                                                    timeStyle:NSDateFormatterShortStyle]];
    } else {
        cell.detailTextLabel.text = @"";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Action sheet

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *document = [documentURLs objectAtIndex:indexPath.row];
    TRACE(@"Opening document %@", document);

    // Dismiss the popover if it's present.
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@"nCryptedBox"
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil];
    [actionSheet addButtonWithTitle:kOpenIn];

    if ([self.appDelegate.nCryptBox isEncryptedFile:document]) {
        [actionSheet addButtonWithTitle:kPreview];
        [actionSheet addButtonWithTitle:kDecrypt];
    } else {
        if ([self.appDelegate.nCryptBox isKeysFile:document]) {
            [actionSheet addButtonWithTitle:kImportKeys];
        } else if ([self.appDelegate.nCryptBox isCryptedBoxFile:document]) {
            [actionSheet setTitle:@"You haven't valid key"];
        } else {
            [actionSheet addButtonWithTitle:kPreview];
            [actionSheet addButtonWithTitle:kEncrypt];
        }
    }

    [actionSheet addButtonWithTitle:kSaveInDropbox];
    [actionSheet addButtonWithTitle:kDelete];
    [actionSheet addButtonWithTitle:@"Cancel"];

    [actionSheet setCancelButtonIndex:[actionSheet numberOfButtons]-1];

    [actionSheet showInView:[self.view window]];
    [actionSheet release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {

    _filePath = [documentURLs objectAtIndex:[self.tableView indexPathForSelectedRow].row];
    if ([_filePath length] == 0)
        return;

    NSString* buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];

    if ([buttonTitle isEqualToString:kOpenIn]) {
        [self openInDocument:_filePath];
    } else if ([buttonTitle isEqualToString:kPreview]) {
        [self previewDocument:_filePath];
    } else if ([buttonTitle isEqualToString:kSaveInDropbox]) {
        [self saveInDropbox];
    } else if ([buttonTitle isEqualToString:kDecrypt]) {
        [self decryptDocument:_filePath];
    } else if ([buttonTitle isEqualToString:kEncrypt]) {
        [self encryptDocument:_filePath];
    } else if ([buttonTitle isEqualToString:kImportKeys]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Import keys"
                                                        message:@"Password:"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"OK",nil];
        alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
        [alert show];
        [alert release];
    } else if ([buttonTitle isEqualToString:kDelete]) {
        NSError* error;
        [[NSFileManager defaultManager] removeItemAtPath:_filePath error:&error];
        [self.tableView reloadData];
    }

}



#pragma mark - Document controller procedures and delegates

-(void)documentInteractionController:(UIDocumentInteractionController *)controller
       willBeginSendingToApplication:(NSString *)application {
    
}

-(void)documentInteractionController:(UIDocumentInteractionController *)controller
          didEndSendingToApplication:(NSString *)application {
    
}

- (void) documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *) controller
{
  documentController = nil;
}



- (void) documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *) controller
{
  documentController = nil;
}



#pragma mark -
#pragma mark File system support

- (NSString *)applicationDocumentsDirectory
{
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (void)directoryDidChange:(DirectoryWatcher *)folderWatcher
{
	[self.documentURLs removeAllObjects];    // clear out the old docs and start over
	
	NSString *documentsDirectoryPath = [self applicationDocumentsDirectory];
	
	NSArray *documentsDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectoryPath error:NULL];
    
	for (NSString* curFileName in [documentsDirectoryContents objectEnumerator])
	{
		NSString *filePath = [documentsDirectoryPath stringByAppendingPathComponent:curFileName];
		
		BOOL isDirectory;
        [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
		
        // proceed to add the document URL to our list (ignore the "Inbox" folder)
        if (!(isDirectory && [curFileName isEqualToString: @"Inbox"]))
        {
            NSString *fullPath = filePath;//[documentsDirectoryPath stringByAppendingPathComponent:filePath];
            [self.documentURLs addObject:fullPath];
        }
	}
	
	[self.tableView reloadData];
}



-(void) openInDocument:(NSString*)filePath {

    NSURL* fileURL = nil;
    /*
    if ([self.appDelegate.nCryptBox isCryptedBoxFile:filePath]) {
        if ([[NSFileManager defaultManager] isReadableFileAtPath:[AppDelegate cachesDirectory]])
        {
            NSString* destFile = [[AppDelegate cachesDirectory] stringByAppendingPathComponent:[filePath lastPathComponent]];
            NSError* error = nil;
            TRACE(@"Copy file: %@ to %@", filePath, [destFile stringByDeletingPathExtension])
            [[NSFileManager defaultManager] copyItemAtPath:filePath toPath:[destFile stringByDeletingPathExtension] error:&error];
            fileURL = [[[NSURL alloc] initFileURLWithPath:[destFile stringByDeletingPathExtension]] autorelease];
        }
    }
     */
    /*
    @try {
        fileURL = [self.appDelegate.nCryptBox decryptFile:filePath];
    }
    @catch (NSException *exception) {
        [[[[UIAlertView alloc]
           initWithTitle:[exception name] message:[exception reason]
           delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
          autorelease]
         show];
        return;
    }
    */

    if (fileURL == nil) {
        fileURL = [[[NSURL alloc] initFileURLWithPath:filePath] autorelease];
    }

    if (documentController)
    {
        [documentController dismissMenuAnimated:NO];
    }

    if (self.appDelegate.popoverController != nil) {
        [self.appDelegate.popoverController dismissPopoverAnimated:YES];
    }

    documentController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
    documentController.delegate = self;
    [documentController retain];

    if (self.appDelegate.rootPopoverButtonItem) {
        [documentController presentOpenInMenuFromBarButtonItem:[self.appDelegate rootPopoverButtonItem] animated:YES];
    } else {
        [documentController presentOpenInMenuFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
    }
}

-(void) previewDocument:(NSString*)filePath {


    @try {
        _fileURL = [self.appDelegate decryptFile:filePath];
    }
    @catch (NSException *exception) {
        [[[[UIAlertView alloc]
           initWithTitle:[exception name] message:[exception reason]
           delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
          autorelease]
         show];
        return;
    }

    TRACE(@"Preview document: %@", filePath);
    PreviewViewController2 *previewController = [[[PreviewViewController2 alloc] init] autorelease];
    previewController.dataSource = self;
    previewController.delegate = self;
    previewController.currentPreviewItemIndex = 0;

    if (_fileURL == nil) {
        _fileURL = [[[NSURL alloc] initFileURLWithPath:filePath] autorelease];
    } else {
        previewController.sourceFile = filePath;
    }

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self presentModalViewController:previewController animated:YES];
    } else {
        if (self.appDelegate.popoverController != nil) {
            [self.appDelegate.popoverController dismissPopoverAnimated:YES];
        }
        [self.appDelegate.splitViewController  presentModalViewController:previewController animated:YES];
    }

}

-(void) encryptDocument:(NSString*)filePath
{
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
    NSString *zipFile = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.zip",[filePath lastPathComponent]]];
    [self.appDelegate  encryptFile:filePath intoFile:zipFile sharedFolderKey:@""];

    NSError* error;
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
}

-(void) decryptDocument:(NSString*)filePath
{
    NSError* error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSURL* url = [self.appDelegate  decryptFile:filePath];
    NSString *unzipFile = [documentsDirectory stringByAppendingPathComponent:[[url path] lastPathComponent]];

    [[NSFileManager defaultManager] moveItemAtPath:[url path] toPath:unzipFile error:&error];

    [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
}

-(void)saveInDropbox
{
    DropboxViewController *detailViewController = [[DropboxViewController alloc] initWithStyle:UITableViewStyleGrouped];
    detailViewController.pathName = @"/";
    detailViewController.modalStyle = YES;
    detailViewController.delegate = self;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:detailViewController];
    [detailViewController release];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
    } else {
        if (self.appDelegate.popoverController != nil) {
            [self.appDelegate.popoverController dismissPopoverAnimated:YES];
        }
    }

    navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentModalViewController:navController animated:YES];
    [navController release];
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
    if ((alertView.tag == 100) && (buttonIndex == 1)) {
        NSError* err = nil;
        NSFileManager* fm = [[[NSFileManager alloc] init] autorelease];
        NSDirectoryEnumerator* en = [fm enumeratorAtPath:[AppDelegate documentsDirectory]];
        BOOL result = NO;

        NSString* file;
        while (file = [en nextObject]) {
            result = [fm removeItemAtPath:[[AppDelegate documentsDirectory] stringByAppendingPathComponent:file]
                                    error:&err];
            if (!result && err) {
                TRACE(@"Error delete file: %@", err);
            }
        }
        [self.tableView reloadData];
        TRACE(@"Delete all files");
        return;
    }

    if (buttonIndex == 1) {
        UITextField* textFiled = [alertView textFieldAtIndex:0];
        if (textFiled != nil) {
            NSUInteger count = [self.appDelegate.nCryptBox loadKeysFile:self.filePath
                                                               password:textFiled.text];

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
}

- (IBAction)deleteAllClicked:(id)sender
{
    UIAlertView* alert = [[UIAlertView alloc]
                          initWithTitle:@"Delete all files" message:@"Are you sure ?"
                          delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    alert.tag = 100;
    [alert show];
    [alert release];
}


#pragma mark -
#pragma mark DropboxViewController delegate
- (void)processSuccessful:(NSString*)pathName sharedKey:(NSString *)sharedKey
{
    NSLog(@"Path name %@",pathName);
    NSLog(@"Shared key %@",sharedKey);
    NSLog(@"File Path %@",self.filePath);

    HUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] keyWindow] animated:YES];
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Uploading ...";

    [self.restClient uploadFile:[self.filePath lastPathComponent]
                         toPath:pathName
                  withParentRev:nil
                       fromPath:self.filePath];
}


- (void)restClient:(DBRestClient*)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    TRACE(@"Uploaded File %@", srcPath);
    HUD.labelText = @"Uploaded";
    [MBProgressHUD hideHUDForView:[[UIApplication sharedApplication] keyWindow] animated:YES];
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError *)error
{
    [MBProgressHUD hideHUDForView:[[UIApplication sharedApplication] keyWindow] animated:YES];
    NSLog(@"%@", NSStringFromSelector(_cmd));

    TRACE(@"Upload error %@", [error localizedDescription]);
    [[[[UIAlertView alloc]
       initWithTitle:[error domain] message:[error localizedDescription]
       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
      autorelease]
     show];
    //    [self.navigationController popViewControllerAnimated:YES];
}

- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress forFile:(NSString *)destPath from:(NSString *)srcPath
{
    if (HUD) {
        HUD.progress = progress;
    }
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
