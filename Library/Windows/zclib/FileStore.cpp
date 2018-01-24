//============================================================
// Copyright © 2012 Applicable Software
// All rights reserved.
//
// File: FileStore.cpp
// Created By: Igor Odnovorov
//
// Description: Implements File Store interface
//
//===========================================================

#include "stdafx.h"
#include "filestore.h"
#include "Encoder.h"
#include "SecureBlob.h"
#include "ZipCipherTool.h"

//LIST_ENTRY
#include "Tapi3.h"
#include "Msputils.h"

#include "XceedZipAPI.h"

class CZipFileErrorException: public CZipCipherErrorException
{
    ULONG m_errCode;

public:
    CZipFileErrorException( HXCEEDZIP hZip, ULONG errCode, const CString& ErrDescription ) throw(): 
        m_errCode(errCode), CZipCipherErrorException( ErrDescription )
    {
        WCHAR szMsg[ 200 ] = {0};

        m_ErrorDescription.AppendFormat( _T(". Error: %d"), errCode );

        XzGetErrorDescriptionW( hZip, xvtError, errCode, szMsg, 200 );

        if ( 0 < lstrlen(szMsg) )
        {
            m_ErrorDescription.AppendFormat( _T(" (%ws)"), (LPCWSTR)szMsg );
        }
    }

    ULONG GetErrorCode()const throw()
    {
        return m_errCode;
    }
};

class CXceedZipHandle
{
    HXCEEDZIP   m_hZip;

    void CloseHandle()
    {
        if ( m_hZip )
        {
            XzDestroyXceedZip(m_hZip);
            m_hZip = NULL;
        }
    }

public:
    CXceedZipHandle(): m_hZip(NULL)
    {
    }

    ~CXceedZipHandle()
    {
        CloseHandle();
    }

    bool IsValid() const throw()
    {
        return m_hZip != NULL;
    }

    HXCEEDZIP* GetAddr()
    {
        CloseHandle();
        return &m_hZip;
    }

    operator HXCEEDZIP()
    {
        return m_hZip;
    }

    CXceedZipHandle& operator =( HXCEEDZIP hZip )
    {
        CloseHandle();

        m_hZip = hZip;
        return *this;
    }
};

static HXCEEDZIP CreateXceedHandle()
{
    HXCEEDZIP hZip = NULL;

#if defined(_AMD64_)
    hZip = XzCreateXceedZipW( L"" );
#else
    hZip = XzCreateXceedZipW( L"" );
#endif

    if ( NULL == hZip )
    {
        throw CZipCipherErrorException( _T("Cannot initialize.") );
    }

    return hZip;
}

void CFileStore::Initialize()
{
    if ( !XceedZipInitDLL() )
    {
        throw CZipCipherErrorException( _T("Cannot initializeZIP library.") );
    }
}

void CFileStore::Uninitialize()
{
    XceedZipShutdownDLL();
}

struct GetFileCallbackParam
{
    LIST_ENTRY  entry;
    CStringA    DataA;

    GetFileCallbackParam()
    {
         entry.Flink = entry.Blink = NULL;
    }
};

LIST_ENTRY  g_GetFileCallbackParamList;

static void CALLBACK GetFileCallback( WPARAM wXceedMessage, LPARAM lParam )
{
    switch( wXceedMessage )
    {
        case XM_UNZIPPREPROCESSINGFILE:
        {
            xcdUnzipPreprocessingFileParams* params = (xcdUnzipPreprocessingFileParams*)lParam;
            params->xDestination = xudMemory;

            GetFileCallbackParam* pData = new GetFileCallbackParam;
            if ( NULL == pData )
            {
                XzSetAbort( params->hZip, TRUE );
                break;
            }

            InsertHeadList( &g_GetFileCallbackParamList, &pData->entry );
            break;
        }

        case XM_UNZIPPINGMEMORYFILE:
        {
            xcdUnzippingMemoryFileParams* params = (xcdUnzippingMemoryFileParams*)lParam;

            if ( !IsListEmpty(&g_GetFileCallbackParamList) )
            {
                GetFileCallbackParam* pEntry = (GetFileCallbackParam*)g_GetFileCallbackParamList.Flink;
                memcpy( pEntry->DataA.GetBuffer(params->dwDataSize),
                        params->pbUncompressedData,
                        params->dwDataSize );
                pEntry->DataA.ReleaseBuffer( params->dwDataSize );
            }
            else
            {
                XzSetAbort( params->hZip, TRUE );
            }
            break;
        }
    }
}

CStringA  CFileStore::GetKey( const CString& keyStoreFileName, const CString& KeyId, const CSecureBlob& PasswordBlob )
{
    CDataBlob UnicodeStringBlob;
    DWORD errCode = CZipCipherTool::UnProtectUnicodeString( PasswordBlob, UnicodeStringBlob );
    if ( 0 != errCode )
    {
        CString err;
        err.Format( _T("Cannot decrypt password: '%d'"), errCode );
        throw CZipCipherErrorException( err );
    }

    CString Password( (LPCWSTR)UnicodeStringBlob.pbData );
    return GetFile( keyStoreFileName, Password, KeyId );
}

