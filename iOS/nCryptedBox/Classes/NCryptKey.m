//============================================================
//
// Copyright (c) nCrypted Cloud, 2012. All Rights Reserved.
//
// File: NCryptKey.m
// Created By: Oleg Lavronov on 9/6/12.
//
// Description: Namespace for nCrypted Cloud functions.
//
//===========================================================
#import "NCryptKey.h"

@implementation NCryptKey

@synthesize ID          = _ID;
@synthesize name        = _name;
@synthesize type        = _type;
@synthesize value       = _value;
@synthesize exportable  = _exportable;
@synthesize ownerid     = _ownerid;
@synthesize ownerbackupkey = _ownerbackupkey;

- (void) dealloc
{
    [_ID release];
    [_name release];
    [_type release];
    [_ownerid release];
    [_ownerbackupkey release];
    [super dealloc];
}

- (id)initWithIdentifier:(NSString *)identifier
{
    if (self = [super init])
    {
        _ID = [[NSString alloc] initWithString:identifier];
        _name = @"Key name";
        _type = @"";
        _ownerid = @"user";
        _ownerbackupkey = @"";
        _value = @"";
    }
    return self;
}

- (id)initWithIdentifier:(NSString *)identifier withName:(NSString *)name
{
    if (self = [super init])
    {
        _ID = [[NSString alloc] initWithString:identifier];
        _name = [[NSString alloc] initWithString:name];
        _type = @"";
        _ownerid = @"user";
        _ownerbackupkey = @"";
        _value = @"";
    }
    return self;
}



@end
