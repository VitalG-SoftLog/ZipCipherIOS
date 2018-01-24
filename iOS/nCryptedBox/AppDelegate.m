//============================================================
//
// Copyright (c) nCrypted Cloud, 2012. All Rights Reserved.
//
// File: AppDelegate.m
// Created By: Oleg Lavronov on 7/25/12.
//
// Description: Main application delegate
//
//===========================================================
#import <DropboxSDK/DropboxSDK.h>
#import "AppDelegate.h"
#import "MasterViewController.h"
#import "DetailViewController.h"
#import "FirstViewController.h"
#import "LoginViewController.h"
#import "StartViewController.h"
#import "RegisterViewController.h"
#import "TimerViewController.h"

@interface AppDelegate () <DBSessionDelegate, DBNetworkRequestDelegate>
{
    KeychainItemWrapper*      _passwordKeychain;
    KeychainItemWrapper*      _accountKeychain;
}
@end

@implementation AppDelegate

@synthesize window                  = _window;
@synthesize navigationController    = _navigationController;
@synthesize splitViewController     = _splitViewController;
@synthesize rootPopoverButtonItem;
@synthesize popoverController;
@synthesize masterViewController;
@synthesize keyDefault              = _keyDefault;
@synthesize keyShared               = _keyShared;
@synthesize backupShared            = _backupShared;
@synthesize keyPassword             = _keyPassword;
@synthesize nCryptBox               = _nCryptBox;
@synthesize webService              = _webService;
@synthesize passwordKeychain        = _passwordKeychain;
@synthesize accountKeychain         = _accountKeychain;


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_webService release];
    [_nCryptBox release];
    [_window release];
    [_navigationController release];
    [_splitViewController release];
    [_passwordKeychain release];
	[_accountKeychain release];

    [super dealloc];
}

// Creates a writable copy of the bundled default keys in the application Documents directory.
- (NSString*) createEditableCopyOfKeysIfNeeded {
    // First, test for existence.
    BOOL success;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryeDirectory = [paths objectAtIndex:0];
    NSString *writablePath = [libraryeDirectory stringByAppendingPathComponent:kKeyStorageFile];
    success = [fileManager fileExistsAtPath:writablePath];
    if (success)
        return writablePath;
    // The writable database does not exist, so copy the default to the appropriate location.
    NSString *defaultPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:kKeyStorageFile];
    success = [fileManager copyItemAtPath:defaultPath toPath:writablePath error:&error];
    if (!success) {
        NSAssert1(0, @"Failed to create writable keys file with message '%@'.", [error localizedDescription]);
    }
    return writablePath;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //[self redirectConsoleLogToDocumentFolder];
    TRACE(@"Start application");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(webError:) name:kWebError object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(webErrorKeyNotFound:) name:kWebErrorKeyNotFound object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveKeys:) name:kRetrieveKeys object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(associateMachineResponse:) name:kAssociateMachine object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(registerAccountResponse:) name:kRegisterAccount object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getKeyResponse:) name:kGetKey object: nil];

    // Get UserName, Account, Password
	KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:kKeychainAccount accessGroup:@"YOUR_APP_ID_HERE.com.ncryptedcloud.NCryptedBox"];
    _accountKeychain = wrapper;
    NSLog(@"Account: %@", [self.passwordKeychain objectForKey:kKeychainAccount]);
    [wrapper release];

    _passwordKeychain = [[KeychainItemWrapper alloc] initWithIdentifier:kKeychainPassword accessGroup:nil];
    _keyPassword = [self.passwordKeychain objectForKey:kSecValueData];
    NSLog(@"Password: %@", _keyPassword);

    // Initializtion
    _webService = [[WebServiceProvider alloc] init];
    _nCryptBox = [[NCryptBox alloc] init];
    _nCryptBox.delegate = self;
    [_nCryptBox setVersionApplication:[NSString stringWithFormat:@"%@-ios", [AppDelegate applicationVersion]]];

    _webService.userEmail = [[NSUserDefaults standardUserDefaults] stringForKey:@"userEmail"];
    _webService.authToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"authToken"];
    _webService.computerName = [[NSUserDefaults standardUserDefaults] stringForKey:@"computerName"];

