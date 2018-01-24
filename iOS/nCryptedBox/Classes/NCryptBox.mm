//============================================================
//
// Copyright (c) nCrypted Cloud, 2012. All Rights Reserved.
//
// File: NCryptBox.m
// Created By: Oleg Lavronov on 8/11/12.
//
// Description: Namespace for nCrypted Cloud functions.
//
//===========================================================
#include "tinyxml.h"

#import <CoreFoundation/CFUUID.h>
#import "NCryptBox.h"
#import "NCryptKey.h"
#import "NCryptException.h"
#import "SecKeyWrapper.h"

//#import "Rsa.h"

extern "C" {
#import "Log.h"
}

@implementation NCryptBox

@synthesize delegate;

NSString* kReadmeContent = @"\r\nThis document has been protected by the nCryptedBox"
"cloud security service.\r\n"
"\r\nIf you wish to view this file, please goto our website\r\n"
"at http://www.ncryptedbox.com for details.\r\n";

@synthesize keys;
@synthesize versionApplication;
@synthesize defaultKey = _defaultKey;
@synthesize defaultKeyValue = _defaultKeyValue;
@synthesize backupKey  = _backupKey;
//@synthesize backupKeyValue = _backupKeyValue;
@synthesize storageKeyID = _storageKeyID;
@synthesize storageKeyValue = _storageKeyValue;


- (id) init {
	if (self= [super init]) {
        keys = [[NSMutableDictionary alloc] init];
        versionApplication = @"(unknown)";
        _defaultKey = @"";
        _defaultKeyValue = @"";
        _backupKey = @"";
        //_backupKeyValue = @"";
        _storageKeyID = @"";
        _storageKeyValue = @"";
	}
	return self;
}


- (void)dealloc
{
    [keys release];
    [super dealloc];
}

+ (BOOL) checkExtension:(NSString*)filePath
{
    if ([[filePath pathExtension] caseInsensitiveCompare:@"zip"] == NSOrderedSame) {
        if ([[[filePath stringByDeletingPathExtension] pathExtension] length] != 0) {
            return YES;
        }
    }
    return NO;
}

