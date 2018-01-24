//============================================================
// Copyright © 2012 Applicable Software
// All rights reserved.
//
// File: cipher.cpp
// Created By: Igor Odnovorov
//
// Description: Implements Cipher interface
//
//===========================================================

#include "stdafx.h"
#include "cipher.h"
#include "Exception.h"
#include "Encoder.h"
#include "ncryptor.h"
#include "Encoder.h"

PNCRYPT_TABLE           g_NcryptTable   = NULL;
NCRYPT_HANDLE_RAND_CTX  g_hRandCtx      = NCRYPT_INVALID_HANDLE;

class CNcryptRSAKeyHandle
{
    NCRYPT_HANDLE_KEY_RSA   m_hKey;

public:
    CNcryptRSAKeyHandle(): m_hKey(NCRYPT_INVALID_HANDLE)
    {
    }

    ~CNcryptRSAKeyHandle()
    {
        CloseHandle();
    }

    bool IsValid() const throw()
    {
        return NCRYPT_INVALID_HANDLE != m_hKey;
    }

    NCRYPT_HANDLE_KEY_RSA* GetKeyAddr() throw()
    {
        CloseHandle();
        return &m_hKey;
    }

    operator NCRYPT_HANDLE_KEY_RSA()
    {
        return m_hKey;
    }

    CNcryptRSAKeyHandle& operator =( NCRYPT_HANDLE_KEY_RSA hKey )
    {
        CloseHandle();

        m_hKey = hKey;
        return *this;
    }

    void CloseHandle()
    {
        if ( IsValid() )
        {
            g_NcryptTable->Rsa_DeleteKey( m_hKey );
            m_hKey = NCRYPT_INVALID_HANDLE;
        }
    }
};

// find string str in NON-0-TERMINATED buffer. return pointer to string or NULL
static const char* _findStringInBuffer( const char* pBuffer, DWORD cbBuffer, const char* str )
{
    // scan buffer for first matching character
    for( DWORD searchPos = 0; searchPos < cbBuffer; searchPos ++ )
    {
        if ( pBuffer[searchPos] == *str )
        {
            const char* pMatch = pBuffer + searchPos;
            DWORD matchPos = 0;
            // first character matches, now compare the rest of the string
            for( matchPos = 0; (searchPos + matchPos) < cbBuffer; matchPos++ )
            {
                // continue until match is broken
                if( pMatch[matchPos] != str[matchPos] )
                {
                    break;
                }
            }

            // if we've reached the end of the search string, we are done.
            if( '\0' == str[matchPos] )
            {
                return pMatch;
            }
        }
    }

    return NULL;
}

static BOOL _getXmlElementInnerText( const char* szTag, const char* pbXmlIn, __in DWORD cbXmlIn, const char** ppOutInnerText, DWORD* pcbOutInnerText)
{
#define MAX_TAG 20
    char formattedTag[MAX_TAG];

    // first find opening tag
    sprintf_s(formattedTag, MAX_TAG, "<%s>", szTag);
    const char* start = _findStringInBuffer( pbXmlIn, cbXmlIn, formattedTag );
    if( NULL == start )
    {
        return FALSE;
    }

    // skip the opening tag
    const char* text = start + strlen(formattedTag);

    // now find closing tag
    sprintf_s(formattedTag, MAX_TAG, "</%s>", szTag);
    const char* end = _findStringInBuffer( pbXmlIn, cbXmlIn, formattedTag );
    if( NULL == end )
    {
        return FALSE;
    }

    if( NULL != ppOutInnerText && NULL != pcbOutInnerText )
    {
        *ppOutInnerText = text;
        *pcbOutInnerText = (DWORD) (end-text);
    }

    return TRUE;
}

static BOOL _getRsaParam( const char* tag, const char* pbXmlIn, __in DWORD cbXmlIn, NCRYPT_RSA_PARAM_VALUE* pOutParam)
{
    const char* pXmlParam = NULL;
    DWORD cbXmlParam = 0;
    pOutParam->cbLen = 0;
    BOOL bFound = _getXmlElementInnerText(tag, pbXmlIn, cbXmlIn, &pXmlParam, &cbXmlParam);
    if( bFound )
    {
        DWORD cbLen = sizeof( pOutParam->data );
        if ( BASE64Decode( pXmlParam, cbXmlParam, pOutParam->data, &cbLen ) )
        {
            pOutParam->cbLen = cbLen;
        }
    }

    return 0 != pOutParam->cbLen;
}

