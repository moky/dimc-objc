//
//  DIMCertifiedMessage.h
//  DIM
//
//  Created by Albert Moky on 2018/9/30.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "DIMSecureMessage.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Instant Message signed by an asymmetric key
 *
 *      data format: {
 *          //-- envelope
 *          sender   : "moki@xxx",
 *          receiver : "hulk@yyy",
 *          time     : 123,
 *          //-- content & key/keys
 *          content  : "...",  // Base64(symmetric)
 *          key      : "...",  // Base64(asymmetric)
 *          keys     : [],
 *          //-- signature
 *          signature: "..."   // Base64
 *      }
 */
@interface DIMCertifiedMessage : DIMSecureMessage

@property (readonly, strong, nonatomic) NSData *signature;

- (instancetype)initWithData:(const NSData *)content
                    envelope:(const DIMEnvelope *)env
                encryptedKey:(const NSData *)key
                   signature:(const NSData *)CT
NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithData:(const NSData *)content
                    envelope:(const DIMEnvelope *)env
               encryptedKeys:(const DIMEncryptedKeyMap *)keys
                   signature:(const NSData *)CT
NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithDictionary:(NSDictionary *)dict
NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
