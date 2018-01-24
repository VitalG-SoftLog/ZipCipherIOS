//============================================================
//
// Copyright (c) nCrypted Cloud, 2012. All Rights Reserved.
//
// File: Log.h
// Created By: Oleg Lavronov on 8/3/12.
//
// Description: Implementation application log system.
//
//===========================================================
#import <Foundation/Foundation.h>

#define TRACE(args...) _Log(@"DEBUG ", __FILE__,__LINE__,__PRETTY_FUNCTION__,args); NSLog(args);

@interface Log : NSObject

void _Log(NSString *prefix, const char *file, int lineNumber, const char *funcName, NSString *format,...);

void append(NSString *msg);


@end