static void _addXmlTag( const char* tag, bool openTag, char* out, ULONG* pcbCur, ULONG cbMax)
{
	ULONG cbCur = *pcbCur;
	ULONG cbTag = (ULONG)strlen(tag);
	ULONG cbXml = cbTag + 2 + (openTag ? 0 : 1);

	// if buffer is not null and not exceeded, then put the tag in.
	if( (NULL != out) && ((cbCur + cbXml) < cbMax) )
	{
		out[cbCur++] = '<';
		if( !openTag )
		{
			out[cbCur++] = '/';
		}
		strcpy_s(out+cbCur, cbMax - cbCur, tag);
		cbCur += cbTag;
		out[cbCur++] = '>';
		// nul-terminate (don't move the pointer)
		out[cbCur] = 0;
	}

	*pcbCur += cbXml;
}

static void _addRsaParam( const char* tag, const NCRYPT_RSA_PARAM_VALUE* pParam, char* out, ULONG* pcbCur, ULONG cbMax)
{
	const CHAR*	pData   = (const CHAR*)pParam->data;
	ULONG		cbData  = pParam->cbLen;

	// open tag
	_addXmlTag( tag, TRUE, out, pcbCur, cbMax);

	// skip leading 0s
	while( 0 == *pData && 0 != cbData )
	{
		pData++;
		cbData--;
	}

	if( NULL != out )
	{
		// base64 encode
		DWORD dlen = cbMax - *pcbCur;
		BASE64Encode( (const BYTE*)pData, cbData, (CHAR*)(out + *pcbCur), &dlen );
		*pcbCur += dlen;
	}
	else
	{
		// just determine the needed size
		DWORD dlen = 0;
		BASE64Encode( (const BYTE*)pData, cbData, NULL, &dlen );
		*pcbCur += dlen;
	}

	// close tag
	_addXmlTag( tag, FALSE, out, pcbCur, cbMax);
}

static void _Rsa_ImportPlainKey( __in_bcount(cbIn) const char* pbXmlIn, __in DWORD cbXmlIn,
                                 BOOLEAN bDecryptionKey,
                                 OUT NCRYPT_HANDLE_KEY_RSA* phKeyOut )
{
    if( !_getXmlElementInnerText( "RSAKeyValue", pbXmlIn, cbXmlIn, NULL, NULL ) )
    {
        throw CCryptoException( NCRYPT_ERR_INVALID_ARG, _T("Failed to parse rsa key value") );
    }
    /*
    <RSAKeyValue>
    <Modulus>…</Modulus>
    <Exponent>…</Exponent>
    <P>…</P>
    <Q>…</Q>
    <DP>…</DP>
    <DQ>…</DQ>
    <InverseQ>…</InverseQ>
    <D>…</D>
    </RSAKeyValue>
    */
    NCRYPT_RSA_PARAM KeyData = {0};

    // public
    _getRsaParam( "Modulus", pbXmlIn, cbXmlIn, &KeyData.N);
    _getRsaParam( "Exponent", pbXmlIn, cbXmlIn, &KeyData.E);

    // private
    if ( bDecryptionKey )
    {
        _getRsaParam( "P", pbXmlIn, cbXmlIn, &KeyData.P);
        _getRsaParam( "Q", pbXmlIn, cbXmlIn, &KeyData.Q);
        _getRsaParam( "DP", pbXmlIn, cbXmlIn, &KeyData.DP);
        _getRsaParam( "DQ", pbXmlIn, cbXmlIn, &KeyData.DQ);
        _getRsaParam( "InverseQ", pbXmlIn, cbXmlIn, &KeyData.QP);
        _getRsaParam( "D", pbXmlIn, cbXmlIn, &KeyData.D);
    }

    if( 0 != KeyData.P.cbLen )
    {
        KeyData.rsaType = NCRYPT_TYPE_RSA_KEY_PRIVATE;
    }
    else
    {
        KeyData.rsaType = NCRYPT_TYPE_RSA_KEY_PUBLIC;
    }

    // public modulus is always the same size as the key
    KeyData.cbKeySize = KeyData.N.cbLen;

    NCRYPT_STATUS status = g_NcryptTable->Rsa_ImportPlainKey( (NCRYPT_KEY_TYPE_RSA)KeyData.rsaType,
                                                              &KeyData,
                                                              phKeyOut );

    RtlSecureZeroMemory( &KeyData, sizeof(KeyData) );
    if ( NCRYPT_SUCCESS != status )
    {
        throw CCryptoException( status, _T("Failed to import rsa key") );
    }
}

