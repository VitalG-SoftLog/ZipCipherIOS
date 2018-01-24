//============================================================
// Copyright © 2012 Applicable Software
// All rights reserved.
//
// File: ncrpt_rsa.cpp
// Created By: Igor Odnovorov
//
// Description: Implements RSA encryption interface
//
//===========================================================
#include "stdafx.h"
#include "ncrpt_rsa.h"
#include "ncrpt_session.h"

#pragma warning ( disable : 4127 ) // conditional expression is constant

#define RSA_READ_BINARY(mpi_out, key_param_in) \
    {\
        int ret = mpi_read_binary(mpi_out,key_param_in.data, key_param_in.cbLen);\
        if (0 != ret){\
            NCRYPT_PRINTV( "mpi_read_binary failed! Err %d", VA_LIST1(ret) );\
            status = NCRYPT_ERR_FAILED; break;\
        }\
    }

#define RSA_WRITE_BINARY( mpi_in, key_param_out ) \
    {\
        key_param_out.cbLen = mpi_size(mpi_in);\
        int ret = mpi_write_binary( mpi_in, key_param_out.data, key_param_out.cbLen );\
        if (0 != ret){\
            NCRYPT_PRINTV( "mpi_write_binary failed! Err %d", VA_LIST1(ret) );\
            status = NCRYPT_ERR_FAILED; break;\
        }\
    }

static int _IsValidKeyType( NCRYPT_KEY_TYPE_RSA keyType )
{
    switch (keyType)
    {
        case NCRYPT_TYPE_RSA_KEY_PRIVATE:
        case NCRYPT_TYPE_RSA_KEY_PUBLIC:
            return 1;
    }
    return 0;
}

static int _IsValidRsaKey( PNCRYPT_RSA_KEY pKey )
{
    if (NCRTP_TABLE_GET_MAJOR_VERSION(pKey->hdr.version) != NCRTP_TABLE_MAJOR_VERSION)
    {
        return 0;
    }
    if (NCRTP_TABLE_GET_MINOR_VERSION(pKey->hdr.version) != NCRTP_TABLE_MINOR_VERSION)
    {
        return 0;
    }

    if ( !_IsValidKeyType(pKey->keyType) )
    {
        return 0;
    }

    return 1;
}

static NCRYPT_STATUS _PtrFromHandle( NCRYPT_HANDLE_KEY_RSA hKey, PNCRYPT_RSA_KEY* pKey )
{
    NCRYPT_STATUS  status = NcryptSession_PtrFromHandle( (NCRPT_HANDLE)hKey, NCRYPT_OBJECT_TYPE_KEY_RSA, (PVOID*)pKey );
    if ( NCRYPT_SUCCESS != status )
    {
        return status;
    }

    if ( !_IsValidRsaKey(*pKey) )
    {
        return NCRYPT_ERR_INVALID_ARG;
    }

    return NCRYPT_SUCCESS;
}

static int _rsa_rng(void* /*p*/)
{
    int iOut = 0;

    NCRYPT_STATUS status = Ncrypt_GenRandom( (UCHAR*)&iOut, sizeof(iOut) );

    if ( NCRYPT_SUCCESS != status )
    {
        NCRYPT_PRINTV( "GenRandom() failed! Err %d", VA_LIST1(status) );
    }

    return iOut;
}

static void _DeleteRsaKey( NCRYPT_RSA_KEY* pKey )
{
    rsa_free( &pKey->rsa );

    NCRYPT_ZERO_MEMORY( pKey, sizeof(NCRYPT_RSA_KEY) );
    NCRYPT_FREE_MEMORY( pKey );
}