+ (NSString *)generateUUIDString
{
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidString = (NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    [uuidString autorelease];
    CFRelease(uuid);
    return uuidString;
}

//    rc/r/rk
- (NSString*) generateComment:(NSString*)keyID backupKey:(NSString*)backupKeyID
{

    NSString* version = [NSString stringWithFormat:@"\nCreated by nCryptedBox Version %@\n"
                         "Copyright (C) nCrypted Cloud. All rights reserved.\n", versionApplication];
    TiXmlDocument* xmlDocument = new TiXmlDocument;
    TiXmlPrinter* xmlPrinter = new TiXmlPrinter;
    TiXmlElement* root = new TiXmlElement("zipcipher");

    TiXmlText* header = new TiXmlText([version cStringUsingEncoding:NSUTF8StringEncoding]);
    header->SetCDATA(true);
    xmlDocument->LinkEndChild(root);
    root->LinkEndChild(header);

    TiXmlElement* nodeRecoveryCollection = new TiXmlElement("rc");
    NSString* entropy = [NSString stringWithFormat:@"{%@}",[NCryptBox generateUUIDString]];
    nodeRecoveryCollection->SetAttribute("rcid", [entropy UTF8String]);
    TiXmlElement* nodeRecovery = new TiXmlElement("r");
    TiXmlElement* nodeRecoveryKey = new TiXmlElement("rk");
    TiXmlText* textRecoveryKey = new TiXmlText([keyID UTF8String]);

    nodeRecoveryKey->LinkEndChild(textRecoveryKey);
    nodeRecovery->LinkEndChild(nodeRecoveryKey);
    nodeRecoveryCollection->LinkEndChild(nodeRecovery);

    NCryptKey* backupKey = nil;
    if ([backupKeyID length] == 0 ) {
        NCryptKey* keyItem = [keys objectForKey:keyID];
        if (keyItem) {
            backupKey = [self.keys objectForKey:keyItem.ownerbackupkey];
        } else {
            backupKey = [self.keys objectForKey:backupKeyID];
        }
        //        backupKey = [self.keys objectForKey:self.backupKey];
    } else {
        NCryptKey* keyItem = [keys objectForKey:keyID];
        if (keyItem) {
            backupKey = [self.keys objectForKey:keyItem.ownerbackupkey];
        } else {
            backupKey = [self.keys objectForKey:backupKeyID];
        }
    }

    if (backupKey) {
        NCryptKey* keyItem = [keys objectForKey:keyID];
        if (keyItem) {
            NSData* data = [Cipher base64DataFromString:backupKey.value];
            NSString* xml = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
            NSString* password = [Cipher generatePassword:keyItem.value withEntropy:entropy count:4096];
            NSLog(@"Password:%@ length: %d\n",password, [password length]);

            NSString* blob = [Cipher encryptByRSAKey:xml withData:[password dataUsingEncoding:NSUTF8StringEncoding]];
            NSLog(@"XML:%@\n",xml);

            TiXmlElement* backupRecovery = new TiXmlElement("r");
            TiXmlElement* backupRecoveryKey = new TiXmlElement("rk");
            TiXmlText* textBackupRecoveryKey = new TiXmlText([backupKey.ID UTF8String]);
            backupRecoveryKey->LinkEndChild(textBackupRecoveryKey);
            TiXmlElement* backupRecoveryBlob = new TiXmlElement("rb");
            TiXmlText* valueBackupRecoveryKey = new TiXmlText([blob UTF8String]);
            valueBackupRecoveryKey->SetCDATA(YES);
            backupRecoveryBlob->LinkEndChild(valueBackupRecoveryKey);

            backupRecovery->LinkEndChild(backupRecoveryKey);
            backupRecovery->LinkEndChild(backupRecoveryBlob);
            nodeRecoveryCollection->LinkEndChild(backupRecovery);
        }
    }

    root->LinkEndChild(nodeRecoveryCollection);

    xmlDocument->Accept(xmlPrinter);

    NSString* result = [NSString stringWithCString:xmlPrinter->CStr() encoding:NSUTF8StringEncoding];
    delete xmlDocument;
    delete xmlPrinter;

    NSLog(@"Comment:\n%@", result);

    return result;
}

- (NCryptKey*)findKey:(NSString*)keyID
{
    NCryptKey* result = [keys valueForKey:keyID];
    if (result == nil) {
        if([self.delegate respondsToSelector:@selector(loadSynchronousKey:)])
        {
            [delegate loadSynchronousKey:keyID];
            result = [keys valueForKey:keyID];
        }
    }
    return result;
}


- (NSString*) passwordFromComment:(NSString*)comment
{
    NSString* entropy = @"";
    NSString* keyID = @"";
    NCryptKey* key = nil;
    NSString* password = @"";
    NSString* backup = @"";
    TRACE(@"Password from comment ...");

    if ([comment length] != 0) {
        NSLog(@"Comment:\n%@", comment);
        TiXmlDocument* xml = new TiXmlDocument;
        xml->Parse([comment UTF8String]);
        TiXmlElement* root = xml->RootElement();
        if (root) {
            TiXmlElement* nodeRecoveryCollection = root->FirstChildElement("rc");
            if (nodeRecoveryCollection) {
                entropy = [NSString stringWithUTF8String:nodeRecoveryCollection->Attribute("rcid")];
                NSLog(@"rcid:\n%@", entropy);
                TiXmlNode* nodeRecovery = nodeRecoveryCollection->FirstChildElement("r");
                while (nodeRecovery) {
                    TiXmlElement* nodeRecoveryKey = nodeRecovery->FirstChildElement("rk");
                    if (nodeRecoveryKey) {
                        keyID = [NSString stringWithUTF8String:nodeRecoveryKey->GetText()];
                    }

                    key = [self findKey:keyID];
                    if (key) {
                        TRACE(@"*key: %@", keyID);
                        TRACE(@"*key-type: %@", key.type);
                        TRACE(@"*entropy: %@", entropy);
                        TRACE(@"*value: %@", key.value);
                        if ([key.type isEqualToString:@"encryption"]) {
                            TiXmlElement* nodeRecoveryBackup = nodeRecovery->FirstChildElement("rb");
                            if (nodeRecoveryBackup) {
                                backup = [NSString stringWithUTF8String:nodeRecoveryBackup->GetText()];
                                NSData* data = [Cipher base64DataFromString:backup];
                                NSString* xml = [[[NSString alloc] initWithData:[Cipher base64DataFromString:key.value]
                                                                       encoding:NSUTF8StringEncoding] autorelease];
                                NSLog(@"RSA xml %@", xml);
                                password = [Cipher decryptByRSAKey:xml withData:data];
                                break;
                            }
                        } else if ([key.value length] != 0) {
                            password = [Cipher generatePassword:key.value withEntropy:entropy count:4096];
                            break;
                        } else {
                            NSAssert(false, @"Unknown key type");
                            password = @"";
                        }
                    }
                    nodeRecovery = nodeRecovery->NextSibling();
                }
            }
        }
        TRACE(@"*password: %@", password);
    }
    return password;
}


- (void)encryptFile:(NSString *)fileName intoFile:(NSString *)intoFile key:(NSString *)keyID backupKey:(NSString *)backupKeyID
{
    ZipFile *zipFile= [[ZipFile alloc] initWithFileName:intoFile mode:ZipFileModeCreate];

    ZipWriteStream *streamReadme = [zipFile writeFileInZipWithName:@"Readme.txt"  compressionLevel:ZipCompressionLevelDefault];
    [streamReadme writeData:[kReadmeContent dataUsingEncoding:NSASCIIStringEncoding]];
    [streamReadme finishedWriting];

    NSString* comment = [self generateComment:keyID backupKey:backupKeyID];
    NSString* password = [self passwordFromComment:comment];

    //TODO: Add TinyXML for generate
    NSString* manifestContent = [NSString stringWithFormat:
                                 @"<zipcipher>\n"
                                 "   <manifest>\n"
                                 "       <fc>\n"
                                 "           <f>\n"
                                 "               <name>\n"
                                 "                   <![CDATA[%@]]>\n"
                                 "               </name>\n"
                                 "           </f>\n"
                                 "       </fc>\n"
                                 "   </manifest>\n"
                                 "</zipcipher>\n", [fileName lastPathComponent]];


    NSData* fileManifest = [manifestContent dataUsingEncoding:NSUTF8StringEncoding];
    uLong crcManifest = crc32(crc32(0L,NULL, 0L), (const Bytef*)[fileManifest bytes], [fileManifest length]);
    ZipWriteStream* streamManifest = [zipFile writeFileInZipWithName:@"manifest"  fileDate:[NSDate date] compressionLevel:ZipCompressionLevelDefault password:password crc32:crcManifest];
    [streamManifest writeData:fileManifest];
    [streamManifest finishedWriting];

    NSData *mainFile = [NSData dataWithContentsOfFile:fileName];
    NSLog(@"File size: %d", [mainFile length]);

    uLong crcMain = crc32(crc32(0L, NULL, 0L), (const Bytef*)[mainFile bytes], [mainFile length]);

    ZipWriteStream* streamMainFile = [zipFile writeFileInZipWithName:[fileName lastPathComponent] fileDate:[NSDate date] compressionLevel:ZipCompressionLevelDefault password:password crc32:crcMain];
    [streamMainFile writeData:mainFile];
    [streamMainFile finishedWriting];

    [zipFile close:comment];
    [zipFile release];
}

- (BOOL) isCryptedBoxFile:(NSString *)fileName
{
    if ([[fileName pathExtension] caseInsensitiveCompare:@"zip"] == NSOrderedSame) {
        ZipFile *unzipFile= [[ZipFile alloc] initWithFileName:fileName mode:ZipFileModeUnzip];
        NSString *comment= [unzipFile getGlobalComment];
        NSLog(@"%@", comment);

        if ([comment length] != 0) {
            NSArray *infos= [unzipFile listFileInZipInfos];

            bool isManifestPresent = false;
            bool isReadmePresent = false;

            int count = 0;
            for (FileInZipInfo *info in infos) {
                isManifestPresent = isManifestPresent || [info.name caseInsensitiveCompare:@"manifest"] == NSOrderedSame;
                isReadmePresent = isReadmePresent || [info.name caseInsensitiveCompare:@"Readme.txt"] == NSOrderedSame;
                count++;
            }
            if ((count == 3) &&
                isManifestPresent &&
                isReadmePresent)
            {
                [unzipFile close];
                [unzipFile release];
                return YES;
            }
        }
        [unzipFile close];
        [unzipFile release];
    }
    return NO;
}


- (BOOL) isEncryptedFile:(NSString *)fileName
{
    @try {
        if ([[fileName pathExtension] caseInsensitiveCompare:@"zip"] == NSOrderedSame) {
            ZipFile *unzipFile= [[ZipFile alloc] initWithFileName:fileName mode:ZipFileModeUnzip];
            NSString *comment= [unzipFile getGlobalComment];
            NSLog(@"%@", comment);

            if ([comment length] != 0) {
                NSString* password = [self passwordFromComment:comment];

                NSArray *infos= [unzipFile listFileInZipInfos];

                bool isManifestPresent = false;
                bool isReadmePresent = false;

                int count = 0;
                for (FileInZipInfo *info in infos) {
                    isManifestPresent = isManifestPresent || [info.name caseInsensitiveCompare:@"manifest"] == NSOrderedSame;
                    isReadmePresent = isReadmePresent || [info.name caseInsensitiveCompare:@"Readme.txt"] == NSOrderedSame;
                    count++;
                }
                if ((count == 3) &&
                    isManifestPresent &&
                    isReadmePresent &&
                    ([password length] != 0))
                {
                    [unzipFile close];
                    [unzipFile release];
                    return YES;
                }
            }
            [unzipFile close];
            [unzipFile release];
        }
    }
    @catch (NSException *exception) {
        [[[[UIAlertView alloc]
		   initWithTitle:[exception name] message:[exception reason]
		   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
		  autorelease]
		 show];
        return NO;
    }
    @finally {
    }
    return NO;
}

- (BOOL) isKeysFile:(NSString *)fileName
{
    BOOL result = NO;
    if ([[fileName pathExtension] caseInsensitiveCompare:@"zip"] == NSOrderedSame) {
        ZipFile*  unzipFile= [[ZipFile alloc] initWithFileName:fileName mode:ZipFileModeUnzip];
        NSString *comment= [unzipFile getGlobalComment];
        if ([comment length] != 0) {
            NSArray*  infos= [unzipFile listFileInZipInfos];

            bool isManifestPresent = false;

            for (FileInZipInfo *info in infos)
            {
                isManifestPresent = isManifestPresent || [info.name caseInsensitiveCompare:@"manifest"] == NSOrderedSame;
            }
            result = !isManifestPresent;
        }

        [unzipFile close];
        [unzipFile release];
    }

    return result;
}


- (NSUInteger) loadKeysFile:(NSString *)fileName  password:(NSString*)password
{
    TRACE(@"Load keys: %@ with password %@", fileName, password);
    NSUInteger result = 0;
    if ([[fileName pathExtension] caseInsensitiveCompare:@"zip"] == NSOrderedSame) {
        ZipFile*  unzipFile= [[ZipFile alloc] initWithFileName:fileName mode:ZipFileModeUnzip];
        NSString* comment= [unzipFile getGlobalComment];
        if ([comment length] != 0) {
            NSArray*  infos= [unzipFile listFileInZipInfos];

            bool isManifestPresent = false;

            for (FileInZipInfo *info in infos)
            {
                isManifestPresent = isManifestPresent || [info.name caseInsensitiveCompare:@"manifest"] == NSOrderedSame;
            }

            ZipReadStream *read = nil;
            // May be keys file ???
            if (!isManifestPresent) {
                for (FileInZipInfo *info in infos)
                {
                    [unzipFile locateFileInZip:info.name];
                    //FileInZipInfo* info =[unzipFile getCurrentFileInZipInfo];
                    NSMutableData *data= [[NSMutableData alloc] initWithLength:info.length];
                    @try {
                        read = [unzipFile readCurrentFileInZipWithPassword:[NSString stringWithUTF8String:[password UTF8String]]];

                        int bytesRead = [read readDataWithBuffer:data];
                        [read finishedReading];
                        if (bytesRead) {
                        }
                        NSString* key = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                        TRACE(@"Key: %@", key);
                        [self loadKeysFromString:key];
                        [data release];
                        result++;
                    }
                    @catch(NSException * e) {
                        [data release];
                        TRACE(@"%@/%@", [e name], [e reason]);
                    }
                }
            }

        }

        [unzipFile close];
    }

    return result;
}


- (NSURL*) decryptFile:(NSString *)fileName
{
    NSURL* fileURL = nil;

    if ([self isEncryptedFile:fileName]) {
        ZipFile*  unzipFile= [[ZipFile alloc] initWithFileName:fileName mode:ZipFileModeUnzip];
        NSString* comment= [unzipFile getGlobalComment];
        NSString* password = [self passwordFromComment:comment];
        NSArray*  infos= [unzipFile listFileInZipInfos];

        for (FileInZipInfo *info in infos)
        {
            if (([info.name caseInsensitiveCompare:@"manifest"] != NSOrderedSame) &&
                ([info.name caseInsensitiveCompare:@"Readme.txt"] != NSOrderedSame))
            {
                if ([unzipFile locateFileInZip:info.name])
                {
                    // Expand the file in memory
                    ZipReadStream *read = nil;

                    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
                    NSString *cacheDirectory = [paths objectAtIndex:0];
                    NSString *tmpFile = [cacheDirectory stringByAppendingPathComponent:info.name];
                    if (info.crypted) {
                        read = [unzipFile readCurrentFileInZipWithPassword:[NSString stringWithUTF8String:[password UTF8String]]];
                    } else {
                        read = [unzipFile readCurrentFileInZip];
                    }
                    TRACE(@"Info file length: %d", info.length);
                    NSMutableData *data= [[NSMutableData alloc] initWithLength:info.length];
                    int bytesRead= [read readDataWithBuffer:data];
                    TRACE(@"Decrypt %d bytes data size %d", bytesRead, [data length]);
                    [read finishedReading];

                    [data writeToFile:tmpFile atomically:NO];
                    [data release];
                    fileURL = [[[NSURL alloc] initFileURLWithPath:tmpFile] autorelease];
                    break;
                }
            }
        }
        [unzipFile close];
        [unzipFile release];
    }
    return fileURL;
}

/*
 <zipcipher>
 <manifest>
 <defaultKey>{6D99F804-63A7-A9B7-69B1-028EE3007569}</defaultKey>
 <backupKey>{EDF35CEC-6471-41AD-9866-1C725CE2132F}</backupKey>
 <kdb>
 <k>
 <kid>{6D99F804-63A7-A9B7-69B1-028EE3007569}</kid>
 <klabel><![CDATA[MyKey]]></klabel>
 <ktype>storage</ktype>
 <exportable>false</exportable>
 <ownerid>user</ownerid>
 </k>
 <k>
 <kid>{EDF35CEC-6471-41AD-9866-1C725CE2132F}</kid>
 <klabel><![CDATA[MyBackupKey]]></klabel>
 <ktype>encryption</ktype>
 <exportable>true</exportable>
 <ownerid>user</ownerid>
 </k>
 </kdb>
 </manifest>
 </zipcipher>
 */

- (NSString*) generateManifestKeyStorage
{
    TiXmlDocument* xmlDocument = new TiXmlDocument;
    TiXmlPrinter* xmlPrinter = new TiXmlPrinter;
    TiXmlElement* root = new TiXmlElement("zipcipher");
    TiXmlElement* manifest = new TiXmlElement("manifest");
    TiXmlElement* defaultKey = new TiXmlElement("defaultKey");
    TiXmlElement* backupKey = new TiXmlElement("backupKey");

    xmlDocument->LinkEndChild(root);
    root->LinkEndChild(manifest);
    manifest->LinkEndChild(defaultKey);
    manifest->LinkEndChild(backupKey);
    defaultKey->LinkEndChild(new TiXmlText([_defaultKey UTF8String]));
    backupKey->LinkEndChild(new TiXmlText([_backupKey UTF8String]));

    TiXmlElement* kdb = new TiXmlElement("kdb");
    manifest->LinkEndChild(kdb);

    for (NSString* keyIdentificator in self.keys) {
        NCryptKey* key = [keys objectForKey:keyIdentificator];
        if (key) {
            TiXmlElement* k = new TiXmlElement("k");
            kdb->LinkEndChild(k);

            TiXmlElement* kid = new TiXmlElement("kid");
            kid->LinkEndChild(new TiXmlText([key.ID UTF8String])) ;
            k->LinkEndChild(kid);

            TiXmlElement* klabel = new TiXmlElement("klabel");
            TiXmlText* klabelText = new TiXmlText([key.name UTF8String]);
            klabelText->SetCDATA(true);
            klabel->LinkEndChild(klabelText);
            k->LinkEndChild(klabel);

            TiXmlElement* ktype = new TiXmlElement("ktype");
            ktype->LinkEndChild(new TiXmlText([key.type UTF8String])) ;
            k->LinkEndChild(ktype);

            TiXmlElement* exportable = new TiXmlElement("exportable");
            exportable->LinkEndChild(new TiXmlText(key.exportable ? [@"true" UTF8String] : [@"false" UTF8String])) ;
            k->LinkEndChild(exportable);

            TiXmlElement* ownerid = new TiXmlElement("ownerid");
            ownerid->LinkEndChild(new TiXmlText([key.ownerid UTF8String])) ;
            k->LinkEndChild(ownerid);

            TiXmlElement* ownerbackupkey = new TiXmlElement("ownerbackupkey");
            ownerbackupkey->LinkEndChild(new TiXmlText([key.ownerbackupkey UTF8String])) ;
            k->LinkEndChild(ownerbackupkey);
        }
    }

    xmlDocument->Accept(xmlPrinter);
    NSString* manifestFile = [NSString stringWithCString:xmlPrinter->CStr() encoding:NSUTF8StringEncoding];
    delete xmlDocument;
    delete xmlPrinter;

    NSLog(@"File manifest:\n%@", manifestFile);
    return manifestFile;
}


- (BOOL) saveKeys:(NSString*)fileName withPassword:(NSString*)password
{
    @try {
        ZipFile *zipFile= [[ZipFile alloc] initWithFileName:fileName mode:ZipFileModeCreate];

        // Write manifest
        NSData* fileManifest = [[self generateManifestKeyStorage] dataUsingEncoding:NSUTF8StringEncoding];
        uLong crcManifest = crcManifest = crc32(crc32(0L,NULL, 0L), (const Bytef*)[fileManifest bytes], [fileManifest length]);

        ZipWriteStream* streamManifest = [password length] == 0 ? [zipFile writeFileInZipWithName:@"manifest"  fileDate:[NSDate date]
                                                                                 compressionLevel:ZipCompressionLevelDefault] :
        // With password
        [zipFile writeFileInZipWithName:@"manifest"  fileDate:[NSDate date]
                       compressionLevel:ZipCompressionLevelDefault
                               password:password
                                  crc32:crcManifest];
        [streamManifest writeData:fileManifest];
        [streamManifest finishedWriting];

        for (NSString* keyID in self.keys) {
            NCryptKey* key = [keys objectForKey:keyID];
            if (key) {
                if ([key.ID isEqualToString:self.defaultKey]) {
                    NSLog(@"Save default key: %@", key.ID);
                    NSLog(@"Save default key value: %@", key.value);
                }

                NSData* fileKey = nil;
                if ([key.type compare:@"storage"] == NSOrderedSame) {
                    fileKey = [[self generateStorageKeyFile:keyID] dataUsingEncoding:NSUTF8StringEncoding];
                } else if ([key.type compare:@"encryption"] == NSOrderedSame) {
                    fileKey = [[self generateEncryptionKeyFile:keyID] dataUsingEncoding:NSUTF8StringEncoding];
                } else if ([key.type compare:@"backup"] == NSOrderedSame) {
                    fileKey = [[self generateEncryptionKeyFile:keyID] dataUsingEncoding:NSUTF8StringEncoding];
                }

                if (fileKey) {
                    uLong crcKey = crc32( crc32(0L,NULL, 0L), (const Bytef*)[fileKey bytes], [fileKey length]);
                    ZipWriteStream* streamKey = [password length] == 0 ? [zipFile writeFileInZipWithName:key.ID  fileDate:[NSDate date]
                                                                                        compressionLevel:ZipCompressionLevelDefault] :
                    // With password
                    [zipFile writeFileInZipWithName:@"manifest"  fileDate:[NSDate date]
                                   compressionLevel:ZipCompressionLevelDefault
                                           password:password
                                              crc32:crcKey];
                    [streamKey writeData:fileKey];
                    [streamKey finishedWriting];
                }
            }
        }

        [zipFile close];
        [zipFile release];
    }
    @catch (NSException *exception) {
        TRACE(@"ERROR keys writing: %@: %@", [exception name], [exception reason]);
        return NO;
    }

    return YES;
}

/*
 <zipcipher>
 <kc>
 <sk>
 <skid>{6D99F804-63A7-A9B7-69B1-028EE3007569}</skid>
 <skv><![CDATA[AKpT53puXAwxwQi/UNf/Py6PVVpsFJ/Du9876E/Kz9Y=]]></skv>
 </sk>
 </kc>
 </zipcipher>
 */
- (NSString*)generateStorageKeyFile:(NSString*)keyID keyValue:(NSString*)keyValue
{
    TiXmlDocument* xmlDocument = new TiXmlDocument;
    TiXmlPrinter* xmlPrinter = new TiXmlPrinter;

    TiXmlElement* root = new TiXmlElement("zipcipher");
    xmlDocument->LinkEndChild(root);
    TiXmlElement* kc = new TiXmlElement("kc");
    TiXmlElement* sk = new TiXmlElement("sk");
    TiXmlElement* skid = new TiXmlElement("skid");
    TiXmlText* skidText = new TiXmlText([keyID UTF8String]);
    TiXmlElement* skv = new TiXmlElement("skv");
    TiXmlText* skvText = new TiXmlText([keyValue UTF8String]);
    skvText->SetCDATA(true);


    root->LinkEndChild(kc);
    kc->LinkEndChild(sk);
    sk->LinkEndChild(skid);
    skid->LinkEndChild(skidText);
    sk->LinkEndChild(skv);
    skv->LinkEndChild(skvText);

    xmlDocument->Accept(xmlPrinter);
    NSString* result = [NSString stringWithCString:xmlPrinter->CStr() encoding:NSUTF8StringEncoding];

    NSLog(@"Storage key file:%@", result);
    delete xmlDocument;
    delete xmlPrinter;

    return result;
}


- (NSString*)generateStorageKeyFile:(NSString*)keyID
{
    NCryptKey* key = [keys objectForKey:keyID];
    if (key) {
        return [self generateStorageKeyFile:key.ID keyValue:key.value];
    }

    return nil;
}

+ (NSString*)generateEncryptionKeyFile:(NSString*)keyID keyValue:(NSString*)keyValue
{
    TiXmlDocument* xmlDocument = new TiXmlDocument;
    TiXmlPrinter* xmlPrinter = new TiXmlPrinter;

    TiXmlElement* root = new TiXmlElement("zipcipher");
    xmlDocument->LinkEndChild(root);
    TiXmlElement* kc = new TiXmlElement("kc");
    TiXmlElement* k = new TiXmlElement("k");
    TiXmlElement* kid = new TiXmlElement("kid");
    TiXmlText* kidText = new TiXmlText([keyID UTF8String]);
    TiXmlElement* kv = new TiXmlElement("kv");
    TiXmlText* kvText = new TiXmlText([keyValue UTF8String]);
    kvText->SetCDATA(true);

    root->LinkEndChild(kc);
    kc->LinkEndChild(k);
    k->LinkEndChild(kid);
    kid->LinkEndChild(kidText);
    k->LinkEndChild(kv);
    kv->LinkEndChild(kvText);

    xmlDocument->Accept(xmlPrinter);
    NSString* result = [NSString stringWithCString:xmlPrinter->CStr() encoding:NSUTF8StringEncoding];

    delete xmlDocument;
    delete xmlPrinter;

    return result;

}


- (NSString*)generateEncryptionKeyFile:(NSString*)keyID
{
    NCryptKey* key = [keys objectForKey:keyID];
    if (key) {
        return [NCryptBox generateEncryptionKeyFile:key.ID keyValue:key.value];
    }

    return nil;
}


- (BOOL) loadKeys:(NSString*)fileName withPassword:(NSString*)password
{
    ZipFile*  unzipFile = nil;
    NSInteger count = 0;

    @try {
        unzipFile= [[ZipFile alloc] initWithFileName:fileName mode:ZipFileModeUnzip];

        if ([unzipFile locateFileInZip:@"manifest"]) {
            ZipReadStream *read = nil;
            if ([password length] == 0) {
                read = [unzipFile readCurrentFileInZip];
            } else {
                read = [unzipFile readCurrentFileInZipWithPassword:[NSString stringWithUTF8String:[password UTF8String]]];
            }
            FileInZipInfo* info = [unzipFile getCurrentFileInZipInfo];
            NSMutableData *data= [[NSMutableData alloc] initWithLength:info.length];
            int bytesRead = [read readDataWithBuffer:data];
            [read finishedReading];
            NSString* manifest = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            TRACE(@"Read manifest %@\nbytes : %d", manifest, bytesRead);

            TiXmlDocument* xmlDocument = new TiXmlDocument;
            xmlDocument->Parse([manifest UTF8String]);
            TiXmlElement* root = xmlDocument->RootElement();
            if (root == nil)
            {
                TRACE(@"ERROR manifest storage key file is wrong");
                return NO;
            }
            TiXmlElement* manifestNode = root->FirstChildElement("manifest");
            if (manifestNode == nil)
            {
                TRACE(@"ERROR manifest xml storage key file is wrong");
                return NO;
            }

            TiXmlElement* defaultKeyNode = manifestNode->FirstChildElement("defaultKey");
            if (defaultKeyNode && defaultKeyNode->GetText())
            {
                self.defaultKey = [NSString stringWithCString:defaultKeyNode->GetText() encoding:NSUTF8StringEncoding];
            } else {
                TRACE(@"ERROR manifest xml storage key file is wrong. Default key not found");
                // return NO;
            }

            TiXmlElement* backupKeyNode = manifestNode->FirstChildElement("backupKey");
            if (backupKeyNode && backupKeyNode->GetText())
            {
                self.backupKey = [NSString stringWithCString:backupKeyNode->GetText() encoding:NSUTF8StringEncoding];
            } else {
                TRACE(@"ERROR manifest xml storage key file is wrong. Backup key not found");
                //                return NO;
            }

            TiXmlElement* kdbNode = manifestNode->FirstChildElement("kdb");
            if (kdbNode == nil)
            {
                TRACE(@"ERROR manifest xml storage key file is wrong. Keys database is empty");
                return NO;
            }

            TiXmlElement* k = kdbNode->FirstChildElement("k");
            if (kdbNode == nil)
            {
                TRACE(@"ERROR manifest xml storage key file is wrong. Keys not found");
                return NO;
            }

            while (k) {
                TiXmlElement* kid = k->FirstChildElement("kid");
                if (kid && kid->GetText())
                {
                    NCryptKey* key = [[NCryptKey alloc] initWithIdentifier:[NSString stringWithCString:kid->GetText() encoding:NSUTF8StringEncoding]];
                    if ([key.ID isEqualToString:self.defaultKey]) {
                        NSLog(@"Read default key: %@", key.ID);
                    }

                    TiXmlElement* klabel = k->FirstChildElement("klabel");
                    if (klabel && klabel->GetText())
                        key.name = [NSString stringWithCString:klabel->GetText() encoding:NSUTF8StringEncoding];

                    TiXmlElement* ktype = k->FirstChildElement("ktype");
                    if (ktype && ktype->GetText())
                        key.type = [NSString stringWithCString:ktype->GetText() encoding:NSUTF8StringEncoding];

                    TiXmlElement* exportable = k->FirstChildElement("exportable");
                    if (exportable && exportable->GetText())
                        key.exportable = [[NSString stringWithCString:exportable->GetText() encoding:NSUTF8StringEncoding] caseInsensitiveCompare:@"true"];

                    TiXmlElement* ownerid = k->FirstChildElement("ownerid");
                    if (ownerid && ownerid->GetText())
                        key.ownerid = [NSString stringWithCString:ownerid->GetText() encoding:NSUTF8StringEncoding];

                    TiXmlElement* ownerbackupkey = k->FirstChildElement("ownerbackupkey");
                    if (ownerbackupkey && ownerbackupkey->GetText())
                        key.ownerbackupkey = [NSString stringWithCString:ownerbackupkey->GetText() encoding:NSUTF8StringEncoding];


                    [keys setObject:key forKey:key.ID];
                    count++;

                    if ([unzipFile locateFileInZip:key.ID]) {
                        ZipReadStream *read = nil;
                        if ([password length] == 0) {
                            read = [unzipFile readCurrentFileInZip];
                        } else {
                            read = [unzipFile readCurrentFileInZipWithPassword:[NSString stringWithUTF8String:[password UTF8String]]];
                        }
                        FileInZipInfo* info = [unzipFile getCurrentFileInZipInfo];
                        NSMutableData *data= [[NSMutableData alloc] initWithLength:info.length];
                        int bytesRead= [read readDataWithBuffer:data];
                        [read finishedReading];

                        if ([key.type compare:@"storage"] == NSOrderedSame) {
                            [self loadStorageKey:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
                        } else if ([key.type compare:@"encryption"] == NSOrderedSame) {
                            [self loadEncryptionKey:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
                        }

                        NCryptKey* k = [keys objectForKey:key.ID];
                        TRACE(@"Read %@ key\nkey:%@\nvalue:%@\nbytes : %d", k.type, k.ID, k.value, bytesRead);
                    }
                }
                k = k->NextSiblingElement();
            }
        }
    }
    @catch (NSException *exception) {
        @throw [[[NCryptException alloc] initWithReason:[NSString stringWithFormat:@"Key storage file is wrong: %@", [exception reason]]] autorelease];
    }
    @finally {
        if (unzipFile) {
            [unzipFile close];
            [unzipFile release];
        }
    }
    return count != 0;
}


- (BOOL)loadStorageKey:(NSString*)xml
{
    TiXmlDocument* xmlDocument = new TiXmlDocument;
    xmlDocument->Parse([xml UTF8String]);

    TiXmlElement* root = xmlDocument->RootElement();
    if (root == nil)
    {
        TRACE(@"Xml storage key file is wrong");
        return NO;
    }

    NSInteger count = 0;
    if (root->Value() != nil)
    {
        if ([@"zipcipher" isEqualToString:[NSString stringWithCString:root->Value() encoding:NSUTF8StringEncoding]]) {
            TiXmlElement* kc = root->FirstChildElement("kc");
            if (kc) {
                TiXmlElement* sk = kc->FirstChildElement("sk");
                while (sk) {
                    TiXmlElement* skid = sk->FirstChildElement("skid");
                    TiXmlElement* skv = sk->FirstChildElement("skv");
                    if ((skid) && (skv)) {
                        if (skid->GetText() != nil)
                        {
                            NSString* keyID = [NSString stringWithCString:skid->GetText() encoding:NSUTF8StringEncoding];
                            NCryptKey* keyStorage = [keys objectForKey:keyID];
                            if (keyStorage == nil) {
                                TRACE(@"Identificator Key storage %@ not found in keys", keyID);
                            }

                            if (![keyStorage.type isEqualToString:@"storage"]) {
                                TRACE(@"Key %@ is not storage key in manifest", keyStorage);
                            }

                            if (skv->GetText() != nil) {
                                [keyStorage setValue:[NSString stringWithCString:skv->GetText() encoding:NSUTF8StringEncoding]];
                            } else {
                                NSLog(@"Key: %@ dont have value", keyID);
                            }

                            [keys setObject:keyStorage forKey:keyID];
                            count++;
                        }
                    }
                    sk = sk->NextSiblingElement();
                }
            }
        }
    }

    return count != 0;
}

- (NSString*)loadEncryptionKey:(NSString*)xml
{
    TiXmlDocument* xmlDocument = new TiXmlDocument;
    xmlDocument->Parse([xml UTF8String]);

    TiXmlElement* root = xmlDocument->RootElement();
    if (root == nil)
    {
        TRACE(@"Xml encryption key file is wrong");
        return NO;
    }

    NSInteger count = 0;
    NSString* keyID = nil;
    if (root->Value() == nil)
    {
        NSLog(@"root->Value()");
    }

    if ([@"zipcipher" isEqualToString:[NSString stringWithCString:root->Value() encoding:NSUTF8StringEncoding]]) {
        TiXmlElement* kc = root->FirstChildElement("kc");
        if (kc) {
            TiXmlElement* k = kc->FirstChildElement("k");
            while (k) {
                TiXmlElement* kid = k->FirstChildElement("kid");
                TiXmlElement* kv = k->FirstChildElement("kv");
                if ((kid) && (kv)) {
                    if (kid->GetText() == nil) {
                        NSLog(@"kid->GetText()");
                    }
                    keyID = [NSString stringWithCString:kid->GetText() encoding:NSUTF8StringEncoding];
                    NCryptKey* keyEncryption = [keys objectForKey:keyID];
                    if (keyEncryption == nil) {
                        TRACE(@"Identificator Key encryption %@ not found in keys", keyID);
                    }

                    if (![keyEncryption.type isEqualToString:@"encryption"]) {
                        TRACE(@"Key %@ is not encryption key in manifest", keyEncryption);
                    }

                    [keyEncryption setValue:[NSString stringWithCString:kv->GetText() encoding:NSUTF8StringEncoding]];

                    [keys setObject:keyEncryption forKey:keyID];
                    count++;
                }
                k = k->NextSiblingElement();
            }
        }
    }
    NSAssert(count != 0, @"A few keys in file");

    return keyID;
}


- (NSString*)createEncryptionKey:(NSString*)xml
{
    TiXmlDocument* xmlDocument = new TiXmlDocument;
    xmlDocument->Parse([xml UTF8String]);

    TiXmlElement* root = xmlDocument->RootElement();
    if (root == nil)
    {
        TRACE(@"Encryption xml key is wrong");
        return NO;
    }

    NSInteger count = 0;
    NSString* keyID = nil;

    if ([@"zipcipher" isEqualToString:[NSString stringWithCString:root->Value() encoding:NSUTF8StringEncoding]]) {
        TiXmlElement* kc = root->FirstChildElement("kc");
        if (kc) {
            TiXmlElement* k = kc->FirstChildElement("k");
            while (k) {
                TiXmlElement* kid = k->FirstChildElement("kid");
                TiXmlElement* kv = k->FirstChildElement("kv");
                if ((kid) && (kv)) {
                    keyID = [NSString stringWithCString:kid->GetText() encoding:NSUTF8StringEncoding];
                    NCryptKey* keyEncryption = [[NCryptKey alloc] initWithIdentifier:keyID];
                    keyEncryption.type = @"encryption";
                    //                    NCryptKey* keyEncryption = [keys objectForKey:keyID];
                    if (keyEncryption == nil) {
                        TRACE(@"Identificator Key encryption %@ not found in keys", keyID);
                    }

                    if (![keyEncryption.type isEqualToString:@"encryption"]) {
                        TRACE(@"Key %@ is not encryption key in manifest", keyEncryption);
                    }

                    [keyEncryption setValue:[NSString stringWithCString:kv->GetText() encoding:NSUTF8StringEncoding]];

                    [keys setObject:keyEncryption forKey:keyID];
                    [keyEncryption release];
                    count++;
                }
                k = k->NextSiblingElement();
            }
        }
    }
    NSAssert(count != 0, @"A few keys in file");

    return keyID;
}


- (NSUInteger)loadKeysFromXmlObject:(TiXmlDocument*)xmlDocument
{
    if (xmlDocument == nil) {
        return 0;
    }
    NSUInteger count = 0;
    TiXmlElement* root = xmlDocument->RootElement();
    if (root) {
        if ([@"zipcipher" isEqualToString:[NSString stringWithCString:root->Value() encoding:NSUTF8StringEncoding]]) {
            TiXmlElement* kc = root->FirstChildElement("kc");
            if (kc) {
                TiXmlElement* sk = kc->FirstChildElement("sk");
                while (sk) {
                    TiXmlElement* skid = sk->FirstChildElement("skid");
                    TiXmlElement* skv = sk->FirstChildElement("skv");
                    if ((skid) && (skv)) {
                        NCryptKey* key = [[NCryptKey alloc] initWithIdentifier:[NSString stringWithCString:skid->GetText() encoding:NSUTF8StringEncoding]];
                        [key setValue:[NSString stringWithCString:skv->GetText() encoding:NSUTF8StringEncoding]];
                        [key setType:@"storage"];
                        [keys setObject:key forKey:key.ID];
                        [key release];
                        count++;
                    }
                    sk = sk->NextSiblingElement();
                }
                TiXmlElement* k = kc->FirstChildElement("k");
                while (k) {
                    TiXmlElement* kid = k->FirstChildElement("kid");
                    TiXmlElement* kv = k->FirstChildElement("kv");
                    if ((kid) && (kv)) {
                        NCryptKey* key = [[NCryptKey alloc] initWithIdentifier:[NSString stringWithCString:kid->GetText() encoding:NSUTF8StringEncoding]];
                        [key setValue:[NSString stringWithCString:kv->GetText() encoding:NSUTF8StringEncoding]];
                        [key setType:@"encryption"];
                        [keys setObject:key forKey:key.ID];
                        [key release];
                        count++;
                    }
                    k = k->NextSiblingElement();
                }
            }
        }
    }
    return count;
}


- (NSUInteger)loadKeysFromString:(NSString*)xmlString
{
    TiXmlDocument* xmlDocument = new TiXmlDocument;
    xmlDocument->Parse([xmlString UTF8String]);
    NSUInteger count = [self loadKeysFromXmlObject:xmlDocument];
    delete xmlDocument;
    return count;
}

- (NSUInteger)loadKeysFromFile:(NSString*)fileName
{
    TiXmlDocument* xmlDocument = new TiXmlDocument([fileName UTF8String]);
    xmlDocument->LoadFile();
    NSUInteger count = [self loadKeysFromXmlObject:xmlDocument];
    delete xmlDocument;

    return count;
}

/*
 - (NSUInteger)loadKeys
 {
 [keys removeAllObjects];
 NSString* keysFile = [self createEditableCopyOfKeysIfNeeded];
 return [self loadKeysFromFile:keysFile];
 }
 */

+ (NSString*) generatePersonalKeyValue:(NSString*)userName withPassword:(NSString*)userPassword
{
    return [Cipher generatePassword:userName withEntropy:userPassword count:4096];
}

+ (NSString*) generatePersonalKeyId:(NSString*)userName
{
    NSData* sha256 = [Cipher getHashValue:[userName dataUsingEncoding:NSUTF8StringEncoding]];

    UInt8* uuid = (UInt8*)[sha256 bytes];

    CFUUIDRef sUUID = CFUUIDCreateWithBytes(kCFAllocatorDefault, uuid[0], uuid[1], uuid[2], uuid[3],
                                            uuid[4], uuid[5], uuid[6], uuid[7],
                                            uuid[8], uuid[9], uuid[10], uuid[11],
                                            uuid[12], uuid[13], uuid[14], uuid[15]);

    NSString *result = [NSString stringWithString:(NSString *)CFUUIDCreateString(kCFAllocatorDefault, sUUID)];
    CFRelease(sUUID);
    return [result autorelease];
}

//Uname: игорь
//Upassword: password
//Keyid: 820439B0079DD4C9C254148E4894518F9D0AB20D50F279B4367E684BB4EBA328
//KeyValue: 5jyjhg0C+KTXyVVq6Pe1rMmck7GkQfG+7+XFzDyg+TA=

- (void)generateStorageKey:(NSString*)userName withPassword:(NSString*)password andEntropy:(NSString*)entropy
{

    NSMutableString* userIdA = [[[NSMutableString alloc] initWithString:entropy] autorelease];
    [userIdA appendString:userName];

    NSString* passwordBlob =  [Cipher generatePassword:password withEntropy:userIdA count:4096];
    if ([entropy length] != 0)
    {
        passwordBlob =  [Cipher generatePassword:passwordBlob withEntropy:entropy count:4096];
    }

    NSData *data = [passwordBlob dataUsingEncoding:NSUTF8StringEncoding];
    const char *bytes = (const char*)[data bytes];
    char *reverseBytes = (char*)malloc(sizeof(char) * [data length]);
    int index = [data length] - 1;
    for (int i = 0; i < [data length]; i++)
        reverseBytes[index-i] = bytes[i];
    NSData *reversedData = [NSData dataWithBytes:reverseBytes length:[data length]];
    free(reverseBytes);

    NSData* sha256 = [Cipher generatePassword:reversedData withEntropy:[userIdA dataUsingEncoding:NSUTF8StringEncoding]];

    NSMutableString* skID = [[NSMutableString alloc] init];

    for (int i = 0; i < [sha256 length]; i++) {
        [skID appendFormat:@"%02X",((UInt8*)[sha256 bytes])[i]];
    }

    [self setStorageKeyID:skID];
    [self setStorageKeyValue:passwordBlob];
    NSLog(@"Keyid:%@", skID);
    NSLog(@"KeyValue:%@", passwordBlob);
    [skID release];
    [passwordBlob release];
}

/*
 <zipcipher>
 <kc>
 <k>
 <kid>{EDF35CEC-6471-41AD-9866-1C725CE2132F}</kid>
 <kv><![CDATA[PFJTQUtleVZhbHVlPjxNb2R1bHVzPnl0S…
 </k>
 </kc>
 </zipcipher>
 */


+ (NSDictionary*) generateRSAkey
{
    NSDate* startTime = [NSDate date];
    NSDictionary* encryptionKey = [Cipher generateNewRSAKey:2048 includePrivateKey:YES];
    NSLog(@"Total time generate RSA: %f", [[NSDate date] timeIntervalSinceDate:startTime]);
    return encryptionKey;

    /*
     NSDate* startTime = [NSDate date];
     NSString* encryptionKey = [Cipher generateNewRSAKey:2048 includePrivateKey:YES];
     NSLog(@"Total time generate RSA: %f", [[NSDate date] timeIntervalSinceDate:startTime]);

     NSString* encryptionKeyID = [self generateUuidString];

     [self generateEncryptionKeyFile:[NSString stringWithFormat:@"{%@}",encryptionKeyID] keyValue:encryptionKey];

     NSString* storageKeyID = [self generateUuidString];
     [self generateStorageKeyFile:[NSString stringWithFormat:@"{%@}",storageKeyID] keyValue:encryptionKey];
     */
    //    ;
    //    NSLog(@"Cipher time: %f", [[NSDate date] timeIntervalSinceDate:timingDate]);
    //    timingDate = [NSDate date];
    //    [[SecKeyWrapper sharedWrapper] generateKeyPair:2048];//kAsymmetricSecKeyPairModulusSize];
    //    NSLog(@"SecKeyWrapper time: %f", [[NSDate date] timeIntervalSinceDate:timingDate]);
    //    NSData* key = [[SecKeyWrapper sharedWrapper] getPublicKeyBits];

    //    NSData* publicTag = [[SecKeyWrapper sharedWrapper] publicTag];
    //    NSLog(@"%@", publicTag);
    //    NSLog(@"%d", [publicTag length]);
    //    NSData* privateTag = [[SecKeyWrapper sharedWrapper] privateTag];
    //    NSLog(@"%@", privateTag);
    //    NSLog(@"%d", [privateTag length]);
    //    NSString *content = [[NSString alloc]  initWithBytes:[key bytes]
    //                                                  length:[key length] encoding: NSASCIIStringEncoding];
    //    NSLog(@"%@",content);

    //    NSLog(@"%@", [Cipher base64StringFromData:key]);

}

/*
 <ncryptedbox>
 <configuration>
 <folder>
 <ownerid>igor@ncryptedbox.com</ownerid>
 <targetkeyid>{093659E3-42E9-4F4B-A876-A67206735A1E}</targetkeyid>
 <recoverykeyid>{01740531-8302-44D1-A957-4BB7B9E06BED}</recoverykeyid>
 <passwordrecovery>
 <![CDATA[bEqZuQdVIyvEzxkWRfZqBroBrsSwSO0rY00VvmvyF80Ou4VXjKCTyxPYFen5csxdSJw7SnnxVM9wjCFye4t1ZsO0LMNlucEU+oPRXD7nTPx2tS9OSHVo+bdTmaYdeCsIjl5s/5yXbIIGHij13O3j5ejbdpK3zy5IMMdZlbxnDm3bkFAM2BmxCIjjx5RE6Jr+1wdr8k0TJAqxrxS+M5HbdVD5Zhprm6WETNXxQhZ+ekGOzuROWbPjYHxbeGMoGhFEaZ64LURLNEvMS0GG7rtW9UUVz77Ier8D980xeVJqJyQaNOu3tzAjz/YWDXJD9etGw+25AXipsm9/17Sh28b6UQ==]]>
 </passwordrecovery>
 <recoverykeyvalue>
 <![CDATA[PFJTQUtleVZhbHVlPjxNb2R1bHVzPmpUU0FVK1gzd0FRdWIxTklWTEJQUnRsSXVreVpNN1Z2MWJub1RrR09KajdoYXRIMlR0ZzZaOXZRbkp4aXZBUFY2MlVzNjN0aVJ0amZ6TnozR3NpQWNCeVpCTUFpUHl6VW4rVGNOaCs5bTBpUVptajFqM242NE9tYllPNUIrVXdQR2UxS1ZRWDJsVGZCYXIrQnVaSjNMM293OFpwdE56cDdlTXFlVWN2ZkQvM01kU1pmWnZZQkN3S2JIa05uaHdDYlM0Q1ZmdnRLcmZnRTBiTzZLUTJWd0lOL0dJVHRia0QzL2dXRmk2MTROb1M3Z0gzb1BRMzRINFBEZmFoekxsMjcyRDZBdWNsdFFKWlZlWjJESVdzU29lLzc4czl1emt5UmRBU3owWWwyNnExV3REaStIWUF4MkVuWmhWSXF6dVA0cUlOTklkNHNOUDNIYmt3OWtLS2hNUT09PC9Nb2R1bHVzPjxFeHBvbmVudD5BUUFCPC9FeHBvbmVudD48L1JTQUtleVZhbHVlPg==]]>
 </recoverykeyvalue>
 <passwordid>
 <![CDATA[/22L7fSBLaQpuesn+e5UCLbGbNzv3+xHv+zs/GU4HFg=]]>
 </passwordid>
 </folder>
 </configuration>
 </ncryptedbox>
 */

- (NSString*) loadNCryptBoxFile:(NSString*)filePath
{
    NSString *contents = [NSString stringWithContentsOfFile:filePath
                                                   encoding:NSUTF8StringEncoding
                                                      error:nil];
    NSString* result = @"";
    if (contents) {
        TiXmlDocument* xml = new TiXmlDocument;
        xml->Parse([contents UTF8String]);
        TiXmlElement* root = xml->RootElement();
        if (root && (root->Value() != nil)) {
            if ([@"ncryptedbox" isEqualToString:[NSString stringWithCString:root->Value() encoding:NSUTF8StringEncoding]]) {
                TiXmlElement* configuration = root->FirstChildElement("configuration");
                if (configuration) {
                    TiXmlElement* folder = configuration->FirstChildElement("folder");
                    if (folder) {
                        TiXmlElement* owneridNode = folder->FirstChildElement("ownerid");
                        if (owneridNode) {
                            NSString* ownerid = [NSString stringWithUTF8String:owneridNode->GetText()];
                            NSLog(@"ownerid: %@", ownerid);
                        }
                        TiXmlElement* targetkeyidNode = folder->FirstChildElement("targetkeyid");
                        NSString* targetkeyid = nil;
                        if (targetkeyidNode) {
                            targetkeyid = [NSString stringWithUTF8String:targetkeyidNode->GetText()];
                            if([self.delegate respondsToSelector:@selector(loadKey:)]) {
                                [delegate loadKey:targetkeyid];
                            }
                            result = targetkeyid;
                            // Check always
                            //id key = [keys objectForKey:targetkeyid];
                            //if (key == nil) {
                            NSLog(@"targetkeyid: %@", targetkeyid);
                        }
                        TiXmlElement* recoverykeyidNode = folder->FirstChildElement("recoverykeyid");
                        NSString* recoverykeyid = nil;
                        if (recoverykeyidNode) {
                            recoverykeyid = [NSString stringWithUTF8String:recoverykeyidNode->GetText()];
                            id key = [keys objectForKey:recoverykeyid];
                            if (key == nil) {
                                //if([self.delegate respondsToSelector:@selector(loadKey:)])
                                //    [delegate loadKey:recoverykeyid];
                            }
                            NSLog(@"recoverykeyid: %@", recoverykeyid);
                        }

                        if([self.delegate respondsToSelector:@selector(didRecieveSharedKeys:backupKey:)]) {
                            [delegate didRecieveSharedKeys:targetkeyid backupKey:recoverykeyid];
                        }

                        TiXmlElement* passwordrecoveryNode = folder->FirstChildElement("passwordrecovery");
                        if (passwordrecoveryNode) {
                            NSString* passwordrecovery = [NSString stringWithUTF8String:passwordrecoveryNode->GetText()];
                            NSLog(@"passwordrecovery: %@", passwordrecovery);
                        }
                        TiXmlElement* recoverykeyvalueNode = folder->FirstChildElement("recoverykeyvalue");
                        if (recoverykeyvalueNode) {
                            NSString* recoverykeyvalue = [NSString stringWithUTF8String:recoverykeyvalueNode->GetText()];
                            NSLog(@"recoverykeyvalue: %@", recoverykeyvalue);
                        }
                        TiXmlElement* passwordidNode = folder->FirstChildElement("passwordid");
                        if (passwordidNode) {
                            NSString* passwordid = [NSString stringWithUTF8String:passwordidNode->GetText()];
                            NSLog(@"passwordid: %@", passwordid);
                        }
                    }
                }
            }
        }
    }
    return result;
}

- (void)importKeyFromDicitonary:(NSDictionary *)key
{
    NSString* keyID = [NSString stringWithString:[key objectForKey:@"key-id"]];
    if (keyID == nil) {
        return;
    }

    if ([keyID length] != 0) {
        NCryptKey* newKey = [[NCryptKey alloc] initWithIdentifier:keyID];
        newKey.name = [NSString stringWithString:[key objectForKey:@"key-label"]];
        NSString* keyType = [key objectForKey:@"key-type"];
        if ([keyType compare:@"0"] == NSOrderedSame) {
            newKey.type = @"storage";
        } else if ([keyType compare:@"1"] == NSOrderedSame) {
            newKey.type = @"encryption";
            self.backupKey = keyID;
        } else {
            NSAssert(false, @"Unknown key type");
        }
        
        newKey.exportable = YES;
        NSString* encryptionKey = [key valueForKey:@"owner-backup-key"];
        [encryptionKey length];
        if (![encryptionKey isKindOfClass:[NSNull class]] && [encryptionKey length] != 0) {
            newKey.ownerbackupkey = [self createEncryptionKey:encryptionKey];
        }
        [self.keys setObject:newKey forKey:keyID];
        if ([newKey.type compare:@"storage"] == NSOrderedSame) {
            [self loadStorageKey:[key objectForKey:@"key-data"]];
        } else if ([newKey.type compare:@"encryption"] == NSOrderedSame) {
            [self loadEncryptionKey:[key objectForKey:@"key-data"]];
        } else {
            NSAssert(false, @"Unknown key type");
        }
        NSLog(@"Import %@ key:%@", newKey.type, keyID);
        [newKey release];
    }
}

#include <sys/socket.h> // Per msqr
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <malloc/malloc.h>

+ (NSString *) macaddress
{
    int                 mib[6];
    size_t              len;
    char                *buf;
    unsigned char       *ptr;
    struct if_msghdr    *ifm;
    struct sockaddr_dl  *sdl;

    mib[0] = CTL_NET;
    mib[1] = AF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_LINK;
    mib[4] = NET_RT_IFLIST;

    if ((mib[5] = if_nametoindex("en0")) == 0) {
        printf("Error: if_nametoindex error\n");
        return NULL;
    }

    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 1\n");
        return NULL;
    }

    if ((buf = (char*)malloc(len)) == NULL) {
        printf("Error: Memory allocation error\n");
        return NULL;
    }

    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 2\n");
        free(buf); // Thanks, Remy "Psy" Demerest
        return NULL;
    }

    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);
    NSString *outstring = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X", *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];

    free(buf);
    return outstring;
}



@end
