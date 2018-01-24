//============================================================
// Copyright © 2012 Applicable Software
// All rights reserved.
//
// File: ncrpt_rand.cpp
// Created By: Igor Odnovorov
//
// Description: Implements random number generator interface
//
//===========================================================
#include "stdafx.h"
#include "ncrpt_rand.h"
#include "ncrpt_session.h"
#include "stdio.h"

static HCRYPTPROV g_DefaultProvider = NULL;

static HCRYPTPROV _CreateCryptProvider()
{
    static LPCTSTR szKeyContainerName  = L"{NCRYPT-2FE8A8ED-0D1E-445B-8DAE-E4961B8ADFC7}";
    static LPCTSTR szProviderName      = MS_ENHANCED_PROV;
    static DWORD   dwProviderType      = PROV_RSA_FULL;

    HCRYPTPROV  hCryptoProvider = NULL;

    if ( !CryptAcquireContext( &hCryptoProvider, szKeyContainerName, szProviderName, dwProviderType, 0) )
    {
    	if ( !CryptAcquireContext(&hCryptoProvider, 
                                  szKeyContainerName, 
                                  szProviderName, 
                                  dwProviderType, 
                                  CRYPT_NEWKEYSET ) )
        {
            NCRYPT_PRINTV( "Could not create crypto context: %d", VA_LIST1(::GetLastError()) );
            return NULL;
        }
    }

    return hCryptoProvider;
}

static void _DeleteCryptProvider( HCRYPTPROV  hCryptoProvider )
{
    CryptReleaseContext( hCryptoProvider, 0 );
}

static int _IsValidContext( PNCRYPT_RAND_CTX pCtx )
{
    if (NCRTP_TABLE_GET_MAJOR_VERSION(pCtx->hdr.version) != NCRTP_TABLE_MAJOR_VERSION)
    {
        return 0;
    }
    if (NCRTP_TABLE_GET_MINOR_VERSION(pCtx->hdr.version) != NCRTP_TABLE_MINOR_VERSION)
    {
        return 0;
    }

    return 1;
}

static NCRYPT_STATUS _PtrFromHandle( NCRYPT_HANDLE_RAND_CTX hCtx, PNCRYPT_RAND_CTX* pCtx )
{
    NCRYPT_STATUS  status = NcryptSession_PtrFromHandle( (NCRPT_HANDLE)hCtx, NCRYPT_OBJECT_TYPE_CTX_RAND, (PVOID*)pCtx );
    if ( NCRYPT_SUCCESS != status )
    {
        return status;
    }

    if ( !_IsValidContext(*pCtx) )
    {
        return NCRYPT_ERR_INVALID_ARG;
    }

    return NCRYPT_SUCCESS;
}


NCRYPT_STATUS Ncrypt_Rand_CreateCtx( OUT NCRYPT_HANDLE_RAND_CTX* phCtx)
{
    NCRYPT_STATUS       status  = NCRYPT_SUCCESS;
    PNCRYPT_RAND_CTX    pCtx    = NULL;

    if ( NULL == phCtx )
    {
        return NCRYPT_ERR_INVALID_ARG;
    }

    pCtx = (PNCRYPT_RAND_CTX)NCRYPT_ALLOC_MEMORY( sizeof(NCRYPT_RAND_CTX) );
    if (NULL == pCtx)
    {
        return NCRYPT_ERR_OUT_OF_MEMORY;
    }

    NCRYPT_ZERO_MEMORY( pCtx, sizeof(NCRYPT_RAND_CTX) );
    pCtx->hdr.magic = NCRYPT_OBJECT_MAGIC;
    pCtx->hdr.type  = NCRYPT_OBJECT_TYPE_CTX_RAND;
    NCRTP_TABLE_SET_VERSION( pCtx->hdr.version, NCRTP_TABLE_MAJOR_VERSION, NCRTP_TABLE_MINOR_VERSION );

    pCtx->hCryptoProvider = _CreateCryptProvider();
    if ( NULL == pCtx->hCryptoProvider )
    {
        status = NCRYPT_ERR_FAILED;
    }

    if ( NCRYPT_SUCCESS == status )
    {
        status = NcryptSession_HandleFromPtr( pCtx, (NCRPT_HANDLE*)phCtx );
    }

    if ( NCRYPT_SUCCESS != status )
    {
        NCRYPT_FREE_MEMORY(pCtx);
    }

    return status;
}

NCRYPT_STATUS Ncrypt_Rand_DeleteCtx( IN NCRYPT_HANDLE_RAND_CTX hCtx )
{
    NCRYPT_STATUS       status  = NCRYPT_SUCCESS;
    PNCRYPT_RAND_CTX    pCtx    = NULL;

    status = _PtrFromHandle( hCtx, &pCtx );
    if ( NCRYPT_SUCCESS != status )
    {
        return status;
    }

    if ( pCtx->hCryptoProvider )
    {
        _DeleteCryptProvider( pCtx->hCryptoProvider );
    }

    NCRYPT_ZERO_MEMORY( pCtx, sizeof(NCRYPT_RAND_CTX) );
    NCRYPT_FREE_MEMORY( pCtx );

    return NCRYPT_SUCCESS;
}

NCRYPT_STATUS Ncrypt_Rand_GenRandom( IN NCRYPT_HANDLE_RAND_CTX hCtx, IN OUT UCHAR* pb, IN ULONG cb )
{
    NCRYPT_STATUS       status  = NCRYPT_SUCCESS;
    PNCRYPT_RAND_CTX    pCtx    = NULL;

    status = _PtrFromHandle( hCtx, &pCtx );
    if ( NCRYPT_SUCCESS != status )
    {
        return status;
    }

    if ( NULL == pb )
    {
        return NCRYPT_ERR_INVALID_ARG;
    }

    if ( !CryptGenRandom(pCtx->hCryptoProvider, cb, pb) )
    {
        NCRYPT_PRINTV( "Failed to generate random number: %d", VA_LIST1(::GetLastError()) );
        status = NCRYPT_ERR_FAILED;
    }

    return status;
}

NCRYPT_STATUS Ncrypt_Rand_Initialize()
{
    NCRYPT_STATUS status = NCRYPT_SUCCESS;

    if ( NULL == g_DefaultProvider )
    {
        g_DefaultProvider = _CreateCryptProvider();
        if ( NULL == g_DefaultProvider )
        {
            status = NCRYPT_ERR_FAILED;
        }
    }

    return status;
}

NCRYPT_STATUS Ncrypt_Rand_Uninitialize()
{
    NCRYPT_STATUS status = NCRYPT_SUCCESS;

    if ( NULL != g_DefaultProvider )
    {
        _DeleteCryptProvider( g_DefaultProvider );
        g_DefaultProvider = NULL;
    }

    return status;
}

NCRYPT_STATUS Ncrypt_GenRandom( IN OUT UCHAR* pb, IN ULONG cb )
{
    NCRYPT_STATUS status = NCRYPT_SUCCESS;

    if ( !CryptGenRandom(g_DefaultProvider, cb, pb) )
    {
        NCRYPT_PRINTV( "Failed to generate random number: %d", VA_LIST1(::GetLastError()) );
        status = NCRYPT_ERR_FAILED;
    }

    return status;
}
