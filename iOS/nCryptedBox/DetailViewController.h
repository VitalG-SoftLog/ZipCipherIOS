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
#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>

#import "MasterViewController.h"

@interface DetailViewController : UIViewController <
                                                    //UISplitViewControllerDelegate,
                                                    QLPreviewControllerDelegate,
                                                    QLPreviewControllerDataSource>
{
    AppDelegate*        _appDelegate;
    UIToolbar*          toolbar;
    UIBarButtonItem*    rootPopoverButtonItem;
    DBRestClient*       _restClient;
    UILabel*            labelStatus;
    UILabel*            labelFile;
    UIProgressView*     progressBar;
    NSString*           _filePath;
    NSURL*              _fileURL;
}

@property (nonatomic, readonly) AppDelegate*            appDelegate;
@property (nonatomic, retain) NSURL*                    fileURL;
@property (nonatomic, retain) NSString*                 filePath;
@property (nonatomic, retain) NSString*                 sharedFolderKey;
@property (strong, nonatomic) id                        detailItem;
@property (nonatomic, retain) IBOutlet UIToolbar*       toolbar;
@property (nonatomic, retain) UIBarButtonItem*          rootPopoverButtonItem;

@property (nonatomic, retain) IBOutlet UILabel*         labelFile;
@property (nonatomic, retain) IBOutlet UILabel*         labelStatus;
@property (nonatomic, retain) IBOutlet UIProgressView*  progressBar;


- (void)configureUpload:(NSString*)filePath;



@end
