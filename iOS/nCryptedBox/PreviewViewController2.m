//============================================================
//
// Copyright (c) nCrypted Cloud, 2012. All Rights Reserved.
//
// File: PreviewViewController2.m
// Created by Oleg Lavronov on 9/29/12.
//
// Description: Main application view controller
//
//===========================================================
#import "PreviewViewController2.h"

@interface PreviewViewController2 ()<DBRestClientDelegate>

@property (nonatomic, readonly) DBRestClient* restClient;

@end

@implementation PreviewViewController2

@synthesize buttonAction;
@synthesize view2;
@synthesize isRemoteStorage;
@synthesize preview = _preview;
@synthesize toolBar;

@synthesize sourceFile = _sourceFile;
@synthesize documentController;
@synthesize sharedFolderKey;
@synthesize detailItem;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
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


- (id)preview
{
    if (_preview == nil) {
        _preview = [[QLPreviewController alloc] init];
    }
    return _preview;
}

- (void)dealloc
{
    [_preview release];
    [super dealloc];
}

- (id<QLPreviewControllerDataSource>)dataSource
{
    return [self.preview dataSource];
}

- (void)setDataSource:(id<QLPreviewControllerDataSource>)dataSource
{
    self.preview.dataSource = dataSource;
}

- (id<QLPreviewControllerDelegate>)delegate
{
    return [self.preview delegate];
}


- (void)setDelegate:(id<QLPreviewControllerDelegate>)delegate
{
    self.preview.delegate = delegate;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //set the frame from the parent view
    CGFloat w= self.view.frame.size.width;
    CGFloat h= self.view.frame.size.height;
    self.preview.view.frame = CGRectMake(0, 0,w, h);
    [self.view2 addSubview:self.preview.view];
    [self.preview didMoveToParentViewController:self];
}

- (void)viewWillLayoutSubviews
{


}

- (void)viewDidAppear:(BOOL)animated
{
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)clickAction:(id)sender
{
    /*
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@"nCryptedBox"
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Text", nil];
*/
    NSURL* fileURL = [[self.preview currentPreviewItem] previewItemURL];
    NSLog(@"Current preview file: %@", [fileURL path]);
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@"nCryptedBox"
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:kOpenIn, nil];

    if (isRemoteStorage) {
        if ([self.appDelegate.nCryptBox isKeysFile:[fileURL path]]) {
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

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [actionSheet showInView:self.view2];
    } else {
        [actionSheet showFromBarButtonItem:buttonAction animated:YES];
    }
    [actionSheet release];
}

- (IBAction)clickDone:(id)sender
{
    float version = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (version >= 3.0)
    {
        // iPhone 3.0 code here
    }

    [self dismissModalViewControllerAnimated:YES];
}


- (void)selectActions:(id)sender
{
    NSURL* fileURL = [[self.preview currentPreviewItem] previewItemURL];
    NSLog(@"Current preview file: %@", [fileURL path]);
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@"nCryptedBox"
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:kOpenIn, nil];

    if (isRemoteStorage) {
        if ([self.appDelegate.nCryptBox isKeysFile:[fileURL path]]) {
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
            fileURL = [[self.preview currentPreviewItem] previewItemURL];
        } else {
            if ([self.sourceFile length] == 0) { // decrypted file
                fileURL = [[self.preview currentPreviewItem] previewItemURL];
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

        NSURL* fileURL = [[self.preview currentPreviewItem] previewItemURL];
        NSString* filePath = [fileURL path];
        if ([self.sourceFile length] == 0) { // Encrypt
            filePath = [[AppDelegate cachesDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.zip",[[fileURL path] lastPathComponent]]];
            [self.appDelegate encryptFile:[fileURL path] intoFile:filePath sharedFolderKey:self.sharedFolderKey];
        }

        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            HUD = [MBProgressHUD showHUDAddedTo:self.view2.window animated:YES];
        } else {
            HUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] keyWindow] animated:YES];
        }

        HUD.mode = MBProgressHUDModeAnnularDeterminate;//MBProgressHUDModeDeterminate;
        HUD.delegate = self;
        HUD.progress = 0.0;
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
            NSURL* fileURL = [[self.preview currentPreviewItem] previewItemURL];
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
    } else {
        [documentController presentOpenInMenuFromRect:CGRectZero inView:view2 animated:YES];
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

    [self dismissModalViewControllerAnimated:YES];
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