static NCRYPT_STATUS _CreateRsaKey( NCRYPT_OBJECT_TYPE handleType, NCRYPT_KEY_TYPE_RSA nKeyType, NCRYPT_RSA_KEY** ppCtx)
{
    NCRYPT_STATUS status = NCRYPT_SUCCESS;
    NCRYPT_RSA_KEY* pCtx = NULL;

    if (NULL == ppCtx)
    {
        return NCRYPT_ERR_INVALID_ARG;
    }

    pCtx = (NCRYPT_RSA_KEY*)NCRYPT_ALLOC_MEMORY(sizeof(NCRYPT_RSA_KEY));
    if (NULL == pCtx)
    {
        return NCRYPT_ERR_OUT_OF_MEMORY;
    }

    NCRYPT_ZERO_MEMORY( pCtx, sizeof(NCRYPT_RSA_KEY) );

    //--set up header
    pCtx->hdr.magic = NCRYPT_OBJECT_MAGIC;
    pCtx->hdr.type  = handleType;
    NCRTP_TABLE_SET_VERSION( pCtx->hdr.version, NCRTP_TABLE_MAJOR_VERSION, NCRTP_TABLE_MINOR_VERSION );
    
    pCtx->keyType = nKeyType;


    *ppCtx = pCtx;
    return status;
}

static bool _CalculateDP( NCRYPT_RSA_KEY* pCtx )
{
    int ret = 0;

    rsa_context *ctx = &pCtx->rsa;
    mpi P1, Q1;

    mpi_init( &P1, &Q1, NULL );

    MPI_CHK( mpi_sub_int( &P1, &ctx->P, 1 ) );
    MPI_CHK( mpi_sub_int( &Q1, &ctx->Q, 1 ) );

    MPI_CHK( mpi_mod_mpi( &ctx->DP, &ctx->D, &P1 ) );
    MPI_CHK( mpi_mod_mpi( &ctx->DQ, &ctx->D, &Q1 ) );
    MPI_CHK( mpi_inv_mod( &ctx->QP, &ctx->Q, &ctx->P ) );

cleanup:
    mpi_free( &Q1, &P1, NULL );

    return 0 == ret;
}

NCRYPT_STATUS Ncrypt_Rsa_GenerateKeyPair( IN int nBits, IN int nExponent,
                                          OUT NCRYPT_HANDLE_KEY_RSA* phPublicKeyOut,
                                          OUT NCRYPT_HANDLE_KEY_RSA* phPrivateKeyOut )
{
    NCRYPT_STATUS status = NCRYPT_SUCCESS;
    int ret = 0;
    NCRYPT_RSA_KEY* pCtxPriv = NULL;
    NCRYPT_RSA_KEY* pCtxPubl = NULL;

    if ( NULL == phPrivateKeyOut)
    {
        return NCRYPT_ERR_INVALID_ARG;
    }

    status = _CreateRsaKey( NCRYPT_OBJECT_TYPE_KEY_RSA, NCRYPT_TYPE_RSA_KEY_PRIVATE, &pCtxPriv );
    if (status != NCRYPT_SUCCESS)
    {
        return status;
    }

    do
    {
        rsa_init( &pCtxPriv->rsa, RSA_PKCS_V15, 0, _rsa_rng, NULL );
    
        ret = rsa_gen_key( &pCtxPriv->rsa, nBits, nExponent);
        if (ret != 0)
        {
            NCRYPT_PRINTV( "rsa_gen_key() failed with error %d", VA_LIST1(ret) );
            status = NCRYPT_ERR_FAILED;
            break;
        }

        status = NcryptSession_HandleFromPtr( pCtxPriv, (NCRPT_HANDLE*)phPrivateKeyOut );
        if ( NCRYPT_SUCCESS != status )
        {
            break;
        }

        if ( phPublicKeyOut )
        {
            status = _CreateRsaKey( NCRYPT_OBJECT_TYPE_KEY_RSA, NCRYPT_TYPE_RSA_KEY_PUBLIC, &pCtxPubl );
            if (status != NCRYPT_SUCCESS)
            {
                break;
            }

            rsa_init(&pCtxPubl->rsa, RSA_PKCS_V15, 0, _rsa_rng, NULL );

            // copy public key parts (N, E) into public context
            mpi_copy(&pCtxPubl->rsa.N, &pCtxPriv->rsa.N);
            mpi_copy(&pCtxPubl->rsa.E, &pCtxPriv->rsa.E);

            pCtxPubl->rsa.len = pCtxPriv->rsa.len; // ( mpi_msb( &pCtxPubl->rsa.N ) + 7 ) >> 3;

            status = NcryptSession_HandleFromPtr( pCtxPubl, (NCRPT_HANDLE*)phPublicKeyOut );
        }
    }
    while( false );

    if ( NCRYPT_SUCCESS != status )
    {
        if ( pCtxPriv )
            _DeleteRsaKey( pCtxPriv );

        if ( pCtxPubl )
            _DeleteRsaKey( pCtxPubl );

        if ( phPrivateKeyOut )
            *phPrivateKeyOut = NCRYPT_INVALID_HANDLE;

        if ( phPublicKeyOut )
        {
            *phPublicKeyOut = NCRYPT_INVALID_HANDLE;
        }
    }

    return status;
}

