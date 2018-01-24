#pragma once
//============================================================
// Copyright � 2012 Applicable Software
// All rights reserved.
//
// File: ncrpt_rand.h
// Created By: Igor Odnovorov
//
// Description: Declares random number generator interface
//
//===========================================================

#include "ncrpt_base.h"
#include "ncryptor.h"
//#include <WinCrypt.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct _NCRYPT_RAND_CTX
{
    NCRYPT_OBJECT_HEADER    hdr;
    HCRYPTPROV              hCryptoProvider;

} NCRYPT_RAND_CTX, *PNCRYPT_RAND_CTX;

NCRYPT_STATUS Ncrypt_Rand_CreateCtx( OUT NCRYPT_HANDLE_RAND_CTX* phCtx );
NCRYPT_STATUS Ncrypt_Rand_GenRandom( IN NCRYPT_HANDLE_RAND_CTX hCtx, IN OUT UCHAR* pb, IN ULONG cb );
NCRYPT_STATUS Ncrypt_Rand_DeleteCtx( IN NCRYPT_HANDLE_RAND_CTX hCtx );

NCRYPT_STATUS Ncrypt_Rand_Initialize();
NCRYPT_STATUS Ncrypt_Rand_Uninitialize();

#ifdef __cplusplus
}
#endif
