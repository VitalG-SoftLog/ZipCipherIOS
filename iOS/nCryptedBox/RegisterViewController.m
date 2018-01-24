//============================================================
//
// Copyright (c) nCrypted Cloud, 2012. All Rights Reserved.
//
// File: RegisterViewController.m
// Created By: Oleg Lavronov on 9/20/12.
//
// Description: Start window
//
//============================================================
#import "Log.h"
#import "RegisterViewController.h"
#import "TimerViewController.h"


@interface RegisterViewController ()

@end

@implementation RegisterViewController

@synthesize appDelegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(registerAccount:) name:kRegisterAccount object: nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(webError:) name:kWebError object: nil];

        self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        self.title = @"Registration";//NSLocalizedString(@"Preview", @"Preview");
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    UIImageView *tableImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Default.png"]];
    [tableImage setFrame:self.tableView.frame];

    self.tableView.backgroundView = tableImage;
    [tableImage release];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
//    [self.tableView reloadData];
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 0) {
        return 6;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
	cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    if (indexPath.section == 0) {
//        NSLog(@"x: %f, y:%f, width: %f, height: %f", cell.frame.origin.x, cell.frame.origin.y, cell.frame.size.width, cell.frame.size.height);
        UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(120.0, 10.0, cell.frame.size.width-20.0-120.0, 30.0)];
        textField.adjustsFontSizeToFitWidth = YES;
        textField.textColor = [UIColor blackColor];
        textField.backgroundColor = [UIColor clearColor];
        textField.autocorrectionType = UITextAutocorrectionTypeNo; // no auto correction support
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone; // no auto capitalization support
        textField.textAlignment = UITextAlignmentLeft;
        textField.tag = 1;
        textField.delegate = self;
        switch (indexPath.row) {
            case 0:
                textField.placeholder = @"example@ncryptedbox.com";
                textField.keyboardType = UIKeyboardTypeEmailAddress;
                textField.returnKeyType = UIReturnKeyNext;
                break;
            case 1:
            case 2:
            case 3:
                textField.placeholder = @"optional";
                textField.keyboardType = UIKeyboardTypeDefault;
                textField.returnKeyType = UIReturnKeyNext;
                break;
            case 4:
                textField.placeholder = @"Required";
                textField.keyboardType = UIKeyboardTypeDefault;
                textField.returnKeyType = UIReturnKeyNext;
                textField.text = [AppDelegate computerName];
                break;
             case 5:
                textField.returnKeyType = UIReturnKeyDone;
                textField.secureTextEntry = YES;
                textField.placeholder = @"Required";
                break;
            default:
                textField.placeholder = @"Required";
                textField.keyboardType = UIKeyboardTypeDefault;
                textField.returnKeyType = UIReturnKeyNext;
                break;
        }
        
        textField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;

        textField.clearButtonMode = UITextFieldViewModeNever; // no clear 'x' button to the right
        [textField setEnabled: YES];

        [cell addSubview:textField];

        [textField release];

        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"E-Mail:";
                break;
            case 1:
                cell.textLabel.text = @"First Name:";
                break;
            case 2:
                cell.textLabel.text = @"Last Name:";
                break;
            case 3:
                cell.textLabel.text = @"Invitation:";
                break;
            case 4:
                cell.textLabel.text = @"Computer name:";
                break;
            case 5:
                cell.textLabel.text = @"Password:";
                break;
            default:
                break;
        }
        
        

    } else {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [button setFrame:cell.frame];//CGRectMake(10.0f, 0.0f, 300.0f, 44.0f)];
        [button setTitle:@"Register" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(doStuff:) forControlEvents:UIControlEventTouchUpInside];
        [cell addSubview:button];
    }
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 54.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {

    if(buttonView == nil) {
        //allocate the view if it doesn't exist yet
        buttonView  = [[UIView alloc] init];

        //create the button
        UIButton* button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        //[button setBackgroundImage:image forState:UIControlStateNormal];

        //the button should be as big as a table view cell
        [button setFrame:CGRectMake(20., 10., 280.0, 44.0)];
        button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;

        [buttonView setBackgroundColor:[UIColor clearColor]];

        //set title, font size and font color
        [button setTitle:@"Register" forState:UIControlStateNormal];
        //[button.titleLabel setFont:[UIFont boldSystemFontOfSize:20]];
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];

        //set action of the button
        [button addTarget:self action:@selector(registerAction:)
         forControlEvents:UIControlEventTouchUpInside];

        //add the button to the view
        [buttonView addSubview:button];
    }

    //return the view for the footer
    return buttonView;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
}

- (IBAction)registerAction:(id)sender
{
    [self.view endEditing:YES];

    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UITextField* emailField = (UITextField*)[cell viewWithTag:1];
    if ([emailField.text length] == 0) {
        [[[[UIAlertView alloc]
           initWithTitle:@"Error" message:@"E-Mail field is required."
           delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
          autorelease]
         show];
        return;
    }

    cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    UITextField* firstField = (UITextField*)[cell viewWithTag:1];

    cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    UITextField* lastField = (UITextField*)[cell viewWithTag:1];

    cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    UITextField* intitationField = (UITextField*)[cell viewWithTag:1];

    cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:0]];
    UITextField* nameField = (UITextField*)[cell viewWithTag:1];
    if ([nameField.text length] == 0) {
        [[[[UIAlertView alloc]
           initWithTitle:@"Error" message:@"Name field is required."
           delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
          autorelease]
         show];
        return;
    }

    cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:5 inSection:0]];
    UITextField* passwordField = (UITextField*)[cell viewWithTag:1];
    if ([passwordField.text length] == 0) {
        [[[[UIAlertView alloc]
           initWithTitle:@"Error" message:@"Password field is required."
           delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
          autorelease]
         show];
        return;
    }

    TRACE(@"Register account:\n%@\n%@\n%@\n%@\n%@\n%@", emailField.text,
                                            firstField.text,
                                            lastField.text,
                                            intitationField.text,
                                            nameField.text,
                                            passwordField.text);

    [appDelegate registerAccount:emailField.text
                       firstName:firstField.text
                        lastName:lastField.text
                      invitation:intitationField.text
                        computername:nameField.text
                        password:passwordField.text];
}

- (void) registerAccountOnMainThread {
    [appDelegate terminateActivityView];
    TimerViewController *controller = [[TimerViewController alloc] initWithNibName:@"TimerViewController" bundle:nil];

    [self.navigationController pushViewController:controller animated:YES];
    [controller release];
//    [self.navigationController push presentModalViewController:controller animated:YES];
//    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void) webErrorOnMainThread:(NSError*)error {
    [appDelegate terminateActivityView];
    [self.navigationController popViewControllerAnimated:YES];
}


- (void) registerAccount:(NSNotification *)notification {
	[self performSelectorOnMainThread:@selector(registerAccountOnMainThread) withObject: nil waitUntilDone: NO];
}

- (void) webError:(NSNotification *)notification {
	[self performSelectorOnMainThread:@selector(webErrorOnMainThread:) withObject:notification.object waitUntilDone: NO];
}


- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {

    for (int row = 0; row < 5; row++) {
        UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
        UITextField* textField = (UITextField*)[cell viewWithTag:1];
        if (textField == theTextField) {
            cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row+1 inSection:0]];
            UITextField* nextField = (UITextField*)[cell viewWithTag:1];
            [nextField becomeFirstResponder];
            return NO;
        }
    }

    [theTextField resignFirstResponder];
    return YES;
}


@end