//    _webService.computerName = [NSString stringWithFormat:@"My%@%@", [[UIDevice currentDevice] name], [NCryptBox generateUUIDString]];
//    _webService.computerName = [NSString stringWithFormat:@"MyPhoneI%@", [[UIDevice currentDevice] name]];
//    [[UIDevice currentDevice] systemVersion];;

    TRACE(@"User email: %@", _webService.userEmail);
    TRACE(@"Auth token: %@", _webService.authToken);
    TRACE(@"Computer name: %@", _webService.computerName);

    // Load keys.xml
    @try {
        [self.nCryptBox loadKeys:[self createEditableCopyOfKeysIfNeeded] withPassword:_keyPassword];
    }
    @catch (NSException *exception) {
        TRACE(@"ERROR keys loading: %@: %@", [exception name], [exception reason]);
    }

    // Create Dropbox session
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    // Set these variables before launching the app
	NSString *root = kDBRootDropbox; // Should be set to either kDBRootAppFolder or kDBRootDropbox
	// You can determine if you have App folder access or Full Dropbox along with your consumer key/secret
	// from https://dropbox.com/developers/apps

	// Look below where the DBSession is created to understand how to use DBSession in your app

	NSString* errorMsg = nil;
	if ([kAPP_KEY rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]].location != NSNotFound) {
		errorMsg = @"Make sure you set the app key correctly in AppDelegate.m";
	} else if ([kAPP_SECRET rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]].location != NSNotFound) {
		errorMsg = @"Make sure you set the app secret correctly in AppDelegate.m";
	} else if ([root length] == 0) {
		errorMsg = @"Set your root to use either App Folder of full Dropbox";
	} else {
		NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
		NSData *plistData = [NSData dataWithContentsOfFile:plistPath];
		NSDictionary *loadedPlist =
        [NSPropertyListSerialization
         propertyListFromData:plistData mutabilityOption:0 format:NULL errorDescription:NULL];
		NSString *scheme = [[[[loadedPlist objectForKey:@"CFBundleURLTypes"] objectAtIndex:0] objectForKey:@"CFBundleURLSchemes"] objectAtIndex:0];
		if ([scheme isEqual:@"db-APP_KEY"]) {
			errorMsg = @"Set your URL scheme correctly in nCryptedBox-Info.plist";
		}
	}

	DBSession* session = [[DBSession alloc] initWithAppKey:kAPP_KEY appSecret:kAPP_SECRET root:kDBRootDropbox];
	session.delegate = self; // DBSessionDelegate methods allow you to handle re-authenticating
	[DBSession setSharedSession:session];
    [session release];

	[DBRequest setNetworkRequestDelegate:self];

	if (errorMsg != nil) {
		[[[[UIAlertView alloc]
		   initWithTitle:@"Error Configuring Session" message:errorMsg
		   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
		  autorelease]
		 show];
	}


    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.masterViewController = [[[MasterViewController alloc] initWithNibName:@"MasterViewController_iPhone" bundle:nil] autorelease];
        self.navigationController = [[[UINavigationController alloc] initWithRootViewController:masterViewController] autorelease];
        self.window.rootViewController = self.navigationController;
    } else {
        self.masterViewController = [[[MasterViewController alloc] initWithNibName:@"MasterViewController_iPad" bundle:nil] autorelease];
        UINavigationController *masterNavigationController = [[[UINavigationController alloc] initWithRootViewController:masterViewController] autorelease];

        FirstViewController *firstViewController = [[[FirstViewController alloc] initWithNibName:@"FirstViewController_iPad" bundle:nil] autorelease];
    	masterViewController.detailViewController = firstViewController;

        self.splitViewController = [[UISplitViewController alloc] init];
        self.splitViewController.viewControllers = [NSArray arrayWithObjects:masterNavigationController, firstViewController, nil];
        self.splitViewController.delegate = masterViewController;
        if ([self.splitViewController respondsToSelector:@selector(setPresentsWithGesture:)]) {
            [self.splitViewController setPresentsWithGesture:NO];
        }
        [self.window addSubview:self.splitViewController.view];
        [self.window makeKeyAndVisible];

        self.window.rootViewController = self.splitViewController;
    }

  //  _webService.authToken = @"";

    [self.window makeKeyAndVisible];

    if ([_webService.authToken length] == 0)
    {
        StartViewController *controller = [[StartViewController alloc] initWithNibName:@"StartViewController" bundle:nil];
        controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:controller];
        [self.window.rootViewController presentModalViewController:navController animated:NO];
        [navController release];
        [controller release];
    }
    return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {

    TRACE(@"Open url:%@", url);
    if ([[DBSession sharedSession] handleOpenURL:url]) {
		if ([[DBSession sharedSession] isLinked]) {
            [self.navigationController pushViewController:(UIViewController*)masterViewController.dropboxViewController animated:NO];
		}
		return YES;
	}

    if ([url isFileURL]) {
        [self.navigationController popToRootViewControllerAnimated:NO];
        [self.masterViewController previewFile:url.path];
        return YES;
    }
	return NO;
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    if (self.popoverController != nil) {
        [self.popoverController dismissPopoverAnimated:YES];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    if (self.popoverController != nil) {
        [self.popoverController dismissPopoverAnimated:YES];
    }
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    if (self.popoverController != nil) {
        [self.popoverController dismissPopoverAnimated:YES];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    if (self.popoverController != nil) {
        [self.popoverController dismissPopoverAnimated:YES];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    if (self.popoverController != nil) {
        [self.popoverController dismissPopoverAnimated:YES];
    }
}


#pragma mark -
#pragma mark DBSessionDelegate methods
- (void)sessionDidReceiveAuthorizationFailure:(DBSession*)session userId:(NSString *)userId {
    NSLog(@"%@", NSStringFromSelector(_cmd));
	relinkUserId = [userId retain];
	[[[[UIAlertView alloc]
	   initWithTitle:@"Dropbox Session Ended" message:@"Do you want to relink?" delegate:self
	   cancelButtonTitle:@"Cancel" otherButtonTitles:@"Relink", nil]
	  autorelease]
	 show];
}


#pragma mark -
#pragma mark UIAlertViewDelegate methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)index {
    NSLog(@"%@", NSStringFromSelector(_cmd));
	if (index != alertView.cancelButtonIndex) {
		[[DBSession sharedSession] linkUserId:relinkUserId fromController:self.masterViewController];
	}
	[relinkUserId release];
	relinkUserId = nil;
}


#pragma mark -
#pragma mark DBNetworkRequestDelegate methods
static int outstandingRequests;

- (void)networkRequestStarted {
	outstandingRequests++;
	if (outstandingRequests == 1) {
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	}
}

- (void)networkRequestStopped {
	outstandingRequests--;
	if (outstandingRequests == 0) {
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	}
}

//
/*
 <zipcipher>
 <kc>
 <sk>
 <skid>{DF5597D5-B10B-4C39-97A4-AE93997B2F84}</skid>
 <skv><![CDATA[H3AUy8LC50BMUNquc1BkPkkxFGJM6fnhwds2iqxdeYg=]]></skv>
 </sk>
 </kc>
 </zipcipher>
 */

#pragma mark -
#pragma mark Keys methods

- (void) redirectConsoleLogToDocumentFolder
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *logPath = [documentsDirectory stringByAppendingPathComponent:@"console.log"];
    freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
}

#pragma mark -
#pragma mark Tools functions

+ (NSString *)formattedFileSize:(unsigned long long)size
{
    NSString *formattedStr = nil;
    if (size == 0)
        formattedStr = @"Empty";
    else
        if (size > 0 && size < 1024)
            formattedStr = [NSString stringWithFormat:@"%qu bytes", size];
        else
            if (size >= 1024 && size < pow(1024, 2))
                formattedStr = [NSString stringWithFormat:@"%.1f KB", (size / 1024.)];
            else
                if (size >= pow(1024, 2) && size < pow(1024, 3))
                    formattedStr = [NSString stringWithFormat:@"%.2f MB", (size / pow(1024, 2))];
                else
                    if (size >= pow(1024, 3))
                        formattedStr = [NSString stringWithFormat:@"%.3f GB", (size / pow(1024, 3))];

    return formattedStr;
}

+ (NSString *)documentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

+ (NSString *)cachesDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

- (void)saveKeys
{
    [self.nCryptBox saveKeys:[self createEditableCopyOfKeysIfNeeded] withPassword:self.keyPassword];
}

- (void)clearKeys
{
    [_webService setUserEmail:@""];
    [_webService setAuthToken:@""];
    [_webService setComputerName:@""];
    [_nCryptBox setDefaultKey:@""];
    [_nCryptBox setBackupKey:@""];
    [_nCryptBox.keys removeAllObjects];
    [self.passwordKeychain resetKeychainItem];
    [self setKeyPassword:@""];
    [self setKeyDefault:@""];
    [self setKeyShared:@""];
    [self setBackupShared:@""];
    [self setKeyBackup:@""];

    NSString* fileName = [self createEditableCopyOfKeysIfNeeded];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError* error = nil;
    [fileManager removeItemAtPath:fileName error:&error];

}

+ (NSString*)applicationVersion {

    return [NSString stringWithFormat:@"%@.%@", [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"],
                                                [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey]];
}

+ (NSString*)computerName {
    return [[UIDevice currentDevice] name];
}

#pragma mark -
#pragma mark Web access
/*
- (void) authorizationRequest:(NSString *)userName andPassword:(NSString *)password
{
    [self showActivityView:@"Associating..."];
    [self.webService sendAssociateMachine:userName andPassword:password];
}
*/ 

- (void)registerAccount:(NSString *)userEmail firstName:(NSString *)firstName
               lastName:(NSString *)lastName invitation:(NSString *)invitation
            computername:(NSString *)computername password:(NSString *)password
{
    [self showActivityView:@"Registering..."];
    [self.webService sendRegisterAccount:userEmail
                               firstName:firstName
                                lastName:lastName
                              invitation:invitation
                            computername:computername
                                password:password];
}

- (void)associateMachine:(NSString *)userEmail
                password:(NSString *)password
                computerName:(NSString *)computerName
{
    [self showActivityView:@"Associating..."];
    [self.webService sendAssociateMachine:userEmail
                                 andPassword:password
                                 andComputerName:computerName];
}

- (void)unlinkMachine
{
    [self showActivityView:@"Unlinking..."];
    [self.webService sendUnlinkMachine];
}

- (void)retriveKeys
{
    [self showActivityView:@"Retrive keys..."];
    [self.webService sendRetrieveKeys];
}

- (void)sendStoreKeys
{
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString* keyID = [NSString stringWithFormat:@"{%@}",[NCryptBox generateUUIDString]];
        NSDictionary* keys = [NCryptBox generateRSAkey];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showActivityView:@"Store keys..."];
            [self.webService sendStoreKeys:keys withKeyID:keyID];

            [@"dd" UTF8String];
            // Backup key
            NCryptKey* backupKey = [[NCryptKey alloc] initWithIdentifier:keyID];

            NSString* privateKey = [keys objectForKey:kPrivateRSAKey];
            backupKey.value = [Cipher base64StringFromData:[privateKey dataUsingEncoding:NSUTF8StringEncoding]];
            backupKey.type = @"encryption";
            backupKey.name = @"Default backup key";
            backupKey.exportable = NO;
            backupKey.ownerid = self.webService.userEmail;
            [self.nCryptBox.keys setObject:backupKey forKey:keyID];

            NCryptKey* defaultKey = [self.nCryptBox.keys objectForKey:self.nCryptBox.defaultKey];
            defaultKey.ownerbackupkey = keyID;
            
            [self.nCryptBox.keys setObject:defaultKey forKey:self.nCryptBox.defaultKey];
            //
            //[defaultKey release];
            [self saveKeys];
        });
    });