static bool _Rsa_ExportPlainKey( IN NCRYPT_HANDLE_KEY_RSA hRsaKey,
                                 IN bool includePrivateKey,
                                 __out_bcount(*pcbOut) char* pbXmlOut,
                                 __inout ULONG* pcbOut )
{
    NCRYPT_RSA_PARAM KeyData = {0};

    NCRYPT_KEY_TYPE_RSA KeyType;
    NCRYPT_STATUS status = g_NcryptTable->Rsa_GetKeyType( hRsaKey, &KeyType );
    if ( NCRYPT_SUCCESS != status )
    {
        throw CCryptoException( status, _T("Cannot get rsa key type") );
    }

    if ( includePrivateKey && NCRYPT_TYPE_RSA_KEY_PRIVATE != KeyType )
    {
        throw CCryptoException( NCRYPT_ERR_INVALID_KEY, _T("Wrong rsa key type") );
    }

	// export key in plain form 
	status = g_NcryptTable->Rsa_ExportPlainKey( hRsaKey, 
												includePrivateKey ? NCRYPT_TYPE_RSA_KEY_PRIVATE: NCRYPT_TYPE_RSA_KEY_PUBLIC, 
												&KeyData );

    if ( NCRYPT_SUCCESS != status )
    {
        throw CCryptoException( status, _T("Failed to import rsa key") );
    }

	ULONG cbMax = *pcbOut + 1;
	ULONG cbCur = 0;

	/*
		<RSAKeyValue>
			<Modulus>…</Modulus>
			<Exponent>…</Exponent>
			<P>…</P>
			<Q>…</Q>
			<DP>…</DP>
			<DQ>…</DQ>
			<InverseQ>…</InverseQ>
			<D>…</D>
		</RSAKeyValue>

	*/
	_addXmlTag("RSAKeyValue", TRUE, pbXmlOut, &cbCur, cbMax);
	_addRsaParam("Modulus", &KeyData.N, pbXmlOut, &cbCur, cbMax);
	_addRsaParam("Exponent", &KeyData.E, pbXmlOut, &cbCur, cbMax);

	if( includePrivateKey )
	{
		_addRsaParam("P", &KeyData.P, pbXmlOut, &cbCur, cbMax);
		_addRsaParam("Q", &KeyData.Q, pbXmlOut, &cbCur, cbMax);
		_addRsaParam("DP", &KeyData.DP, pbXmlOut, &cbCur, cbMax);
		_addRsaParam("DQ", &KeyData.DQ, pbXmlOut, &cbCur, cbMax);
		_addRsaParam("InverseQ", &KeyData.QP, pbXmlOut, &cbCur, cbMax);
		_addRsaParam("D", &KeyData.D, pbXmlOut, &cbCur, cbMax);
	}

	_addXmlTag("RSAKeyValue", FALSE, pbXmlOut, &cbCur, cbMax);

	RtlSecureZeroMemory( &KeyData, sizeof(KeyData) );

	*pcbOut = cbCur;
	if( cbCur > cbMax && 0 != cbMax  )
	{
        return false;
	}

    return true;
}

static bool _Rsa_Pkcs1Encrypt( NCRYPT_HANDLE_KEY_RSA hKey,
                               IN const UCHAR* pIn, ULONG cbIn,
                               UCHAR* pOut, IN OUT ULONG* pcbOut )
{
    NCRYPT_STATUS status = g_NcryptTable->Rsa_Pkcs1Encrypt( hKey,
                                                            pIn, cbIn,
                                                            pOut, pcbOut );

    if ( NCRYPT_ERR_BUFFER_TOO_SMALL == status )
        return false;

    if ( NCRYPT_SUCCESS != status )
    {
        throw CCryptoException( status, _T("Failed to encrypt") );
    }

    return true;
}

