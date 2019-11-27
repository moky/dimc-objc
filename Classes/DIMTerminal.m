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
//  DIMTerminal.m
//  DIMClient
//
//  Created by Albert Moky on 2019/2/25.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSObject+JsON.h"

#import "MKMGroup+Extension.h"

#import "DIMFacebook.h"
#import "DIMMessenger.h"

#import "DIMAmanuensis.h"

#import "DIMServer.h"
#import "DIMTerminal+Request.h"
#import "DIMTerminal+Response.h"
#import "DIMTerminal+Group.h"
#import "DIMMuteCommand.h"
#import "DIMTerminal.h"

@interface DIMTerminal ()

@end

@implementation DIMTerminal

- (instancetype)init {
    if (self = [super init]) {
        _users = [[NSMutableArray alloc] init];
        
        _currentStation = nil;
        _session = nil;
    }
    return self;
}

- (NSString *)language {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *languages = [defaults objectForKey:@"AppleLanguages"];
    return languages.firstObject;
}

#pragma mark - User(s)

- (NSArray<DIMUser *> *)users {
    return [_users copy];
}

- (DIMUser *)currentUser {
    return _currentStation.currentUser;
}

- (void)setCurrentUser:(DIMUser *)user {
    _currentStation.currentUser = user;
    if (user && ![_users containsObject:user]) {
        // insert the user to the first
        [_users insertObject:user atIndex:0];
    }
    
    //Save current user
    [[NSUserDefaults standardUserDefaults] setObject:user.ID forKey:@"Current_User_ID"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)addUser:(DIMUser *)user {
    NSAssert([user.ID isValid], @"invalid user: %@", user);
    if (user && ![_users containsObject:user]) {
        [_users addObject:user];
    }
    // check current user
    if (!_currentStation.currentUser) {
        _currentStation.currentUser = user;
    }
}

- (void)removeUser:(DIMUser *)user {
    if ([_users containsObject:user]) {
        [_users removeObject:user];
    }
    // check current user
    if ([_currentStation.currentUser isEqual:user]) {
        _currentStation.currentUser = _users.firstObject;
    }
}

/**
 *  Process system command
 *
 * @return NO to let MessageProcessor(DB) finish the rest of the job
 */
- (BOOL)_processCommand:(DIMCommand *)cmd commander:(DIMID *)sender {
    // group commands
    if ([cmd isKindOfClass:[DIMGroupCommand class]]) {
        NSAssert(cmd.group, @"group command error: %@", cmd);
        // NOTICE: let MessageProcessor(DB) to parse group command
        return NO;
    }
    // history command
    if ([cmd isKindOfClass:[DIMHistoryCommand class]]) {
        //NSAssert(false, @"history command not supported yet: %@", cmd);
        
        if([cmd isKindOfClass:[DIMMuteCommand class]]){
            [self processMuteCommand:(DIMMuteCommand *)cmd];
            return YES;
        }
        
        return NO;
    }
    
    //
    //  system commands
    //
    if ([cmd isKindOfClass:[DIMHandshakeCommand class]]) {
        // handshake
        [self processHandshakeCommand:(DIMHandshakeCommand *)cmd];
        return YES;
    }
    if ([cmd isKindOfClass:[DIMProfileCommand class]]) {
        // query profile response
        [self processProfileCommand:(DIMProfileCommand *)cmd];
        return YES;
    }
    if ([cmd isKindOfClass:[DIMMetaCommand class]]) {
        // query meta response
        [self processMetaCommand:(DIMMetaCommand *)cmd];
        return YES;
    }
    
    // other commands
    NSString *command = cmd.command;
    if ([command isEqualToString:@"users"]) {
        // query online users response
        [self processOnlineUsersCommand:cmd];
        return YES;
    }
    if ([command isEqualToString:@"search"]) {
        // search users response
        [self processSearchUsersCommand:cmd];
        return YES;
    }
    if ([command isEqualToString:@"contacts"]) {
        // get contacts response
        [self processContactsCommand:cmd];
        return YES;
    }
    
    // NOTE: let the MessageProcessor(DB) to do the job
    return NO;
}

#pragma mark DIMStationDelegate

- (void)station:(DIMStation *)server didReceivePackage:(NSData *)data {
    
    // 1. decode to reliable message
    NSDictionary *dict = [data jsonDictionary];
    DIMReliableMessage *rMsg = DKDReliableMessageFromDictionary(dict);
    NSAssert(rMsg, @"failed to decode message: %@", dict);
    DIMMessenger *messenger = [DIMMessenger sharedInstance];

    // 2. verify it with sender's meta.key
    DIMSecureMessage *sMsg = [messenger verifyMessage:rMsg];
    if (!sMsg) {
        // NOTICE: if meta for sender not found,
        //         the client will query it automatically
        // TODO: insert the message to a temporary queue to waiting meta
        return ;
    }
    
    // 3. check receiver
    DIMUser *user = nil;
    DIMID *receiver = DIMIDWithString(rMsg.envelope.receiver);
    if (MKMNetwork_IsGroup(receiver.type)) {
        // group message
        NSAssert(sMsg.envelope.group == nil || [DIMIDWithString(sMsg.envelope.group) isEqual:receiver],
                 @"group error: %@ != %@", receiver, sMsg.envelope.group);
        // check group membership
        DIMGroup *group = DIMGroupWithID(receiver);
        for (DIMUser *item in self.users) {
            if ([group existsMember:item.ID]) {
                user = item;
                NSLog(@"got new message for: %@", item.ID);
                break;
            }
        }
        if (user) {
            // trim for current user
            sMsg = [sMsg trimForMember:user.ID];
        }
    } else {
        for (DIMUser *item in self.users) {
            if ([item.ID isEqual:receiver]) {
                user = item;
                NSLog(@"got new message for: %@", item.ID);
                break;
            }
        }
    }
    if (!user) {
        NSAssert(false, @"!!! wrong recipient: %@", receiver);
        return ;
    }
    
    // 4. decrypt it for local user
    DIMInstantMessage *iMsg = [messenger decryptMessage:sMsg];
    if (iMsg == nil) {
        NSLog(@"failed to decrypt message: %@", sMsg);
        return ;
    }
    DIMID *sender = DIMIDWithString(rMsg.envelope.sender);
    DIMContent *content = iMsg.content;
    
    // check meta for new group ID
    NSString *gid = content.group;
    if (gid) {
        DIMID *ID = DIMIDWithString(gid);
        if (![ID isBroadcast]) {
            // check meta
            DIMMeta *meta = DIMMetaForID(ID);
            if (!meta) {
                // NOTICE: if meta for group not found,
                //         the client will query it automatically
                // TODO: insert the message to a temporary queue to waiting meta
                return;
            }
        }
        // check whether the group members info needs update
        DIMGroup *group = DIMGroupWithID(ID);
        // if the group info not found, and this is not an 'invite' command
        //     query group info from the sender
        BOOL needsUpdate = group.founder == nil;
        if ([content isKindOfClass:[DIMInviteCommand class]]) {
            // FIXME: can we trust this stranger?
            //        may be we should keep this members list temporary,
            //        and send 'query' to the founder immediately.
            // TODO: check whether the members list is a full list,
            //       it should contain the group owner(founder)
            needsUpdate = NO;
        }
        if (needsUpdate) {
            DIMQueryGroupCommand *query;
            query = [[DIMQueryGroupCommand alloc] initWithGroup:ID];
            // query assistant
            NSArray<DIMID *> *assistants = group.assistants;
            for (DIMID *ass in assistants) {
                [self sendContent:query to:ass];
            }
            // query sender
            [self sendContent:query to:sender];
        }
    }

    // 5. process commands
    if ([content isKindOfClass:[DIMCommand class]]) {
        DIMCommand *cmd = (DIMCommand *)content;
        if ([self _processCommand:cmd commander:sender]) {
            NSLog(@"command processed: %@", content);
            return;
        }
        // NOTE: let the message processor to do the job
        //return;
    }
    
    if (MKMNetwork_IsStation(sender.type)) {
        NSLog(@"*** message from station: %@", content);
        //return ;
    }
    
    // 6. save the message
    //    it may be a normal message content,
    //    or a group command, or a receipt, ...
    DIMAmanuensis *clerk = [DIMAmanuensis sharedInstance];
    [clerk saveMessage:iMsg];
}

@end