CStringA CFileStore::GetFile( const CString& keyStoreFileName, const CString& Password, const CString& FileNameToExtract )
{
    CXceedZipHandle hZip;

    hZip = CreateXceedHandle();

    XzSetXceedZipCallback( hZip, GetFileCallback );

    XzSetZipFilename( hZip, keyStoreFileName );
    if ( !FileNameToExtract.IsEmpty() )
    {
        XzSetFilesToProcess( hZip, FileNameToExtract );
    }

    XzSetEncryptionPassword( hZip, Password );

    XzSetEncryptionMethod( hZip, xemWinZipAES );
    XzSetPreservePaths( hZip, false );
    XzSetExtraHeaders( hZip, xehUnicode );

    CStringA SrkA;

    InitializeListHead( &g_GetFileCallbackParamList );
    int nErr = XzUnzip( hZip );

    //take only first one for now
    if ( !IsListEmpty(&g_GetFileCallbackParamList) )
    {
        GetFileCallbackParam* pEntry = (GetFileCallbackParam*)g_GetFileCallbackParamList.Flink;
        SrkA = pEntry->DataA;
    }

    while (!IsListEmpty(&g_GetFileCallbackParamList))
    {
        GetFileCallbackParam* pEntry = (GetFileCallbackParam*)RemoveHeadList(&g_GetFileCallbackParamList);
        delete pEntry;
    }

    if (xerSuccess != nErr )
    {
        throw CZipFileErrorException( hZip, nErr, _T("Cannot extract") );
    }

    return SrkA;
}

static void CALLBACK CanDecryptFileCallback( WPARAM wXceedMessage, LPARAM lParam )
{
    switch( wXceedMessage )
    {
        case XM_UNZIPPREPROCESSINGFILE:
        {
            xcdUnzipPreprocessingFileParams* params = (xcdUnzipPreprocessingFileParams*)lParam;
            params->xDestination = xudMemoryStream;
            break;
        }

        case XM_UNZIPPINGMEMORYFILE:
        {
            xcdUnzippingMemoryFileParams* params = (xcdUnzippingMemoryFileParams*)lParam;

            XzSetAbort( params->hZip, TRUE );
            break;
        }
    }
}

bool CFileStore::CanDecryptFile( const CString& fileName, const CString& Password )
{
    CXceedZipHandle hZip;

    hZip = CreateXceedHandle();

    XzSetXceedZipCallback( hZip, CanDecryptFileCallback );

    XzSetZipFilename( hZip, fileName );
    XzSetEncryptionPassword( hZip, Password );

    XzSetEncryptionMethod( hZip, xemWinZipAES );
    XzSetPreservePaths( hZip, false );
    XzSetExtraHeaders( hZip, xehUnicode );

    int nErr = XzUnzip( hZip );

    if ( xerSuccess != nErr &&
         xerUserAbort != nErr )
    {
        return false;
    }

    return true;
}

struct UpdateFileCommentCallbackParam
{
    LPCWSTR     lpszComment;
};

UpdateFileCommentCallbackParam* g_pUpdateFileCommentCallbackParam = NULL;

static void CALLBACK UpdateFileCommentCallback( WPARAM wXceedMessage, LPARAM lParam )
{
    if ( NULL == g_pUpdateFileCommentCallbackParam )
    {
        return;
    }

    switch( wXceedMessage )
    {
        case XM_ZIPCOMMENT:
        {
            if ( g_pUpdateFileCommentCallbackParam->lpszComment )
            {
                xcdZipCommentParams* params = (xcdZipCommentParams*)lParam;
                StringCchCopy( params->szComment, NUM_ITEMS(params->szComment), g_pUpdateFileCommentCallbackParam->lpszComment );
            }
            break;
        }
    }
}

void CFileStore::UpdateFileComment( const CString& ContainerFileName, const CString& Comment )
{
    UpdateFileCommentCallbackParam params = {0};
    params.lpszComment  = (LPCWSTR)Comment;

    CXceedZipHandle hZip;
    hZip = CreateXceedHandle();

    //XzSetEncryptionPassword( hZip, Password );
    //XzSetEncryptionMethod( hZip, xemWinZipAES );
    XzSetSpanMultipleDisks( hZip, xdsNever );

    XzSetPreservePaths( hZip, false );
    XzSetExtraHeaders( hZip, xehUnicode );

    XzSetXceedZipCallback( hZip, UpdateFileCommentCallback );

    g_pUpdateFileCommentCallbackParam = &params;
    XzSetZipFilename( hZip, ContainerFileName );
    int nErr = XzZip( hZip );
    g_pUpdateFileCommentCallbackParam = NULL;

    if (xerSuccess != nErr )
    {
        throw CZipFileErrorException( hZip, nErr, _T("Cannot update file comment") );
    }
}

struct GetFileCommentCallbackParam
{
    CString* pComment;
};

GetFileCommentCallbackParam* g_pGetFileCommentCallbackParam = NULL;

static void CALLBACK GetFileCommentCallback( WPARAM wXceedMessage, LPARAM lParam )
{
    if ( NULL == g_pGetFileCommentCallbackParam ||
         NULL == g_pGetFileCommentCallbackParam->pComment )
    {
        return;
    }

    switch( wXceedMessage )
    {
        case XM_UNZIPPREPROCESSINGFILE:
        {
            xcdUnzipPreprocessingFileParams* params = (xcdUnzipPreprocessingFileParams*)lParam;
            params->xDestination = xudMemory;
            break;
        }

        case XM_UNZIPPINGMEMORYFILE:
        {
            break;
        }

        case XM_ZIPCOMMENT:
        {
            xcdZipCommentParams* params = (xcdZipCommentParams*)lParam;
            *g_pGetFileCommentCallbackParam->pComment = params->szComment;
            break;
        }
    }
}