NCRYPT_STATUS Ncrypt_Rsa_DeleteKey( IN NCRYPT_HANDLE_KEY_RSA hKey)
{
    NCRYPT_STATUS   status  = NCRYPT_SUCCESS;
    PNCRYPT_RSA_KEY pKey    = NULL;
    
    status = _PtrFromHandle( hKey, &pKey );
    if ( NCRYPT_SUCCESS == status )
    {
        _DeleteRsaKey( pKey );
    }
    return status;
}

NCRYPT_STATUS Ncrypt_Rsa_CheckKey( NCRYPT_HANDLE_KEY_RSA hKey )
{
    NCRYPT_STATUS   status  = NCRYPT_SUCCESS;
    PNCRYPT_RSA_KEY pKey    = NULL;

    int nRet = 1;
    
    status = _PtrFromHandle( hKey, &pKey );
    if ( NCRYPT_SUCCESS != status)
    {
        return status;
    }

    if ( pKey->keyType == NCRYPT_TYPE_RSA_KEY_PRIVATE )
    {
        nRet = rsa_check_privkey(&pKey->rsa);
    }
    else if ( pKey->keyType == NCRYPT_TYPE_RSA_KEY_PUBLIC )
    {
        nRet = rsa_check_pubkey(&pKey->rsa);
    }
    else
    {
        return NCRYPT_ERR_ERR_UNEXPECTED;
    }

    if ( 0 != nRet )
    {
        status = NCRYPT_ERR_INVALID_KEY;
    }

    return status;
}

NCRYPT_STATUS Ncrypt_Rsa_GetKeyType( NCRYPT_HANDLE_KEY_RSA hKey,
                                     OUT NCRYPT_KEY_TYPE_RSA* pKeyType )
{
    NCRYPT_STATUS   status  = NCRYPT_SUCCESS;
    PNCRYPT_RSA_KEY pKey    = NULL;

    if ( NULL == pKeyType )
    {
        return NCRYPT_ERR_INVALID_ARG;
    }
    
    status = _PtrFromHandle( hKey, &pKey );
    if ( NCRYPT_SUCCESS != status)
    {
        return status;
    }

    *pKeyType = pKey->keyType;

    return NCRYPT_SUCCESS;
}

NCRYPT_STATUS Ncrypt_Rsa_ExportPlainKey( IN NCRYPT_HANDLE_KEY_RSA hRsaKey, IN NCRYPT_KEY_TYPE_RSA rsaTypeToExport,
                                         OUT NCRYPT_RSA_PARAM* pKeyData )
{
    NCRYPT_STATUS   status  = NCRYPT_SUCCESS;
    PNCRYPT_RSA_KEY pCtx    = NULL;

    // check the pointer to buffer size
    if ( NULL == pKeyData )
    {
        return NCRYPT_ERR_INVALID_ARG;
    }

    NCRYPT_ZERO_MEMORY( pKeyData, sizeof(NCRYPT_RSA_PARAM) );

    status = _PtrFromHandle( hRsaKey, &pCtx );
    if ( NCRYPT_SUCCESS != status )
    {
        return status;
    }

    pKeyData->rsaType   = pCtx->keyType;
    pKeyData->cbKeySize = pCtx->rsa.len;

    do
    {
        // both public and private keys have public part
        RSA_WRITE_BINARY(&pCtx->rsa.N, pKeyData->N);
        RSA_WRITE_BINARY(&pCtx->rsa.E, pKeyData->E);

        // private key will have more info
        if ( NCRYPT_TYPE_RSA_KEY_PRIVATE == rsaTypeToExport )
        {
            if ( NCRYPT_TYPE_RSA_KEY_PRIVATE != pCtx->keyType )
            {
                status = NCRYPT_ERR_INVALID_ARG;
                break;
            }
            RSA_WRITE_BINARY(&pCtx->rsa.D, pKeyData->D);
            RSA_WRITE_BINARY(&pCtx->rsa.P, pKeyData->P);
            RSA_WRITE_BINARY(&pCtx->rsa.Q, pKeyData->Q);

            RSA_WRITE_BINARY(&pCtx->rsa.DP, pKeyData->DP);
            RSA_WRITE_BINARY(&pCtx->rsa.DQ, pKeyData->DQ);
            RSA_WRITE_BINARY(&pCtx->rsa.QP, pKeyData->QP);
        }
        else
        {
            // exported key contains only public data
            pKeyData->rsaType = NCRYPT_TYPE_RSA_KEY_PUBLIC;
        }
    }
    while( FALSE );

    if ( NCRYPT_SUCCESS != status )
    {
        NCRYPT_ZERO_MEMORY( pKeyData, sizeof(NCRYPT_RSA_PARAM) );
    }

    return status;
}

