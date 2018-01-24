//============================================================
//
// Copyright (c) nCrypted Cloud, 2012. All Rights Reserved.
//
// File: MasterViewController.h
// Created By: Oleg Lavronov on 7/25/12.
//
// Description: Main application view controller
//
//===========================================================
#import <UIKit/UIKit.h>
#import <QuickLook/QuickLook.h>

@protocol SubstitutableDetailViewController
- (void)showRootPopoverButtonItem:(UIBarButtonItem *)barButtonItem;
- (void)invalidateRootPopoverButtonItem:(UIBarButtonItem *)barButtonItem;
@end


@class AppDelegate;
@class LocalDriveViewController;
@class DropboxViewController;
@class HelpViewController;
@class SettingsViewController;
@class LogViewController;
@class DetailViewController;
@class FirstViewController;

@interface MasterViewController : UITableViewController <UISplitViewControllerDelegate,
                                                        UIAlertViewDelegate,
                                                        QLPreviewControllerDataSource,
                                                        QLPreviewControllerDelegate>
{
    AppDelegate*            appDelegate;
    NSURL*                  fileURL;
    NSString*               _previewFile;

    LocalDriveViewController*   localDriveViewController;
    DropboxViewController*      dropboxViewController;
    HelpViewController*         helpViewController;
    LogViewController*          logViewController;
//    DetailViewController*       _detailViewController;
}


@property (nonatomic, assign) AppDelegate*                  appDelegate;
@property (nonatomic, retain) NSURL*                        fileURL;
@property (nonatomic, retain) NSString*                     previewFile;

@property (nonatomic, retain) LocalDriveViewController*     localDriveViewController;
@property (nonatomic, retain) DropboxViewController*        dropboxViewController;
@property (nonatomic, retain) HelpViewController*           helpViewController;
@property (nonatomic, retain) LogViewController*            logViewController;
@property (nonatomic, retain) FirstViewController*          detailViewController;


- (void) previewFile:(NSString*) fileName;
//- (NSString*) compressFile:(NSString*) fileName;



@end
