//============================================================
// Copyright © 2012 Applicable Software
// All rights reserved.
//
// File: ncrpt_table.cpp
// Created By: Igor Odnovorov
//
// Description: Implements nCrypt library interface
//
//===========================================================
#include "stdafx.h"
#include "ncryptor.h"
#include "ncrpt_base.h"
#include "ncrpt_rand.h"
#include "ncrpt_session.h"
#include "ncrpt_hash.h"
#include "ncrpt_rsa.h"

static volatile LONG    g_NcrptTableInitCount   = 0;
static NCRYPT_TABLE     g_NcrptTable            = {0};

PNCRYPT_TABLE  Ncryptor_Initialize()
{
    if( 1 == InterlockedIncrement(&g_NcrptTableInitCount) )
    {
        Ncrypt_Rand_Initialize();
        NcryptSession_Initialize();

        NCRTP_TABLE_SET_VERSION( g_NcrptTable.Version, NCRTP_TABLE_MAJOR_VERSION, NCRTP_TABLE_MINOR_VERSION );

        g_NcrptTable.Rand_CreateCtx = Ncrypt_Rand_CreateCtx;
        g_NcrptTable.Rand_GenRandom = Ncrypt_Rand_GenRandom;
        g_NcrptTable.Rand_DeleteCtx = Ncrypt_Rand_DeleteCtx;

        g_NcrptTable.Hash_CreateCtx = Ncrypt_Hash_CreateCtx; 
        g_NcrptTable.Hash_ResetCtx  = Ncrypt_Hash_ResetCtx; 
        g_NcrptTable.Hash_DeleteCtx = Ncrypt_Hash_DeleteCtx; 
        g_NcrptTable.Hash_Update    = Ncrypt_Hash_Update; 
        g_NcrptTable.Hash_Final     = Ncrypt_Hash_Final;

        g_NcrptTable.Rsa_GenerateKeyPair    = Ncrypt_Rsa_GenerateKeyPair;    
        g_NcrptTable.Rsa_DeleteKey          = Ncrypt_Rsa_DeleteKey;
        g_NcrptTable.Rsa_CheckKey           = Ncrypt_Rsa_CheckKey;
        g_NcrptTable.Rsa_GetKeyType         = Ncrypt_Rsa_GetKeyType;
        g_NcrptTable.Rsa_ExportPlainKey     = Ncrypt_Rsa_ExportPlainKey;
        g_NcrptTable.Rsa_ImportPlainKey     = Ncrypt_Rsa_ImportPlainKey;
        g_NcrptTable.Rsa_Pkcs1Encrypt       = Ncrypt_Rsa_Pkcs1Encrypt;
        g_NcrptTable.Rsa_Pkcs1Decrypt       = Ncrypt_Rsa_Pkcs1Decrypt;
    }

    return &g_NcrptTable;
}

void Ncryptor_Uninitialize()
{
    if( 0 == InterlockedDecrement(&g_NcrptTableInitCount) )
    {
        NcryptSession_Uninitialize();
        Ncrypt_Rand_Uninitialize();
    }
}

PNCRYPT_TABLE   Ncryptor_Get()
{
    if ( g_NcrptTableInitCount )
    {
        return &g_NcrptTable;
    }

    return NULL;
}
