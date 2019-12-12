// license: https://mit-license.org
//
//  DIM-SDK : Decentralized Instant Messaging Software Development Kit
//
//                               Written in 2019 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2019 Albert Moky
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// =============================================================================
//
//  DIMFacebook+Extension.m
//  DIMClient
//
//  Created by Albert Moky on 2019/11/29.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSObject+Singleton.h"

#import "NSNotificationCenter+Extension.h"
#import "DIMClientConstants.h"

#import "MKMImmortals.h"
#import "DIMSocialNetworkDatabase.h"

#import "DIMMessenger+Extension.h"

#import "DIMFacebook+Extension.h"

@interface DIMAddressNameService (Extension)

@property (weak, nonatomic) DIMSocialNetworkDatabase *database;

+ (instancetype)sharedInstance;

@end

@interface _SharedANS : DIMAddressNameService {
    
    DIMSocialNetworkDatabase *_database;
}

+ (instancetype)sharedInstance;

@end

@implementation _SharedANS

SingletonImplementations(_SharedANS, sharedInstance)

- (DIMSocialNetworkDatabase *)database {
    return _database;
}

- (void)setDatabase:(DIMSocialNetworkDatabase *)database {
    _database = database;
}

- (nullable DIMID *)IDWithName:(NSString *)username {
    DIMID *ID = [_database ansRecordForName:username];
    if (ID) {
        return ID;
    }
    return [super IDWithName:username];
}

- (nullable NSArray<NSString *> *)namesWithID:(DIMID *)ID {
    NSArray<NSString *> *names = [_database namesWithANSRecord:ID];
    if (names) {
        return names;
    }
    return [super namesWithID:ID];
}

- (BOOL)saveID:(DIMID *)ID withName:(NSString *)username {
    if (![self cacheID:ID withName:username]) {
        // username is reserved
        return NO;
    }
    return [_database saveANSRecord:ID forName:username];
}

@end

@implementation DIMAddressNameService (Extension)

+ (instancetype)sharedInstance {
    return [_SharedANS sharedInstance];
}

- (DIMSocialNetworkDatabase *)database {
    NSAssert(false, @"override me!");
    return nil;
}

- (void)setDatabase:(DIMSocialNetworkDatabase *)database {
    NSAssert(false, @"override me!");
}

@end

#pragma mark -

@interface _SharedFacebook : DIMFacebook {
    
    // user db
    DIMSocialNetworkDatabase *_database;
    
    // immortal accounts
    MKMImmortals *_immortals;
    
    // query tables
    NSMutableDictionary<DIMID *, NSDate *> *_metaQueryTable;
    NSMutableDictionary<DIMID *, NSDate *> *_profileQueryTable;
}

@end

@implementation _SharedFacebook

SingletonImplementations(_SharedFacebook, sharedInstance)

- (instancetype)init {
    if (self = [super init]) {
        
        // user db
        _database = [[DIMSocialNetworkDatabase alloc] init];
        
        // immortal accounts
        _immortals = [[MKMImmortals alloc] init];
        
        // query tables
        _metaQueryTable    = [[NSMutableDictionary alloc] init];
        _profileQueryTable = [[NSMutableDictionary alloc] init];
        
        // ANS
        DIMAddressNameService *ans = [DIMAddressNameService sharedInstance];
        ans.database = _database;
        self.ans = ans;
    }
    return self;
}

- (nullable NSArray<DIMID *> *)allUsers {
    return [_database allUsers];
}

- (BOOL)saveUsers:(NSArray<DIMID *> *)list {
    return [_database saveUsers:list];
}

#pragma mark Storage

- (BOOL)saveMeta:(DIMMeta *)meta forID:(DIMID *)ID {
    return [_database saveMeta:meta forID:ID];
}

