//============================================================
//
// Copyright (c) nCrypted Cloud, 2012. All Rights Reserved.
//
// File: DropboxViewController.h
// Created By: Oleg Lavronov on 7/25/12.
//
// Description: Dropbox view controller
//
//===========================================================
#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>
#import "AppDelegate.h"

@class DBRestClient;

@protocol DropboxViewControllerDelegate <NSObject>
@required
- (void) processSuccessful:(NSString*)pathName sharedKey:(NSString*)sharedKey;
@end


@interface DropboxViewController : UITableViewController<MBProgressHUDDelegate,
                                                        QLPreviewControllerDataSource,
                                                        QLPreviewControllerDelegate>
{
    AppDelegate*                _appDelegate;
	MBProgressHUD *HUD;
    NSString*                   _pathName;
    NSMutableArray*             _documentURLs;
    NSMutableDictionary*        _sharedFolders;
    NSString*                   relinkUserId;
    DBRestClient*               _restClient;
    UIActivityIndicatorView*    activityIndicator;

    UIView* activityView;
    UIActivityIndicatorView*    activityWheel;

    NSString* filesHash;

    BOOL working;
    id <DropboxViewControllerDelegate> delegate;
}

@property (retain) id delegate;
@property (nonatomic, retain) NSURL*                    fileURL;
@property (nonatomic, retain) NSString*                 filePath;
@property (strong, nonatomic) id                        detailItem;

@property (nonatomic, readonly) AppDelegate*                    appDelegate;
@property (nonatomic, readonly) NSString*                       pathName;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView* activityIndicator;
@property (nonatomic, retain) NSMutableArray*                   documentURLs;
@property (nonatomic, retain) NSMutableDictionary*              sharedFolders;
@property (nonatomic, retain) UIView*                           activityView;
@property (nonatomic, retain) UIActivityIndicatorView*          activityWheel;
@property (nonatomic, retain) NSString*                         sharedFolderKey;
@property (nonatomic, assign) BOOL                              modalStyle;



- (void)setPathName:(NSString *)newPathName;
- (void)reloadView;

@end
