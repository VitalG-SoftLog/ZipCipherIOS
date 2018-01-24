//============================================================
//
// Copyright (c) nCrypted Cloud, 2012. All Rights Reserved.
//
// File: StartViewController.m
// Created By: Oleg Lavronov on 9/20/12.
//
// Description: Start window
//
//============================================================
#import "StartViewController.h"
#import "RegisterViewController.h"
#import "LoginViewController.h"
#import "TimerViewController.h"
#import "LogViewController.h"

@interface StartViewController ()

@end

@implementation StartViewController

@synthesize buttonLog;
@synthesize tableView;
@synthesize labelVersion;
@synthesize labelName;
@synthesize imageLogo;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [tableView release];
    [labelVersion release];
    [labelName release];
    [buttonLog release];
    [imageLogo release];

    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    /*
     if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
     {
         self = [super initWithNibName: [NSString stringWithFormat:@"%@-iPad", nibNameOrNil] bundle:nibBundleOrNil];
     } else {
         self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
     }
     */
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(storeKeys:) name:kStoreKeys object: nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(webError:) name:kWebError object: nil];
        self.title = @"Welcome to nCryptedBox";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationItem setBackBarButtonItem:[[UIBarButtonItem alloc]
                                               initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:nil action:nil]];

    [self.labelVersion setText:[AppDelegate applicationVersion]];

    [self.tableView setBackgroundView:nil];
    [self.tableView setBackgroundView:[[[UIView alloc] init] autorelease]];
    [self.tableView setBackgroundColor:UIColor.clearColor];

    [self.tableView setAlpha:.0];
    [self.labelVersion setAlpha:.0];
    [self.labelName setAlpha:.0];
    [self.buttonLog setAlpha:.0];
    [self.imageLogo setAlpha:.0];

    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.tableView = nil;
    self.labelVersion = nil;
    self.labelName = nil;
    self.buttonLog = nil;
    self.imageLogo = nil;

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:1.0];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];

    [self.tableView setAlpha:1.0];
    [self.labelVersion setAlpha:1.0];
    [self.labelName setAlpha:1.0];
    [self.buttonLog setAlpha:1.0];
    [self.imageLogo setAlpha:1.0];
    [UIView commitAnimations];
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;//(interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}
/*
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {

    CGRect frame = [self.view bounds];
    return frame.size.height - (44.0 * 3);
}
*/
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CellIdentifier";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"I'm already a nCryptBox user";
            break;
        case 1:
            cell.textLabel.text = @"I'm new to nCryptBox";
            break;
        default:
            break;
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    switch (indexPath.row) {
        case 0:
        {
            LoginViewController *controller = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
            [self.navigationController pushViewController:controller animated:YES];
            [controller release];
            break;
        }
        case 1:
        {
            RegisterViewController *controller = [[RegisterViewController alloc] initWithNibName:@"RegisterViewController" bundle:nil];
            [self.navigationController pushViewController:controller animated:YES];
            [controller release];
/*
            TimerViewController *controller = [[TimerViewController alloc] initWithNibName:@"TimerViewController" bundle:nil];
            [self.navigationController presentModalViewController:controller animated:YES];
*/
            break;
        }
        default:
            break;
    }
}

-(IBAction) clickLog
{
    LogViewController *controller = [[LogViewController alloc] initWithNibName:@"LogViewController_iPhone" bundle:nil];
    [self.navigationController pushViewController:controller animated:YES];
    [controller release];
}


#pragma mark -

- (void) storeKeysOnMainThread {
    [self.appDelegate terminateActivityView];
    [self.navigationController popToRootViewControllerAnimated:YES];
    [self dismissModalViewControllerAnimated:NO];
}

- (void) webErrorOnMainThread {
    [self.appDelegate terminateActivityView];
    [self.navigationController popToRootViewControllerAnimated:YES];
}


- (void) storeKeys:(NSNotification *)notification {
	[self performSelectorOnMainThread:@selector(storeKeysOnMainThread) withObject: nil waitUntilDone: NO];
}

- (void) webError:(NSNotification *)notification {
	[self performSelectorOnMainThread:@selector(webErrorOnMainThread) withObject:notification.object waitUntilDone: NO];
}



@end