/*
    NSString* keyID = [NSString stringWithFormat:@"{%@}",[NCryptBox generateUUIDString]];
    NSDictionary* keys = [NCryptBox generateRSAkey];

    [self showActivityView:@"Store keys..."];
    [self.webService sendStoreKeys:keys withKeyID:keyID];
*/ 
}

#pragma mark -
#pragma mark NCryptedBox wrapper
- (void)encryptFile:(NSString *)fileName intoFile:(NSString *)intoFile sharedFolderKey:(NSString*)sharedFolderKey
{
    // Show the HUD in the main tread
    dispatch_async(dispatch_get_main_queue(), ^{
        // No need to hod onto (retain)
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] keyWindow] animated:YES];
        hud.labelText = @"Encrypting ...";
    });

    // Do a taks in the background
    @try {
        if ([sharedFolderKey length] != 0) {
            [_nCryptBox encryptFile:fileName intoFile:intoFile key:sharedFolderKey backupKey:sharedFolderKey];
        } else {
            [_nCryptBox encryptFile:fileName intoFile:intoFile key:self.keyDefault backupKey:nil];
        }
    }
    @catch (NSException *exception) {
        TRACE(@"EXEPTION:%@", [exception name]);
    }
    @finally {
        // Hide the HUD in the main tread
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:[[UIApplication sharedApplication] keyWindow] animated:YES];
        });
    }

}


