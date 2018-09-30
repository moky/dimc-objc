//
//  MKMAsymmetricKey.h
//  MingKeMing
//
//  Created by Albert Moky on 2018/9/25.
//  Copyright © 2018年 DIM Group. All rights reserved.
//

#import "MKMCryptographyKey.h"

NS_ASSUME_NONNULL_BEGIN

#define ACAlgorithmRSA @"RSA"
#define ACAlgorithmECC @"ECC"

@protocol MKMPublicKey <NSObject>

/**
 *  CT = encrypt(text, PK)
 */
- (NSData *)encrypt:(const NSData *)plaintext;

/**
 *  OK = verify(text, signature, PK)
 */
- (BOOL)verify:(const NSData *)plaintext
     signature:(const NSData *)ciphertext;

@end

@protocol MKMPrivateKey <NSObject>

/**
 *  text = decrypt(CT, SK);
 */
- (NSData *)decrypt:(const NSData *)ciphertext;

/**
 *  signature = sign(text, SK);
 */
- (NSData *)sign:(const NSData *)plaintext;

@end

//@protocol MKMAsymmetricKey <MKMPublicKey, MKMPrivateKey>
//
//@end

/**
 *  Asymmetric Cryptography Key
 *
 *      keyInfo format: {
 *          algorithm: "ECC", // RSA, ...
 *          ...
 *      }
 */
@interface MKMAsymmetricKey : MKMCryptographyKey

@end

NS_ASSUME_NONNULL_END