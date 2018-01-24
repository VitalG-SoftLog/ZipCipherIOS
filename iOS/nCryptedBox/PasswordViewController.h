//
//  PasswordViewController.h
//  nCryptedBox
//
//  Created by Oleg Lavronov on 8/31/12.
//  Copyright (c) 2012 nCrypted Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ApplicationViewController.h"

@protocol PasswordViewDelegate <NSObject>

-(void)modalViewControllerDidFinish:(UIViewController *)viewController;

@end

@interface PasswordViewController : ApplicationViewController <UITableViewDelegate,
                                                                UITextFieldDelegate>
{
    id<PasswordViewDelegate> delegate;
}

@property (assign) id<PasswordViewDelegate> delegate;
@property (nonatomic, retain) IBOutlet UITableView *tableView;

@end