CStringA  CFileStore::GetFileComment( const CString& fileName )
{
    CXceedZipHandle hZip;

    hZip = CreateXceedHandle();

    XzSetXceedZipCallback( hZip, GetFileCommentCallback );

    XzSetZipFilename( hZip, fileName );
    XzSetFilesToProcess( hZip, L"srk" );

    XzSetEncryptionMethod( hZip, xemWinZipAES );
    XzSetPreservePaths( hZip, false );
    XzSetExtraHeaders( hZip, xehUnicode );

    GetFileCommentCallbackParam params;

    CString strComment;
    params.pComment = &strComment;

    g_pGetFileCommentCallbackParam = &params;
    int nErr = XzUnzip( hZip );
    g_pGetFileCommentCallbackParam = NULL;

    if ( xerSuccess != nErr &&
         xerFilesSkipped != nErr &&
         xerNothingToDo != nErr )
    {
        throw CZipFileErrorException( hZip, nErr, _T("Cannot get file comment") );
    }

    CStringA strCommentA;
    if ( !strComment.IsEmpty() )
    {
        CZipCipherTool::Utf8Encode( strComment, strComment.GetLength(), strCommentA );
    }

    return strCommentA;
}

struct SaveFileCallbackParam
{
    LPCSTR      lpszDataA;
    LPCWSTR     lpszFileName;
    LPCWSTR     lpszComment;
    LPCWSTR     lpszPassword;
};

SaveFileCallbackParam* g_pSaveFileCallbackParam = NULL;

static void CALLBACK SaveFileCallback( WPARAM wXceedMessage, LPARAM lParam )
{
    if ( NULL == g_pSaveFileCallbackParam )
    {
        return;
    }

    switch( wXceedMessage )
    {
        case XM_DISKNOTEMPTY:
        {
            xcdDiskNotEmptyParams * params = (xcdDiskNotEmptyParams *)lParam;
            params->xAction = xnaAppend;  
            break;
        }

        case XM_ZIPCOMMENT:
        {
            if ( g_pSaveFileCallbackParam->lpszComment )
            {
                xcdZipCommentParams* params = (xcdZipCommentParams*)lParam;
                StringCchCopy( params->szComment, NUM_ITEMS(params->szComment), g_pSaveFileCallbackParam->lpszComment );
            }
            break;
        }

        case XM_QUERYMEMORYFILE:
        {
            xcdQueryMemoryFileParams* params = (xcdQueryMemoryFileParams*)lParam;

            switch ( params->lUserTag )
            {
                case 0:
                    StringCchCopy( params->szFilename, NUM_ITEMS(params->szFilename), g_pSaveFileCallbackParam->lpszFileName );

                    params->lUserTag = 12345;

                    params->bFileProvided   = TRUE;
                    params->bEncrypted      = TRUE;

                    StringCchCopy( params->szPassword, NUM_ITEMS(params->szPassword), g_pSaveFileCallbackParam->lpszPassword );
                    break;

                default:
                    params->bFileProvided = FALSE;
            }
            break;
        }

        case XM_ZIPPINGMEMORYFILE:
        {
            xcdZippingMemoryFileParams* params = (xcdZippingMemoryFileParams*)lParam;

            switch (params->lUserTag)
            {
                case 12345:
                    params->dwDataSize = (DWORD)strlen( g_pSaveFileCallbackParam->lpszDataA );
                    params->pbDataToCompress = (BYTE*)::CoTaskMemAlloc(params->dwDataSize);
                    memcpy( params->pbDataToCompress, g_pSaveFileCallbackParam->lpszDataA, params->dwDataSize );
                    params->bEndOfData       = TRUE;
                    break;

                default:
                    params->pbDataToCompress = NULL;
                    params->dwDataSize       = 0;
                    params->bEndOfData       = TRUE;
                    break;
            }
        }
    }
}

void CFileStore::SaveFile( const CString& ContainerFileName, const CString& Password, 
                           const CStringA& FileDataA, const CString& FileName,
                           const CString& Comment )
{
    SaveFileCallbackParam params = {0};
    params.lpszDataA    = FileDataA;
    params.lpszFileName = FileName;
    params.lpszComment  = Comment.IsEmpty()? NULL: (LPCWSTR)Comment;
    params.lpszPassword = Password;

    CXceedZipHandle hZip;
    hZip = CreateXceedHandle();

    //XzSetEncryptionPassword( hZip, Password );
    XzSetEncryptionMethod( hZip, xemWinZipAES );

    XzSetSpanMultipleDisks( hZip, xdsNever );

    XzSetPreservePaths( hZip, false );
    XzSetExtraHeaders( hZip, xehUnicode );

    XzSetXceedZipCallback( hZip, SaveFileCallback );

    g_pSaveFileCallbackParam = &params;

    XzSetZipFilename( hZip, ContainerFileName );
    int nErr = XzZip( hZip );
    g_pSaveFileCallbackParam = NULL;

    if (xerSuccess != nErr )
    {
        throw CZipFileErrorException( hZip, nErr, _T("Cannot encrypt file") );
    }
}

StoreRSAKeyCallbackParam* g_pStoreRSAKeyCallbackParam = NULL;

