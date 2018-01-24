//============================================================
//
// Copyright (c) nCrypted Cloud, 2012. All Rights Reserved.
//
// File: NCryptKey.h
// Created By: Oleg Lavronov on 9/6/12.
//
// Description: Namespace for nCrypted Cloud functions.
//
//===========================================================
#import <Foundation/Foundation.h>

@interface NCryptKey : NSObject

@property (nonatomic, copy) NSString*     ID;
@property (nonatomic, copy) NSString*     name;
@property (nonatomic, copy) NSString*     type;
@property (nonatomic, copy) NSString*     value;
@property (nonatomic, assign) BOOL        exportable;
@property (nonatomic, copy) NSString*     ownerid;
@property (nonatomic, copy) NSString*     ownerbackupkey;

- (id)initWithIdentifier:(NSString *)identifier;
- (id)initWithIdentifier:(NSString *)identifier withName:(NSString *)name;


@end
