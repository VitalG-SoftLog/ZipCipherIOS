//
//  SettingsViewController.m
//  nCryptedBox
//
//  Created by Oleg Lavronov on 8/12/12.
//  Copyright (c) 2012 nCrypted Cloud. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()
{
    NSArray* _items;
}
@end

@implementation SettingsViewController

@synthesize appDelegate = _appDelegate;

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _items   = [[NSArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    passwordCount = 0;
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [self reloadData];
    
    UIBarButtonItem *btnCancel = [[[UIBarButtonItem alloc] initWithTitle:@"Clear"
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:self
                                                                  action:@selector(clearClicked:)]autorelease];
    self.navigationItem.rightBarButtonItem = btnCancel;
}

- (void) reloadData {

    [_items release];

    _items = [[NSArray alloc] initWithArray:[self.appDelegate.nCryptBox.keys allKeys]];

    if (self.navigationItem.rightBarButtonItem)
    {
        [self.navigationItem.rightBarButtonItem setEnabled:[_items count] > 1];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void) viewWillAppear:(BOOL)animated
{
    [self reloadData];
    [self.tableView reloadData];
    [super viewWillAppear:animated];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return @" ";
            break;
        default:
            break;
    }
    return @"Select active key";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 1;
            break;
        default:
            break;
    }
    return [_items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellSwitch = @"cellSwitch";
    static NSString *cellIdentifier = @"cellIdentifier";

    UITableViewCell *cell = nil;
    if ([indexPath section] == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:cellSwitch];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    }


    if (cell == nil) {
        if ([indexPath section] == 0) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellSwitch] autorelease];
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
                //cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            
            cell.textLabel.text = @"Secure my keys";
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            UISwitch *switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
            [switchview setTag:1];
            [switchview addTarget:self action:@selector(passwordChanged:) forControlEvents:UIControlEventValueChanged];
            [switchview setOn:([self.appDelegate.keyPassword length] != 0) animated:YES];
            cell.accessoryView = switchview;
            [switchview release];
        } else {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
                //cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
        }

    }

    if (indexPath.section == 0) {
        UISwitch* switchview = (UISwitch*)[cell viewWithTag:1];
        [switchview setOn:([self.appDelegate.keyPassword length] != 0) animated:YES];
    } else {
        NCryptKey* key = [self.appDelegate.nCryptBox.keys objectForKey:[_items objectAtIndex:indexPath.row]];
        if (key) {
            cell.textLabel.textColor = [UIColor darkTextColor];
            if ([key.ID isEqualToString:self.appDelegate.keyDefault])
            {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                cell.textLabel.textColor = [UIColor greenColor];
            } else if ([key.ID isEqualToString:self.appDelegate.keyBackup]) {
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.textLabel.textColor = [UIColor blueColor];
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }

            [cell.textLabel setText:[NSString stringWithString:key.name]];
            cell.detailTextLabel.text = [NSString stringWithString:key.ID];
        }
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
    NSString* k = [_items objectAtIndex:indexPath.row];
    [self.appDelegate setKeyDefault:[NSString stringWithString:k]];
    TRACE(@"Set default key: %@",self.appDelegate.keyDefault);

    [tableView reloadData];
}

#pragma mark -
#pragma mark Actions
- (IBAction)buttonImport:(id)sender
{

}

- (IBAction)clearClicked:(id)sender
{
    UIAlertView* alert = [[UIAlertView alloc]
                          initWithTitle:@"Clear all keys" message:@"Are you sure ?"
                          delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    alert.tag = kAlertClearAllKeysTag;
    [alert show];
    [alert release];

    [self.tableView reloadData];
    TRACE(@"Clear keys");
}

- (IBAction)passwordChanged:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]]) {
        UISwitch* switchPassword = (UISwitch*)sender;
        if (switchPassword.on) {
            [self showModalPasswordView];
        } else {
            [self showAlertPassword];
        }
    }
}

#pragma mark -
#pragma mark Show

- (void)showModalPasswordView
{
    PasswordViewController* modalController = nil;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        modalController = [[PasswordViewController alloc] initWithNibName:@"PasswordViewController" bundle:nil];
    } else {
        modalController = [[PasswordViewController alloc] initWithNibName:@"PasswordViewController" bundle:nil];
        [modalController setModalPresentationStyle:UIModalPresentationFormSheet];
    }
    modalController.delegate = self;

    [self presentModalViewController:modalController  animated:YES  ];
}

- (void)showAlertPassword
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Enter my keys password:"
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"OK",nil];
    alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
    alert.tag = kAlertPasswordEnterTag;

    [alert show];
    [alert release];
    passwordCount++;
}

#pragma mark -
#pragma mark AlertView delegates

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case kAlertPasswordEnterTag:
            TRACE(@"Enter password");
            if (buttonIndex == 1) {
                if (passwordCount >= 3) {
                    [[[[UIAlertView alloc] initWithTitle:@"Please wait a minute."
                                                 message:nil
                                                delegate:nil
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil] autorelease] show];

                    UISwitch* switchview = (UISwitch*)[[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] viewWithTag:1];
                    [switchview setOn:YES animated:YES];
                    [switchview setEnabled:NO];

                   [NSTimer scheduledTimerWithTimeInterval:60
                                                    target:self
                                                  selector:@selector(timerEnableSwitchPassword:)
                                                   userInfo:nil
                                                    repeats:NO];

                } else {
                    UITextField* textFiled = [alertView textFieldAtIndex:0];
                    if ([textFiled.text compare:[self.appDelegate keyPassword]] == NSOrderedSame) {
                        UISwitch* switchview = (UISwitch*)[[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] viewWithTag:1];
                        if ([switchview isOn]) {
                            [self showModalPasswordView];
                        } else {
                            self.appDelegate.keyPassword = @"";
                            [self.appDelegate saveKeys];
                        }
                    } else {
                        [self showAlertPassword];
                    }
                }
            } else {
                UISwitch* switchview = (UISwitch*)[[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] viewWithTag:1];
                
                [switchview setOn:([self.appDelegate.keyPassword length] != 0) animated:YES];
                passwordCount = 0;
            }
            break;
        case kAlertClearAllKeysTag:
            if (buttonIndex == 1) {
                [self.appDelegate clearKeys];
                [self reloadData];
                [self.tableView reloadData];
                TRACE(@"Delete all keys");
            }
            break;
        default:
            break;
    }
}

- (IBAction)timerEnableSwitchPassword:(id)sender
{
    UISwitch* switchview = (UISwitch*)[[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] viewWithTag:1];
    [switchview setEnabled:YES];
    passwordCount = 0;
}



#pragma mark -
#pragma mark TextField delegate

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    return YES;
}


- (void)textFieldDidEndEditing:(UITextField *)textField
{
    //UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    //UITextField* passwodField = (UITextField*)[cell viewWithTag:1];
    //[self.appDelegate setKeyPassword:[passwodField text]];

}

#pragma mark -
#pragma mark Modal delegate

-(void)modalViewControllerDidFinish:(UIViewController *)viewController
{
    [self.tableView reloadData];
}



@end