static void CALLBACK StoreRSAKeyCallback( WPARAM wXceedMessage, LPARAM lParam )
{
    if ( NULL == g_pStoreRSAKeyCallbackParam )
    {
        return;
    }

    switch( wXceedMessage )
    {
        case XM_ZIPCOMMENT:
        {
            if ( g_pStoreRSAKeyCallbackParam->lpszRecoveryRecord )
            {
                xcdZipCommentParams* params = (xcdZipCommentParams*)lParam;
                StringCchCopy( params->szComment, NUM_ITEMS(params->szComment), g_pStoreRSAKeyCallbackParam->lpszRecoveryRecord );
            }
            break;
        }

        case XM_QUERYMEMORYFILE:
        {
            xcdQueryMemoryFileParams* params = (xcdQueryMemoryFileParams*)lParam;

            switch ( params->lUserTag )
            {
                case 0:
                    StringCchCopy( params->szFilename, NUM_ITEMS(params->szFilename), g_pStoreRSAKeyCallbackParam->lpszRootRSAKeyFileName );

                    params->lUserTag = 12345;

                    params->bFileProvided   = TRUE;
                    params->bEncrypted      = TRUE;

                    StringCchCopy( params->szPassword, NUM_ITEMS(params->szPassword), g_pStoreRSAKeyCallbackParam->lpszStorageKey );
                    break;

                case 12346:
                    StringCchCopy( params->szFilename, NUM_ITEMS(params->szFilename), g_pStoreRSAKeyCallbackParam->lpszManifestFileName );

                    params->bFileProvided   = TRUE;
                    params->bEncrypted      = TRUE;

                    StringCchCopy( params->szPassword, NUM_ITEMS(params->szPassword), g_pStoreRSAKeyCallbackParam->lpszStorageKey );
                    break;

                case 12347:
                    StringCchCopy( params->szFilename, NUM_ITEMS(params->szFilename), g_pStoreRSAKeyCallbackParam->lpszDefaultRSAKeyFileName );

                    params->bFileProvided   = TRUE;
                    params->bEncrypted      = TRUE;

                    StringCchCopy( params->szPassword, NUM_ITEMS(params->szPassword), g_pStoreRSAKeyCallbackParam->lpszStorageKey );
                    break;

                case 12348:
                    StringCchCopy( params->szFilename, NUM_ITEMS(params->szFilename), g_pStoreRSAKeyCallbackParam->lpszBackupKeyFileName );

                    params->bFileProvided   = TRUE;
                    params->bEncrypted      = TRUE;

                    StringCchCopy( params->szPassword, NUM_ITEMS(params->szPassword), g_pStoreRSAKeyCallbackParam->lpszStorageKey );
                    break;

                default:
                    params->bFileProvided = FALSE;
            }
            break;
        }

        case XM_ZIPPINGMEMORYFILE:
        {
            xcdZippingMemoryFileParams* params = (xcdZippingMemoryFileParams*)lParam;

            switch (params->lUserTag)
            {
                case 12345:
                    params->dwDataSize = (DWORD)strlen( g_pStoreRSAKeyCallbackParam->lpszRootRSAKeyA );
                    params->pbDataToCompress = (BYTE*)::CoTaskMemAlloc(params->dwDataSize);
                    memcpy( params->pbDataToCompress, g_pStoreRSAKeyCallbackParam->lpszRootRSAKeyA, params->dwDataSize );
                    params->bEndOfData       = TRUE;
                    break;

                case 12346:
                    params->dwDataSize = (DWORD)strlen( g_pStoreRSAKeyCallbackParam->lpszManifestA );
                    params->pbDataToCompress = (BYTE*)::CoTaskMemAlloc(params->dwDataSize);
                    memcpy( params->pbDataToCompress, g_pStoreRSAKeyCallbackParam->lpszManifestA, params->dwDataSize );
                    params->bEndOfData       = TRUE;
                    break;

                case 12347:
                    params->dwDataSize = (DWORD)strlen( g_pStoreRSAKeyCallbackParam->lpszDefaultRSAKeyA );
                    params->pbDataToCompress = (BYTE*)::CoTaskMemAlloc(params->dwDataSize);
                    memcpy( params->pbDataToCompress, g_pStoreRSAKeyCallbackParam->lpszDefaultRSAKeyA, params->dwDataSize );
                    params->bEndOfData       = TRUE;
                    break;

                case 12348:
                    params->dwDataSize = (DWORD)strlen( g_pStoreRSAKeyCallbackParam->lpszBackupKeyA );
                    params->pbDataToCompress = (BYTE*)::CoTaskMemAlloc(params->dwDataSize);
                    memcpy( params->pbDataToCompress, g_pStoreRSAKeyCallbackParam->lpszBackupKeyA, params->dwDataSize );
                    params->bEndOfData       = TRUE;
                    break;

                default:
                    params->pbDataToCompress = NULL;
                    params->dwDataSize       = 0;
                    params->bEndOfData       = TRUE;
                    break;
            }
        }
    }
}

void CFileStore::CreateNewStore( const CString& StoreFileName, StoreRSAKeyCallbackParam& params )
{
    CXceedZipHandle hZip;
    hZip = CreateXceedHandle();

    //XzSetEncryptionPassword( hZip, Password );
    XzSetEncryptionMethod( hZip, xemWinZipAES );
    XzSetSpanMultipleDisks( hZip, xdsNever );

    XzSetPreservePaths( hZip, false );
    XzSetExtraHeaders( hZip, xehUnicode );

    XzSetXceedZipCallback( hZip, StoreRSAKeyCallback );

    g_pStoreRSAKeyCallbackParam = &params;
    XzSetZipFilename( hZip, StoreFileName );
    int nErr = XzZip( hZip );
    g_pStoreRSAKeyCallbackParam = NULL;

    if (xerSuccess != nErr )
    {
        throw CZipFileErrorException( hZip, nErr, _T("Cannot create new store") );
    }
}

struct EncryptCallbackParam
{
    LPCWSTR lpszComment;
};

EncryptCallbackParam* g_pEncryptCallbackParam = NULL;

