//============================================================
//
// Copyright (c) nCrypted Cloud, 2012. All Rights Reserved.
//
// File: LocalDriveViewController.h
// Created By: Oleg Lavronov on 7/25/12.
//
// Description: Local drive view controller
//
//===========================================================
#import <UIKit/UIKit.h>
#import <QuickLook/QuickLook.h>
#import <DropboxSDK/DropboxSDK.h>
#import "MBProgressHUD.h"
#import "AppDelegate.h"
#import "DirectoryWatcher.h"
#import "DropboxViewController.h"


@interface LocalDriveViewController : UITableViewController <UIDocumentInteractionControllerDelegate,
                                                                UIActionSheetDelegate,
                                                                QLPreviewControllerDataSource,
                                                                QLPreviewControllerDelegate,
                                                                DirectoryWatcherDelegate,
                                                                DropboxViewControllerDelegate,
                                                                DBRestClientDelegate,
                                                                MBProgressHUDDelegate
                                                                >
{
    AppDelegate*        _appDelegate;
    DirectoryWatcher*   docWatcher;
    NSMutableArray*     documentURLs;
    UIDocumentInteractionController *documentController;
    NSURL*              _fileURL;
    NSString*           _filePath;
    DBRestClient*       _restClient;
    MBProgressHUD*      HUD;
}

@property (nonatomic, readonly)AppDelegate*     appDelegate;
@property (nonatomic, retain)DirectoryWatcher*  docWatcher;
@property (nonatomic, retain)NSMutableArray*    documentURLs;
@property (nonatomic, retain)UIDocumentInteractionController *documentController;
@property (nonatomic, readonly)NSURL*           fileURL;
@property (nonatomic, readonly)NSString*        filePath;

-(NSString *) applicationDocumentsDirectory;
-(void) openInDocument:(NSString*)filePath;
-(void) previewDocument:(NSString*)filePath;
-(void) directoryDidChange:(DirectoryWatcher *)folderWatcher;




@end
