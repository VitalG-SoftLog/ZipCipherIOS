#pragma once

/* public api for steve reid's public domain SHA-1 implementation */
/* this file is in the public domain */

#ifndef __SHA1_H
#define __SHA1_H

#ifdef __cplusplus
extern "C" 
{
#endif

//#define SHA1_PRINT_RES

#ifndef uint8_t
typedef unsigned char uint8_t;
#endif

#ifndef uint32_t
typedef unsigned int uint32_t;
#endif

typedef struct 
{
    unsigned long total[2];     /*!< number of bytes processed  */
    unsigned long state[5];     /*!< intermediate digest state  */
    unsigned char buffer[64];   /*!< data block being processed */

    unsigned char ipad[64];     /*!< HMAC: inner padding        */
    unsigned char opad[64];     /*!< HMAC: outer padding        */ } sha1_ctx;

#define SHA1_DIGEST_SIZE 20

void sha1_init(sha1_ctx* context);
void sha1_update(sha1_ctx *ctx, const unsigned char *input, int ilen);
void sha1_final(sha1_ctx* context, uint8_t digest[SHA1_DIGEST_SIZE]);

void sha1(const unsigned char *input, int ilen, unsigned char output[SHA1_DIGEST_SIZE]);

void sha1_hmac_init( sha1_ctx *ctx, unsigned char *key, int keylen );
void sha1_hmac_update( sha1_ctx *ctx, unsigned char *input, int ilen );
void sha1_hmac_final( sha1_ctx *ctx, unsigned char output[SHA1_DIGEST_SIZE] );

void sha1_hmac( unsigned char *key, int keylen, unsigned char *input, int ilen, unsigned char output[SHA1_DIGEST_SIZE] ); 

#ifdef __cplusplus
}
#endif

#endif /* __SHA1_H */