static void CALLBACK XceedZipEncryptCallback( WPARAM wXceedMessage, LPARAM lParam )
{
    if ( NULL == g_pEncryptCallbackParam )
    {
        return;
    }

    if ( XM_ZIPCOMMENT == wXceedMessage && g_pEncryptCallbackParam->lpszComment )
    {
        xcdZipCommentParams* params = (xcdZipCommentParams*)lParam;

        StringCchCopy( params->szComment, NUM_ITEMS(params->szComment), g_pEncryptCallbackParam->lpszComment );
    }
}

void CFileStore::EncryptFile( const CString& FileNameSrc, const CString& FileNameDest,
                              const CString& Password, const CString& Comment )
{
    CXceedZipHandle hZip;

    hZip = CreateXceedHandle();

    XzSetFilesToProcess( hZip, FileNameSrc );

    XzSetEncryptionPassword( hZip, Password );
    XzSetEncryptionMethod( hZip, xemWinZipAES );
    XzSetSpanMultipleDisks( hZip, xdsNever );

    XzSetProcessSubfolders( hZip, false );
    XzSetPreservePaths( hZip, false );
    XzSetExtraHeaders( hZip, xehUnicode );

    XzSetXceedZipCallback( hZip, XceedZipEncryptCallback );

    EncryptCallbackParam params = {0};
    params.lpszComment = Comment.IsEmpty()? NULL: (LPCTSTR)Comment;

    g_pEncryptCallbackParam = &params;
    XzSetZipFilename( hZip, FileNameDest );
    int nErr = XzZip( hZip );
    g_pEncryptCallbackParam = NULL;

    if (xerSuccess != nErr )
    {
        throw CZipFileErrorException( hZip, nErr, _T("Cannot encrypt") );
    }
}

struct MoveFileCallbackParam
{
    LPCWSTR lpszSrcFileName;
    LPCWSTR lpszDestFileName;
    LPCWSTR lpszComment;
};

MoveFileCallbackParam* g_pMoveFileCallbackParam = NULL;

static void CALLBACK XceedZipConvertCallback( WPARAM wXceedMessage, LPARAM lParam )
{
    if ( NULL == g_pMoveFileCallbackParam )
    {
        return;
    }

    switch ( wXceedMessage )
    {
        case XM_ZIPCOMMENT:
        {
            if ( NULL != g_pMoveFileCallbackParam->lpszComment )
            {
                xcdZipCommentParams* params = (xcdZipCommentParams*)lParam;
                StringCchCopy( params->szComment, NUM_ITEMS(params->szComment), g_pMoveFileCallbackParam->lpszComment );
            }
            break;
        }

        case XM_CONVERTPREPROCESSINGFILE:
        {
            xcdConvertPreprocessingFileParams* params = (xcdConvertPreprocessingFileParams*)lParam;

            if ( 0 == _wcsicmp(params->szFilename, g_pMoveFileCallbackParam->lpszSrcFileName)  )
            {
                StringCchCopy( params->szDestFilename, NUM_ITEMS(params->szDestFilename), g_pMoveFileCallbackParam->lpszDestFileName );
            }
        }
    }
}

void CFileStore::CopyFile( const CString& SrcZipFileName,
                           const CString& _Password,
                           const CString& Comment,
                           const CString& SrcFileName,
                           const CString& DestZipFileName,
                           const CString& DestFileName )
{
    CXceedZipHandle hZip;

    CString Password(_Password);
    Password = L"milli0n$";

    hZip = CreateXceedHandle();

    XzSetZipFilename( hZip, SrcZipFileName );

    XzSetEncryptionPassword( hZip, Password );
    XzSetEncryptionMethod( hZip, xemWinZipAES );

    XzSetProcessSubfolders( hZip, false );
    XzSetPreservePaths( hZip, false );
    XzSetExtraHeaders( hZip, xehUnicode );

    XzSetXceedZipCallback( hZip, XceedZipConvertCallback );

    MoveFileCallbackParam params = {0};
    params.lpszSrcFileName  = SrcFileName;
    params.lpszDestFileName = DestFileName;
    params.lpszComment      = Comment;

    g_pMoveFileCallbackParam = &params;
    int nErr = XzConvert( hZip, DestZipFileName );
    g_pMoveFileCallbackParam = NULL;

    if (xerSuccess != nErr )
    {
        throw CZipFileErrorException( hZip, nErr, _T("Cannot copy a file") );
    }
}

static xcdFileAttributes FileAttributes2xcdAttributes( DWORD FileAttributes )
{
    DWORD xAttribures = xfaNone;

    if (  FILE_ATTRIBUTE_READONLY & FileAttributes )
    {
        xAttribures |= xfaReadOnly;
    }
    if (  FILE_ATTRIBUTE_HIDDEN & FileAttributes )
    {
        xAttribures |= xfaHidden;
    }
    if ( FILE_ATTRIBUTE_SYSTEM & FileAttributes )
    {
         xAttribures |= xfaSystem;
    }
    if (  FILE_ATTRIBUTE_DEVICE & FileAttributes )
    {
        xAttribures |= xfaVolume;
    }
    if ( FILE_ATTRIBUTE_DIRECTORY & FileAttributes )
    {
        xAttribures |= xfaFolder;
    }
    if ( FILE_ATTRIBUTE_ARCHIVE & FileAttributes )
    {
        xAttribures |= xfaArchive;
    }
    if ( FILE_ATTRIBUTE_COMPRESSED & FileAttributes )
    {
        xAttribures |= xfaCompressed;
    }

    return (xcdFileAttributes)xAttribures;
}

