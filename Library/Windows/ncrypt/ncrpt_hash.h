#pragma once
//============================================================
// Copyright © 2012 Applicable Software
// All rights reserved.
//
// File: ncrpt_hash.h
// Created By: Igor Odnovorov
//
// Description: Declares hash related structures and functions
//
//===========================================================

#include "ncrpt_base.h"
#include "ncryptor.h"
#include "Hash\sha1.h"
#include "Hash\sha2.h"
#include "Hash\hmac_sha2.h"
#include "Hash\rsaglobal.h"
#include "Hash\rsamd5.h"

#ifdef __cplusplus
extern "C" {
#endif

//------ SHA -------------------------------------------------------
typedef struct _NCRYPT_HASH_CTX
{
    NCRYPT_OBJECT_HEADER    hdr;
    NCRYPT_HASH_ALG         hashType;
    union
    {
        sha1_ctx    ctx_sha1;
        sha224_ctx  ctx_sha2_224;
        sha256_ctx  ctx_sha2_256;
        sha384_ctx  ctx_sha2_384;
        sha512_ctx  ctx_sha2_512;
        MD5_CTX     ctx_md5;
    };
} NCRYPT_HASH_CTX, *PNCRYPT_HASH_CTX;

NCRYPT_STATUS Ncrypt_Hash_CreateCtx( IN NCRYPT_HASH_ALG hashType, OUT NCRYPT_HANDLE_HASH_CTX* phCtx );
NCRYPT_STATUS Ncrypt_Hash_ResetCtx( IN NCRYPT_HANDLE_HASH_CTX hCtx );
NCRYPT_STATUS Ncrypt_Hash_DeleteCtx( IN NCRYPT_HANDLE_HASH_CTX hCtx );
NCRYPT_STATUS Ncrypt_Hash_Update( IN NCRYPT_HANDLE_HASH_CTX hCtx, IN const UCHAR* pbData, IN ULONG cbData );
NCRYPT_STATUS Ncrypt_Hash_Final( IN NCRYPT_HANDLE_HASH_CTX hCtx, OUT UCHAR* pOutHash, IN OUT ULONG* pcbOutHash );
NCRYPT_STATUS Ncrypt_Hash_SelfTest();

#ifdef __cplusplus
}
#endif
