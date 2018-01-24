//============================================================
//
// Copyright (c) nCrypted Cloud, 2012. All Rights Reserved.
//
// File: LoginViewController.m
// Created By: Oleg Lavronov on 9/12/12.
//
// Description: Login window
//
//============================================================
#import "WebServiceProvider.h"
#import "LoginViewController.h"

@interface LoginViewController ()
{
}
@end

@implementation LoginViewController

@synthesize appDelegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(associateMachine:) name:kAssociateMachine object: nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(webError:) name:kWebError object: nil];

        self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        self.title = @"Assotiate";//NSLocalizedString(@"Preview", @"Preview");
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
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 0) {
#ifdef DEBUG
        return 5;
#else
        return 3;
#endif
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
                textField.placeholder = @"Required";
                textField.keyboardType = UIKeyboardTypeDefault;
                textField.returnKeyType = UIReturnKeyNext;
                textField.secureTextEntry = YES;
                break;
            case 2:
                textField.placeholder = @"Required";
                textField.keyboardType = UIKeyboardTypeDefault;
                textField.returnKeyType = UIReturnKeyNext;
                textField.text = [AppDelegate computerName];
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
                cell.textLabel.text = @"Password:";
                break;
            case 2:
                cell.textLabel.text = @"Computer Name:";
                break;
#ifdef DEBUG
            case 3:
                cell.textLabel.text = @"staging.ncryptedbox.com";
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                break;
            case 4:
                cell.textLabel.text = @"www.ncryptedbox.com";
                break;
#endif
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

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 54.0;
}


-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 54.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {

    if(buttonView == nil) {
        //allocate the view if it doesn't exist yet
        buttonView  = [[UIView alloc] init];

        UIButton* button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        //[button setBackgroundImage:image forState:UIControlStateNormal];

        [button setFrame:CGRectMake(20, 10, 280, 44)];
        button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;

        [buttonView setBackgroundColor:[UIColor clearColor]];

        //set title, font size and font color
        [button setTitle:@"Login" forState:UIControlStateNormal];
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
    UITextField* passwordField = (UITextField*)[cell viewWithTag:1];
    if ([passwordField.text length] == 0) {
        [[[[UIAlertView alloc]
           initWithTitle:@"Error" message:@"Password field is required."
           delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
          autorelease]
         show];
        return;
    }

    cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    UITextField* computerNameField = (UITextField*)[cell viewWithTag:1];
    if ([computerNameField.text length] == 0) {
        [[[[UIAlertView alloc]
           initWithTitle:@"Error" message:@"Computer Name field is required."
           delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
          autorelease]
         show];
        return;
    }

    TRACE(@"Associate machine: email: %@ password: %@", emailField.text, passwordField.text);
    [appDelegate associateMachine:emailField.text
                        password:passwordField.text
                     computerName:computerNameField.text];
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {

    for (int row = 0; row < 1; row++) {
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

- (void)webError:(id)error
{

}

- (void) associateMachineOnMainThread {
    [appDelegate terminateActivityView];
    [self dismissModalViewControllerAnimated:YES];
}

- (void)associateMachine:(id)object
{
    [self performSelectorOnMainThread:@selector(associateMachineOnMainThread) withObject: nil waitUntilDone: NO];
}


@end
