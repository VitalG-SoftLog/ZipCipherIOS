//============================================================
//
// Copyright (c) nCrypted Cloud, 2012. All Rights Reserved.
//
// File: PreviewViewController.m
// Created By: Oleg Lavronov on  8/5/12.
//
// Description: Detail controller for iPad
//
//===========================================================
#import "PreviewViewController.h"
#import "DetailViewController.h"
#import "DropboxViewController.h"

@interface PreviewViewController () <DBRestClientDelegate>

//- (void)setWorking:(BOOL)isWorking;
@property (nonatomic, readonly) DBRestClient* restClient;

@end

@implementation PreviewViewController

@synthesize appDelegate;
@synthesize sourceFile = _sourceFile;
@synthesize documentController;
@synthesize isRemoteStorage;
@synthesize sharedFolderKey;
@synthesize detailItem;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configureNavBar:)
                                                     name:UIApplicationDidBecomeActiveNotification object:nil];
        isRemoteStorage = NO;
        sharedFolderKey = @"";
    }
    return self;
}

- (DBRestClient*)restClient {
    if (_restClient == nil) {
        _restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        _restClient.delegate = self;
    }
    return _restClient;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
/*
    // Button in center of Navigation Bar
    UISegmentedControl *button = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Save", nil]];
    button.frame = CGRectMake(0, 0, 100, 30);
    button.center = self.view.center;
    button.momentary = YES;
    button.segmentedControlStyle = UISegmentedControlStyleBar;
    button.tintColor = [UIColor colorWithHue:0.6 saturation:0.33 brightness:0.69 alpha:0];
    [button addTarget:self action:@selector(saveToDocumentsClicked) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = button;
*/
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self configureNavBar:self];
    if (appDelegate.rootPopoverButtonItem != nil) {
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:nil
                                                                      action:nil];
        // self.navigationItem.backBarButtonItem = backButton;
        [backButton release];
    } else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                       initWithTitle: @"Done"
                                       style:UIBarButtonItemStyleDone
                                       target:self
                                       action:@selector(doneClicked:)];

        // self.navigationItem.leftBarButtonItem = backButton;
        [backButton release];
    }
    [self.navigationController setNavigationBarHidden:NO];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    //[self navigationItem].rightBarButtonItems = nil;
}


- (IBAction)editClicked:(id)sender
{
    if (self.currentPreviewItem != nil) {
        TRACE(@"Edit file %@", [self.currentPreviewItem previewItemURL]);
        UIDocumentInteractionController* docController = [UIDocumentInteractionController
                                                          interactionControllerWithURL:[self.currentPreviewItem previewItemURL]];
        if (docController)
        {
            docController.delegate = self;
            if ([[UIApplication sharedApplication] canOpenURL:[self.currentPreviewItem previewItemURL]]) {

                [docController presentOpenInMenuFromRect:CGRectZero
                                                  inView:self.view animated:NO];
            }
            [docController dismissMenuAnimated:NO];
        }
    }
}

- (void)configureNavBar:(id)sender
{
    if (documentController)
    {
        [documentController dismissMenuAnimated:NO];
        [documentController release];
        documentController = nil;
    }
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                               target:self
                                                                               action:@selector(selectActions:)];
    [[self navigationItem]setRightBarButtonItem:saveButton];

    [saveButton release];
}

- (void)selectActions:(id)sender
{
    NSURL* fileURL = [[self currentPreviewItem] previewItemURL];
    NSLog(@"Current preview file: %@", [fileURL path]);
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@"nCryptedBox"
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:kOpenIn, nil];

    if (isRemoteStorage) {
        if ([appDelegate.nCryptBox isKeysFile:[fileURL path]]) {
            [actionSheet addButtonWithTitle:kImportKeys];
        }
        else if (([self.sourceFile length] != 0) && ([self.appDelegate.nCryptBox isEncryptedFile:self.sourceFile])) {
            [actionSheet addButtonWithTitle:kDecrypt];
        } else if ([self.sourceFile length] == 0) {
            [actionSheet addButtonWithTitle:kEncrypt];
        }
    }

    [actionSheet addButtonWithTitle:@"Cancel"];
    [actionSheet setCancelButtonIndex:[actionSheet numberOfButtons]-1];

    [actionSheet showInView:[self.view window]];
    [actionSheet release];

}

