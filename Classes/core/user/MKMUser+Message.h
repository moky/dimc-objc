//
//  MKMUser+Message.h
//  DIMCore
//
//  Created by Albert Moky on 2018/9/30.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "MingKeMing.h"

NS_ASSUME_NONNULL_BEGIN

@class DIMInstantMessage;
@class DIMSecureMessage;
@class DIMCertifiedMessage;

@interface MKMUser (Message)

- (DIMInstantMessage *)decryptMessage:(const DIMSecureMessage *)msg;

- (DIMCertifiedMessage *)signMessage:(const DIMSecureMessage *)msg;

// passphrase
- (MKMSymmetricKey *)keyForDecrpytMessage:(const DIMSecureMessage *)msg;

@end

NS_ASSUME_NONNULL_END