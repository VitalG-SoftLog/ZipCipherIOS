#pragma once
//============================================================
// Copyright © 2012 Applicable Software
// All rights reserved.
//
// File: FileStore.h
// Created By: Igor Odnovorov
//
// Description: Defines File Store interface
//
//===========================================================

#include "zipciphercallback.h"

struct StoreRSAKeyCallbackParam
{
    LPCSTR      lpszRootRSAKeyA;
    LPCWSTR     lpszRootRSAKeyFileName;
    LPCSTR      lpszBackupKeyA;
    LPCWSTR     lpszBackupKeyFileName;
    LPCSTR      lpszDefaultRSAKeyA;
    LPCWSTR     lpszDefaultRSAKeyFileName;
    LPCWSTR     lpszRecoveryRecord;
    LPCWSTR     lpszStorageKey;
    LPCSTR      lpszManifestA;
    LPCWSTR     lpszManifestFileName;
};

typedef struct _ZipCipherItemInfo
{
    WCHAR       szFilename[ 260 ]; 
    LONG        lSize; 
    LONG        lSizeHigh;
    DWORD       Attributes; 
    SYSTEMTIME  stLastModified; 
    SYSTEMTIME  stLastAccessed; 
    SYSTEMTIME  stCreated; 

} ZipCipherItemInfo;

class CSecureBlob;

class CFileStore
{
public:
    static void     Initialize();
    static void     Uninitialize();

    static CStringA  GetKey( const CString& keyStoreFileName, const CString& KeyId, const CSecureBlob& PasswordBlob );

    static CStringA  GetFile( const CString& keyStoreFileName, const CString& Password, const CString& FileNameToExtract=_T("") );

    static CStringA  GetFileComment( const CString& keyStoreFileName );

    static void      SaveFile( const CString& ContainerFileName, const CString& Password, 
                               const CStringA& FileDataA, const CString& FileName,
                               const CString& Comment = _T("") );

    static void CreateNewStore( const CString& StoreFileName, StoreRSAKeyCallbackParam&  );

    static void EncryptFile( const CString& FileNameSrc, const CString& FileNameDest,
                             const CString& Password, const CString& Comment );
    static CString EncryptFile( const CString& ZipFileName,
                                const CString& Password, const CString& Comment,
                                LPFNZIPCIPHERCALLBACK lpfnCallback, void* Ctx );

    static void DecryptFile( const CString& fileName,
                             const CString& FolderNameDest,
                             const CString& Password,
                             LPCWSTR lpszFileNameToDecrypt=NULL );
    static void DecryptFile( LPCWSTR lpszZipFileName,
                             const CString& Password,
                             LPCWSTR lpszFileNameToExtract,
                             LPFNZIPCIPHERCALLBACK lpfnCallback,
                             void* Ctx );

    static bool CanDecryptFile( const CString& fileName, const CString& Password );

    static void UpdateFileComment( const CString& ContainerFileName, const CString& Comment );

    static bool GetItemInfo( const CString& fileName, int ItemIndex, ZipCipherItemInfo& ItemInfo );

    static void CopyFile( const CString& SrcZipFileName,
                          const CString& Password,
                          const CString& Comment,
                          const CString& SrcFileName,
                          const CString& DestZipFileName,
                          const CString& DestFileName );

    static void RemoveFile( const CString& ContainerFileName, const CString& FileNameToRemove );
};