#pragma once
//============================================================
// Copyright © 2012 Applicable Software
// All rights reserved.
//
// File: ncryptor.h
// Created By: Igor Odnovorov
//
// Description: Defines nCrypt library interface
//
//===========================================================

#include "ncryptor_defines.h"

//--Handles
typedef struct _NCRYPT_HASH_CTX         *NCRYPT_HANDLE_HASH_CTX;
typedef struct _NCRYPT_RAND_CTX         *NCRYPT_HANDLE_RAND_CTX;
typedef struct _NCRYPT_RSA_KEY          *NCRYPT_HANDLE_KEY_RSA;

//Rand
typedef NCRYPT_STATUS (*Ncrypt_Rand_CreateCtxFnPtr)( OUT NCRYPT_HANDLE_RAND_CTX* phCtx );
typedef NCRYPT_STATUS (*Ncrypt_Rand_GenRandomFnPtr)( IN NCRYPT_HANDLE_RAND_CTX hCtx, IN OUT UCHAR* pb, IN ULONG cb );
typedef NCRYPT_STATUS (*Ncrypt_Rand_DeleteCtxFnPtr)( IN NCRYPT_HANDLE_RAND_CTX hCtx );

//Hash
typedef NCRYPT_STATUS (*Ncrypt_Hash_CreateCtxFnPtr)( IN NCRYPT_HASH_ALG hashType, OUT NCRYPT_HANDLE_HASH_CTX* phCtxOut ); 
typedef NCRYPT_STATUS (*Ncrypt_Hash_ResetCtxFnPtr)( IN NCRYPT_HANDLE_HASH_CTX hCtx ); 
typedef NCRYPT_STATUS (*Ncrypt_Hash_DeleteCtxFnPtr)( IN NCRYPT_HANDLE_HASH_CTX hCtx ); 
typedef NCRYPT_STATUS (*Ncrypt_Hash_UpdateFnPtr)( IN NCRYPT_HANDLE_HASH_CTX hCtx, IN const UCHAR* pbIn, IN ULONG cbIn ); 
typedef NCRYPT_STATUS (*Ncrypt_Hash_FinalFnPtr)( IN NCRYPT_HANDLE_HASH_CTX hCtx, OUT UCHAR* pbHashOut, IN OUT ULONG* cbHashOut ); 

//RSA
typedef NCRYPT_STATUS (*Ncrypt_Rsa_GenerateKeyPairFnPtr)( IN int nBits, IN int nExponent,
                                                          OUT NCRYPT_HANDLE_KEY_RSA* phPublicKeyOut,
                                                          OUT NCRYPT_HANDLE_KEY_RSA* phPrivateKeyOut ); 
typedef NCRYPT_STATUS (*Ncrypt_Rsa_DeleteKeyFnPtr)( IN NCRYPT_HANDLE_KEY_RSA hKey);
typedef NCRYPT_STATUS (*Ncrypt_Rsa_CheckKeyFnPtr)( NCRYPT_HANDLE_KEY_RSA hKey );
typedef NCRYPT_STATUS (*Ncrypt_Rsa_GetKeyTypeFnPtr)( NCRYPT_HANDLE_KEY_RSA hKey,
                                                     OUT NCRYPT_KEY_TYPE_RSA* pKeyType );

typedef NCRYPT_STATUS (*Ncrypt_Rsa_ExportPlainKeyFnPtr)( IN NCRYPT_HANDLE_KEY_RSA hRsaKey, IN NCRYPT_KEY_TYPE_RSA rsaTypeToExport,
                                                         OUT NCRYPT_RSA_PARAM* pOutKeyData );
typedef NCRYPT_STATUS (*Ncrypt_Rsa_ImportPlainKeyFnPtr)( IN NCRYPT_KEY_TYPE_RSA rsaType,
                                                         IN const NCRYPT_RSA_PARAM* pKeyData,
                                                         OUT NCRYPT_HANDLE_KEY_RSA* phKeyOut );
typedef NCRYPT_STATUS (*Ncrypt_Rsa_Pkcs1EncryptFnPtr)( NCRYPT_HANDLE_KEY_RSA hKey, IN const UCHAR* pIn, ULONG cbIn,
                                                       UCHAR* pOut, IN OUT ULONG* pcbOut );
typedef NCRYPT_STATUS (*Ncrypt_Rsa_Pkcs1DecryptFnPtr)( NCRYPT_HANDLE_KEY_RSA hKey, IN const UCHAR* pIn, ULONG cbIn,
                                                       UCHAR* pOut, IN OUT ULONG* pcbOut);

typedef struct _NCRYPT_TABLE
{
    ULONG   Version;

    //Rand
    Ncrypt_Rand_CreateCtxFnPtr  Rand_CreateCtx;
    Ncrypt_Rand_GenRandomFnPtr  Rand_GenRandom;
    Ncrypt_Rand_DeleteCtxFnPtr  Rand_DeleteCtx;

    //Hashing
    Ncrypt_Hash_CreateCtxFnPtr  Hash_CreateCtx; 
    Ncrypt_Hash_ResetCtxFnPtr   Hash_ResetCtx ; 
    Ncrypt_Hash_DeleteCtxFnPtr  Hash_DeleteCtx; 
    Ncrypt_Hash_UpdateFnPtr     Hash_Update; 
    Ncrypt_Hash_FinalFnPtr      Hash_Final; 

    //RSA
    Ncrypt_Rsa_GenerateKeyPairFnPtr Rsa_GenerateKeyPair;    
    Ncrypt_Rsa_DeleteKeyFnPtr       Rsa_DeleteKey;
    Ncrypt_Rsa_CheckKeyFnPtr        Rsa_CheckKey;
    Ncrypt_Rsa_GetKeyTypeFnPtr      Rsa_GetKeyType;
    Ncrypt_Rsa_ExportPlainKeyFnPtr  Rsa_ExportPlainKey;
    Ncrypt_Rsa_ImportPlainKeyFnPtr  Rsa_ImportPlainKey;
    Ncrypt_Rsa_Pkcs1EncryptFnPtr    Rsa_Pkcs1Encrypt;
    Ncrypt_Rsa_Pkcs1DecryptFnPtr    Rsa_Pkcs1Decrypt;

} NCRYPT_TABLE, *PNCRYPT_TABLE;

#define NCRTP_TABLE_MAJOR_VERSION           1
#define NCRTP_TABLE_MINOR_VERSION           0
#define NCRTP_TABLE_SET_VERSION(version,major,minor) (version = (major<<16) | minor)
#define NCRTP_TABLE_GET_MAJOR_VERSION(ver) (ver>>16)
#define NCRTP_TABLE_GET_MINOR_VERSION(ver) (ver&0xffff)

PNCRYPT_TABLE   Ncryptor_Initialize();
void            Ncryptor_Uninitialize();
PNCRYPT_TABLE   Ncryptor_Get();
