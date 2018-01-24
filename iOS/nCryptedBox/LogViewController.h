//============================================================
//
// Copyright (c) nCrypted Cloud, 2012. All Rights Reserved.
//
// File: LogViewController.h
// Created By: Oleg Lavronov on 8/3/12.
//
// Description: View controller for show log file application
//
//===========================================================
#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "MasterViewController.h"
#import "Log.h"

@interface LogViewController : UIViewController <SubstitutableDetailViewController, UITextViewDelegate>
{
    AppDelegate*                appDelegate;
    IBOutlet UITextView*        textView;
    IBOutlet UINavigationBar*   navigationBar;
//    IBOutlet UIBarButtonItem*   buttonClear;
}

@property (nonatomic, assign) AppDelegate*          appDelegate;
@property (nonatomic, retain) IBOutlet UITextView*  textView;
@property (nonatomic, retain) IBOutlet UINavigationBar *navigationBar;
//@property (nonatomic, retain) IBOutlet UIBarButtonItem *buttonClear;

- (IBAction)buttonClicked:(id)sender;


@end
