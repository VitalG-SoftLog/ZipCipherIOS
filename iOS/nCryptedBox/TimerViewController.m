//============================================================
//
// Copyright (c) nCrypted Cloud, 2012. All Rights Reserved.
//
// File: TimerViewController.m
// Created By: Oleg Lavronov on 10/4/12.
//
// Description: Timer window
//
//============================================================
#import "TimerViewController.h"

@interface TimerViewController ()
{
    NSTimer* timer;
    NSTimeInterval  startTime;
}

@end

@implementation TimerViewController

@synthesize labelTimer;

- (void)dealloc
{
    [labelTimer release];
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    startTime = [[NSDate date] timeIntervalSince1970];
    timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(increaseTimerCount) userInfo:nil repeats:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.appDelegate sendStoreKeys];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)increaseTimerCount
{
    NSTimeInterval  nowTime = [[NSDate date] timeIntervalSince1970] - startTime;

    int minutes = floor(nowTime/60);
    int seconds = round(nowTime - minutes * 60);

    labelTimer.text = [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
}


@end
