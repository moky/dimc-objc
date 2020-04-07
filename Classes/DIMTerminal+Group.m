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
//  DIMTerminal+Group.m
//  DIMClient
//
//  Created by Albert Moky on 2019/3/9.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <DIMSDK/DIMSDK.h>

#import "NSData+Crypto.h"

#import "DIMFacebook+Extension.h"
#import "DIMMessenger+Extension.h"
#import "MKMGroup+Extension.h"
#import "DIMGroupManager.h"
#import "DIMRegister.h"

#import "DIMTerminal+Group.h"

@implementation DIMTerminal (GroupManage)

- (nullable DIMGroup *)createGroupWithSeed:(NSString *)seed
                                      name:(NSString *)name
                                   members:(NSArray<DIMID *> *)list {
    DIMUser *user = self.currentUser;
    DIMID *founder = user.ID;

    // 0. make sure the founder is in the front
    NSUInteger index = [list indexOfObject:founder];
    if (index == NSNotFound) {
        NSAssert(false, @"the founder not found in the member list");
        // add the founder to the front of group members list
        NSMutableArray *mArray = [list mutableCopy];
        [mArray insertObject:founder atIndex:0];
        list = mArray;
    } else if (index != 0) {
        // move the founder to the front
        NSMutableArray *mArray = [list mutableCopy];
        [mArray exchangeObjectAtIndex:index withObjectAtIndex:0];
        list = mArray;
    }
    
    // 1. create profile
    DIMRegister *reg = [[DIMRegister alloc] init];
    DIMGroup *group = [reg createGroupWithSeed:seed name:name founder:founder];
    
    // 2. send out group info
    [self _broadcastGroup:group.ID meta:group.meta profile:group.profile];
    
    // 4. send out 'invite' command
    DIMGroupManager *gm = [[DIMGroupManager alloc] initWithGroupID:group.ID];
    [gm invite:list];
    
    return group;
}

- (BOOL)_broadcastGroup:(DIMID *)ID meta:(nullable DIMMeta *)meta profile:(DIMProfile *)profile {
    DIMMessenger *messenger = [DIMMessenger sharedInstance];
    DIMFacebook *facebook = [DIMFacebook sharedInstance];
    // create 'profile' command
    DIMCommand *cmd = [[DIMProfileCommand alloc] initWithID:ID
                                                       meta:meta
                                                    profile:profile];
    // 1. share to station
    [messenger sendCommand:cmd];
    // 2. send to group assistants
    NSArray<DIMID *> *assistants = [facebook assistantsOfGroup:ID];
    for (DIMID *ass in assistants) {
        [messenger sendContent:cmd receiver:ass];
    }
    return YES;
}

- (BOOL)updateGroupWithID:(DIMID *)group
                  members:(NSArray<DIMID *> *)list
                  profile:(nullable DIMProfile *)profile {
    DIMGroupManager *gm = [[DIMGroupManager alloc] initWithGroupID:group];
    DIMFacebook *facebook = [DIMFacebook sharedInstance];
    DIMID *owner = [facebook ownerOfGroup:group];
    NSArray<DIMID *> *members = [facebook membersOfGroup:group];
    DIMUser *user = self.currentUser;

    // 1. update profile
    if (profile) {
        [facebook saveProfile:profile];
        [self _broadcastGroup:group meta:nil profile:profile];
    }
    
    // 2. check expel
    NSMutableArray<DIMID *> *outMembers = [[NSMutableArray alloc] initWithCapacity:members.count];
    for (DIMID *item in members) {
        if ([list containsObject:item]) {
            continue;
        }
        [outMembers addObject:item];
    }
    if ([outMembers count] > 0) {
        // only the owner can expel members
        if (![owner isEqual:user.ID]) {
            NSLog(@"user (%@) not the owner of group: %@", user, group);
            return NO;
        }
        if (![gm expel:outMembers]) {
            NSLog(@"failed to expel members: %@", outMembers);
            return NO;
        }
        NSLog(@"%lu member(s) expeled: %@", outMembers.count, outMembers);
    }
    
    // 3. check invite
    NSMutableArray<DIMID *> *newMembers = [[NSMutableArray alloc] initWithCapacity:list.count];
    for (DIMID *item in list) {
        if ([members containsObject:item]) {
            continue;
        }
        [newMembers addObject:item];
    }
    if ([newMembers count] > 0) {
        // only the group member can invite new members
        if (![owner isEqual:user.ID] && ![members containsObject:user.ID]) {
            NSLog(@"user (%@) not a member of group: %@", user.ID, group);
            return NO;
        }
        if (![gm invite:newMembers]) {
            NSLog(@"failed to invite members: %@", newMembers);
            return NO;
        }
        NSLog(@"%lu member(s) invited: %@", newMembers.count, newMembers);
    }
    
    return YES;
}

@end
