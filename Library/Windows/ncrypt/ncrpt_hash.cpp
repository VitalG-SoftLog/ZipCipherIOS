//============================================================
// Copyright © 2012 Applicable Software
// All rights reserved.
//
// File: ncrpt_hash.cpp
// Created By: Igor Odnovorov
//
// Description: Implements nCrypt hash interface
//
//===========================================================
#include "stdafx.h"
#include "ncrpt_hash.h"
#include "ncrpt_session.h"

static int _IsValidHashAlg( NCRYPT_HASH_ALG hashType )
{
    switch (hashType)
    {
        case NCRYPT_HASH_ALG_MD5:
        case NCRYPT_HASH_ALG_SHA1_160:
        case NCRYPT_HASH_ALG_SHA2_224:
        case NCRYPT_HASH_ALG_SHA2_256:
        case NCRYPT_HASH_ALG_SHA2_384:
        case NCRYPT_HASH_ALG_SHA2_512:
            return 1;
    }
    return 0;
}

static int _IsValidHashContext( PNCRYPT_HASH_CTX pCtx )
{
    if (NCRTP_TABLE_GET_MAJOR_VERSION(pCtx->hdr.version) != NCRTP_TABLE_MAJOR_VERSION)
    {
        return 0;
    }
    if (NCRTP_TABLE_GET_MINOR_VERSION(pCtx->hdr.version) != NCRTP_TABLE_MINOR_VERSION)
    {
        return 0;
    }

    if ( !_IsValidHashAlg(pCtx->hashType) )
    {
        return 0;
    }

    return 1;
}

static NCRYPT_STATUS _PtrFromHandle( NCRYPT_HANDLE_HASH_CTX hCtx, PNCRYPT_HASH_CTX* pCtx )
{
    NCRYPT_STATUS  status = NcryptSession_PtrFromHandle( (NCRPT_HANDLE)hCtx, NCRYPT_OBJECT_TYPE_CTX_HASH, (PVOID*)pCtx );
    if ( NCRYPT_SUCCESS != status )
    {
        return status;
    }

    if ( !_IsValidHashContext(*pCtx) )
    {
        return NCRYPT_ERR_INVALID_ARG;
    }

    return NCRYPT_SUCCESS;
}

static NCRYPT_STATUS _ResetCtx( PNCRYPT_HASH_CTX pCtx )
{
    switch ( pCtx->hashType )
    {
        case NCRYPT_HASH_ALG_MD5:
        {
            MD5Init (&pCtx->ctx_md5);
            break;
        }
        case NCRYPT_HASH_ALG_SHA1_160:
        {
            sha1_init(&pCtx->ctx_sha1);
            break;
        }
        case NCRYPT_HASH_ALG_SHA2_224:
        {
            sha224_init(&pCtx->ctx_sha2_224);
            break;
        }
        case NCRYPT_HASH_ALG_SHA2_256:
        {
            sha256_init(&pCtx->ctx_sha2_256);
            break;
        }
        case NCRYPT_HASH_ALG_SHA2_384:
        {
            sha384_init(&pCtx->ctx_sha2_384);
            break;
        }
        case NCRYPT_HASH_ALG_SHA2_512:
        {
            sha512_init(&pCtx->ctx_sha2_512);
            break;
        }
        default:
            return NCRYPT_ERR_UNKNOWN_ALG;
    }

    return NCRYPT_SUCCESS;
}

static ULONG _GetHashSize( NCRYPT_HASH_ALG hashAlg )
{
    switch ( hashAlg )
    {
        case NCRYPT_HASH_ALG_MD5:
        {
            return NCRYPT_SIZE_HASH_MD5;
        }
        case NCRYPT_HASH_ALG_SHA1_160:
        {
            return NCRYPT_SIZE_HASH_SHA1_160;
        }
        case NCRYPT_HASH_ALG_SHA2_224:
        {
            return NCRYPT_SIZE_HASH_SHA2_224;
        }
        case NCRYPT_HASH_ALG_SHA2_256:
        {
            return NCRYPT_SIZE_HASH_SHA2_256;
        }
        case NCRYPT_HASH_ALG_SHA2_384:
        {
            return NCRYPT_SIZE_HASH_SHA2_384;
        }
        case NCRYPT_HASH_ALG_SHA2_512:
        {
            return NCRYPT_SIZE_HASH_SHA2_512;
        }
    }

    return 0;
}

