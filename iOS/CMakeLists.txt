PROJECT(p7zip)

cmake_minimum_required(VERSION 2.8)

INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP
					${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/include_windows
					${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/myWindows
					${CMAKE_CURRENT_SOURCE_DIR}/p7zip/C
					)

SET(src
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/myWindows/myGetTickCount.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/myWindows/wine_date_and_time.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/myWindows/myAddExeFlag.cpp 
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/myWindows/mySplitCommandLine.cpp
	
	
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/Common/CommandLineParser.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/Common/CRC.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/Common/IntToString.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/Common/ListFileUtils.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/Common/StdInStream.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/Common/StdOutStream.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/Common/MyString.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/Common/StringConvert.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/Common/StringToInt.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/Common/UTFConvert.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/Common/MyWindows.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/Common/MyVector.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/Common/Wildcard.cpp
	
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/Windows/Error.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/Windows/FileDir.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/Windows/FileFind.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/Windows/FileIO.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/Windows/FileName.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/Windows/PropVariant.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/Windows/PropVariantConversions.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/Windows/Synchronization.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/Windows/System.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/Windows/Time.cpp
	
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Common/CreateCoder.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Common/CWrappers.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Common/FilePathAutoRename.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Common/FileStreams.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Common/FilterCoder.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Common/InBuffer.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Common/InOutTempBuffer.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Common/LimitedStreams.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Common/LockedStream.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Common/MemBlocks.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Common/MethodId.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Common/MethodProps.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Common/OffsetStream.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Common/OutBuffer.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Common/OutMemStream.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Common/ProgressMt.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Common/ProgressUtils.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Common/StreamBinder.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Common/StreamObjects.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Common/StreamUtils.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Common/VirtThread.cpp

#	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/UI/Console/BenchCon.cpp
#	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/UI/Console/ConsoleClose.cpp
#	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/UI/Console/ExtractCallbackConsole.cpp
#	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/UI/Console/List.cpp
#	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/UI/Console/Main.cpp
#	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/UI/Console/MainAr.cpp
#	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/UI/Console/OpenCallbackConsole.cpp
#	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/UI/Console/PercentPrinter.cpp
#	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/UI/Console/UpdateCallbackConsole.cpp
#	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/UI/Console/UserInputUtils.cpp
	
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/UI/Common/ArchiveCommandLine.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/UI/Common/ArchiveExtractCallback.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/UI/Common/ArchiveOpenCallback.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/UI/Common/Bench.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/UI/Common/DefaultName.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/UI/Common/EnumDirItems.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/UI/Common/Extract.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/UI/Common/ExtractingFilePath.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/UI/Common/LoadCodecs.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/UI/Common/OpenArchive.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/UI/Common/PropIDUtils.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/UI/Common/SetProperties.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/UI/Common/SortUtils.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/UI/Common/TempFiles.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/UI/Common/Update.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/UI/Common/UpdateAction.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/UI/Common/UpdateCallback.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/UI/Common/UpdatePair.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/UI/Common/UpdateProduce.cpp
	
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/Bz2Handler.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/DeflateProps.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/GzHandler.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/LzmaHandler.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/PpmdHandler.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/SplitHandler.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/XzHandler.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/ZHandler.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/Common/CoderMixer2.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/Common/CoderMixer2MT.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/Common/CrossThreadProgress.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/Common/DummyOutStream.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/Common/FindSignature.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/Common/HandlerOut.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/Common/InStreamWithCRC.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/Common/ItemNameUtils.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/Common/MultiStream.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/Common/OutStreamWithCRC.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/Common/ParseProperties.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/7z/7zCompressionMode.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/7z/7zDecode.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/7z/7zEncode.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/7z/7zExtract.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/7z/7zFolderInStream.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/7z/7zFolderOutStream.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/7z/7zHandler.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/7z/7zHandlerOut.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/7z/7zHeader.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/7z/7zIn.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/7z/7zOut.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/7z/7zProperties.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/7z/7zSpecStream.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/7z/7zUpdate.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/7z/7zRegister.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/Cab/CabBlockInStream.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/Cab/CabHandler.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/Cab/CabHeader.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/Cab/CabIn.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/Cab/CabRegister.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/Tar/TarHandler.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/Tar/TarHandlerOut.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/Tar/TarHeader.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/Tar/TarIn.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/Tar/TarOut.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/Tar/TarUpdate.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/Tar/TarRegister.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/Zip/ZipAddCommon.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/Zip/ZipHandler.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/Zip/ZipHandlerOut.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/Zip/ZipHeader.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/Zip/ZipIn.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/Zip/ZipItem.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/Zip/ZipOut.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/Zip/ZipUpdate.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Archive/Zip/ZipRegister.cpp
	
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/Bcj2Coder.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/Bcj2Register.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/BcjCoder.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/BcjRegister.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/BitlDecoder.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/BranchCoder.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/BranchMisc.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/BranchRegister.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/ByteSwap.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/BZip2Crc.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/BZip2Decoder.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/BZip2Encoder.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/BZip2Register.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/CopyCoder.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/CopyRegister.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/Deflate64Register.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/DeflateDecoder.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/DeflateEncoder.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/DeflateRegister.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/DeltaFilter.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/ImplodeDecoder.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/ImplodeHuffmanDecoder.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/Lzma2Decoder.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/Lzma2Encoder.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/Lzma2Register.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/LzmaDecoder.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/LzmaEncoder.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/LzmaRegister.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/LzOutWindow.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/Lzx86Converter.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/LzxDecoder.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/PpmdDecoder.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/PpmdEncoder.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/PpmdRegister.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/PpmdZip.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/QuantumDecoder.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/ShrinkDecoder.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Compress/ZDecoder.cpp
	
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Crypto/7zAes.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Crypto/7zAesRegister.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Crypto/HmacSha1.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Crypto/MyAes.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Crypto/Pbkdf2HmacSha1.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Crypto/RandGen.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Crypto/Sha1.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Crypto/WzAes.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Crypto/ZipCrypto.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/CPP/7zip/Crypto/ZipStrong.cpp
	
	
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/C/7zStream.c
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/C/Aes.c
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/C/Alloc.c
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/C/Bra.c
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/C/Bra86.c
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/C/BraIA64.c
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/C/BwtSort.c
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/C/Delta.c
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/C/HuffEnc.c
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/C/LzFind.c
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/C/LzFindMt.c
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/C/Lzma2Dec.c
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/C/Lzma2Enc.c
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/C/LzmaDec.c
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/C/LzmaEnc.c
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/C/MtCoder.c
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/C/Ppmd7.c
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/C/Ppmd7Dec.c
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/C/Ppmd7Enc.c
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/C/Ppmd8.c
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/C/Ppmd8Dec.c
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/C/Ppmd8Enc.c
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/C/Sha256.c
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/C/Sort.c
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/C/Threads.c
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/C/Xz.c
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/C/XzCrc64.c
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/C/XzDec.c
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/C/XzEnc.c
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/C/XzIn.c
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/C/7zCrc.c
	${CMAKE_CURRENT_SOURCE_DIR}/p7zip/C/7zCrcOpt.c
	)
	


#------------------------------------------------------------------------------
# iOS specific	
#------------------------------------------------------------------------------
cmake_policy(SET CMP0015 NEW)
cmake_policy(SET CMP0016 NEW)	

add_definitions(-D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -DNDEBUG -D_REENTRANT -DENV_UNIX -D_7ZIP_LARGE_PAGES -DBREAK_HANDLER -DUNICODE -D_UNICODE)
	
SET (SDKVER "5.1")
SET (DEVROOT "/Applications/Xcode.app/Contents/Developer/Platforms/${SDKVER}/Developer")
SET (SDKROOT "${DEVROOT}/SDKs/iPhoneOS${SDKVER}.sdk")
SET (CMAKE_OSX_SYSROOT "${SDKROOT}")
SET (CMAKE_OSX_ARCHITECTURES "$(ARCHS_UNIVERSAL_IPHONE_OS)")

set(CMAKE_CXX_FLAGS "-x objective-c++")
set(CMAKE_EXE_LINKER_FLAGS
    "-framework CoreGraphics -framework UIKit"
)
link_directories(\${HOME}/\${SDKROOT}/lib)
#------------------------------------------------------------------------------

#set(MACOSX_BUNDLE_GUI_IDENTIFIER "com.mycompany.\${PRODUCT_NAME:identifier}")
#set(APP_TYPE MACOSX_BUNDLE)
	
	
ADD_LIBRARY(${PROJECT_NAME} STATIC ${src})	
TARGET_LINK_LIBRARIES(${PROJECT_NAME} pthread)

#set_target_properties(${PROJECT_NAME} PROPERTIES XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "iPhone Developer: My Name")

