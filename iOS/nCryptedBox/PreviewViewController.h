//============================================================
//
// Copyright (c) nCrypted Cloud, 2012. All Rights Reserved.
//
// File: PreviewViewController.h
// Created By: Oleg Lavronov on  8/5/12.
//
// Description: Detail controller for iPad
//
//===========================================================
#import <QuickLook/QuickLook.h>
#import <DropboxSDK/DropboxSDK.h>
#import "MBProgressHUD.h"
#import "AppDelegate.h"
#import "MasterViewController.h"


@interface PreviewViewController : QLPreviewController <UIActionSheetDelegate,
                                                        MBProgressHUDDelegate,
                                                        UIDocumentInteractionControllerDelegate>
{
    AppDelegate*    appDelegate;
    MBProgressHUD*  HUD;
    DBRestClient*   _restClient;
}

@property (nonatomic, assign) AppDelegate*   appDelegate;
@property (nonatomic, retain) NSString*      sourceFile;
@property (nonatomic, retain) UIDocumentInteractionController* documentController;
@property (nonatomic, assign) BOOL           isRemoteStorage;
@property (nonatomic, retain) NSString*      sharedFolderKey;
@property (nonatomic, retain) id             detailItem;



@end
