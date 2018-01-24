//============================================================
//
// Copyright (c) nCrypted Cloud, 2012. All Rights Reserved.
//
// File: NCryptException.m
// Created By: Oleg Lavronov on 9/8/12.
//
// Description: NCryptBox exceptions.
//
//===========================================================
#import "NCryptException.h"

@implementation NCryptException

@synthesize error= _error;

- (id) initWithReason:(NSString *)reason {
	if (self= [super initWithName:@"NCryptException" reason:reason userInfo:nil]) {
		_error= 0;
	}

	return self;
}

- (id) initWithError:(NSInteger)error reason:(NSString *)reason {
	if (self= [super initWithName:@"NCryptException" reason:reason userInfo:nil]) {
		_error= error;
	}

	return self;
}



@end
