//
//  PasswordViewController.m
//  nCryptedBox
//
//  Created by Oleg Lavronov on 8/31/12.
//  Copyright (c) 2012 nCrypted Cloud. All rights reserved.
//

#import "PasswordViewController.h"

@interface PasswordViewController ()

@end

@implementation PasswordViewController

@synthesize delegate;
@synthesize tableView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setAutoresizesSubviews:YES];
    [tableView setAutoresizesSubviews:YES]; 

    //tableView.delegate = self;

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;//(interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source
/*
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Enter";
}
*/

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 2;
            break;

        default:
            break;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        if (indexPath.section == 1) {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            UISwitch *switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
            [switchview setTag:1];
            [switchview addTarget:self action:@selector(showPasswordChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = switchview;
            [switchview release];
        } else {
            UITextField *passwordTextField = nil;
            if (IPHONE) {
                passwordTextField = [[UITextField alloc] initWithFrame:CGRectMake(160, 10, cell.contentView.frame.size.width-180, cell.contentView.frame.size.height-20)];
            } else {
                passwordTextField = [[UITextField alloc] initWithFrame:CGRectMake(180, 10, cell.contentView.frame.size.width, cell.contentView.frame.size.height-20)];
            }
            [cell setAutoresizesSubviews:YES];
            passwordTextField.adjustsFontSizeToFitWidth = YES;
            passwordTextField.textColor = [UIColor blackColor];
            passwordTextField.placeholder = @"Required";
            passwordTextField.keyboardType = UIKeyboardTypeDefault;
            passwordTextField.returnKeyType = UIReturnKeyDone;
            passwordTextField.secureTextEntry = YES;
            passwordTextField.backgroundColor = [UIColor clearColor];
            passwordTextField.autocorrectionType = UITextAutocorrectionTypeNo; // no auto correction support
            passwordTextField.autocapitalizationType = UITextAutocapitalizationTypeNone; // no auto capitalization support
            passwordTextField.textAlignment = UITextAlignmentLeft;
            passwordTextField.tag = 1;
            passwordTextField.clearButtonMode = UITextFieldViewModeAlways; // no clear 'x' button to the right
            passwordTextField.delegate = self;
            passwordTextField.text = [self.appDelegate keyPassword];
            [passwordTextField setEnabled: YES];
            [cell addSubview:passwordTextField];
            [passwordTextField release];
        }
    }


    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"New password:";
                break;
            case 1:
                cell.textLabel.text = @"Confirm:";
                break;

            default:
                break;
        }
    } else {
        cell.textLabel.text = @"Show Cleartext:";
    }

    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

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

#pragma mark - 
#pragma mark - Actions

- (IBAction)doneClicked:(id)sender
{
    UITextField* passwordField = (UITextField*)[[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] viewWithTag:1];
    UITextField* confirmField = (UITextField*)[[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] viewWithTag:1];
/*
    if ([passwordField.text length] == 0) {
        [[[[UIAlertView alloc]
		   initWithTitle:@"Error" message:@"Password can't be empty."
		   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
		  autorelease]
		 show];
        return;
    }
*/
    if (![passwordField.text isEqualToString:confirmField.text]) {
        [[[[UIAlertView alloc]
		   initWithTitle:@"Error" message:@"Wrong password."
		   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
		  autorelease]
		 show];
        return;
    }

    [self.appDelegate setKeyPassword:passwordField.text];

    NSLog(@"Set password");
    [delegate modalViewControllerDidFinish:self];
    [self dismissModalViewControllerAnimated:YES];
    
}

- (IBAction)buttonClicked:(id)sender
{
    NSLog(@"Cancel clicked");
    [delegate modalViewControllerDidFinish:self];
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)showPasswordChanged:(id)sender
{
    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    UISwitch* showPassword = (UISwitch*)[cell viewWithTag:1];

    cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UITextField* passwordField = (UITextField*)[cell viewWithTag:1];
    [passwordField resignFirstResponder];
    [passwordField setSecureTextEntry:!showPassword.on];

    cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    passwordField = (UITextField*)[cell viewWithTag:1];
    [passwordField resignFirstResponder];
    [passwordField setSecureTextEntry:!showPassword.on];

}



@end
