//
//  Cipher.m
//  nCryptedBox
//
//  Created by Oleg Lavronov on 7/29/12.
//  Copyright (c) 2012 Lundlay. All rights reserved.
//

#include "tinyxml.h"
#include "ncrpt_base.h"
#include "ncryptor.h"
#include "ncrpt_rsa.h"


#import "Cipher.h"
#import "NCryptException.h"


#ifdef __cplusplus
extern "C" {
#include <polarssl/sha2.h>
#include <polarssl/rsa.h>
}
#endif


static PNCRYPT_TABLE g_NcryptTable = nil;


@implementation Cipher
{
@private
    rsa_context* _rsaContext;
}

+(void) initialize
{
    if (g_NcryptTable == nil)
        g_NcryptTable = Ncryptor_Initialize();
}

- (id) init {
	if (self= [super init]) {
        //        rsa_init(_rsaContext, RSA_PKCS_V15, 0);
        _rsaContext = (rsa_context*)malloc(sizeof(rsa_context));
        rsa_init(_rsaContext, RSA_PKCS_V15, 0, _rsa_rng, NULL );
	}
	return self;
}


- (void) dealloc {
	rsa_free(_rsaContext);
	[super dealloc];
}


#pragma mark -
#pragma mark Base64


static char base64EncodingTable[64] = {
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
    'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
    'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
    'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/'
};


+ (NSData *)base64DataFromString: (NSString *)string
{
    unsigned long ixtext, lentext;
    unsigned char ch, inbuf[4], outbuf[3];
    short i, ixinbuf;
    Boolean flignore, flendtext = false;
    const unsigned char *tempcstring;
    NSMutableData *theData;

    if (string == nil)
    {
        return [NSData data];
    }

    ixtext = 0;

    tempcstring = (const unsigned char *)[string UTF8String];

    lentext = [string length];

    theData = [NSMutableData dataWithCapacity: lentext];

    ixinbuf = 0;

    while (true)
    {
        if (ixtext >= lentext)
        {
            break;
        }

        ch = tempcstring [ixtext++];

        flignore = false;

        if ((ch >= 'A') && (ch <= 'Z'))
        {
            ch = ch - 'A';
        }
        else if ((ch >= 'a') && (ch <= 'z'))
        {
            ch = ch - 'a' + 26;
        }
        else if ((ch >= '0') && (ch <= '9'))
        {
            ch = ch - '0' + 52;
        }
        else if (ch == '+')
        {
            ch = 62;
        }
        else if (ch == '=')
        {
            flendtext = true;
        }
        else if (ch == '/')
        {
            ch = 63;
        }
        else
        {
            flignore = true;
        }

        if (!flignore)
        {
            short ctcharsinbuf = 3;
            Boolean flbreak = false;

            if (flendtext)
            {
                if (ixinbuf == 0)
                {
                    break;
                }

                if ((ixinbuf == 1) || (ixinbuf == 2))
                {
                    ctcharsinbuf = 1;
                }
                else
                {
                    ctcharsinbuf = 2;
                }

                ixinbuf = 3;

                flbreak = true;
            }

            inbuf [ixinbuf++] = ch;

            if (ixinbuf == 4)
            {
                ixinbuf = 0;

                outbuf[0] = (inbuf[0] << 2) | ((inbuf[1] & 0x30) >> 4);
                outbuf[1] = ((inbuf[1] & 0x0F) << 4) | ((inbuf[2] & 0x3C) >> 2);
                outbuf[2] = ((inbuf[2] & 0x03) << 6) | (inbuf[3] & 0x3F);

                for (i = 0; i < ctcharsinbuf; i++)
                {
                    [theData appendBytes: &outbuf[i] length: 1];
                }
            }
            
            if (flbreak)
            {
                break;
            }
        }
    }
    
    return theData;
}


