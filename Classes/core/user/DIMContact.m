//
//  DIMContact.m
//  DIM
//
//  Created by Albert Moky on 2018/9/30.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "NSObject+JsON.h"

#import "DIMInstantMessage.h"
#import "DIMSecureMessage.h"
#import "DIMCertifiedMessage.h"
#import "DIMEnvelope.h"
#import "DIMMessageContent.h"

#import "DIMKeyStore.h"

#import "DIMContact.h"

@implementation DIMContact

+ (instancetype)contactWithID:(const MKMID *)ID {
    NSAssert(ID.address.network == MKMNetwork_Main, @"address error");
    MKMConsensus *cons = [MKMConsensus sharedInstance];
    MKMEntityManager *em = [MKMEntityManager sharedManager];
    MKMMeta *meta = [em metaWithID:ID];
    MKMHistory *history = [em historyWithID:ID];
    DIMContact *contact = [[DIMContact alloc] initWithID:ID meta:meta];
    if (contact) {
        contact.historyDelegate = cons;
        NSUInteger count = [contact runHistory:history];
        NSAssert(count == history.count, @"history error");
    }
    return contact;
}

- (MKMSymmetricKey *)passphrase {
    DIMKeyStore *store = [DIMKeyStore sharedStore];
    return [store passphraseForEntity:self];
}

- (DIMSecureMessage *)encryptMessage:(const DIMInstantMessage *)msg {
    DIMEnvelope *env = msg.envelope;
    MKMID *to = env.receiver;
    NSAssert([to isEqual:_ID], @"recipient error");
    
    DIMMessageContent *content = msg.content;
    NSAssert(content, @"content cannot be empty");
    
    // 1. JsON
    NSData *json = [content jsonData];
    
    // 2. use a random symmetric key to encrypt the content
    MKMSymmetricKey *scKey = self.passphrase;
    NSAssert(scKey, @"passphrase cannot be empty");
    NSData *CT = [scKey encrypt:json];
    
    // 3. use the contact's public key to encrypt the symmetric key
    NSData *PW = [scKey jsonData];
    PW = [self encrypt:PW];
    
    // 4. create secure message
    return [[DIMSecureMessage alloc] initWithContent:CT
                                            envelope:env
                                           secretKey:PW];
}

- (DIMSecureMessage *)verifyMessage:(const DIMCertifiedMessage *)msg {
    DIMEnvelope *env = msg.envelope;
    MKMID *from = env.sender;
    NSAssert([from isEqual:_ID], @"sender error");
    
    NSData *content = msg.content;
    NSAssert(content, @"content cannot be empty");
    NSData *CT = msg.signature;
    NSAssert(CT, @"signature cannot be empty");
    
    // 1. use the contact's public key to verify the signature
    if (![self verify:content signature:CT]) {
        // signature error
        return nil;
    }
    
    NSData *PW = msg.secretKey;
    NSAssert(PW, @"secret key cannot be empty");
    
    // 2. create secure message
    return [[DIMSecureMessage alloc] initWithContent:content
                                            envelope:env
                                           secretKey:PW];
}

#pragma mark - Encrypt/Verify functions for passphrase/signature

- (NSData *)encrypt:(const NSData *)plaintext {
    MKMPublicKey *PK = self.publicKey;
    return [PK encrypt:plaintext];
}

- (BOOL)verify:(const NSData *)plaintext
     signature:(const NSData *)ciphertext {
    MKMPublicKey *PK = self.publicKey;
    return [PK verify:plaintext signature:ciphertext];
}

@end