static bool _Rsa_Pkcs1Decrypt( NCRYPT_HANDLE_KEY_RSA hKey, IN const UCHAR* pIn, ULONG cbIn,
                               UCHAR* pOut, IN OUT ULONG* pcbOut)
{
    NCRYPT_STATUS status = g_NcryptTable->Rsa_Pkcs1Decrypt( hKey,
                                                            pIn, cbIn,
                                                            pOut, pcbOut );
    if ( NCRYPT_ERR_BUFFER_TOO_SMALL == status )
        return false;

    if ( NCRYPT_SUCCESS != status )
    {
        throw CCryptoException( status, _T("Failed to decrypt") );
    }

    return true;
}

static void _Rsa_GenerateKeyPair( IN int nBits, IN int nExponent,
                                  OUT NCRYPT_HANDLE_KEY_RSA* phPublicKeyOut,
                                  OUT NCRYPT_HANDLE_KEY_RSA* phPrivateKeyOut )
{
    NCRYPT_STATUS status = g_NcryptTable->Rsa_GenerateKeyPair( nBits, nExponent,
                                                               phPublicKeyOut,
                                                    phPrivateKeyOut );
    if ( NCRYPT_SUCCESS != status )
    {
        throw CCryptoException( status, _T("Failed to decrypt") );
    }
}

void CCipher::Initialize()
{
    g_NcryptTable = Ncryptor_Initialize();
    if ( NULL == g_NcryptTable )
    {
        CCipher::Uninitialize();
        throw CZipCipherErrorException( L"Could not initialize crypto interface" );
    }

    NCRYPT_STATUS nstatus = g_NcryptTable->Rand_CreateCtx( &g_hRandCtx );
    if ( NCRYPT_SUCCESS != nstatus )
    {
        CCipher::Uninitialize();
        throw CZipCipherErrorException( L"Could not create random number generator" );
    }
}

void CCipher::Uninitialize()
{
    if ( g_NcryptTable )
    {
        if ( NCRYPT_INVALID_HANDLE != g_hRandCtx )
        {
            g_NcryptTable->Rand_DeleteCtx( g_hRandCtx );
            g_hRandCtx = NCRYPT_INVALID_HANDLE;
        }
        Ncryptor_Uninitialize();
    }
}

CStringA CCipher::EncryptByRSAKey( const CStringA& XmlRSAKey, const BYTE* pIn, DWORD cbIn )
{
    CNcryptRSAKeyHandle hKey;

    _Rsa_ImportPlainKey( XmlRSAKey, XmlRSAKey.GetLength(), FALSE, hKey.GetKeyAddr() );

    ULONG cbOut = 0;
    _Rsa_Pkcs1Encrypt( hKey,  pIn, cbIn, NULL, &cbOut );

    BYTE* buffer = (BYTE*)alloca(cbOut);
    if( !_Rsa_Pkcs1Encrypt( hKey,  pIn, cbIn, buffer, &cbOut) )
    {
        throw CCryptoException( NCRYPT_ERR_FAILED, _T("Failed to encrypt") );
    }

    DWORD cbEncoded = 0;
    if ( !BASE64Encode(buffer, cbOut, NULL, &cbEncoded) )
    {
        throw CZipCipherErrorException( _T("Failed to encode encrypted key") );
    }
    CStringA BlobA;
    if ( !BASE64Encode(buffer, cbOut, BlobA.GetBuffer(cbEncoded), &cbEncoded) )
    {
        throw CZipCipherErrorException( _T("Failed to encode encrypted key") );
    }
    BlobA.ReleaseBuffer( cbEncoded );

    return BlobA;
}

void CCipher::GenerateRandom( BYTE* buffer, ULONG cbBuffer )
{
    NCRYPT_STATUS status = g_NcryptTable->Rand_GenRandom( g_hRandCtx, buffer, cbBuffer );
    if ( NCRYPT_SUCCESS != status )
    {
        throw CZipCipherErrorException( L"Failed to generate random number" );
    }
}

