//
//  Cipher.h
//  nCryptedBox
//
//  Created by Oleg Lavronov on 7/29/12.
//  Copyright (c) 2012 Lundlay. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef RSA_PUBLIC
#define RSA_PUBLIC      0
#endif

#ifndef RSA_PRIVATE
#define RSA_PRIVATE     1
#endif

#define kPrivateRSAKey  @"private-key-xml"
#define kPublicRSAKey   @"public-key-xml"

//! Default public key exponent for RSA key pair generation
#define NCRYPT_DEFAULT_RSA_PUBLIC_EXPONENT    0x10001


typedef enum {
	RsaModePublic = RSA_PUBLIC,
    RsaModePrivate = RSA_PRIVATE
} RsaMode;



@interface Cipher : NSObject

+ (NSData *)base64DataFromString: (NSString *)string;
+ (NSString *)base64StringFromData: (NSData *)data length: (int)length;
+ (NSString *)base64StringFromData:(NSData *)data;

+ (NSData *)getHashValue:(NSData*)secret;
+ (NSData *)hashPasswordWithSalt:(NSData*)secret entropy:(NSData*)entropy;
+ (NSString *)generatePassword:(NSString*)secret withEntropy:(NSString*)entropy count:(NSUInteger)count;
+ (NSData *)generatePassword:(NSData*)secret withEntropy:(NSData*)entropy;

+ (NSDictionary *)generateNewRSAKey:(int)nBits includePrivateKey:(BOOL)includePrivateKey;
+ (NSString *)encryptByRSAKey:(NSString*)xmlRSAKey withData:(NSData*)data;
+ (NSString *)decryptByRSAKey:(NSString*)xmlRSAKey withData:(NSData*)data;



@end
