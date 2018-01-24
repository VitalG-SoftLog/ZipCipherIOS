#pragma once
//============================================================
// Copyright � 2012 Applicable Software
// All rights reserved.
//
// File: ncrpt_rsa.h
// Created By: Igor Odnovorov
//
// Description: Declares RSA encryption interface
//
//===========================================================

#include "polarssl/rsa.h"
#include "polarssl/bignum.h"

#include "ncrpt_base.h"
#include "ncryptor.h"

//#ifdef __cplusplus
//extern "C" {
//#endif

//------ SHA -------------------------------------------------------
typedef struct _NCRYPT_RSA_KEY
{
    NCRYPT_OBJECT_HEADER    hdr;
    NCRYPT_KEY_TYPE_RSA     keyType;
    rsa_context             rsa;

} NCRYPT_RSA_KEY, *PNCRYPT_RSA_KEY;

NCRYPT_STATUS Ncrypt_Rsa_GenerateKeyPair( IN int nBits, IN int nExponent,
                                          OUT NCRYPT_HANDLE_KEY_RSA* phPublicKeyOut,
                                          OUT NCRYPT_HANDLE_KEY_RSA* phPrivateKeyOut ); 
NCRYPT_STATUS Ncrypt_Rsa_DeleteKey( IN NCRYPT_HANDLE_KEY_RSA hKey);
NCRYPT_STATUS Ncrypt_Rsa_CheckKey( NCRYPT_HANDLE_KEY_RSA hKey );
NCRYPT_STATUS Ncrypt_Rsa_GetKeyType( NCRYPT_HANDLE_KEY_RSA hKey,
                                     OUT NCRYPT_KEY_TYPE_RSA* pKeyType );
NCRYPT_STATUS Ncrypt_Rsa_ExportPlainKey( IN NCRYPT_HANDLE_KEY_RSA hRsaKey, IN NCRYPT_KEY_TYPE_RSA rsaTypeToExport,
                                         OUT NCRYPT_RSA_PARAM* pOutKeyData );
NCRYPT_STATUS Ncrypt_Rsa_ImportPlainKey( IN NCRYPT_KEY_TYPE_RSA rsaType,
                                         IN const NCRYPT_RSA_PARAM* pKeyData,
                                         OUT NCRYPT_HANDLE_KEY_RSA* phKeyOut );
NCRYPT_STATUS Ncrypt_Rsa_Pkcs1Encrypt( NCRYPT_HANDLE_KEY_RSA hKey, IN const UCHAR* pIn, ULONG cbIn,
                                       UCHAR* pOut, IN OUT ULONG* pcbOut );
NCRYPT_STATUS Ncrypt_Rsa_Pkcs1Decrypt( NCRYPT_HANDLE_KEY_RSA hKey, IN const UCHAR* pIn, ULONG cbIn,
                                       UCHAR* pOut, IN OUT ULONG* pcbOut);

//#ifdef __cplusplus
//}
//#endif