NCRYPT_STATUS Ncrypt_Hash_CreateCtx( IN NCRYPT_HASH_ALG hashType, OUT NCRYPT_HANDLE_HASH_CTX* phCtx)
{
    NCRYPT_STATUS       status  = NCRYPT_SUCCESS;
    PNCRYPT_HASH_CTX    pCtx    = NULL;

    if ( NULL == phCtx )
    {
        return NCRYPT_ERR_INVALID_ARG;
    }
    
    if ( !_IsValidHashAlg(hashType) )
    {
        return NCRYPT_ERR_UNKNOWN_ALG;
    }

    pCtx = (PNCRYPT_HASH_CTX)NCRYPT_ALLOC_MEMORY( sizeof(NCRYPT_HASH_CTX) );
    if (NULL == pCtx)
    {
        return NCRYPT_ERR_OUT_OF_MEMORY;
    }

    NCRYPT_ZERO_MEMORY( pCtx, sizeof(NCRYPT_HASH_CTX) );

    pCtx->hdr.magic = NCRYPT_OBJECT_MAGIC;
    pCtx->hdr.type  = NCRYPT_OBJECT_TYPE_CTX_HASH;
    NCRTP_TABLE_SET_VERSION( pCtx->hdr.version, NCRTP_TABLE_MAJOR_VERSION, NCRTP_TABLE_MINOR_VERSION );
    
    pCtx->hashType = hashType;

    status = _ResetCtx( pCtx );
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

NCRYPT_STATUS Ncrypt_Hash_ResetCtx( IN NCRYPT_HANDLE_HASH_CTX hCtx )
{
    NCRYPT_STATUS       status  = NCRYPT_SUCCESS;
    PNCRYPT_HASH_CTX    pCtx    = NULL;

    status = _PtrFromHandle( hCtx, &pCtx );
    if ( NCRYPT_SUCCESS != status )
    {
        return status;
    }

    return _ResetCtx( pCtx );
}

NCRYPT_STATUS Ncrypt_Hash_DeleteCtx( IN NCRYPT_HANDLE_HASH_CTX hCtx )
{
    NCRYPT_STATUS       status  = NCRYPT_SUCCESS;
    PNCRYPT_HASH_CTX    pCtx    = NULL;

    status = _PtrFromHandle( hCtx, &pCtx );
    if ( NCRYPT_SUCCESS != status )
    {
        return status;
    }

    NCRYPT_ZERO_MEMORY( pCtx, sizeof(NCRYPT_HASH_CTX) );
    NCRYPT_FREE_MEMORY( pCtx );

    return NCRYPT_SUCCESS;
}

NCRYPT_STATUS Ncrypt_Hash_Update( IN NCRYPT_HANDLE_HASH_CTX hCtx, IN const UCHAR* pbData, IN ULONG cbData )
{
    NCRYPT_STATUS       status  = NCRYPT_SUCCESS;
    PNCRYPT_HASH_CTX    pCtx    = NULL;

    status = _PtrFromHandle( hCtx, &pCtx );
    if ( NCRYPT_SUCCESS != status )
    {
        return status;
    }

    if ( NULL == pbData )
    {
        return NCRYPT_ERR_INVALID_ARG;
    }

    switch ( pCtx->hashType )
    {
        case NCRYPT_HASH_ALG_MD5:
        {
            MD5Update(&pCtx->ctx_md5, (UCHAR*)pbData, cbData);
            break;
        }
        case NCRYPT_HASH_ALG_SHA1_160:
        {
            sha1_update(&pCtx->ctx_sha1, pbData, cbData);
            break;
        }
        case NCRYPT_HASH_ALG_SHA2_224:
        {
            sha224_update(&pCtx->ctx_sha2_224, pbData, cbData);
            break;
        }
        case NCRYPT_HASH_ALG_SHA2_256:
        {
            sha256_update(&pCtx->ctx_sha2_256, pbData, cbData);
            break;
        }
        case NCRYPT_HASH_ALG_SHA2_384:
        {
            sha384_update(&pCtx->ctx_sha2_384, pbData, cbData);
            break;
        }
        case NCRYPT_HASH_ALG_SHA2_512:
        {
            sha512_update(&pCtx->ctx_sha2_512, pbData, cbData);
            break;
        }
        default:
        {
            return NCRYPT_ERR_UNKNOWN_ALG;
        }
    }

    return NCRYPT_SUCCESS;
}

NCRYPT_STATUS Ncrypt_Hash_Final( IN NCRYPT_HANDLE_HASH_CTX hCtx, OUT UCHAR* pOutHash, IN OUT ULONG* pcbOutHash )
{
    NCRYPT_STATUS       status  = NCRYPT_SUCCESS;
    PNCRYPT_HASH_CTX    pCtx    = NULL;

    if ( NULL == pcbOutHash )
    {
        return NCRYPT_ERR_INVALID_ARG;
    }

    status = _PtrFromHandle( hCtx, &pCtx );
    if ( NCRYPT_SUCCESS != status )
    {
        return status;
    }

    ULONG cbHash = _GetHashSize( pCtx->hashType );
    if ( NULL == pOutHash )
    {
        *pcbOutHash = cbHash;
        return NCRYPT_SUCCESS;
    }

    status = _PtrFromHandle( hCtx, &pCtx );
    if ( NCRYPT_SUCCESS != status )
    {
        return status;
    }

    switch ( pCtx->hashType )
    {
        case NCRYPT_HASH_ALG_MD5:
        {
            if ( NCRYPT_SIZE_HASH_MD5 > *pcbOutHash )
            {
                return NCRYPT_ERR_BUFFER_TOO_SMALL;
            }
            MD5Final(pOutHash, &pCtx->ctx_md5);
            break;
        }
        case NCRYPT_HASH_ALG_SHA1_160:
        {
            if ( NCRYPT_SIZE_HASH_SHA1_160 > *pcbOutHash )
            {
                return NCRYPT_ERR_BUFFER_TOO_SMALL;
            }
            sha1_final(&pCtx->ctx_sha1, pOutHash);
            break;
        }
        case NCRYPT_HASH_ALG_SHA2_224:
        {
            if ( NCRYPT_SIZE_HASH_SHA2_224 > *pcbOutHash )
            {
                return NCRYPT_ERR_BUFFER_TOO_SMALL;
            }
            sha224_final(&pCtx->ctx_sha2_224, pOutHash);
            break;
        }
        case NCRYPT_HASH_ALG_SHA2_256:
        {
            if ( NCRYPT_SIZE_HASH_SHA2_256 > *pcbOutHash )
            {
                return NCRYPT_ERR_BUFFER_TOO_SMALL;
            }
            sha256_final(&pCtx->ctx_sha2_256, pOutHash);
            break;
        }
        case NCRYPT_HASH_ALG_SHA2_384:
        {
            if (NCRYPT_SIZE_HASH_SHA2_384 > *pcbOutHash)
            {
                return NCRYPT_ERR_BUFFER_TOO_SMALL;
            }
            sha384_final(&pCtx->ctx_sha2_384, pOutHash);
            break;
        }
        case NCRYPT_HASH_ALG_SHA2_512:
        {
            if ( NCRYPT_SIZE_HASH_SHA2_512 > *pcbOutHash )
            {
                return NCRYPT_ERR_BUFFER_TOO_SMALL;
            }
            sha512_final(&pCtx->ctx_sha2_512, pOutHash);
            break;
        }
        default:
            return NCRYPT_ERR_UNKNOWN_ALG;
    }

    *pcbOutHash = cbHash;
    return NCRYPT_SUCCESS;
}

//
// Self test
//
#define HASH_SELFTEST_NUM           5
#define HASH_SELFTEST_MAX_MSG_SIZE  128
#define HASH_SELFTEST_MAX_RES_SIZE  NCRYPT_SIZE_HASH_SHA2_512

typedef struct _HashTestVector
{
    NCRYPT_HASH_ALG hashType;
    unsigned char   Message[HASH_SELFTEST_MAX_MSG_SIZE];
    int             cbMessage;
    unsigned char   HashRes[HASH_SELFTEST_MAX_RES_SIZE];
    int             cbHashRes;
} HashTestVector;

static const HashTestVector testVector[HASH_SELFTEST_NUM] = 
{
    {
        NCRYPT_HASH_ALG_SHA1_160,
        //7e3a4c325cb9c52b88387f93d01ae86d42098f5efa7f9457388b5e74b6d28b24
        //38d42d8b64703324d4aa25ab6aad153ae30cd2b2af4d5e5c00a8a2d0220c6116
        {0x7e,0x3a,0x4c,0x32,0x5c,0xb9,0xc5,0x2b,0x88,0x38,0x7f,0x93,0xd0,0x1a,0xe8,0x6d,0x42,0x09,0x8f,0x5e,0xfa,0x7f,0x94,0x57,0x38,0x8b,0x5e,0x74,0xb6,0xd2,0x8b,0x24,
        0x38,0xd4,0x2d,0x8b,0x64,0x70,0x33,0x24,0xd4,0xaa,0x25,0xab,0x6a,0xad,0x15,0x3a,0xe3,0x0c,0xd2,0xb2,0xaf,0x4d,0x5e,0x5c,0x00,0xa8,0xa2,0xd0,0x22,0x0c,0x61,0x16},
        64,
        //a3054427cdb13f164a610b348702724c808a0dcc
        {0xa3,0x05,0x44,0x27,0xcd,0xb1,0x3f,0x16,0x4a,0x61,0x0b,0x34,0x87,0x02,0x72,0x4c,0x80,0x8a,0x0d,0xcc},
        20
    },
    {
        NCRYPT_HASH_ALG_SHA2_224,
        //81675f6f8ac523cabf94a8a43370a91d9717826e5026e6cdcd23d49217c0c797
        //a95e2ee483d11b8c7a633fd2d21b16900e3f5fda0717cfde3cf4060e6971c282
        {0x81,0x67,0x5f,0x6f,0x8a,0xc5,0x23,0xca,0xbf,0x94,0xa8,0xa4,0x33,0x70,0xa9,0x1d,0x97,0x17,0x82,0x6e,0x50,0x26,0xe6,0xcd,0xcd,0x23,0xd4,0x92,0x17,0xc0,0xc7,0x97,
        0xa9,0x5e,0x2e,0xe4,0x83,0xd1,0x1b,0x8c,0x7a,0x63,0x3f,0xd2,0xd2,0x1b,0x16,0x90,0x0e,0x3f,0x5f,0xda,0x07,0x17,0xcf,0xde,0x3c,0xf4,0x06,0x0e,0x69,0x71,0xc2,0x82},
        64,
        //3c699b3b62e432e10a255fa7f6a6dbfc6d4b5813d6dcae32142e09fa
        {0x3c,0x69,0x9b,0x3b,0x62,0xe4,0x32,0xe1,0x0a,0x25,0x5f,0xa7,0xf6,0xa6,0xdb,0xfc,0x6d,0x4b,0x58,0x13,0xd6,0xdc,0xae,0x32,0x14,0x2e,0x09,0xfa},
        28
    },
    {
        NCRYPT_HASH_ALG_SHA2_256,
        //3592ecfd1eac618fd390e7a9c24b656532509367c21a0eac1212ac83c0b20cd8
        //96eb72b801c4d212c5452bbbf09317b50c5c9fb1997553d2bbc29bb42f5748ad
        {0x35,0x92,0xec,0xfd,0x1e,0xac,0x61,0x8f,0xd3,0x90,0xe7,0xa9,0xc2,0x4b,0x65,0x65,0x32,0x50,0x93,0x67,0xc2,0x1a,0x0e,0xac,0x12,0x12,0xac,0x83,0xc0,0xb2,0x0c,0xd8,
        0x96,0xeb,0x72,0xb8,0x01,0xc4,0xd2,0x12,0xc5,0x45,0x2b,0xbb,0xf0,0x93,0x17,0xb5,0x0c,0x5c,0x9f,0xb1,0x99,0x75,0x53,0xd2,0xbb,0xc2,0x9b,0xb4,0x2f,0x57,0x48,0xad},
        64,
        //105a60865830ac3a371d3843324d4bb5fa8ec0e02ddaa389ad8da4f10215c454
        {0x10,0x5a,0x60,0x86,0x58,0x30,0xac,0x3a,0x37,0x1d,0x38,0x43,0x32,0x4d,0x4b,0xb5,0xfa,0x8e,0xc0,0xe0,0x2d,0xda,0xa3,0x89,0xad,0x8d,0xa4,0xf1,0x02,0x15,0xc4,0x54},
        32
    },
    {
        NCRYPT_HASH_ALG_SHA2_384,
        //e06e21e2449ad75182808668167ca41150711fd4a8c64ffb51ae29f411adb5f8
        //4f58c2ea6e5cd88259c16eaa5f705d2842f3957e8a7d0e0e1f2a028217875a6b
        //cd556628338ad00a6999d3b68ef3a8cad6ce41c3dc253a1e3a000dbd58f5858d
        //81ef75663c2ea932d98f1d524a0e6d3d34898d6a46c7ba71cab8b06d79fe1ea4
        {0xe0,0x6e,0x21,0xe2,0x44,0x9a,0xd7,0x51,0x82,0x80,0x86,0x68,0x16,0x7c,0xa4,0x11,0x50,0x71,0x1f,0xd4,0xa8,0xc6,0x4f,0xfb,0x51,0xae,0x29,0xf4,0x11,0xad,0xb5,0xf8,
        0x4f,0x58,0xc2,0xea,0x6e,0x5c,0xd8,0x82,0x59,0xc1,0x6e,0xaa,0x5f,0x70,0x5d,0x28,0x42,0xf3,0x95,0x7e,0x8a,0x7d,0x0e,0x0e,0x1f,0x2a,0x02,0x82,0x17,0x87,0x5a,0x6b,
        0xcd,0x55,0x66,0x28,0x33,0x8a,0xd0,0x0a,0x69,0x99,0xd3,0xb6,0x8e,0xf3,0xa8,0xca,0xd6,0xce,0x41,0xc3,0xdc,0x25,0x3a,0x1e,0x3a,0x00,0x0d,0xbd,0x58,0xf5,0x85,0x8d,
        0x81,0xef,0x75,0x66,0x3c,0x2e,0xa9,0x32,0xd9,0x8f,0x1d,0x52,0x4a,0x0e,0x6d,0x3d,0x34,0x89,0x8d,0x6a,0x46,0xc7,0xba,0x71,0xca,0xb8,0xb0,0x6d,0x79,0xfe,0x1e,0xa4},
        128,
        //fa707a7639a6ec82ff72db0490409ef3e8cef1cece79f11600cecd1f7ac71c13b09975f1e2a768840dab12863bc69b1c
        {0xfa,0x70,0x7a,0x76,0x39,0xa6,0xec,0x82,0xff,0x72,0xdb,0x04,0x90,0x40,0x9e,0xf3,0xe8,0xce,0xf1,0xce,0xce,0x79,0xf1,0x16,0x00,0xce,0xcd,0x1f,0x7a,0xc7,0x1c,0x13,
        0xb0,0x99,0x75,0xf1,0xe2,0xa7,0x68,0x84,0x0d,0xab,0x12,0x86,0x3b,0xc6,0x9b,0x1c},
        48
    },
    {
        NCRYPT_HASH_ALG_SHA2_512,
        //b7d5d5f8955d1ad349b9e618c7987814f6dc7bdc6c4ee59a79902026685468d6
        //01cc74965361583bb0a8aa14f892e3c21be3094ad9e58b69cc5d6d28a9bea4af
        //c39dc45ed065d81af04c91e5eb85a4b2bab76d774aafd8837c52811270d51a1f
        //03300e7996cf6319128be5b328da818bde42ef8a471494919156a60d460191cc
        {0xb7,0xd5,0xd5,0xf8,0x95,0x5d,0x1a,0xd3,0x49,0xb9,0xe6,0x18,0xc7,0x98,0x78,0x14,0xf6,0xdc,0x7b,0xdc,0x6c,0x4e,0xe5,0x9a,0x79,0x90,0x20,0x26,0x68,0x54,0x68,0xd6,
        0x01,0xcc,0x74,0x96,0x53,0x61,0x58,0x3b,0xb0,0xa8,0xaa,0x14,0xf8,0x92,0xe3,0xc2,0x1b,0xe3,0x09,0x4a,0xd9,0xe5,0x8b,0x69,0xcc,0x5d,0x6d,0x28,0xa9,0xbe,0xa4,0xaf,
        0xc3,0x9d,0xc4,0x5e,0xd0,0x65,0xd8,0x1a,0xf0,0x4c,0x91,0xe5,0xeb,0x85,0xa4,0xb2,0xba,0xb7,0x6d,0x77,0x4a,0xaf,0xd8,0x83,0x7c,0x52,0x81,0x12,0x70,0xd5,0x1a,0x1f,
        0x03,0x30,0x0e,0x79,0x96,0xcf,0x63,0x19,0x12,0x8b,0xe5,0xb3,0x28,0xda,0x81,0x8b,0xde,0x42,0xef,0x8a,0x47,0x14,0x94,0x91,0x91,0x56,0xa6,0x0d,0x46,0x01,0x91,0xcc},
        128,
        //6e7fb797dfca7577432c0b339fe9003b36942a549b112d32016b257c9a866e43
        //85e01d4e757d4378b8e61f5a8a29aa73f2daafdaab23dfe4e0b93df21374e594
        {0x6e,0x7f,0xb7,0x97,0xdf,0xca,0x75,0x77,0x43,0x2c,0x0b,0x33,0x9f,0xe9,0x00,0x3b,0x36,0x94,0x2a,0x54,0x9b,0x11,0x2d,0x32,0x01,0x6b,0x25,0x7c,0x9a,0x86,0x6e,0x43,
        0x85,0xe0,0x1d,0x4e,0x75,0x7d,0x43,0x78,0xb8,0xe6,0x1f,0x5a,0x8a,0x29,0xaa,0x73,0xf2,0xda,0xaf,0xda,0xab,0x23,0xdf,0xe4,0xe0,0xb9,0x3d,0xf2,0x13,0x74,0xe5,0x94},
        64
    },
};

NCRYPT_STATUS Ncrypt_Hash_SelfTest()
{
    NCRYPT_STATUS status = NCRYPT_SUCCESS;

    unsigned char testResult[HASH_SELFTEST_MAX_RES_SIZE] = {0};

    int i = 0;

    NCRYPT_HANDLE_HASH_CTX  hCtx = NCRYPT_INVALID_HANDLE;
    for (i = 0; i<HASH_SELFTEST_NUM; i++)
    {
        status = Ncrypt_Hash_CreateCtx( testVector[i].hashType, &hCtx );
        if ( NCRYPT_SUCCESS != status )
        {
            break;
        }

        status = Ncrypt_Hash_Update( hCtx, testVector[i].Message, testVector[i].cbMessage );
        if ( NCRYPT_SUCCESS != status )
        {
            break;
        }

        ULONG cbHash = sizeof(testResult);
        status = Ncrypt_Hash_Final( hCtx, testResult, &cbHash ); 
        if ( NCRYPT_SUCCESS != status )
        {
            break;
        }

        if (0 != memcmp(testResult, testVector[i].HashRes, testVector[i].cbHashRes))
        {
            status = NCRYPT_ERR_SELFTESTFAILED;
            break;
        }

        status = Ncrypt_Hash_DeleteCtx( hCtx );
        if ( NCRYPT_SUCCESS != status )
        {
            break;
        }

        hCtx = NCRYPT_INVALID_HANDLE;
        NCRYPT_ZERO_MEMORY( testResult, sizeof(testResult) );
    }

    if ( NCRYPT_INVALID_HANDLE != hCtx )
    {
        Ncrypt_Hash_DeleteCtx( hCtx );
    }

    return status;
}
