// license: https://mit-license.org
//
//  SeChat : Secure/secret Chat Application
//
//                               Written in 2020 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2020 Albert Moky
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
//  SCMessageProcessor.m
//  DIMClient
//
//  Created by Albert Moky on 2020/12/13.
//  Copyright © 2020 DIM Group. All rights reserved.
//

#import "DIMFacebook+Extension.h"
#import "DIMMessenger+Extension.h"

#import "SCMessageProcessor.h"

@implementation SCMessageProcessor

- (instancetype)initWithMessenger:(DIMMessenger *)transceiver {
    if (self = [super initWithMessenger:transceiver]) {
    }
    return self;
}

- (DIMFacebook *)facebook {
    return [self.messenger facebook];
}

- (BOOL)isEmptyGroup:(id<MKMID>)group {
    id<MKMID> owner = [self.facebook ownerOfGroup:group];
    NSArray *members = [self.facebook membersOfGroup:group];
    return !owner || members.count == 0;
}

// check whether need to update group
- (BOOL)isWaitingGroup:(id<DKDContent>)content sender:(id<MKMID>)sender {
    // Check if it is a group message, and whether the group members info needs update
    id<MKMID> group = content.group;
    if (!group || MKMIDIsBroadcast(group)) {
        // 1. personal message
        // 2. broadcast message
        return NO;
    }
    // chek meta for new group ID
    id<MKMMeta> meta = [self.facebook metaForID:group];
    if (!meta) {
        // NOTICE: if meta for group not found,
        //         facebook should query it from DIM network automatically
        // TODO: insert the message to a temporary queue to wait meta
        //NSAssert(false, @"group meta not found: %@", group);
        return YES;
    }
    // query group command
    if ([self isEmptyGroup:group]) {
        // NOTICE: if the group info not found, and this is not an 'invite' command
        //         query group info from the sender
        if ([content isKindOfClass:[DIMInviteCommand class]] ||
            [content isKindOfClass:[DIMResetGroupCommand class]]) {
            // FIXME: can we trust this stranger?
            //        may be we should keep this members list temporary,
            //        and send 'query' to the owner immediately.
            // TODO: check whether the members list is a full list,
            //       it should contain the group owner(owner)
            return NO;
        } else {
            return [self.messenger queryGroupForID:group fromMember:sender];
        }
    } else if ([self.facebook group:group containsMember:sender] ||
               [self.facebook group:group containsAssistant:sender] ||
               [self.facebook group:group isOwner:sender]) {
        // normal membership
        return NO;
    } else {
        // if assistants exist, query them
        NSArray<id<MKMID>> *assistants = [self.facebook assistantsOfGroup:group];
        NSMutableArray<id<MKMID>> *mArray = [[NSMutableArray alloc] initWithCapacity:(assistants.count+1)];
        for (id<MKMID> item in assistants) {
            [mArray addObject:item];
        }
        // if owner found, query it
        id<MKMID> owner = [self.facebook ownerOfGroup:group];
        if (owner && ![mArray containsObject:owner]) {
            [mArray addObject:owner];
        }
        return [self.messenger queryGroupForID:group fromMembers:mArray];
    }
}

#pragma mark Process

- (nullable id<DKDContent>)processContent:(id<DKDContent>)content
                              withMessage:(id<DKDReliableMessage>)rMsg {
    id<MKMID> sender = rMsg.sender;
    if ([self isWaitingGroup:content sender:sender]) {
        // save this message in a queue to wait group meta response
        [rMsg setObject:rMsg.group forKey:@"waiting"];
        [self.messenger suspendMessage:rMsg];
        return nil;
    }
    
    id<DKDContent> res;
    @try {
        res = [super processContent:content withMessage:rMsg];
    } @catch (NSException *e) {
        if ([e.name isEqualToString:@"GroupError"]) {
            NSAssert([e.reason isEqualToString:@"not ready"], @"error: %@", e);
            id<MKMID> group = [e.userInfo objectForKey:@"group"];
            if (group) {
                [rMsg setObject:group forKey:@"waiting"];
                [self.messenger suspendMessage:rMsg];
            }
        }
    } @finally {
        //
    }
    if (!res) {
        // respond nothing
        return nil;
    }
    if ([res isKindOfClass:[DIMHandshakeCommand class]]) {
        // urgent command
        return res;
    }
    
    if ([res isKindOfClass:[DIMReceiptCommand class]]) {
        if (MKMNetwork_IsStation(sender.type)) {
            // no need to respond receipt to station
            return nil;
        }
        NSLog(@"receipt to sender: %@", sender);
    }
    
    // check receiver
    id<MKMID> receiver = rMsg.envelope.receiver;
    DIMUser *user = [self.facebook selectLocalUserWithID:receiver];
    NSAssert(user, @"receiver error: %@", receiver);
    
    // pack message
    id<DKDEnvelope> env = DKDEnvelopeCreate(user.ID, sender, nil);
    id<DKDInstantMessage> iMsg = DKDInstantMessageCreate(env, res);
    // normal response
    [self.messenger sendInstantMessage:iMsg callback:NULL priority:1];
    // DON'T respond to station directly
    return nil;
}

@end
