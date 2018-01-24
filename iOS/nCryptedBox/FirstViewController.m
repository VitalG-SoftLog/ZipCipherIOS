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
#import "FirstViewController.h"

@interface FirstViewController ()

@end

@implementation FirstViewController

@synthesize toolbar;
@synthesize rootPopoverButtonItem;

- (void)showRootPopoverButtonItem:(UIBarButtonItem *)barButtonItem {

    // Add the popover button to the toolbar.
    NSMutableArray *itemsArray = [toolbar.items mutableCopy];
    [itemsArray insertObject:barButtonItem atIndex:0];
    [toolbar setItems:itemsArray animated:NO];
    [itemsArray release];

    self.rootPopoverButtonItem = barButtonItem;

}

- (void)invalidateRootPopoverButtonItem:(UIBarButtonItem *)barButtonItem {

    // Remove the popover button from the toolbar.
    NSMutableArray *itemsArray = [toolbar.items mutableCopy];
    [itemsArray removeObject:barButtonItem];
    [toolbar setItems:itemsArray animated:NO];
    [itemsArray release];
    self.rootPopoverButtonItem = nil;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.toolbar = nil;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    /*
    if (self.rootPopoverButtonItem != nil) {
        [self.rootPopoverButtonItem.target performSelector:self.rootPopoverButtonItem.action
                                                withObject:self.rootPopoverButtonItem];
    }
     */
}

- (void)viewWillAppear:(BOOL)animated
{
    CGSize size = CGSizeMake(320, 200); // size of view in popover
    self.contentSizeForViewInPopover = size;
    [super viewWillAppear:animated];
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
