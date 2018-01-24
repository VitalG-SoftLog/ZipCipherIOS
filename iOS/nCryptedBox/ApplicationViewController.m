//============================================================
//
// Copyright (c) nCrypted Cloud, 2012. All Rights Reserved.
//
// File: ApplicationViewController.h
// Created By: Oleg Lavronov on 9/1/12.
//
// Description: Abstract class for application views
//
//============================================================
#import "ApplicationViewController.h"

@interface ApplicationViewController ()

@end

@implementation ApplicationViewController

@synthesize appDelegate;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    }
    return self;
}

@end
