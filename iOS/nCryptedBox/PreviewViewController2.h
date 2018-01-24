//============================================================
//
// Copyright (c) nCrypted Cloud, 2012. All Rights Reserved.
//
// File: PreviewViewController2.h
// Created by Oleg Lavronov on 9/29/12.
//
// Description: Main application view controller
//
//===========================================================
#import <UIKit/UIKit.h>
#import <QuickLook/QuickLook.h>
#import <DropboxSDK/DropboxSDK.h>
#import "MBProgressHUD.h"
#import "ApplicationViewController.h"

@interface PreviewViewController2 : ApplicationViewController<QLPreviewControllerDelegate,
                                                                UIActionSheetDelegate,
                                                                MBProgressHUDDelegate,
                                                                UIGestureRecognizerDelegate,
                                                                UIDocumentInteractionControllerDelegate>
{
    MBProgressHUD*  HUD;
    DBRestClient*   _restClient;
}

@property (nonatomic, retain) QLPreviewController*      preview;
@property (assign) id<QLPreviewControllerDataSource>    dataSource;
@property (assign) id <QLPreviewControllerDelegate>     delegate;

@property (nonatomic, assign) BOOL                      isRemoteStorage;
@property (readonly) id<QLPreviewItem>                  currentPreviewItem;
@property NSInteger                                     currentPreviewItemIndex;
@property (nonatomic, retain) NSString*                 sourceFile;
@property (nonatomic, retain) UIDocumentInteractionController* documentController;
@property (nonatomic, retain) NSString*                 sharedFolderKey;
@property (nonatomic, retain) id                        detailItem;

@property (nonatomic, retain) IBOutlet UIView*          view2;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* buttonAction;
@property (nonatomic, retain) IBOutlet UIToolbar*       toolBar;


- (IBAction)clickAction:(id)sender;
- (IBAction)clickDone:(id)sender;


@end
