//============================================================
//
// Copyright (c) nCrypted Cloud, 2012. All Rights Reserved.
//
// File: NCryptBox.h
// Created By: Oleg Lavronov on 9/5/12.
//
// Description: Namespace for nCrypted Cloud functions.
//
//===========================================================
#import <Foundation/Foundation.h>

#ifdef DEBUG
#define kWebServiceDNS @"https://www.ncryptedbox.com/index.php?option=com_ncryptedbox&format=raw"
//#define kWebServiceDNS @"https://staging.ncryptedbox.com/app/index.php?option=com_ncryptedbox&format=raw"
#else
#define kWebServiceDNS @"https://staging.ncryptedbox.com/app/index.php?option=com_ncryptedbox&format=raw"
#endif

#define kWebKEY                @"KeyID"

#define kWebGENERAL_ERROR               -1
#define kWebNONE                        0
#define kWebEMAIL_EXISTS                1
#define kWebUSENAME_EXISTS              2
#define kWebAUTOREGISTER_DISABLED       3
#define kWebCANNOT_ASSOCIATE_MACHINE_WITH_ACCOUNT 4
#define kWebSAVING_USER_FAILED          5
#define kWebEMAIL_NOTFOUND              6
#define kWebINVALID_MACHINE_NAME        7
#define kWebCOMPUTERNAME_EXISTS         8
#define kWebCOMPUTERNAME_NOTFOUND       9
#define kWebACCOUNT_NOTFOUND            10
#define kWebINVALID_AUTH_TOKEN          11
#define kWebCANNOT_INSERT_KEY_RECORD    12
#define kWebKEY_NOTFOUND                13
#define kWebINVALID_INVITATION          14
#define kWebINVITATION_REQUIRED         15
#define kWebINVALID_TASK                16
#define kWebINVALID_MESSAGE_VERSION     17
#define kWebINVALID_MESSAGE_TYPE        18
#define kWebCANNOT_CREATE_GROUP         19
#define kWebCANNOT_CREATE_ASSOCIATION   20

// Error descruptions
#define kWebError               @"WebError"
#define kWebErrorKeyNotFound    @"WebErrorKeyNotFound"
#define kRegisterAccount        @"RegisterAccount"
#define kAssociateMachine       @"AssociateMachine"
#define kUnlinkMachine          @"UnlinkMachine"
#define kValidateToken          @"ValidateToken"
#define kRetrieveKeys           @"RetrieveKeys"
#define kStoreKeys              @"StoreKeys"
#define kGetKey                 @"GetKey"

@interface WebServiceProvider : NSObject <NSURLConnectionDelegate,
NSURLConnectionDataDelegate>
{

}

@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, copy) NSString* userName;
@property (nonatomic, copy) NSString* userEmail;
@property (nonatomic, copy) NSString* userPassword;
@property (nonatomic, copy) NSString* authToken;
@property (nonatomic, copy) NSString* computerName;


#pragma mark -
#pragma mark Internet Connection
// checks whether an Internet connection is available
- (BOOL) isConnectionAvailable;

#pragma mark -
#pragma mark Login
- (void) sendRegisterAccount:(NSString *)userEmail firstName:(NSString *)firstName
                    lastName:(NSString *)lastName invitation:(NSString *)invitation
                computername:(NSString *)computername password:(NSString *)password;

- (void) sendAssociateMachine:(NSString *)userEmail
                  andPassword:(NSString *)password
              andComputerName:(NSString *)computerName;

- (void) sendUnlinkMachine;

- (void) sendRetrieveKeys;

- (void) sendStoreKeys:(NSDictionary*)keys withKeyID:(NSString*)keyID;

- (void) sendGetKey:(NSString*)keyID;

- (NSDictionary*) sendSynchronousGetKey:(NSString*)keyID;

- (void) dialogServerError:(NSString*) error;


@end
