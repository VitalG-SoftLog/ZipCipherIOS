//============================================================
//
// Copyright (c) nCrypted Cloud, 2012. All Rights Reserved.
//
// File: HelpViewController.h
// Created By: Oleg Lavronov on 7/25/12.
//
// Description: Help page view controller
//
//===========================================================
#import <UIKit/UIKit.h>

@interface HelpViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) id detailItem;

@property (strong, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end
