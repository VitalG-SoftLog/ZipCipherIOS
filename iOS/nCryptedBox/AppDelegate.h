//============================================================
//
// Copyright (c) nCrypted Cloud, 2012. All Rights Reserved.
//
// File: AppDelegate.h
// Created By: Oleg Lavronov on 7/25/12.
//
// Description: Main application delegate functions
//
//============================================================
#import <UIKit/UIKit.h>
#import "Log.h"
#import "NCryptBox.h"
#import "NCryptKey.h"
#import "MBProgressHUD.h"
#import "WebServiceProvider.h"
#import "MasterViewController.h"
#import "KeychainItemWrapper.h"

#define IPHONE ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
#define IPAD ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)

#define kKeyStorageFile @"keys.zip"
#define kNCryptedBoxFile @".nCryptedBox"
// Dropbox keys
// Change APP_KEY also in Info.plist application
#define kAPP_KEY    @"ovzfb184v6nq7py"
#define kAPP_SECRET @"khakczbga1410z0"

// Keychain identificators
#define kKeychainPassword @"Password"
#define kKeychainAccount  @"Account"

// Action sheet button names for Preview
#define kOpenIn         @"Open in..."
#define kPreview        @"Preview..."
#define kDecrypt        @"Decrypt"
#define kEncrypt        @"Encrypt"
#define kImportKeys     @"Import keys..."
#define kDelete         @"Delete"
#define kSaveInDropbox  @"Save in Dropbox"

// Notification names for observer
#define kNotifyDropboxDeleted @"DropboxDeleted"

// Tags for AlertView
#define kAlertPasswordEnterTag  100
#define kAlertClearAllKeysTag   101


@interface AppDelegate : UIResponder <UIApplicationDelegate,
                                        MBProgressHUDDelegate,
                                        NCryptBoxDelegate>
{
    
    NSString*                   relinkUserId;
    UISplitViewController*      _splitViewController;
    NCryptBox*                  _nCryptBox;
    MBProgressHUD*              _HUD;
    MBProgressHUD *HUD;

    // Split master detail for iPad
    UIPopoverController*        popoverController;
    UIBarButtonItem*            rootPopoverButtonItem;
    MasterViewController*       masterViewController;
}

@property (strong, nonatomic) UIWindow*                 window;
@property (strong, nonatomic) UINavigationController*   navigationController;
@property (strong, nonatomic) UISplitViewController*    splitViewController;
@property (nonatomic, assign) UIBarButtonItem*          rootPopoverButtonItem;
@property (nonatomic, retain) UIPopoverController*      popoverController;
@property (nonatomic, retain) MasterViewController*     masterViewController;
@property (nonatomic, readonly) NCryptBox*              nCryptBox;
@property (nonatomic, retain) NSString*                 keyDefault;
@property (nonatomic, retain) NSString*                 keyShared;
@property (nonatomic, retain) NSString*                 backupShared;
@property (nonatomic, retain) NSString*                 keyBackup;
@property (nonatomic, retain) NSString*                 keyPassword;
@property (nonatomic, retain) KeychainItemWrapper*      passwordKeychain;
@property (nonatomic, retain) KeychainItemWrapper*      accountKeychain;
@property (nonatomic, strong) WebServiceProvider*       webService;



- (NSString*)keyPassword;
- (void)setKeyPassword:(NSString*)keyPassword;
- (NSString*)keyDefault;
- (void)setKeyDefault:(NSString*)keyDefault;
- (NSString*)keyBackup;
- (void)setKeyBackup:(NSString*)keyBackup;


+ (NSString*)formattedFileSize:(unsigned long long)size;
+ (NSString*)documentsDirectory;
+ (NSString*)cachesDirectory;
+ (NSString*)applicationVersion;
+ (NSString*)computerName;


- (void)encryptFile:(NSString *)fileName intoFile:(NSString *)intoFile sharedFolderKey:(NSString*)sharedFolderKey;
- (NSURL*) decryptFile:(NSString *)fileName;

- (void)showBusyIndicator:(NSString*)label;
- (void)hideBusyIndicator;

- (void)saveKeys;
- (void)clearKeys;


// JSON
- (void)registerAccount:(NSString *)userEmail
              firstName:(NSString *)firstName
               lastName:(NSString *)lastName
             invitation:(NSString *)invitation
           computername:(NSString *)computername
               password:(NSString *)password;

- (void)associateMachine:(NSString *)userEmail
                password:(NSString *)password
            computerName:(NSString *)computerName;

- (void)unlinkMachine;
- (void)retriveKeys;
- (void)sendStoreKeys;


// HUD
- (void)showActivityView:(NSString*)message;
- (void)terminateActivityView;



@end
