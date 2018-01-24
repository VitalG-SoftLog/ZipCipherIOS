//============================================================
//
// Copyright (c) nCrypted Cloud, 2012. All Rights Reserved.
//
// File: RegisterViewController.h
// Created By: Oleg Lavronov on 9/20/12.
//
// Description: Start window
//
//============================================================
#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@interface RegisterViewController : UITableViewController<UITextFieldDelegate>
{
     UIView *buttonView;
}

@property (nonatomic, assign) AppDelegate*  appDelegate;


@end
