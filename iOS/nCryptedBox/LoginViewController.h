//============================================================
//
// Copyright (c) nCrypted Cloud, 2012. All Rights Reserved.
//
// File: LoginViewController.h
// Created By: Oleg Lavronov on 9/12/12.
//
// Description: Login window
//
//============================================================
#import <UIKit/UIKit.h>
#import "ApplicationViewController.h"

@interface LoginViewController : UITableViewController<UITextFieldDelegate>
{
    UIView *buttonView;
}

@property (nonatomic, assign) AppDelegate*  appDelegate;


@end
