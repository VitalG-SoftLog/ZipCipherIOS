//============================================================
//
// Copyright (c) nCrypted Cloud, 2012. All Rights Reserved.
//
// File: NCryptBox.h
// Created By: Oleg Lavronov on 8/11/12.
//
// Description: Namespace for nCrypted Cloud functions.
//
//===========================================================
#import <Foundation/Foundation.h>
#import "../../Objective-Zip/ZipFile.h"
#import "../../Objective-Zip/ZipException.h"
#import "../../Objective-Zip/FileInZipInfo.h"
#import "../../Objective-Zip/ZipWriteStream.h"
#import "../../Objective-Zip/ZipReadStream.h"
#import "../../Objective-PolarSSL/Cipher.h"

@protocol NCryptBoxDelegate

@optional

-(void)loadSynchronousKey:(NSString*)keyID;
-(void)loadKey:(NSString*)keyID;
-(void)didRecieveSharedKeys:(NSString*)keyID backupKey:(NSString*)backupKeyID;

@end



@interface NCryptBox : NSObject
{
    id <NCryptBoxDelegate> delegate;
}

@property (nonatomic, strong) NSMutableDictionary* keys;
@property (nonatomic, copy) NSString* versionApplication;
@property (nonatomic, copy) NSString* defaultKey;
@property (nonatomic, copy) NSString* defaultKeyValue;
@property (nonatomic, copy) NSString* backupKey;
//@property (nonatomic, copy) NSString* backupKeyValue;
@property (nonatomic, copy) NSString* storageKeyID;
@property (nonatomic, copy) NSString* storageKeyValue;
@property (nonatomic,assign) id delegate;


- (BOOL)loadKeys:(NSString*)fileName withPassword:(NSString*)password;
- (BOOL)loadStorageKey:(NSString*)xml;
- (NSString*)loadEncryptionKey:(NSString*)xml;
- (NSString*)createEncryptionKey:(NSString*)xml;


- (BOOL)saveKeys:(NSString*)fileName withPassword:(NSString*)password;


// old
- (NSUInteger)loadKeys;
- (NSUInteger)loadKeysFromString:(NSString*)xmlString;
- (NSUInteger)loadKeysFromFile:(NSString*)filName;
- (NSUInteger)loadKeysFile:(NSString *)fileName  password:(NSString*)password;
- (void)importKeyFromDicitonary:(NSDictionary *)key;

+ (NSString*)generateUUIDString;
+ (NSDictionary*)generateRSAkey;

+ (NSString*)generateEncryptionKeyFile:(NSString*)keyID keyValue:(NSString*)keyValue;

- (NSString*)loadNCryptBoxFile:(NSString*)filePath;

- (NSString*)passwordFromComment:(NSString*)comment;

- (void)encryptFile:(NSString *)fileName intoFile:(NSString *)intoFile key:(NSString *)keyID backupKey:(NSString *)backupKeyID;
- (NSURL*)decryptFile:(NSString *)fileName;


+ (BOOL)checkExtension:(NSString*)filePath;
- (BOOL)isEncryptedFile:(NSString *)fileName;
- (BOOL)isCryptedBoxFile:(NSString *)fileName;
- (NSURL*)decryptFile:(NSString *)fileName;
- (BOOL)isKeysFile:(NSString *)fileName;


+ (NSString*)generatePersonalKeyValue:(NSString*)userName withPassword:(NSString*)userPassword;
+ (NSString*)generatePersonalKeyId:(NSString*)userName;

- (void)generateStorageKey:(NSString*)userName withPassword:(NSString*)password andEntropy:(NSString*)entropy;
- (void)generateRSAkey;

+ (NSString *) macaddress;


@end