- (NSURL*) decryptFile:(NSString *)fileName
{
    NSURL* result = nil;

    dispatch_async(dispatch_get_main_queue(), ^{
        // No need to hod onto (retain)
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] keyWindow] animated:YES];
        hud.labelText = @"Decrypting ...";
    });

    // Do a taks in the background
    @try {
        result = [_nCryptBox decryptFile:fileName];
    }
    @catch (NSException *exception) {
        TRACE(@"EXEPTION:%@", [exception name]);
    }
    @finally {
        // Hide the HUD in the main tread
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:[[UIApplication sharedApplication] keyWindow] animated:YES];
        });
    }
    return result;
}


#pragma mark -
#pragma mark MBProgressHUDDelegate methods
- (void)hudWasHidden {
    // Remove HUD from screen when the HUD was hidded
    [_HUD removeFromSuperview];
    [_HUD release];
}

- (void)showBusyIndicator:(NSString*)label
{
    _HUD = [[MBProgressHUD alloc] initWithView:[[UIApplication sharedApplication] keyWindow]];
    if (IPHONE) {
//        _HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.visibleViewController.view];
//        _HUD = [[MBProgressHUD alloc] initWithView:[[UIApplication sharedApplication] keyWindow]];
    } else {
//        _HUD = [[MBProgressHUD alloc] initWithView:self.splitViewController.view];
    }
    _HUD.mode = MBProgressHUDModeDeterminate;
    [self.navigationController.view addSubview:_HUD];
    _HUD.delegate = self;
    _HUD.labelText = label;
    // Show the HUD while the provided method executes in a new thread
    //    [HUD showWhileExecuting:@selector(myProgressTask) onTarget:self withObject:nil animated:YES];
   // [_HUD showUsingAnimation:YES];
}

