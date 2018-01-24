//============================================================
//
// Copyright (c) nCrypted Cloud, 2012. All Rights Reserved.
//
// File: FirstViewController.h
// Created By:Oleg Lavronov on 8/16/12.
//
// Description: Main application view controller
//
//===========================================================
#import <UIKit/UIKit.h>
#import "MasterViewController.h"

@interface FirstViewController : UIViewController <SubstitutableDetailViewController>
{
    UIToolbar*          toolbar;
    UIBarButtonItem*    rootPopoverButtonItem;
}



@property (nonatomic, retain) IBOutlet UIToolbar*   toolbar;
@property (nonatomic, retain) UIBarButtonItem*      rootPopoverButtonItem;

@end
