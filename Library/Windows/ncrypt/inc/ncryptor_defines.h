#pragma once
//============================================================
// Copyright © 2012 Applicable Software
// All rights reserved.
//
// File: ncryptor.h
// Created By: ncryptor_defines.h
//
// Description: Defines nCrypt library export interface
//
//===========================================================

#ifdef __cplusplus
extern "C" 
{
#endif

#pragma pack(push, _ncryptor_export_, 1)

#define FACILITY_NCRYPT 0x40

#ifndef FACILITY_ITF
    #define FACILITY_ITF            4
#endif

#define NCRYPT_MAKE_ERROR(x) (0xf0000000 | (FACILITY_ITF << 16) | (FACILITY_NCRYPT << 8) | x)

//--Error codes
#define NCRYPT_SUCCESS                    0
#define NCRYPT_ERR_FAILED                 NCRYPT_MAKE_ERROR(0x01)
#define NCRYPT_ERR_INVALID_ARG            NCRYPT_MAKE_ERROR(0x02)
#define NCRYPT_ERR_BAD_HANDLE             NCRYPT_MAKE_ERROR(0x03)
#define NCRYPT_ERR_UNINITIALIZED          NCRYPT_MAKE_ERROR(0x04)
#define NCRYPT_ERR_ERR_UNEXPECTED         NCRYPT_MAKE_ERROR(0x05)
#define NCRYPT_ERR_UNKNOWN_ALG            NCRYPT_MAKE_ERROR(0x06)
#define NCRYPT_ERR_OUT_OF_MEMORY          NCRYPT_MAKE_ERROR(0x07)
#define NCRYPT_ERR_BUFFER_TOO_SMALL       NCRYPT_MAKE_ERROR(0x08)
#define NCRYPT_ERR_SELFTESTFAILED         NCRYPT_MAKE_ERROR(0x09)
#define NCRYPT_ERR_INVALID_KEY            NCRYPT_MAKE_ERROR(0x0a)
#define NCRYPT_ERR_INVALID_KEY_SIZE       NCRYPT_MAKE_ERROR(0x0b)
#define NCRYPT_ERR_TOO_MUCH_DATA          NCRYPT_MAKE_ERROR(0x0c)

//Algorithm Types

//SHA algorithms
typedef enum _NCRYPT_HASH_ALG
{
    NCRYPT_HASH_ALG_SHA1_160,
    NCRYPT_HASH_ALG_SHA2_224,
    NCRYPT_HASH_ALG_SHA2_256,
    NCRYPT_HASH_ALG_SHA2_384,
    NCRYPT_HASH_ALG_SHA2_512,
    NCRYPT_HASH_ALG_MD5,

}NCRYPT_HASH_ALG;

//-- All sizes are in bytes
#define NCRYPT_SIZE_HASH_MD5        16
#define NCRYPT_SIZE_HASH_SHA1_160   20
#define NCRYPT_SIZE_HASH_SHA2_224   28
#define NCRYPT_SIZE_HASH_SHA2_256   32
#define NCRYPT_SIZE_HASH_SHA2_384   48
#define NCRYPT_SIZE_HASH_SHA2_512   64

#define NCRYPT_SIZE_KEY_MAX         512

#define NCRYPT_INVALID_HANDLE 0

//RSA key types
typedef enum _NCRYPT_KEY_TYPE_RSA
{
    NCRYPT_TYPE_RSA_KEY_PRIVATE,
    NCRYPT_TYPE_RSA_KEY_PUBLIC,

}NCRYPT_KEY_TYPE_RSA;

typedef struct _NCRYPT_RSA_PARAM NCRYPT_RSA_PARAM;

typedef ULONG      NCRYPT_STATUS;

//
//RSA Key Parameter
//
typedef struct _NCRYPT_RSA_PARAM_VALUE
{
    UINT32  cbLen;
    UCHAR   data[NCRYPT_SIZE_KEY_MAX];

} NCRYPT_RSA_PARAM_VALUE;

//
//RSA PARAMETER structure for RsaImportPlainKey
//
typedef struct _NCRYPT_RSA_PARAM
{
    UINT32                  rsaType;                /* private or public    */
    UINT32                  cbKeySize;              /*!<  key size in bytes */

    NCRYPT_RSA_PARAM_VALUE  N;                      /*!<  public modulus    */
    NCRYPT_RSA_PARAM_VALUE  E;                      /*!<  public exponent   */

    NCRYPT_RSA_PARAM_VALUE  D;                      /*!<  private exponent  */
    NCRYPT_RSA_PARAM_VALUE  P;                      /*!<  1st prime factor  */
    NCRYPT_RSA_PARAM_VALUE  Q;                      /*!<  2nd prime factor  */
    
    // optional
    NCRYPT_RSA_PARAM_VALUE  DP;                     /*!<  D % (P - 1)       */
    NCRYPT_RSA_PARAM_VALUE  DQ;                     /*!<  D % (Q - 1)       */
    NCRYPT_RSA_PARAM_VALUE  QP;                     /*!<  1 / (Q % P)       */

} NCRYPT_RSA_PARAM;

//! Default public key exponent for RSA key pair generation
#define NCRYPT_DEFAULT_RSA_PUBLIC_EXPONENT    0x10001

#pragma pack(pop, _ncryptor_export_)

#ifdef __cplusplus
}
#endif