- (void)hideBusyIndicator
{
    //[_HUD hideUsingAnimation:YES];
}

#pragma mark -
#pragma mark NCryptBox properties
- (void)setKeyPassword:(NSString*)password
{
    if (_keyPassword != password) {
        if (_keyPassword == nil) {
            _keyPassword = [[NSString alloc] init];
        }
        _keyPassword = password;
        [_passwordKeychain resetKeychainItem];
        [_passwordKeychain setObject:self.keyPassword forKey:kSecValueData];
        [self.nCryptBox saveKeys:[self createEditableCopyOfKeysIfNeeded] withPassword:self.keyPassword];
    }
}

- (NSString*)keyDefault
{
    return self.nCryptBox.defaultKey;
}

- (void)setKeyDefault:(NSString*)keyDefault
{
    self.nCryptBox.defaultKey = keyDefault;
    [self.nCryptBox saveKeys:[self createEditableCopyOfKeysIfNeeded] withPassword:self.keyPassword];
}

- (NSString*)keyBackup
{
    return self.nCryptBox.backupKey;
}

- (void)setKeyBackup:(NSString*)keyBackup
{
    self.nCryptBox.backupKey = keyBackup;
    [self.nCryptBox saveKeys:[self createEditableCopyOfKeysIfNeeded] withPassword:self.keyPassword];
}