+ (NSString *) base64StringFromData: (NSData *)data length: (int)length
{
    unsigned long ixtext, lentext;
    long ctremaining;
    unsigned char input[3], output[4];
    short i, charsonline = 0, ctcopy;
    const unsigned char *raw;
    NSMutableString *result;

    lentext = [data length];
    if (lentext < 1)
        return @"";
    result = [NSMutableString stringWithCapacity: lentext];
    raw = (const unsigned char*)[data bytes];
    ixtext = 0;

    while (true) {
        ctremaining = lentext - ixtext;
        if (ctremaining <= 0)
            break;
        for (i = 0; i < 3; i++) {
            unsigned long ix = ixtext + i;
            if (ix < lentext)
                input[i] = raw[ix];
            else
                input[i] = 0;
        }
        output[0] = (input[0] & 0xFC) >> 2;
        output[1] = ((input[0] & 0x03) << 4) | ((input[1] & 0xF0) >> 4);
        output[2] = ((input[1] & 0x0F) << 2) | ((input[2] & 0xC0) >> 6);
        output[3] = input[2] & 0x3F;
        ctcopy = 4;
        switch (ctremaining) {
            case 1:
                ctcopy = 2;
                break;
            case 2:
                ctcopy = 3;
                break;
        }

        for (i = 0; i < ctcopy; i++)
            [result appendString: [NSString stringWithFormat: @"%c", base64EncodingTable[output[i]]]];
        
        for (i = ctcopy; i < 4; i++)
            [result appendString: @"="];
        
        ixtext += 3;
        charsonline += 4;
        
        if ((length > 0) && (charsonline >= length))
            charsonline = 0;
    }     
    return result;
}