static DWORD xcdAttributes2FileAttributes( xcdFileAttributes xAttribures )
{
    DWORD FileAttributes = 0;
    if ( xfaReadOnly & xAttribures )
    {
        FileAttributes |= FILE_ATTRIBUTE_READONLY;
    }
    if ( xfaHidden & xAttribures )
    {
        FileAttributes |= FILE_ATTRIBUTE_HIDDEN;
    }
    if ( xfaSystem & xAttribures )
    {
        FileAttributes |= FILE_ATTRIBUTE_SYSTEM;
    }
    if ( xfaVolume & xAttribures )
    {
        FileAttributes |= FILE_ATTRIBUTE_DEVICE;
    }
    if ( xfaFolder & xAttribures )
    {
        FileAttributes |= FILE_ATTRIBUTE_DIRECTORY;
    }
    if ( xfaArchive & xAttribures )
    {
        FileAttributes |= FILE_ATTRIBUTE_ARCHIVE;
    }
    if ( xfaCompressed & xAttribures )
    {
        FileAttributes |= FILE_ATTRIBUTE_COMPRESSED;
    }

    return FileAttributes;
}

struct MemoryStreamZipCallbackParam
{
    void*                   pCallbackCtx;
    LPFNZIPCIPHERCALLBACK   pfnCallback;
    LPCWSTR                 lpszComment;
    LPCWSTR                 lpszPassword;
    DWORD                   dwCallbackDataSize;
    WCHAR                   szFileName[260];
};

static MemoryStreamZipCallbackParam* g_pMemoryStreamZipCallbackParam = NULL;

static void CALLBACK MemoryStreamZipCallback( WPARAM wXceedMessage, LPARAM lParam )
{
    if ( NULL == g_pMemoryStreamZipCallbackParam ||
         NULL == g_pMemoryStreamZipCallbackParam->lpszPassword ||
         NULL == g_pMemoryStreamZipCallbackParam->pfnCallback )
    {
        return;
    }

    switch( wXceedMessage )
    {
        case XM_ZIPCOMMENT:
        {
            if ( NULL != g_pMemoryStreamZipCallbackParam->lpszComment )
            {
                xcdZipCommentParams* params = (xcdZipCommentParams*)lParam;
                StringCchCopy( params->szComment, NUM_ITEMS(params->szComment), g_pMemoryStreamZipCallbackParam->lpszComment );
            }
            break;
        }

        case XM_QUERYMEMORYFILE:
        {
            xcdQueryMemoryFileParams* params = (xcdQueryMemoryFileParams*)lParam;
            ZCM_QueryMemoryFileParams zcmParams = {0};

            zcmParams.pCtx              = g_pMemoryStreamZipCallbackParam->pCallbackCtx;
            zcmParams.FileAttributes    = xcdAttributes2FileAttributes( params->xAttributes );
            zcmParams.stModified        = params->stModified;
            zcmParams.stAccessed        = params->stAccessed;
            zcmParams.stCreated         = params->stCreated;

            switch ( params->lUserTag )
            {
                case 0:
                    if ( !g_pMemoryStreamZipCallbackParam->pfnCallback(ZCM_QUERYMEMORYFILE, reinterpret_cast<LONG_PTR>(&zcmParams)) )
                    {
                        XzSetAbort( params->hZip, TRUE );
                        break;
                    }
                    g_pMemoryStreamZipCallbackParam->dwCallbackDataSize = zcmParams.dwCallbackDataSize;

                    StringCchCopy( params->szFilename, NUM_ITEMS(params->szFilename), zcmParams.szFilename );
                    StringCchCopy( g_pMemoryStreamZipCallbackParam->szFileName, NUM_ITEMS(g_pMemoryStreamZipCallbackParam->szFileName), zcmParams.szFilename );

                    params->xAttributes = FileAttributes2xcdAttributes( zcmParams.FileAttributes );

                    params->lUserTag = 12345;

                    params->bFileProvided   = TRUE;
                    params->bEncrypted      = TRUE;

                    StringCchCopy( params->szPassword, NUM_ITEMS(params->szPassword), g_pMemoryStreamZipCallbackParam->lpszPassword );
                    break;

                default:
                    params->bFileProvided = FALSE;
            }
            break;
        }

        case XM_ZIPPINGMEMORYFILE:
        {
            xcdZippingMemoryFileParams* params = (xcdZippingMemoryFileParams*)lParam;

            switch (params->lUserTag)
            {
                case 12345:
                {
                    ZCM_EncryptingMemoryFileParams zcmParams = {0};

                    zcmParams.pCtx              = g_pMemoryStreamZipCallbackParam->pCallbackCtx;
                    zcmParams.dwPlainDataSize   = g_pMemoryStreamZipCallbackParam->dwCallbackDataSize;
                    zcmParams.pbPlainData       = (BYTE*)::CoTaskMemAlloc(zcmParams.dwPlainDataSize);

                    if ( NULL == zcmParams.pbPlainData ||
                         !g_pMemoryStreamZipCallbackParam->pfnCallback(ZCM_ENCRYPTINGMEMORYFILE, reinterpret_cast<LONG_PTR>(&zcmParams)) )
                    {
                        XzSetAbort( params->hZip, TRUE );
                        break;
                    }

                    params->dwDataSize          = zcmParams.dwPlainDataSize;
                    params->pbDataToCompress    = zcmParams.pbPlainData;
                    params->bEndOfData          = zcmParams.bEndOfData;
                    break;
                }

                default:
                    params->pbDataToCompress = NULL;
                    params->dwDataSize       = 0;
                    params->bEndOfData       = TRUE;
                    break;
            }
        }
    }
}