- (void)showActivityView:(NSString*)message
{
    HUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] keyWindow] animated:YES];
    HUD.delegate = self;
    HUD.labelText = message;
}

- (void)terminateActivityView
{
    [HUD hide:YES];
}

#pragma mark -
#pragma mark MBProgressHUDDelegate methods
- (void)hudWasHidden:(MBProgressHUD *)hud {
	// Remove HUD from screen when the HUD was hidded
	//[HUD removeFromSuperview];
	//[HUD release];
	HUD = nil;
    NSLog(@"HUD release");
}

#pragma mark -
#pragma mark NCryptBoxDelegate
-(void)loadSynchronousKey:(NSString*)keyID
{
    /*NSDictionary* message = */[self.webService sendSynchronousGetKey:keyID];
}

-(void)loadKey:(NSString*)keyID
{
    [self.webService sendGetKey:keyID];
}

- (void)didRecieveSharedKeys:(NSString *)keyID backupKey:(NSString *)backupKeyID
{
    self.keyShared = keyID;
    self.backupShared = backupKeyID;
}

#pragma mark -
#pragma mark WebServiceProvider notification
- (void) recieveKeysOnMainThread:(id)keys {
    [self terminateActivityView];
    if ([keys isKindOfClass:[NSArray class]] ) {
        [self.nCryptBox.keys removeAllObjects];
        NCryptKey* defaultKey = [[NCryptKey alloc] initWithIdentifier:self.nCryptBox.defaultKey];
        defaultKey.value = self.nCryptBox.defaultKeyValue;
        defaultKey.type = @"storage";
        defaultKey.name = @"Default key";
        [self.nCryptBox.keys setObject:defaultKey forKey:defaultKey.ID];
        NSLog(@"%@", defaultKey.ID);
        [defaultKey release];

        for (id key in keys) {
            if ([key isKindOfClass:[NSDictionary class]]) {
                [self.nCryptBox importKeyFromDicitonary:key];
            }
        }
        [self.nCryptBox saveKeys:[self createEditableCopyOfKeysIfNeeded] withPassword:self.keyPassword];
    }
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    [[[[UIAlertView alloc]
       initWithTitle:@"Application error" message:@"Memory leaks :-("
       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
      autorelease]
     show];
}

- (void) webErrorOnMainThread:(NSError*)error
{
    [self terminateActivityView];
    [[[[UIAlertView alloc]
       initWithTitle:@"Server error" message:[error localizedDescription]
       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
      autorelease]
     show];
    if (error.code == kWebINVALID_AUTH_TOKEN) {
        
    }
}

- (void) webErrorKeyNotFoundOnMainThread:(NSError*)error
{
    [self terminateActivityView];
#ifdef DEBUG
    [self webErrorOnMainThread:error];
#endif
    NSString* keyID = [[error userInfo] objectForKey:kWebKEY];
    if ([keyID length] != 0) {
        NCryptKey* key = [self.nCryptBox.keys objectForKey:keyID];
        if (key) {
            TRACE(@"Remove backup key: %@", key.ownerbackupkey);
            [self.nCryptBox.keys removeObjectForKey:key.ownerbackupkey];
            TRACE(@"Remove key: %@", key.ID);
            [self.nCryptBox.keys removeObjectForKey:key.ID];
            [self saveKeys];
        }
    }
}


- (void) associateMachineOnMainThread:(id)object
{
    [self terminateActivityView];
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSDictionary* message = object;
        [self.nCryptBox generateStorageKey:[message objectForKey:@"email"] withPassword:[message objectForKey:@"password"] andEntropy:@""];
        self.nCryptBox.defaultKey = self.nCryptBox.storageKeyID;
        self.nCryptBox.defaultKeyValue = self.nCryptBox.storageKeyValue;
        TRACE(@"Default key: %@", self.nCryptBox.defaultKey);
        TRACE(@"Default key value: %@", self.nCryptBox.defaultKeyValue);
        [self saveKeys];
    }

}

- (void) registerAccountResponseOnMainThread:(NSDictionary*)message
{
    [self.nCryptBox.keys removeAllObjects];

    NSString* email = [message objectForKey:@"email"];
    NSString* password = [message objectForKey:@"password"];
    if ([email length] && [password length]) {
        // Default key
        [self.nCryptBox generateStorageKey:email withPassword:password andEntropy:@""];
        NCryptKey* defaultKey = [[NCryptKey alloc] initWithIdentifier:self.nCryptBox.storageKeyID];
        defaultKey.value = self.nCryptBox.storageKeyValue;
        defaultKey.type = @"storage";
        defaultKey.name = @"Default key";
        [self.nCryptBox.keys setObject:defaultKey forKey:defaultKey.ID];
        self.nCryptBox.defaultKey = defaultKey.ID;
        NSLog(@"%@", defaultKey.ID);
        [defaultKey release];
    }
    [self.nCryptBox saveKeys:[self createEditableCopyOfKeysIfNeeded] withPassword:@""];
}

- (void) getKeyResponseOnMainThread:(id)object
{
    [self terminateActivityView];
    if ([object isKindOfClass:[NSDictionary class]]) {
        [self.nCryptBox importKeyFromDicitonary:object];
    }
}

- (void) registerAccountResponse:(NSNotification *)notification
{
	[self performSelectorOnMainThread:@selector(registerAccountResponseOnMainThread:) withObject:notification.object waitUntilDone: NO];
}


- (void) recieveKeys:(NSNotification *)notification
{
	[self performSelectorOnMainThread:@selector(recieveKeysOnMainThread:) withObject:notification.object waitUntilDone: NO];
}

- (void) webError:(NSNotification *)notification
{
	[self performSelectorOnMainThread:@selector(webErrorOnMainThread:) withObject:notification.object waitUntilDone: NO];
}

- (void) webErrorKeyNotFound:(NSNotification *)notification
{
	[self performSelectorOnMainThread:@selector(webErrorKeyNotFoundOnMainThread:) withObject:notification.object waitUntilDone: NO];
}


- (void) associateMachineResponse:(NSNotification *)notification
{
	[self performSelectorOnMainThread:@selector(associateMachineOnMainThread:) withObject:notification.object waitUntilDone: NO];
}

- (void) getKeyResponse:(NSNotification *)notification
{
	[self performSelectorOnMainThread:@selector(getKeyResponseOnMainThread:) withObject:notification.object waitUntilDone: NO];
}

@end
