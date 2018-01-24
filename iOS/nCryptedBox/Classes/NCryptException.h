//============================================================
//
// Copyright (c) nCrypted Cloud, 2012. All Rights Reserved.
//
// File: NCryptException.h
// Created By: Oleg Lavronov on 9/8/12.
//
// Description: NCryptBox exceptions.
//
//===========================================================
#import <Foundation/Foundation.h>

@interface NCryptException : NSException {

@private
    NSInteger _error;
}

- (id) initWithReason:(NSString *)reason;
- (id) initWithError:(NSInteger)error reason:(NSString *)reason;

@property (nonatomic, readonly) NSInteger error;

@end