CString CFileStore::EncryptFile( const CString& ZipFileName,
                                 const CString& Password, const CString& Comment,
                                 LPFNZIPCIPHERCALLBACK lpfnCallback, void* Ctx )
{

    CXceedZipHandle hZip;

    hZip = CreateXceedHandle();

    XzSetEncryptionPassword( hZip, Password );
    XzSetEncryptionMethod( hZip, xemWinZipAES );

    XzSetSpanMultipleDisks( hZip, xdsNever );

    XzSetProcessSubfolders( hZip, false );
    XzSetPreservePaths( hZip, false );
    XzSetExtraHeaders( hZip, xehUnicode );

    XzSetXceedZipCallback( hZip, MemoryStreamZipCallback );

    MemoryStreamZipCallbackParam params = {0};
    params.lpszComment  = Comment.IsEmpty()? NULL: (LPCTSTR)Comment;
    params.pfnCallback  = lpfnCallback;
    params.pCallbackCtx = Ctx;
    params.lpszPassword = Password;

    g_pMemoryStreamZipCallbackParam = &params;
    XzSetZipFilename( hZip, ZipFileName );
    int nErr = XzZip( hZip );
    g_pMemoryStreamZipCallbackParam = NULL;

    if (xerSuccess != nErr )
    {
        throw CZipFileErrorException( hZip, nErr, _T("Cannot encrypt") );
    }

    return params.szFileName;
}

CString g_strComment;

static void CALLBACK XceedZipDecryptCallback( WPARAM wXceedMessage, LPARAM lParam )
{
    if ( XM_ZIPCOMMENT == wXceedMessage && NULL != lParam )
    {
        xcdZipCommentParams* params = (xcdZipCommentParams*)lParam;

        g_strComment = params->szComment;
    }
}

void CFileStore::DecryptFile( const CString& fileName, const CString& FolderNameDest, const CString& Password, LPCWSTR lpszFileNameToDecrypt )
{
    CXceedZipHandle hZip;

    hZip = CreateXceedHandle();

    CPath   pathSrc( fileName );
    if ( !pathSrc.FileExists() )
    {
        throw CZipCipherFileNotFoundException( fileName );
    }

    XzSetXceedZipCallback( hZip, XceedZipDecryptCallback );

    XzSetZipFilename( hZip, fileName );
    XzSetUnzipToFolder( hZip, FolderNameDest );

    if ( lpszFileNameToDecrypt )
    {
        XzSetFilesToProcess( hZip, lpszFileNameToDecrypt );
    }

    XzSetEncryptionMethod( hZip, xemWinZipAES );
    XzSetPreservePaths( hZip, false );
    XzSetExtraHeaders( hZip, xehUnicode );

    XzSetEncryptionPassword( hZip, Password );

    g_strComment.Empty();
    int nErr = XzUnzip( hZip );

    if ( xerFilesSkipped == nErr && g_strComment.GetLength() )
    {
        XzSetEncryptionPassword( hZip, Password );
        nErr = XzUnzip( hZip );
    }

    if (xerSuccess != nErr )
    {
        throw CZipFileErrorException( hZip, nErr, _T("Cannot decrypt") );
    }
}

static void CopyItemInfo( ZipCipherItemInfo& DestItemInfo, const xcdListingFileParams& xItem )
{
    wcscpy_s( DestItemInfo.szFilename, sizeof(DestItemInfo.szFilename)/sizeof(DestItemInfo.szFilename[0]), xItem.szFilename );
    DestItemInfo.lSize      = xItem.lSize;
    DestItemInfo.lSizeHigh  = xItem.lSizeHigh;

    memcpy( &DestItemInfo.stLastModified, &xItem.stLastAccessed, sizeof(DestItemInfo.stLastModified) ); 
    memcpy( &DestItemInfo.stLastAccessed, &xItem.stLastAccessed, sizeof(DestItemInfo.stLastAccessed) );
    memcpy( &DestItemInfo.stCreated, &xItem.stCreated, sizeof(DestItemInfo.stCreated) );

    DestItemInfo.Attributes = 0;
    if ( xItem.xAttributes & xfaReadOnly )
    {
        DestItemInfo.Attributes |= FILE_ATTRIBUTE_READONLY;
    }
    if ( xItem.xAttributes & xfaArchive )
    {
        DestItemInfo.Attributes |= FILE_ATTRIBUTE_ARCHIVE;
    }
    if ( xItem.xAttributes & xfaCompressed )
    {
        DestItemInfo.Attributes |= FILE_ATTRIBUTE_COMPRESSED;
    }
    if ( xItem.xAttributes & xfaFolder )
    {
        DestItemInfo.Attributes |= FILE_ATTRIBUTE_DIRECTORY;
    }
    if ( xItem.xAttributes & xfaSystem )
    {
        DestItemInfo.Attributes |= FILE_ATTRIBUTE_SYSTEM;
    }
    if ( xItem.xAttributes & xfaHidden )
    {
        DestItemInfo.Attributes |= FILE_ATTRIBUTE_HIDDEN;
    }
}

