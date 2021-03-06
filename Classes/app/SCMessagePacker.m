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
//  SCMessagePacker.m
//  DIMClient
//
//  Created by Albert Moky on 2020/12/19.
//  Copyright © 2020 DIM Group. All rights reserved.
//

#import "SCMessagePacker.h"

@implementation SCMessagePacker

- (void)attachKeyDigest:(id<DKDReliableMessage>)rMsg {
    if (rMsg.delegate == nil) {
        rMsg.delegate = self.transceiver;
    }
    if ([rMsg encryptedKey]) {
        // 'key' exists
        return;
    }
    NSDictionary *keys = [rMsg encryptedKeys];
    if ([keys objectForKey:@"digest"]) {
        // key digest already exists
        return;
    }
    // get key with direction
    id<MKMSymmetricKey> key;
    id<MKMID> sender = rMsg.envelope.sender;
    id<MKMID> group = rMsg.envelope.group;
    if (group) {
        key = [self.messenger cipherKeyFrom:sender to:group generate:NO];
    } else {
        id<MKMID> receiver = rMsg.envelope.receiver;
        key = [self.messenger cipherKeyFrom:sender to:receiver generate:NO];
    }
    // get key data
    NSData *data = key.data;
    if ([data length] < 6) {
        if ([key.algorithm isEqualToString:@"PLAIN"]) {
            NSLog(@"broadcast message has no key: %@", rMsg);
            return;
        }
        NSAssert(false, @"key data error: %@", key);
        return;
    }
    // get digest
    NSRange range = NSMakeRange([data length] - 6, 6);
    NSData *part = [data subdataWithRange:range];
    NSData *digest = MKMSHA256Digest(part);
    NSString *base64 = MKMBase64Encode(digest);
    // set digest
    NSMutableDictionary *mDict = [[NSMutableDictionary alloc] initWithDictionary:keys];
    NSUInteger pos = base64.length - 8;
    [mDict setObject:[base64 substringFromIndex:pos] forKey:@"digest"];
    [rMsg setObject:mDict forKey:@"keys"];
}

#pragma mark Serialization

- (nullable NSData *)serializeMessage:(id<DKDReliableMessage>)rMsg {
    [self attachKeyDigest:rMsg];
    return [super serializeMessage:rMsg];
}

- (nullable id<DKDReliableMessage>)deserializeMessage:(NSData *)data {
    if ([data length] < 2) {
        return nil;
    }
    return [super deserializeMessage:data];
}

#pragma mark Reuse message key

- (nullable id<DKDSecureMessage>)encryptMessage:(id<DKDInstantMessage>)iMsg {
    id<DKDSecureMessage> sMsg = [super encryptMessage:iMsg];
    
    id<MKMID> receiver = iMsg.receiver;
    if (MKMIDIsGroup(receiver)) {
        // reuse group message keys
        id<MKMID> sender = iMsg.sender;
        id<MKMSymmetricKey> key = [self.messenger cipherKeyFrom:sender to:receiver generate:NO];
        [key setObject:@(YES) forKey:@"reused"];
    }
    // TODO: reuse personal message key?
    
    return sMsg;
}

- (nullable id<DKDInstantMessage>)decryptMessage:(id<DKDSecureMessage>)sMsg {
    id<DKDInstantMessage> iMsg = nil;
    @try {
        iMsg = [super decryptMessage:sMsg];
    } @catch (NSException *exception) {
        // check exception thrown by DKD: chat.dim.dkd.EncryptedMessage.decrypt()
        if ([exception.reason isEqualToString:@"failed to decrypt key in msg"]) {
            // visa.key not updated?
            DIMUser *user = [self.facebook currentUser];
            id<MKMVisa> visa = user.visa;
            NSAssert([visa isValid], @"user visa not found: %@", user);
            id<DIMCommand> cmd = [[DIMDocumentCommand alloc] initWithID:user.ID document:visa];
            [self.messenger sendContent:cmd sender:user.ID receiver:sMsg.sender callback:NULL priority:1];
        } else {
            // FIXME: message error?
            @throw exception;
        }
    } @finally {
        //
    }
    return iMsg;
}

@end
