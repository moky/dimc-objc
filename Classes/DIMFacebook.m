//
//  DIMFacebook.m
//  DIMClient
//
//  Created by Albert Moky on 2019/6/26.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSObject+Singleton.h"

#import "DIMServer.h"

#import "DIMFacebook.h"

@implementation DIMFacebook

SingletonImplementations(DIMFacebook, sharedInstance)

- (BOOL)verifyProfile:(DIMProfile *)profile {
    DIMID *ID = profile.ID;
    DIMPublicKey *key = nil;
    // check signer
    if (MKMNetwork_IsCommunicator(ID.type)) {
        // verify with meta.key
        DIMMeta *meta = [self metaForID:ID];
        key = meta.key;
    } else if (MKMNetwork_IsGroup(ID.type)) {
        // verify with group owner's meta.key
        DIMGroup *group = DIMGroupWithID(ID);
        DIMMeta *meta = [self metaForID:group.owner];
        key = meta.key;
    }
    return [profile verify:key];
}

- (DIMProfile *)profileForID:(DIMID *)ID {
    DIMProfile *profile = [super profileForID:ID];
    if (profile && [self verifyProfile:profile]) {
        // signature correct
        return profile;
    }
    // profile error
    return profile;
}

#pragma mark - DIMBarrackDelegate

- (nullable DIMAccount *)accountWithID:(DIMID *)ID {
    DIMAccount *account = [self.delegate accountWithID:ID];
    if (account) {
        if (account.dataSource == nil) {
            account.dataSource = self;
        }
        return account;
    }
    
    // check meta
    DIMMeta *meta = DIMMetaForID(ID);
    if (!meta) {
        NSLog(@"meta not found: %@", ID);
    }
    
    if (MKMNetwork_IsStation(ID.type)) {
        account = [[DIMServer alloc] initWithID:ID];
        return account;
    }
    
    account = [[DIMAccount alloc] initWithID:ID];
    account.dataSource = self;
    return account;
}

- (nullable DIMUser *)userWithID:(DIMID *)ID {
    DIMUser *user = [self.delegate userWithID:ID];
    if (user) {
        if (user.dataSource == nil) {
            user.dataSource = self;
        }
        return user;
    }
    
    // check meta
    DIMMeta *meta = DIMMetaForID(ID);
    if (!meta) {
        NSLog(@"meta not found: %@", ID);
    }
    
    user = [[DIMUser alloc] initWithID:ID];
    user.dataSource = self;
    return user;
}

- (nullable DIMGroup *)groupWithID:(DIMID *)ID {
    DIMGroup *group = [self.delegate groupWithID:ID];
    if (group) {
        if (group.dataSource == nil) {
            group.dataSource = self;
        }
        return group;
    }
    
    // check meta
    DIMMeta *meta = DIMMetaForID(ID);
    if (!meta) {
        NSLog(@"meta not found: %@", ID);
    }
    
    // create it
    if (ID.type == MKMNetwork_Polylogue) {
        group = [[DIMPolylogue alloc] initWithID:ID];
    } else if (ID.type == MKMNetwork_Chatroom) {
        group = [[DIMChatroom alloc] initWithID:ID];
    } else {
        NSAssert(false, @"group error: %@", ID);
    }
    group.dataSource = self;
    return group;
}

@end
