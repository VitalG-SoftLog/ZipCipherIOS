#pragma once
//============================================================
// Copyright © 2012 Applicable Software
// All rights reserved.
//
// File: ncrpt_session.h
// Created By: Igor Odnovorov
//
// Description: defines nCrypt library session interface
//
//===========================================================

NCRYPT_STATUS   NcryptSession_Initialize();
void            NcryptSession_Uninitialize();
NCRYPT_STATUS   NcryptSession_PtrFromHandle( IN NCRPT_HANDLE h, IN NCRYPT_OBJECT_TYPE opjectType, PVOID* pptr );
NCRYPT_STATUS   NcryptSession_HandleFromPtr( PVOID p, OUT NCRPT_HANDLE* ph );
