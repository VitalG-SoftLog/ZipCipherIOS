//
//  SettingsViewController.h
//  nCryptedBox
//
//  Created by Oleg Lavronov on 8/12/12.
//  Copyright (c) 2012 nCrypted Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "PasswordViewController.h"


@interface SettingsViewController : UITableViewController <PasswordViewDelegate,
                                                            UIAlertViewDelegate,
                                                            UITextFieldDelegate>
{
    AppDelegate*    _appDelegate;
    UInt16          passwordCount;
}

@property (nonatomic, retain) AppDelegate*      appDelegate;


- (IBAction)buttonImport:(id)sender;


@end
