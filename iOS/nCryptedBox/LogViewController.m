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
#import "LogViewController.h"

@interface LogViewController ()  
@end

@implementation LogViewController

@synthesize appDelegate;
@synthesize textView;
@synthesize navigationBar;
//@synthesize buttonClear;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(webError:) name:kWebError object: nil];
    }
    return self;
}

- (void)viewDidLoad
{
    // Add clear button
    [super viewDidLoad];
    
    if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)) {
        UIBarButtonItem *btnCancel = [[[UIBarButtonItem alloc] initWithTitle:@"Clear"
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:self
                                                                      action:@selector(buttonClicked:)]autorelease];
        self.navigationItem.rightBarButtonItem = btnCancel;
        [self setTitle:@"Log file"];
    } else {
//        [navigationBar.topItem setRightBarButtonItem:btnCancel animated:NO];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.textView = nil;
    self.navigationBar = nil;
    //self.buttonClear = nil;
}

- (void)dealloc
{
    [textView release];
    [navigationBar release];
    //[buttonClear release];
    [super dealloc];
}



- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *logPath = [documentsDirectory stringByAppendingPathComponent:@"console.log"];
    NSError *error = nil;
    
    textView.text = [[[NSString alloc] initWithContentsOfFile:logPath encoding:NSUTF8StringEncoding error:&error] autorelease];
}


/*
- (void)splitViewController:(MGSplitViewController*)svc willChangeSplitOrientationToVertical:(BOOL)isVertical
{
	NSLog(@"%@", NSStringFromSelector(_cmd));
}
*/

#pragma mark - Text view
-  (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    return NO;
}

#pragma mark -
#pragma mark Managing the popover

- (void)showRootPopoverButtonItem:(UIBarButtonItem *)barButtonItem {
    // Add the popover button to the left navigation item.
    [navigationBar.topItem setLeftBarButtonItem:barButtonItem animated:NO];
}


- (void)invalidateRootPopoverButtonItem:(UIBarButtonItem *)barButtonItem {
    // Remove the popover button.
    [navigationBar.topItem setLeftBarButtonItem:nil animated:NO];
}


#pragma mark -
#pragma mark Rotation support
/*
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}
*/

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


#pragma mark -
#pragma mark Actions

- (IBAction)buttonClicked:(id)sender
{
    [self.view endEditing:YES];
    // For error information
    NSError *error = nil;
    
    // Create file manager
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *logPath = [documentsDirectory stringByAppendingPathComponent:@"console.log"];
    
    if ([fileMgr removeItemAtPath:logPath error:&error] != YES)
        NSLog(@"Unable to delete file: %@", [error localizedDescription]);
    
    textView.text = @"";
    TRACE(@"Clear log file");
}

-(void) webError:(id)error
{

}

@end
