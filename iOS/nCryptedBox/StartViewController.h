//============================================================
//
// Copyright (c) nCrypted Cloud, 2012. All Rights Reserved.
//
// File: StartViewController.h
// Created By: Oleg Lavronov on 9/20/12.
//
// Description: Start window
//
//============================================================
#import <UIKit/UIKit.h>
#import "ApplicationViewController.h"

@interface StartViewController : ApplicationViewController<UITableViewDataSource,
                                                            UITableViewDelegate>
{
}


@property (nonatomic, retain) IBOutlet UILabel      *labelVersion;
@property (nonatomic, retain) IBOutlet UILabel      *labelName;
@property (nonatomic, retain) IBOutlet UIButton     *buttonLog;
@property (nonatomic, retain) IBOutlet UITableView  *tableView;
@property (nonatomic, retain) IBOutlet UIImageView  *imageLogo;

-(IBAction) clickLog;

@end
