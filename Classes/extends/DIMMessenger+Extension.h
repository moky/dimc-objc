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
//  DIMMessenger+Extension.h
//  DIMClient
//
//  Created by Albert Moky on 2019/11/29.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <DIMSDK/DIMSDK.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kNotificationName_MessageSent;
extern NSString * const kNotificationName_SendMessageFailed;

@interface DIMMessenger (Extension)

@property (strong, nonatomic) DIMStation *currentServer;

+ (instancetype)sharedInstance;

- (BOOL)sendContent:(id<DKDContent>)content receiver:(id<MKMID>)receiver;

/**
 *  broadcast message content to everyone@everywhere
 *
 * @param content - broadcast content
 * @return YES on sucess
 */
- (BOOL)broadcastContent:(id<DKDContent>)content;

/**
 *  pack and send command to station
 *
 * @param cmd - command
 * @return YES on success
 */
- (BOOL)sendCommand:(DIMCommand *)cmd;

/**
 *  Interface for client to query meta from station
 *
 * @param ID - entity ID
 * @return YES on success
 */
- (BOOL)queryMetaForID:(id<MKMID>)ID;

/**
 *  Interface for client to query document from station
 *
 * @param ID - entity ID
 * @return YES on success
 */
- (BOOL)queryDocumentForID:(id<MKMID>)ID;

/**
 *  Query group member list from any member
 *
 * @param group - group ID
 * @param member - member ID
 * @return YES on success
 */
- (BOOL)queryGroupForID:(id<MKMID>)group fromMember:(id<MKMID>)member;
- (BOOL)queryGroupForID:(id<MKMID>)group fromMembers:(NSArray<id<MKMID>> *)members;

/**
 *  Post document & meta to station
 *
 * @param doc - entity document
 * @param meta - enntity meta
 * @return YES on success
 */
- (BOOL)postDocument:(id<MKMDocument>)doc withMeta:(nullable id<MKMMeta>)meta;

/**
 *  Broadcast visa to all contacts
 *
 * @param visa - user visa document
 * @return YES on success
 */
- (BOOL)broadcastVisa:(id<MKMVisa>)visa;

/**
 *  Encrypt and post contacts list to station
 *
 * @param contacts - ID list
 * @return YES on success
 */
- (BOOL)postContacts:(NSArray<id<MKMID>> *)contacts;

/**
 *  Query contacts while login from a new device
 *
 * @return YES on success
 */
- (BOOL)queryContacts;

/**
 *  Query mute-list from station
 *
 * @return YES on success
 */
- (BOOL)queryMuteList;

@end

NS_ASSUME_NONNULL_END