+(NSString *)base64StringFromData:(NSData *)data
{
    //Point to start of the data and set buffer sizes
    int inLength = [data length];
    int outLength = ((((inLength * 4)/3)/4)*4) + (((inLength * 4)/3)%4 ? 4 : 0);
    const char *inputBuffer = (const char *)[data bytes];
    char *outputBuffer = (char*)malloc(outLength);
    outputBuffer[outLength] = 0;
    
    //64 digit code
    static char Encode[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    
    //start the count
    int cycle = 0;
    int inpos = 0;
    int outpos = 0;
    char temp;
    
    //Pad the last to bytes, the outbuffer must always be a multiple of 4
    outputBuffer[outLength-1] = '=';
    outputBuffer[outLength-2] = '=';
    
    /* http://en.wikipedia.org/wiki/Base64
     Text content   M           a           n
     ASCII          77          97          110
     8 Bit pattern  01001101    01100001    01101110
     
     6 Bit pattern  010011  010110  000101  101110
     Index          19      22      5       46
     Base64-encoded T       W       F       u
     */
    
    
    while (inpos < inLength){
        switch (cycle) {
            case 0:
                outputBuffer[outpos++] = Encode[(inputBuffer[inpos]&0xFC)>>2];
                cycle = 1;
                break;
            case 1:
                temp = (inputBuffer[inpos++]&0x03)<<4;
                outputBuffer[outpos] = Encode[temp];
                cycle = 2;
                break;
            case 2:
                outputBuffer[outpos++] = Encode[temp|(inputBuffer[inpos]&0xF0)>> 4];
                temp = (inputBuffer[inpos++]&0x0F)<<2;
                outputBuffer[outpos] = Encode[temp];
                cycle = 3;
                break;
            case 3:
                outputBuffer[outpos++] = Encode[temp|(inputBuffer[inpos]&0xC0)>>6];
                cycle = 4;
                break;
            case 4:
                outputBuffer[outpos++] = Encode[inputBuffer[inpos++]&0x3f];
                cycle = 0;
                break;                          
            default:
                cycle = 0;
                break;
        }
    }
    NSString *pictemp = [NSString stringWithUTF8String:outputBuffer];
    free(outputBuffer); 
    return pictemp;
}


+ (NSData*) getHashValue:(NSData*)secret
{
    const char *string = (const char *)[secret bytes];
    unsigned char output[32] = {0};
    
    /* Hash folder */
    /*
    sha256_ctx ctx;
    sha256_init(&ctx);
    sha256_update(&ctx, (const unsigned char *)string, secret.length);
    sha256_final(&ctx, output);
     */

    /* Polar SSL */
    sha2_context ctx;
    
    sha2_starts(&ctx, 0);
    sha2_update(&ctx, (const unsigned char *)string, (size_t)secret.length);
    sha2_finish(&ctx, output);
    
    return [NSData dataWithBytes:output length:sizeof(output)];
}


+ (NSData*) hashPasswordWithSalt:(NSData*)secret entropy:(NSData*)entropy
{
    const char *string = (const char *)[secret bytes];
    const char *alt = (const char *)[entropy bytes];
    unsigned char output[32] = {0};
    
    /* Hash */
    /*
    sha256_ctx ctx;
    
    sha256_init(&ctx);
    sha256_update(&ctx, (const unsigned char *)string, secret.length);
    sha256_update(&ctx, (const unsigned char *)alt, entropy.length);
    sha256_final(&ctx, output);
*/
    /* PolarSSL */

    sha2_context ctx;
    
    sha2_starts(&ctx, 0);
    sha2_update(&ctx, (const unsigned char *)string, secret.length);
    sha2_update(&ctx, (const unsigned char *)alt, entropy.length);
    sha2_finish(&ctx, output);

    return [NSData dataWithBytes:output length:sizeof(output)];

}

+ (NSString*) generatePassword:(NSString*)secret withEntropy:(NSString*)entropy count:(NSUInteger)count
{
    const char *string = [secret UTF8String];
    NSData* secretKey;
    
    if (secret.length <= 32) {
        char key[32] = {0};
        memcpy(key, string, [secret lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
        secretKey = [NSData dataWithBytes:(const void *)key length:sizeof(key)];
    } else {
        secretKey = [Cipher getHashValue:[secret dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    secretKey = [secretKey subdataWithRange:NSMakeRange(0, 32)];
    
    NSData* currentEntropy = [Cipher hashPasswordWithSalt:secretKey entropy:[entropy dataUsingEncoding:NSUTF8StringEncoding]];
    
    if (count > 1)
    {
        for (long i = 1; i < count; i++ )
        {
            char  buffer[32] = {0};
            const char* newEntropy = (const char*)[[Cipher hashPasswordWithSalt:secretKey entropy:currentEntropy] bytes];
            const char* curEntropy = (const char*)[currentEntropy bytes];
            
            for (long j = 0; j < currentEntropy.length; j++ )
            {
                buffer[j] = curEntropy[j] ^ newEntropy[j];
            }
            
            currentEntropy = [NSData dataWithBytes:(const void *)buffer length:sizeof(buffer)];
        }
    }

    return [Cipher base64StringFromData:currentEntropy];
}


+ (NSData*) generatePassword:(NSData*)secret withEntropy:(NSData*)entropy
{
    NSData* secretKey;

    if (secret.length <= 32) {
        char key[32] = {0};
        memcpy(key, [secret bytes], [secret length]);
        secretKey = [NSData dataWithBytes:(const void *)key length:sizeof(key)];
    } else {
        secretKey = [Cipher getHashValue:secret];
    }

    secretKey = [secretKey subdataWithRange:NSMakeRange(0, 32)];

    NSData* currentEntropy = [Cipher hashPasswordWithSalt:secretKey entropy:entropy];

    for (long i = 1; i < 4096; i++ )
    {
        char  buffer[32] = {0};
        const char* newEntropy = (const char*)[[Cipher hashPasswordWithSalt:secretKey entropy:currentEntropy] bytes];
        const char* curEntropy = (const char*)[currentEntropy bytes];

        for (long j = 0; j < currentEntropy.length; j++ )
        {
            buffer[j] = curEntropy[j] ^ newEntropy[j];
        }

        currentEntropy = [NSData dataWithBytes:(const void *)buffer length:sizeof(buffer)];
    }

    return currentEntropy;
}



- (NSString*) pkcs1_decrypt:(RsaMode)mode input:(NSString *)input{
    /**
     * \brief          Do an RSA operation, then remove the message padding
     *
     * \param ctx      RSA context
     * \param mode     RSA_PUBLIC or RSA_PRIVATE
     * \param olen     will contain the plaintext length
     * \param input    buffer holding the encrypted data
     * \param output   buffer that will hold the plaintext
     * \param output_max_len    maximum length of the output buffer
     *
     * \return         0 if successful, or an POLARSSL_ERR_RSA_XXX error code
     *
     * \note           The output buffer must be as large as the size
     *                 of ctx->N (eg. 128 bytes if RSA-1024 is used) otherwise
     *                 an error is thrown.
     int rsa_pkcs1_decrypt( rsa_context *ctx,
     int mode, size_t *olen,
     const unsigned char *input,
     unsigned char *output,
     size_t output_max_len );
     */
    int len = 0;
    const char *inStr = [input UTF8String];
    unsigned int max_len = 2048;
	unsigned char output[max_len];

    int err = rsa_pkcs1_decrypt(_rsaContext, (int)mode, &len, (const unsigned char *) inStr, output, max_len);

    if (err != 0)
    {
        NSLog(@"Error pkcs1_decrypt");
    }

    NSMutableString *result = [[NSMutableString alloc] init];
    for(int i = 0; i < max_len; i++ )
    {
        [result appendFormat:@"%02x", output[i]];
    }


    return result;
}


#pragma mark -
#pragma mark RSA keys

+ (NCRYPT_RSA_PARAM_VALUE) getRsaParam:(const char*)params
{
    NSData* data = [Cipher base64DataFromString:[NSString stringWithUTF8String:params]];
    NSLog(@"data length %d", [data length]);

    NCRYPT_RSA_PARAM_VALUE result;
    memset(result.data, 0x0, sizeof(result.data));
    result.cbLen = [data length];
    memcpy(&result.data, [data bytes], result.cbLen);
    return result;
}

+ (NSString*) setRsaParam:(NCRYPT_RSA_PARAM_VALUE)param
{
    NSData* data = [[[NSData alloc] initWithBytes:param.data length:param.cbLen] autorelease];
    NSString* result = [Cipher base64StringFromData:data];
    NSLog(@"param:%@", result);
    return result;
}


+ (NCRYPT_HANDLE_KEY_RSA) importPlainKey:(NSString*)xmlRSAKeyValue decryption:(BOOL)decryption
{

    NCRYPT_RSA_PARAM KeyData = {0};

    TiXmlDocument* xml = new TiXmlDocument;
    xml->Parse([xmlRSAKeyValue UTF8String]);
    TiXmlElement* root = xml->RootElement();

    if (root == nil)
        @throw [[[NCryptException alloc] initWithReason:@"Key storage file is wrong"] autorelease];

    TiXmlElement* modulus = root->FirstChildElement("Modulus");
    if (modulus)
        KeyData.N = [Cipher getRsaParam:modulus->GetText()];

    TiXmlElement* exponent = root->FirstChildElement("Exponent");
    if (exponent)
        KeyData.E = [Cipher getRsaParam:exponent->GetText()];

    // private
    if ( decryption )
    {
        TiXmlElement* p = root->FirstChildElement("P");
        if (p)
            KeyData.P = [Cipher getRsaParam:p->GetText()];

        TiXmlElement* q = root->FirstChildElement("Q");
        if (q)
            KeyData.Q = [Cipher getRsaParam:q->GetText()];

        TiXmlElement* dp = root->FirstChildElement("DP");
        if (dp)
            KeyData.DP = [Cipher getRsaParam:dp->GetText()];

        TiXmlElement* dq = root->FirstChildElement("DQ");
        if (dq)
            KeyData.DQ = [Cipher getRsaParam:dq->GetText()];

        TiXmlElement* inverseQ = root->FirstChildElement("InverseQ");
        if (inverseQ)
            KeyData.QP = [Cipher getRsaParam:inverseQ->GetText()];

        TiXmlElement* d = root->FirstChildElement("D");
        if (d)
            KeyData.D = [Cipher getRsaParam:d->GetText()];
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
    NCRYPT_HANDLE_KEY_RSA hKey;

    NCRYPT_STATUS status = g_NcryptTable->Rsa_ImportPlainKey((NCRYPT_KEY_TYPE_RSA)KeyData.rsaType,
                                                             &KeyData,
                                                             &hKey);

    RtlSecureZeroMemory(&KeyData, sizeof(KeyData));
    if ( NCRYPT_SUCCESS != status )
    {
        @throw [[[NCryptException alloc] initWithReason:@"Failed to import rsa key"] autorelease];
    }

    return hKey;
}

+ (NSString*)rsaToXml:(NCRYPT_HANDLE_KEY_RSA)hKey
{
    NCRYPT_KEY_TYPE_RSA keyType;
    NCRYPT_STATUS status = g_NcryptTable->Rsa_GetKeyType(hKey, &keyType);
    if (NCRYPT_SUCCESS != status)
    {
        @throw [[[NCryptException alloc] initWithReason:@"Cannot get rsa key type"] autorelease];
    }
    NCRYPT_RSA_PARAM keyData = {0};
	status = g_NcryptTable->Rsa_ExportPlainKey(hKey,
                                               keyType,
                                               &keyData);
    if (NCRYPT_SUCCESS != status)
    {
        @throw [[[NCryptException alloc] initWithReason:@"Failed to import rsa key"] autorelease];
    }
    
    TiXmlDocument* xmlDocument = new TiXmlDocument;
    TiXmlElement* root = new TiXmlElement("RSAKeyValue");
    xmlDocument->LinkEndChild(root);
    TiXmlElement* modulus = new TiXmlElement("Modulus");
    if (modulus) {
        modulus->LinkEndChild(new TiXmlText([[self setRsaParam:keyData.N] UTF8String]));
        root->LinkEndChild(modulus);
    }

    TiXmlElement* exponent = new TiXmlElement("Exponent");
    if (exponent) {
        exponent->LinkEndChild(new TiXmlText([[self setRsaParam:keyData.E] UTF8String]));
        root->LinkEndChild(exponent);
    }

    if (keyType == NCRYPT_TYPE_RSA_KEY_PRIVATE) {
        TiXmlElement* p = new TiXmlElement("P");
        if (p) {
            p->LinkEndChild(new TiXmlText([[self setRsaParam:keyData.P] UTF8String]));
            root->LinkEndChild(p);
        }

        TiXmlElement* q = new TiXmlElement("Q");
        if (q) {
            q->LinkEndChild(new TiXmlText([[self setRsaParam:keyData.Q] UTF8String]));
            root->LinkEndChild(q);
        }

        TiXmlElement* dp = new TiXmlElement("DP");
        if (dp) {
            dp->LinkEndChild(new TiXmlText([[self setRsaParam:keyData.DP] UTF8String]));
            root->LinkEndChild(dp);
        }

        TiXmlElement* dq = new TiXmlElement("DQ");
        if (dq) {
            dq->SetValue([[self setRsaParam:keyData.DQ] UTF8String]);
            root->LinkEndChild(dq);
        }

        TiXmlElement* inverseQ = new TiXmlElement("InverseQ");
        if (inverseQ) {
            inverseQ->LinkEndChild(new TiXmlText([[self setRsaParam:keyData.QP] UTF8String]));
            root->LinkEndChild(inverseQ);
        }

        TiXmlElement* d = new TiXmlElement("D");
        if (d) {
            d->LinkEndChild(new TiXmlText([[self setRsaParam:keyData.D] UTF8String]));
            root->LinkEndChild(d);
        }
    }

    TiXmlPrinter* xmlPrinter = new TiXmlPrinter;
    xmlDocument->Accept(xmlPrinter);

    NSString* result = [NSString stringWithCString:xmlPrinter->CStr() encoding:NSUTF8StringEncoding];
    delete xmlDocument;
    delete xmlPrinter;
    NSLog(@"RSA key type %d:\n%@", keyType, result);
    return result;
}

+ (NSDictionary*)generateNewRSAKey:(int)nBits includePrivateKey:(BOOL)includePrivateKey
{
    NCRYPT_HANDLE_KEY_RSA hPublicKey;
    NCRYPT_HANDLE_KEY_RSA hPrivateKey;

    NCRYPT_STATUS status = Ncrypt_Rsa_GenerateKeyPair(nBits, NCRYPT_DEFAULT_RSA_PUBLIC_EXPONENT,
                                                      &hPublicKey,
                                                      &hPrivateKey);

    if ( NCRYPT_SUCCESS != status )
    {
        @throw [[[NCryptException alloc] initWithReason:@"Failed generate key pair by rsa key"] autorelease];
    }


    NCRYPT_KEY_TYPE_RSA keyType;
    status = g_NcryptTable->Rsa_GetKeyType(hPrivateKey, &keyType);
    if (NCRYPT_SUCCESS != status)
    {
        @throw [[[NCryptException alloc] initWithReason:@"Cannot get rsa key type"] autorelease];
    }

    if (includePrivateKey && NCRYPT_TYPE_RSA_KEY_PRIVATE != keyType)
    {
        @throw [[[NCryptException alloc] initWithReason:@"Wrong rsa key type"] autorelease];
    }

	// export key in plain form
    NCRYPT_RSA_PARAM keyData = {0};
	status = g_NcryptTable->Rsa_ExportPlainKey(hPrivateKey,
                                               includePrivateKey ? NCRYPT_TYPE_RSA_KEY_PRIVATE: NCRYPT_TYPE_RSA_KEY_PUBLIC,
                                               &keyData );
    if (NCRYPT_SUCCESS != status)
    {
        @throw [[[NCryptException alloc] initWithReason:@"Failed to import rsa key"] autorelease];
    }

    NSDictionary* result = [NSDictionary dictionaryWithObjectsAndKeys:
                            [Cipher rsaToXml:hPublicKey],     @"public-key-xml",
                            [Cipher rsaToXml:hPrivateKey],       @"private-key-xml",
                            nil];


    return result;

/*

    TiXmlDocument* xmlDocument = new TiXmlDocument;
    TiXmlElement* root = new TiXmlElement("RSAKeyValue");
    xmlDocument->LinkEndChild(root);
    TiXmlElement* modulus = new TiXmlElement("Modulus");
    if (modulus) {
        modulus->LinkEndChild(new TiXmlText([[self setRsaParam:keyData.N] UTF8String]));
        root->LinkEndChild(modulus);
    }

    TiXmlElement* exponent = new TiXmlElement("Exponent");
    if (exponent) {
        exponent->LinkEndChild(new TiXmlText([[self setRsaParam:keyData.E] UTF8String]));
        root->LinkEndChild(exponent);
    }

    if (keyType == NCRYPT_TYPE_RSA_KEY_PRIVATE) {
        TiXmlElement* p = new TiXmlElement("P");
        if (p) {
            p->LinkEndChild(new TiXmlText([[self setRsaParam:keyData.P] UTF8String]));
            root->LinkEndChild(p);
        }

        TiXmlElement* q = new TiXmlElement("Q");
        if (q) {
            q->LinkEndChild(new TiXmlText([[self setRsaParam:keyData.Q] UTF8String]));
            root->LinkEndChild(q);
        }


        TiXmlElement* dp = new TiXmlElement("DP");
        if (dp) {
            dp->LinkEndChild(new TiXmlText([[self setRsaParam:keyData.DP] UTF8String]));
            root->LinkEndChild(dp);
        }

        TiXmlElement* dq = new TiXmlElement("DQ");
        if (dq) {
            dq->SetValue([[self setRsaParam:keyData.DQ] UTF8String]);
            root->LinkEndChild(dq);
        }

        TiXmlElement* inverseQ = new TiXmlElement("InverseQ");
        if (inverseQ) {
            inverseQ->LinkEndChild(new TiXmlText([[self setRsaParam:keyData.QP] UTF8String]));
            root->LinkEndChild(inverseQ);
        }

        TiXmlElement* d = new TiXmlElement("D");
        if (d) {
            d->LinkEndChild(new TiXmlText([[self setRsaParam:keyData.D] UTF8String]));
            root->LinkEndChild(d);
        }
    }


    TiXmlPrinter* xmlPrinter = new TiXmlPrinter;
    xmlDocument->Accept(xmlPrinter);

    NSString* result = [NSString stringWithCString:xmlPrinter->CStr() encoding:NSUTF8StringEncoding];
    delete xmlDocument;
    delete xmlPrinter;
    NSLog(@"RSA key:\n%@", result);
    return result;
 */
}


+ (NSString*)encryptByRSAKey:(NSString*)xmlRSAKey withData:(NSData*)data
{
    NCRYPT_HANDLE_KEY_RSA hKey = [self importPlainKey:xmlRSAKey decryption:NO];

    ULONG cbOut = 0;
    NCRYPT_STATUS status = Ncrypt_Rsa_Pkcs1Encrypt(hKey, (const UCHAR*)[data bytes], [data length],
                                                   nil, &cbOut);
    if ( NCRYPT_ERR_BUFFER_TOO_SMALL != status )
    {
        @throw [[[NCryptException alloc] initWithReason:@"Failed encrypt by rsa key"] autorelease];
    }

    UCHAR* buffer = (UCHAR*)malloc(cbOut);
    if(NCRYPT_SUCCESS != Ncrypt_Rsa_Pkcs1Encrypt( hKey, (const UCHAR*)[data bytes], [data length], buffer, &cbOut))
    {
        @throw [[[NCryptException alloc] initWithReason:@"Failed to encrypt"] autorelease];
    }

    NSData* bufferData = [[NSData alloc] initWithBytes:buffer length:cbOut];
    free(buffer);

    NSString* result = [Cipher base64StringFromData:bufferData];
    [bufferData release];

    NSLog(@"Encrypt RSA password: %@", result);

    return result;
}


+ (NSString*)decryptByRSAKey:(NSString*)xmlRSAKey withData:(NSData*)data
{
    NCRYPT_HANDLE_KEY_RSA hKey = [self importPlainKey:xmlRSAKey decryption:YES];

    ULONG cbOut = [data length];
    UCHAR* buffer = (UCHAR*)malloc(cbOut);
    if(NCRYPT_SUCCESS != Ncrypt_Rsa_Pkcs1Decrypt( hKey, (const UCHAR*)[data bytes], [data length], buffer, &cbOut))
    {
        @throw [[[NCryptException alloc] initWithReason:@"Failed to decrypt"] autorelease];
    }

    NSData* bufferData = [[NSData alloc] initWithBytes:buffer length:cbOut];
    free(buffer);

    NSString* result = [[[NSString alloc] initWithData:bufferData encoding:NSUTF8StringEncoding] autorelease];//[Cipher base64StringFromData:bufferData];
    [bufferData release];
    
    NSLog(@"Decrypt RSA password: %@", result);
    
    return result;
}


/*
NSData* data = [Cipher base64DataFromString:key.value];
NSString *xml = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
NSLog(@"Base64: %@", str);
//                        [Cipher importPlainKey:str decryption:YES];
[Cipher encryptByRSAKey:xml withData:];
*/


@end