NCRYPT_STATUS Ncrypt_Rsa_ImportPlainKey( IN NCRYPT_KEY_TYPE_RSA rsaType,
                                         IN const NCRYPT_RSA_PARAM* pKeyData,
                                         OUT NCRYPT_HANDLE_KEY_RSA* phKeyOut )
{
    NCRYPT_STATUS   status  = NCRYPT_SUCCESS;
    NCRYPT_RSA_KEY* pCtx    = NULL;

    if ( NULL == phKeyOut || NULL == pKeyData )
    {
        return NCRYPT_ERR_INVALID_ARG;
    }

    if( (NCRYPT_TYPE_RSA_KEY_PRIVATE == rsaType) &&
        (NCRYPT_TYPE_RSA_KEY_PRIVATE != pKeyData->rsaType) )
    {
        return NCRYPT_ERR_INVALID_ARG;
    }

    do
    {
        status = _CreateRsaKey( NCRYPT_OBJECT_TYPE_KEY_RSA, rsaType, &pCtx );
        if ( NCRYPT_SUCCESS != status ) break; 

        rsa_init( &pCtx->rsa, RSA_PKCS_V15, 0, _rsa_rng, NULL );

        pCtx->rsa.len = pKeyData->cbKeySize;

        //validate
        if ( pKeyData->cbKeySize != pKeyData->N.cbLen )
        {
            status = NCRYPT_ERR_INVALID_KEY_SIZE; break;
        }
        if(pKeyData->cbKeySize < pKeyData->E.cbLen)
        {
            status = NCRYPT_ERR_INVALID_KEY_SIZE; break;
        }

        // both public and private keys have public part
        RSA_READ_BINARY(&pCtx->rsa.N, pKeyData->N);
        RSA_READ_BINARY(&pCtx->rsa.E, pKeyData->E);

        // private key have more info
        if( NCRYPT_TYPE_RSA_KEY_PRIVATE == rsaType )
        {
            if ( pKeyData->cbKeySize != pKeyData->D.cbLen )
            {
                status = NCRYPT_ERR_INVALID_KEY_SIZE; break;
            }
            if ( pKeyData->cbKeySize/2 != pKeyData->P.cbLen )
            {
                status = NCRYPT_ERR_INVALID_KEY_SIZE; break;
            }
            if ( pKeyData->cbKeySize/2 != pKeyData->Q.cbLen )
            {
                status = NCRYPT_ERR_INVALID_KEY_SIZE; break;
            }

            RSA_READ_BINARY(&pCtx->rsa.D, pKeyData->D);
            RSA_READ_BINARY(&pCtx->rsa.P, pKeyData->P);
            RSA_READ_BINARY(&pCtx->rsa.Q, pKeyData->Q);

            // if any derived parameters is not specified, then we need to calculate them all.
            if ( (0 == pKeyData->DP.cbLen) || (0 == pKeyData->DQ.cbLen) || (0 == pKeyData->QP.cbLen) )
            {
                if ( !_CalculateDP(pCtx) )
                {
                    status = NCRYPT_ERR_INVALID_KEY; break;
                }
            }
            else
            {
                RSA_READ_BINARY(&pCtx->rsa.DP, pKeyData->DP);
                RSA_READ_BINARY(&pCtx->rsa.DQ, pKeyData->DQ);
                RSA_READ_BINARY(&pCtx->rsa.QP, pKeyData->QP);
            }
        }

        status = NcryptSession_HandleFromPtr( pCtx, (NCRPT_HANDLE*)phKeyOut );
        if ( NCRYPT_SUCCESS == status )
        {
            status = Ncrypt_Rsa_CheckKey( *phKeyOut );
        }
        break;
    }
    while(FALSE);

    if ( NCRYPT_SUCCESS != status )
    {
        _DeleteRsaKey( pCtx ); pCtx = NULL;
        *phKeyOut = NCRYPT_INVALID_HANDLE;
    }

    return status;

}