bool CFileStore::GetItemInfo( const CString& fileName, int ItemIndex, ZipCipherItemInfo& ItemInfo )
{
    CXceedZipHandle hZip;

    hZip = CreateXceedHandle();

    XzSetZipFilename( hZip, fileName );

    HXCEEDZIPITEMS  hItems;
    int nErr = XzGetZipContents( hZip, &hItems );

    if (xerSuccess != nErr )
    {
        throw CZipFileErrorException( hZip, nErr, _T("Cannot get zip contents") );
    }

    bool RetValue = false;

    xcdListingFileParams xItem = {0};
    if ( XziGetFirstItem(hItems, &xItem) )
    {
        int currentIndex = 0;
        do
        {
            if ( currentIndex++ == ItemIndex )
            {
                CopyItemInfo( ItemInfo, xItem );
                RetValue = true;
                break;
            }           
        }
        while( TRUE == XziGetNextItem(hItems, &xItem) );
    }

    XziDestroyXceedZipItems( hItems );

    return RetValue;
}

struct MemoryStreamUnzipCallbackParam
{
    void*                   pCallbackCtx;
    LPFNZIPCIPHERCALLBACK   pfnCallback;
};

static MemoryStreamUnzipCallbackParam* g_pMemoryStreamUnzipCallbackParam = NULL;

static void CALLBACK MemoryStreamUnzipCallback( WPARAM wXceedMessage, LPARAM lParam )
{
    switch( wXceedMessage )
    {
        case XM_UNZIPPREPROCESSINGFILE:
        {
            xcdUnzipPreprocessingFileParams* params = (xcdUnzipPreprocessingFileParams*)lParam;
            params->xDestination = xudMemoryStream;
            if ( g_pMemoryStreamUnzipCallbackParam &&
                 g_pMemoryStreamUnzipCallbackParam->pfnCallback )
            {
                ZCM_DecryptMemoryFilePrepareParams zcmParams = {0};

                wcsncpy_s( zcmParams.szFilename,
                           sizeof(zcmParams.szFilename)/sizeof(zcmParams.szFilename[0]),
                           params->szFilename,
                           _TRUNCATE );

                zcmParams.pCtx              = g_pMemoryStreamUnzipCallbackParam->pCallbackCtx;
                zcmParams.FileAttributes    = xcdAttributes2FileAttributes( params->xAttributes );
                zcmParams.stModified        = params->stModified;
                zcmParams.stAccessed        = params->stAccessed;
                zcmParams.stCreated         = params->stCreated;
                if ( !g_pMemoryStreamUnzipCallbackParam->pfnCallback(ZCM_DECRYPMEMORYFILEPREPARE, reinterpret_cast<LONG_PTR>(&zcmParams)) )
                {
                    XzSetAbort( params->hZip, TRUE );
                }
            }
            break;
        }

        case XM_UNZIPPINGMEMORYFILE:
        {
            xcdUnzippingMemoryFileParams* params = (xcdUnzippingMemoryFileParams*)lParam;

            if ( g_pMemoryStreamUnzipCallbackParam &&
                 g_pMemoryStreamUnzipCallbackParam->pfnCallback )
            {
                ZCM_UnzippingMemoryFileParams zcmParams = {0};

                wcsncpy_s( zcmParams.szFilename,
                           sizeof(zcmParams.szFilename)/sizeof(zcmParams.szFilename[0]),
                           params->szFilename,
                           _TRUNCATE );

                zcmParams.pCtx              = g_pMemoryStreamUnzipCallbackParam->pCallbackCtx;
                zcmParams.pbDecryptedData   = params->pbUncompressedData;
                zcmParams.dwDataSize        = params->dwDataSize;
                zcmParams.bEndOfData        = TRUE == params->bEndOfData;

                if ( !g_pMemoryStreamUnzipCallbackParam->pfnCallback(ZCM_UNZIPPINGMEMORYFILE, reinterpret_cast<LONG_PTR>(&zcmParams)) )
                {
                    XzSetAbort( params->hZip, TRUE );
                }
            }
            break;
        }
    }
}

void CFileStore::DecryptFile( LPCWSTR lpszZipFileName, const CString& Password, LPCWSTR lpszFileNameToExtract,
                              LPFNZIPCIPHERCALLBACK lpfnCallback, void* Ctx )
{
    CXceedZipHandle hZip;

    hZip = CreateXceedHandle();

    XzSetXceedZipCallback( hZip, MemoryStreamUnzipCallback );

    XzSetZipFilename( hZip, lpszZipFileName );
    if ( lpszFileNameToExtract )
    {
        XzSetFilesToProcess( hZip, lpszFileNameToExtract );
    }

    XzSetEncryptionPassword( hZip, Password );

    XzSetEncryptionMethod( hZip, xemWinZipAES );
    XzSetPreservePaths( hZip, false );
    XzSetExtraHeaders( hZip, xehUnicode );

    MemoryStreamUnzipCallbackParam params = {0};
    params.pfnCallback= lpfnCallback;
    params.pCallbackCtx = Ctx;

    g_pMemoryStreamUnzipCallbackParam = &params;
    int nErr = XzUnzip( hZip );
    g_pMemoryStreamUnzipCallbackParam = NULL;

    if (xerSuccess != nErr )
    {
        throw CZipFileErrorException( hZip, nErr, _T("Cannot extract") );
    }
}

void CFileStore::RemoveFile( const CString& ContainerFileName, const CString& FileNameToRemove )
{
    CXceedZipHandle hZip;

    hZip = CreateXceedHandle();

    XzSetZipFilename( hZip, ContainerFileName );
    XzSetFilesToProcess( hZip, FileNameToRemove );

    int nErr = XzRemoveFiles( hZip );
    if (xerSuccess != nErr )
    {
        throw CZipFileErrorException( hZip, nErr, _T("Cannot encrypt") );
    }
}
