//============================================================
// Copyright � 2012 Applicable Software
// All rights reserved.
//
// File: ncrpt_session.cpp
// Created By: Igor Odnovorov
//
// Description: Implements nCrypt library session interface
//
//===========================================================
//#include "stdafx.h"
#include "ncrpt_base.h"
#include "ncryptor.h"
#include "ncrpt_session.h"

static ULONG_PTR   g_HandleSeed = {0};

#ifdef __APPLE__

inline bool IsBadReadPtr(const void *p, unsigned int cb)

{
    return false;
}

void RtlSecureZeroMemory(void *ptr, unsigned int cb)
{
    if (ptr) {
        memset(ptr,0,cb);
    }
}


#endif

static bool _NcryptSession_IsInitialized()
{
    return 0 != g_HandleSeed;
}

NCRYPT_STATUS   NcryptSession_Initialize()
{
    NCRYPT_STATUS status = NCRYPT_SUCCESS;
    if ( !_NcryptSession_IsInitialized() )
    {
        status = Ncrypt_GenRandom( (UCHAR*)&g_HandleSeed, (unsigned long)sizeof(g_HandleSeed) );
    }

    return status;
}

void NcryptSession_Uninitialize()
{
    g_HandleSeed = NULL;
}

NCRYPT_STATUS NcryptSession_PtrFromHandle( IN NCRPT_HANDLE h, IN NCRYPT_OBJECT_TYPE opjectType, PVOID* pptr )
{
    NCRYPT_STATUS status = NCRYPT_SUCCESS;
    NCRYPT_OBJECT_HEADER* p = NULL;

    if (NULL == pptr || NCRYPT_INVALID_HANDLE == h)
    {
        return NCRYPT_ERR_INVALID_ARG;
    }

    if ( !_NcryptSession_IsInitialized() )
    {
        return NCRYPT_ERR_UNINITIALIZED;
    }

    p = (NCRYPT_OBJECT_HEADER*)(g_HandleSeed ^ (ULONG_PTR)h);
    if (NULL == p)
    {
        return NCRYPT_ERR_BAD_HANDLE;
    }

    //--validate ptr here
    if( !NCRYPT_IS_ADDRESS_VALID(p, sizeof(NCRYPT_OBJECT_HEADER)))
    {
        return NCRYPT_ERR_BAD_HANDLE;
    }

    if ( NCRYPT_OBJECT_MAGIC != p->magic || 
         opjectType != p->type )
    {
        return NCRYPT_ERR_BAD_HANDLE;
    }

    *pptr = p;

    return status;
}

NCRYPT_STATUS NcryptSession_HandleFromPtr( PVOID p, OUT NCRPT_HANDLE* ph )
{
    NCRPT_HANDLE   h  = NCRYPT_INVALID_HANDLE;

    if ( NULL == ph )
    {
        return NCRYPT_ERR_INVALID_ARG;
    }

    if ( !_NcryptSession_IsInitialized() )
    {
        return NCRYPT_ERR_UNINITIALIZED;
    }

    h = (NCRPT_HANDLE)(g_HandleSeed ^ (ULONG_PTR)p);

    if ( NCRYPT_INVALID_HANDLE == h )
    {
        return NCRYPT_ERR_ERR_UNEXPECTED;
    }

    *ph = h;
    return NCRYPT_SUCCESS;
}

#ifdef __APPLE__
#import <Security/Security.h>

NCRYPT_STATUS Ncrypt_GenRandom( IN OUT UCHAR* pb, IN ULONG cb )
{
    SecRandomCopyBytes(kSecRandomDefault, cb, pb);
    return NCRYPT_SUCCESS;
}

#endif