- (nullable DIMMeta *)loadMetaForID:(DIMID *)ID {
    if ([ID isBroadcast]) {
        // broadcast ID has not meta
        return nil;
    }
    // try from database
    DIMMeta *meta = [_database metaForID:ID];
    if (meta) {
        return meta;
    }
    // try from immortals
    if (MKMNetwork_IsPerson(ID.type)) {
        meta = [_immortals metaForID:ID];
        if (meta) {
            return meta;
        }
    }
    
    // check for duplicated querying
    NSDate *now = [[NSDate alloc] init];
    NSDate *lastTime = [_metaQueryTable objectForKey:ID];
    NSTimeInterval dt = [now timeIntervalSince1970] - [lastTime timeIntervalSince1970];
    if (dt > 30) {
        [_metaQueryTable setObject:now forKey:ID];
        // query from DIM network
        DIMMessenger *messenger = [DIMMessenger sharedInstance];
        [messenger queryMetaForID:ID];
    }
    
    return nil;
}

- (BOOL)saveProfile:(DIMProfile *)profile {
    return [_database saveProfile:profile];
}

- (nullable DIMProfile *)loadProfileForID:(DIMID *)ID {
    // try from database
    DIMProfile *profile = [_database profileForID:ID];
    BOOL isEmpty = [[profile propertyKeys] count] == 0;
    if (!isEmpty) {
        return profile;
    }
    // try from immortals
    if (MKMNetwork_IsPerson(ID.type)) {
        DIMProfile *tai = [_immortals profileForID:ID];
        if (tai) {
            return tai;
        }
    }
    
    // check for duplicated querying
    NSDate *now = [[NSDate alloc] init];
    NSDate *lastTime = [_profileQueryTable objectForKey:ID];
    NSTimeInterval dt = [now timeIntervalSince1970] - [lastTime timeIntervalSince1970];
    if (dt > 30) {
        [_profileQueryTable setObject:now forKey:ID];
        // query from DIM network
        DIMMessenger *messenger = [DIMMessenger sharedInstance];
        [messenger queryProfileForID:ID];
    }
    
    return profile;
}

- (BOOL)savePrivateKey:(DIMPrivateKey *)key user:(DIMID *)ID {
    return [_database savePrivateKey:key forID:ID];
}

- (nullable DIMPrivateKey *)loadPrivateKey:(DIMID *)ID {
    return (DIMPrivateKey *)[_database privateKeyForSignature:ID];
}

- (BOOL)saveContacts:(NSArray<DIMID *> *)contacts user:(DIMID *)ID {
    if (![self cacheContacts:contacts user:ID]) {
        return NO;
    }
    BOOL OK = [_database saveContacts:contacts user:ID];
    if (OK) {
        NSDictionary *info = @{@"ID": ID};
        [NSNotificationCenter postNotificationName:kNotificationName_ContactsUpdated
                                            object:self
                                          userInfo:info];
    }
    return OK;
}

- (nullable NSArray<DIMID *> *)loadContacts:(DIMID *)ID {
    return [_database contactsOfUser:ID];
}

- (BOOL)saveMembers:(NSArray<DIMID *> *)members group:(DIMID *)ID {
    if (![self cacheMembers:members group:ID]) {
        return NO;
    }
    BOOL OK = [_database saveMembers:members group:ID];
    if (OK) {
        NSDictionary *info = @{@"group": ID};
        [NSNotificationCenter postNotificationName:kNotificationName_GroupMembersUpdated
                                            object:self
                                          userInfo:info];
    }
    return OK;
}

- (nullable NSArray<DIMID *> *)loadMembers:(DIMID *)ID {
    return [_database membersOfGroup:ID];
}

@end

#pragma mark -

@implementation DIMFacebook (Extension)

+ (instancetype)sharedInstance {
    return [_SharedFacebook sharedInstance];
}

- (nullable NSArray<DIMID *> *)allUsers {
    NSAssert(false, @"override me!");
    return nil;
}

- (BOOL)saveUsers:(NSArray<DIMID *> *)list {
    NSAssert(false, @"override me!");
    return NO;
}

@end