NCRYPT_STATUS Ncrypt_Rsa_Pkcs1Encrypt( NCRYPT_HANDLE_KEY_RSA hKey, IN const UCHAR* pIn, ULONG cbIn,
                                       UCHAR* pOut, IN OUT ULONG* pcbOut )
{
    NCRYPT_STATUS   status  = NCRYPT_SUCCESS;
    PNCRYPT_RSA_KEY pKey    = NULL;
    int ret, nMode = 0;

    if ( NULL == pcbOut )
    {
        return NCRYPT_ERR_INVALID_ARG;
    }

    status = _PtrFromHandle( hKey, &pKey );
    if ( NCRYPT_SUCCESS != status)
    {
        return status;
    }

    if ( NCRYPT_TYPE_RSA_KEY_PUBLIC == pKey->keyType )
    {
        nMode = RSA_PUBLIC;
    }
    else
    if ( NCRYPT_TYPE_RSA_KEY_PRIVATE == pKey->keyType )
    {
        nMode = RSA_PRIVATE;
    }
    else
    {
        return NCRYPT_ERR_INVALID_ARG;
    }

    // plain data len cannot exceed encryption key length minus padding
    if( cbIn >= (ULONG)(pKey->rsa.len-11) )
    {
        return NCRYPT_ERR_TOO_MUCH_DATA;
    }

    // check output buffer size
    if (*pcbOut < (ULONG)pKey->rsa.len)
    {
        *pcbOut = pKey->rsa.len;
        return NCRYPT_ERR_BUFFER_TOO_SMALL;
    }

    //Add the message padding, then do an RSA operation
    ret = rsa_pkcs1_encrypt( &pKey->rsa, nMode, cbIn, pIn, pOut);
    
    return ( 0 == ret )? NCRYPT_SUCCESS: NCRYPT_ERR_FAILED;
}

NCRYPT_STATUS Ncrypt_Rsa_Pkcs1Decrypt( NCRYPT_HANDLE_KEY_RSA hKey, IN const UCHAR* pIn, ULONG cbIn,
                                       UCHAR* pOut, IN OUT ULONG* pcbOut)
{
    NCRYPT_STATUS   status  = NCRYPT_SUCCESS;
    PNCRYPT_RSA_KEY pKey    = NULL;
    int ret, len, nMode = 0;

    if ( NULL == pcbOut )
    {
        return NCRYPT_ERR_INVALID_ARG;
    }

    status = _PtrFromHandle( hKey, &pKey );
    if ( NCRYPT_SUCCESS != status )
    {
        return status;
    }

    // check input buffer size
    if ( cbIn < (ULONG)pKey->rsa.len )
    {
        return NCRYPT_ERR_TOO_MUCH_DATA;
    }

    if ( NCRYPT_TYPE_RSA_KEY_PUBLIC == pKey->keyType )
    {
        nMode = RSA_PUBLIC;
    }
    else
    if ( NCRYPT_TYPE_RSA_KEY_PRIVATE == pKey->keyType )
    {
        nMode = RSA_PRIVATE;
    }
    else
    {
        return NCRYPT_ERR_INVALID_ARG;
    }

    ret = rsa_pkcs1_decrypt( &pKey->rsa, nMode, &len, pIn, pOut, *pcbOut );
    if( ret != 0 )
    {
        return NCRYPT_ERR_FAILED;
    }

    *pcbOut = (ULONG)len;
    return NCRYPT_SUCCESS;
}