void CCipher::RsaDecrypt( const CStringA& XmlRSAKey,
                          const BYTE* pIn, ULONG cbIn,
                          BYTE* pOut, ULONG& cbOut )
{
    CNcryptRSAKeyHandle hKey;

    _Rsa_ImportPlainKey( XmlRSAKey, XmlRSAKey.GetLength(), TRUE, hKey.GetKeyAddr() );

    if( !_Rsa_Pkcs1Decrypt(hKey,  pIn, cbIn, pOut, &cbOut) )
    {
        throw CCryptoException( NCRYPT_ERR_FAILED, _T("Failed to decrypt storage key") );
    }
}

CStringA CCipher::ClonePublicKey( const CStringA& RSAKey )
{
    const char* pbXmlIn = RSAKey;
    DWORD       cbXmlIn = RSAKey.GetLength();

    if( !_getXmlElementInnerText( "RSAKeyValue", pbXmlIn, cbXmlIn, NULL, NULL ) )
    {
        throw CCryptoException( NCRYPT_ERR_INVALID_ARG, _T("Failed to parse rsa key value") );
    }
    /*
    <RSAKeyValue>
    <Modulus>…</Modulus>
    <Exponent>…</Exponent>
    <P>…</P>
    <Q>…</Q>
    <DP>…</DP>
    <DQ>…</DQ>
    <InverseQ>…</InverseQ>
    <D>…</D>
    </RSAKeyValue>
    */

    // public
    NCRYPT_RSA_PARAM_VALUE  N;                      /*!<  public modulus    */
    NCRYPT_RSA_PARAM_VALUE  E;                      /*!<  public exponent   */

    _getRsaParam( "Modulus", pbXmlIn, cbXmlIn, &N);
    _getRsaParam( "Exponent", pbXmlIn, cbXmlIn, &E);

    ULONG cbCur = 0;
	_addXmlTag("RSAKeyValue", TRUE, NULL, &cbCur, 0);
	_addRsaParam("Modulus", &N, NULL, &cbCur, 0);
	_addRsaParam("Exponent", &E, NULL, &cbCur, 0);
	_addXmlTag("RSAKeyValue", FALSE, NULL, &cbCur, 0);

    ULONG cbMax = cbCur+1;

    CStringA strRsaKey;
    char* xml = strRsaKey.GetBuffer( cbMax );

    cbCur = 0;
	_addXmlTag("RSAKeyValue", TRUE, xml, &cbCur, cbMax);
	_addRsaParam("Modulus", &N, xml, &cbCur, cbMax);
	_addRsaParam("Exponent", &E, xml, &cbCur, cbMax);
	_addXmlTag("RSAKeyValue", FALSE, xml, &cbCur, cbMax);

    strRsaKey.ReleaseBuffer( cbCur );
    return strRsaKey;
}

CStringA CCipher::GenerateNewRSAKey( KeyStrength keyStrength )
{
    CNcryptRSAKeyHandle hKey;

    int bitLen = 0;
    switch ( keyStrength )
    {
        case Rsa_1024bit:
            bitLen = 1024;
            break;
        case Rsa_2048bit:
            bitLen = 2048;
            break;
        case Rsa_4096bit:
            bitLen = 4096;
            break;
        default:
        {
            CString err;
            err.Format( _T("Unknown key strength: %d"), keyStrength );

            throw CZipCipherErrorException( err );
        }
    }

    _Rsa_GenerateKeyPair( bitLen, NCRYPT_DEFAULT_RSA_PUBLIC_EXPONENT,
                          NULL, hKey.GetKeyAddr() );
    CStringA strRsaKey;

    ULONG cbXmlEstimate = 0;
    _Rsa_ExportPlainKey( hKey, true, NULL, &cbXmlEstimate );

    char* xml = strRsaKey.GetBuffer( cbXmlEstimate );
    if ( !_Rsa_ExportPlainKey(hKey, true, xml, &cbXmlEstimate) )
    {
        throw CCryptoException( NCRYPT_ERR_ERR_UNEXPECTED, _T("Failed to export a new key") );
    }

    strRsaKey.ReleaseBuffer( cbXmlEstimate );
    return strRsaKey;
}

