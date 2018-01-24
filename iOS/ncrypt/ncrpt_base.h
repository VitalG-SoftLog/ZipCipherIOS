#pragma once
//============================================================
// Copyright � 2012 Applicable Software
// All rights reserved.
//
// File: ncrpt_base.h
// Created By: Igor Odnovorov
//
// Description: defines nCrypt library base interface
//
//===========================================================

#ifdef __APPLE__
#include <stdlib.h>
#include <string.h>
#include <malloc/malloc.h>


#ifndef ULONG
#define ULONG unsigned long
#endif
#ifndef UCHAR
#define UCHAR unsigned char
#endif

#ifndef HANDLE_PTR
#define HANDLE_PTR DWORD
#endif
#ifndef ULONG_PTR
#define ULONG_PTR unsigned long
#endif

#ifndef IN
#define IN
#endif

#ifndef OUT
#define OUT
#endif

#ifndef PVOID
#define PVOID void*
#endif

#ifndef UINT32
#define UINT32 unsigned int
#endif

#ifndef NULL
#define NULL 0x00
#endif

#ifndef FALSE
#define FALSE false
#endif


#ifdef __cplusplus
extern "C" {
    void RtlSecureZeroMemory(void *ptr, unsigned int cb);
}
#endif

#endif

#if defined(WIN32)
#include "malloc.h"
#include "targetver.h"
#define WIN32_LEAN_AND_MEAN             // Exclude rarely-used stuff from Windows headers
#include <windows.h>
#endif //WIN32



#define NCRYPT_ALLOC_MEMORY(cb)         malloc(cb)
#define NCRYPT_FREE_MEMORY(ptr)         free(ptr)
#define NCRYPT_ZERO_MEMORY(ptr, cb)     RtlSecureZeroMemory(ptr, cb)
#define NCRYPT_IS_ADDRESS_VALID(p, cb)  (!IsBadReadPtr(p, cb))

#define PARAM_VA_LIST1( p1 ) p1
#define PARAM_VA_LIST2( p1, p2 ) p1, p2
#define PARAM_VA_LIST3( p1, p2, p3 ) p1, p2, p3
#define PARAM_VA_LIST4( p1, p2, p3, p4 ) p1, p2, p3, p4
#define PARAM_VA_LIST5( p1, p2, p3, p4, p5 ) p1, p2, p3, p4, p5

#define NCRYPT_PRINT(message) printf( message )
#define NCRYPT_PRINTV(message,p) printf( message, PARAM_##p )

#define NCRYPT_OBJECT_MAGIC 'boCn'

typedef enum _NCRYPT_OBJECT_TYPE
{
    NCRYPT_OBJECT_TYPE_INVALID      = 0,

    NCRYPT_OBJECT_TYPE_KEY_RSA      = 1,
    NCRYPT_OBJECT_TYPE_CTX_HASH     = 3,
    NCRYPT_OBJECT_TYPE_CTX_RAND     = 4

} NCRYPT_OBJECT_TYPE;


typedef struct _NCRYPT_OBJECT_HEADER
{
    ULONG               magic;
    ULONG               version;
    NCRYPT_OBJECT_TYPE  type;

} NCRYPT_OBJECT_HEADER;

typedef ULONG   NCRYPT_STATUS;

typedef struct _NCRYPT_OBJECT_HEADER    *NCRPT_HANDLE;

NCRYPT_STATUS Ncrypt_GenRandom( IN OUT UCHAR* pb, IN ULONG cb );
