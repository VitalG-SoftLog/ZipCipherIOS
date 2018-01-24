#pragma once
//============================================================
// Copyright © 2012 Applicable Software
// All rights reserved.
//
// File: cipher.h
// Created By: Igor Odnovorov
//
// Description: Defines cipher interface
//
//===========================================================

class CCipher
{
public:
    static void     Initialize();
    static void     Uninitialize();

    static CStringA EncryptByRSAKey( const CStringA& RSAKey, const BYTE* pIn, DWORD cbIn );

    static void     GenerateRandom( BYTE* buffer, ULONG cbBuffer );

    static  void    RsaDecrypt( const CStringA& RSAKey, const BYTE* pIn, ULONG cbIn,
                                BYTE* pOut, ULONG& cbOut );

    static CStringA ClonePublicKey( const CStringA& RSAKey );

    enum KeyStrength
    {
        Rsa_1024bit,
        Rsa_2048bit,
        Rsa_4096bit
    };

    static CStringA GenerateNewRSAKey( KeyStrength keyStrength=Rsa_2048bit );

    static void     GeneratePassword( const BYTE* pSecret, ULONG cbSecret, const BYTE* entropy, DWORD cbEntropy, ULONG nCount, UCHAR* hash, ULONG& cbHash );

    static void     GetHashValue( const BYTE* pData, ULONG cbData,
                                  /*OUT*/UCHAR* hash,
                                  /*IN, OUT*/ULONG& cbHash );
};