void CCipher::GetHashValue( const BYTE* pData, ULONG cbData, UCHAR* hash, ULONG& cbHash )
{
    if ( NULL == hash )
    {
        cbHash = NCRYPT_SIZE_HASH_SHA2_256;
        return;
    }

    NCRYPT_HANDLE_HASH_CTX  hCtx    = NCRYPT_INVALID_HANDLE;
    NCRYPT_STATUS           status  = g_NcryptTable->Hash_CreateCtx( NCRYPT_HASH_ALG_SHA2_256,  &hCtx );
    if ( NCRYPT_SUCCESS == status )
    {
        status = g_NcryptTable->Hash_Update( hCtx, pData, cbData );
        if ( NCRYPT_SUCCESS == status )
        {
            status = g_NcryptTable->Hash_Final( hCtx, hash, &cbHash );
        }

        g_NcryptTable->Hash_DeleteCtx( hCtx );
    }

    if ( NCRYPT_SUCCESS != status )
    {
        throw CCryptoException( status, _T("Cannot calculate hash value") );
    }
}

static void HashPasswordWithSalt( const BYTE* pSecret, ULONG cbSecret, const BYTE* entropy, DWORD cbEntropy, UCHAR* hash, ULONG& cbHash )
{
    NCRYPT_HANDLE_HASH_CTX  hCtx    = NCRYPT_INVALID_HANDLE;
    NCRYPT_STATUS           status  = g_NcryptTable->Hash_CreateCtx( NCRYPT_HASH_ALG_SHA2_256,  &hCtx );
    if ( NCRYPT_SUCCESS == status )
    {
        status = g_NcryptTable->Hash_Update( hCtx, pSecret, cbSecret );
        if ( NCRYPT_SUCCESS == status )
        {
            status = g_NcryptTable->Hash_Update( hCtx, entropy, cbEntropy );
            if ( NCRYPT_SUCCESS == status )
            {
                status = g_NcryptTable->Hash_Final( hCtx, hash, &cbHash );
            }
        }

        g_NcryptTable->Hash_DeleteCtx( hCtx );
    }

    if ( NCRYPT_SUCCESS != status )
    {
        throw CCryptoException( status, _T("Cannot calculate hash value") );
    }
}

void CCipher::GeneratePassword( const BYTE* pSecret, ULONG cbSecret, const BYTE* entropy, DWORD cbEntropy, ULONG nCount, UCHAR* hash, ULONG& cbHash )
{
    if ( NULL == hash )
    {
        cbHash = NCRYPT_SIZE_HASH_SHA2_256;
        return;
    }

    if ( cbHash < NCRYPT_SIZE_HASH_SHA2_256 )
    {
        throw CZipCipherErrorException( _T("Buffer too small") );
    }

    BYTE            SecretKey[NCRYPT_SIZE_HASH_SHA2_256] = {0};
    ULONG           cbSecretKey = sizeof(SecretKey);
    if ( cbSecret <= cbSecretKey )
    {
        memcpy( SecretKey, pSecret, cbSecret );
    }
    else
    {
        GetHashValue( pSecret, cbSecret, SecretKey, cbSecretKey );
    }

    BYTE            CurrentEntropy[NCRYPT_SIZE_HASH_SHA2_256];
    ULONG           cbCurrentEntropy = sizeof(CurrentEntropy);
    
    HashPasswordWithSalt( SecretKey, sizeof(SecretKey), entropy, cbEntropy, CurrentEntropy, cbCurrentEntropy );

    if ( 1 < nCount )
    {
        for ( ULONG i=1; i<nCount; i++ )
        {
            BYTE    NewEntropy[NCRYPT_SIZE_HASH_SHA2_256];
            ULONG   cbNewEntropy = sizeof(NewEntropy);

            HashPasswordWithSalt( SecretKey, sizeof(SecretKey), CurrentEntropy, cbCurrentEntropy, NewEntropy, cbNewEntropy );

            for ( size_t j=0; j<sizeof(CurrentEntropy); j++ )
            {
                CurrentEntropy[j] = CurrentEntropy[j] ^ NewEntropy[j];
            }
        }
    }

    memcpy( hash, CurrentEntropy, cbCurrentEntropy );
    cbHash = cbCurrentEntropy;
}