- (UIImage *)addBackground:(CGRect)bounds
{
    UIGraphicsBeginImageContextWithOptions(bounds.size, YES, 1);
    size_t num_locations = 2;
    CGFloat locations[2] = { 0.0, 1.0 };
    // These are the colors! That's two RBGA values
    CGFloat components[8] = {
        0.5,0.5,0.5, 0.8,
        0.1,0.1,0.1, 0.5 };
    CGColorSpaceRef myColorspace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef myGradient = CGGradientCreateWithColorComponents (myColorspace, components, locations, num_locations);
    float myRadius = (bounds.size.width*.9)/2;
    CGPoint center = CGPointMake(bounds.size.width / 2.0, bounds.size.height / 2.0);
    CGContextDrawRadialGradient (UIGraphicsGetCurrentContext(), myGradient, center, 0, center, myRadius, kCGGradientDrawsAfterEndLocation);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    CGColorSpaceRelease(myColorspace);
    CGGradientRelease(myGradient);
    UIGraphicsEndImageContext();
    return image;
}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString* button = [actionSheet buttonTitleAtIndex:buttonIndex];

    if ([button isEqualToString:kOpenIn]) {

        NSURL* fileURL = nil;
        if ([self isRemoteStorage]) { // Dropbox
            fileURL = [[self currentPreviewItem] previewItemURL];
        } else {
            if ([self.sourceFile length] == 0) { // decrypted file
                fileURL = [[self currentPreviewItem] previewItemURL];
            } else {
                fileURL = [NSURL fileURLWithPath:self.sourceFile];
            }
        }
        [self openInDocument:[fileURL path]];

    } else if ([button isEqualToString:kEncrypt] || [button isEqualToString:kDecrypt]) {

        if ([button isEqualToString:kEncrypt] && [self.appDelegate.keyDefault length] == 0)
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

        NSURL* fileURL = [[self currentPreviewItem] previewItemURL];
        NSString* filePath = [fileURL path];
        if ([self.sourceFile length] == 0) { // Encrypt
            filePath = [[AppDelegate cachesDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.zip",[[fileURL path] lastPathComponent]]];
            [appDelegate encryptFile:[fileURL path] intoFile:filePath sharedFolderKey:self.sharedFolderKey];
        }

        HUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] keyWindow] animated:YES];
        HUD.mode = MBProgressHUDModeAnnularDeterminate;//MBProgressHUDModeDeterminate;
        HUD.delegate = self;
        HUD.labelText = @"Uploading ...";

        DBMetadata* info = self.detailItem;//((DBMetadata*)_detailItem);
        [self.restClient uploadFile:[filePath lastPathComponent]
                             toPath:[info.path stringByDeletingLastPathComponent]
                      withParentRev:nil
                           fromPath:filePath];
    } else if ([button isEqualToString:kImportKeys]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Import keys"
                                                        message:@"Password:"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"OK",nil];
        alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
        alert.tag = 100;

        [alert show];
        [alert release];
    }

}


#pragma mark -
#pragma mark AlertView delegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ((alertView.tag == 100) && (buttonIndex == 1)) {
        UITextField* textFiled = [alertView textFieldAtIndex:0];
        if (textFiled != nil) {
            NSURL* fileURL = [[self currentPreviewItem] previewItemURL];
            NSUInteger count = [self.appDelegate.nCryptBox loadKeysFile:[fileURL path]
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
                [self.navigationController popToRootViewControllerAnimated:YES];
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


#pragma mark -
#pragma mark AlertView delegate
-(void) openInDocument:(NSString*)filePath
{
    if (documentController)
    {
        [documentController dismissMenuAnimated:NO];
        [documentController release];
    }

    documentController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:filePath]];

    documentController.delegate = self;
    [documentController retain];

    if (documentController)
    {
        [documentController dismissMenuAnimated:NO];
    }

    if (self.appDelegate.popoverController != nil) {
        [self.appDelegate.popoverController dismissPopoverAnimated:YES];
    }
    

    if (self.navigationItem.rightBarButtonItem) {
        [documentController presentOpenInMenuFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
    }
}


-(void)documentInteractionController:(UIDocumentInteractionController *)controller
       willBeginSendingToApplication:(NSString *)application
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

-(void)documentInteractionController:(UIDocumentInteractionController *)controller
          didEndSendingToApplication:(NSString *)application
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [self dismissModalViewControllerAnimated:YES];
}

- (void) documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *) controller
{
    NSLog(@"%@", NSStringFromSelector(_cmd));

    if (documentController) {
        [documentController dismissMenuAnimated:NO];
        [documentController release];
    }

    documentController = nil;
}

- (void) documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *) controller
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    if (documentController) {
        [documentController dismissMenuAnimated:NO];
        [documentController release];
    }
    documentController = nil;
}

- (IBAction)doneClicked:(id)sender
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [self  dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Dropbox delegate

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    TRACE(@"Uploaded File %@", srcPath);
    HUD.labelText = @"Uploaded";
    if ([self.detailItem isKindOfClass:[DBMetadata class]]) {
        [self.restClient deletePath:[self.detailItem path]];
    }

}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError *)error
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [MBProgressHUD hideHUDForView:[[UIApplication sharedApplication] keyWindow] animated:YES];
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

- (void)restClient:(DBRestClient*)client deletedPath:(NSString *)path
{
    TRACE(@"Dropbox delete: %@", path);
    [MBProgressHUD hideHUDForView:[[UIApplication sharedApplication] keyWindow] animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissModalViewControllerAnimated:YES];
    }
}

- (void)restClient:(DBRestClient*)client deletePathFailedWithError:(NSError*)error
{
    self.navigationItem.hidesBackButton = NO;
    [MBProgressHUD hideHUDForView:[[UIApplication sharedApplication] keyWindow] animated:YES];

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
#pragma mark MBProgressHUD delegate
- (void)hudWasHidden:(MBProgressHUD *)hud
{
    if (hud == HUD) {
        HUD = nil;
    }
}


@end
