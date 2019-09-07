//
//  DIMTerminal+Request.m
//  DIMClient
//
//  Created by Albert Moky on 2019/2/25.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSNotificationCenter+Extension.h"

#import "DIMFacebook.h"
#import "DIMMessenger.h"

#import "DIMServer.h"
#import "DIMTerminal+Request.h"

NSString * const kNotificationName_MessageSent       = @"MessageSent";
NSString * const kNotificationName_SendMessageFailed = @"SendMessageFailed";

@implementation DIMTerminal (Packing)

- (nullable DIMInstantMessage *)sendContent:(DIMContent *)content
                                         to:(DIMID *)receiver {
    if (!self.currentUser) {
        NSLog(@"not login, drop message content: %@", content);
        // TODO: save the message content in waiting queue
        return nil;
    }
    if (!DIMMetaForID(receiver)) {
        // TODO: check profile.key
        NSLog(@"cannot get public key for receiver: %@", receiver);
        // NOTICE: if meta for sender not found,
        //         the client will query it automatically
        // TODO: save the message content in waiting queue
        return nil;
    }
    DIMID *sender = self.currentUser.ID;
    
    // make instant message
    DIMInstantMessage *iMsg = DKDInstantMessageCreate(content, sender, receiver, nil);
    // callback
    DIMTransceiverCallback callback;
    callback = ^(DIMReliableMessage *rMsg, NSError *error) {
        NSString *name = nil;
        if (error) {
            NSLog(@"send message error: %@", error);
            name = kNotificationName_SendMessageFailed;
            iMsg.state = DIMMessageState_Error;
            iMsg.error = [error localizedDescription];
        } else {
            NSLog(@"sent message: %@ -> %@", iMsg, rMsg);
            name = kNotificationName_MessageSent;
            iMsg.state = DIMMessageState_Accepted;
        }
        
        NSDictionary *info = @{@"message": iMsg};
        [NSNotificationCenter postNotificationName:name
                                            object:self
                                          userInfo:info];
    };
    // send out
    if ([[DIMMessenger sharedInstance] sendInstantMessage:iMsg callback:callback dispersedly:YES]) {
        return iMsg;
    } else {
        NSLog(@"failed to send message: %@", iMsg);
        return nil;
    }
}

- (void)sendCommand:(DIMCommand *)cmd {
    if (!_currentStation) {
        NSLog(@"not connect, drop command: %@", cmd);
        // TODO: save the command in waiting queue
        return ;
    }
    [self sendContent:cmd to:_currentStation.ID];
}

@end

@implementation DIMTerminal (Request)

- (BOOL)login:(DIMLocalUser *)user {
    if (!user || [self.currentUser isEqual:user]) {
        NSLog(@"user not change");
        return NO;
    }
    
    // clear session
    _session = nil;
    
    NSLog(@"logout: %@", self.currentUser);
    self.currentUser = user;
    NSLog(@"login: %@", user);
    
    // add to the list of this client
    if (![_users containsObject:user]) {
        [_users addObject:user];
    }
    return YES;
}

- (void)onHandshakeAccepted:(NSString *)session {
    // post current profile to station
    DIMProfile *profile = self.currentUser.profile;
    if (profile) {
        [self postProfile:profile];
    }
}

- (void)postProfile:(DIMProfile *)profile {
    DIMLocalUser *user = [self currentUser];
    DIMID *ID = user.ID;
    if (![profile.ID isEqual:ID]) {
        NSAssert(false, @"profile ID not match: %@, %@", ID, profile.ID);
        return ;
    }
    DIMCommand *cmd = [[DIMProfileCommand alloc] initWithID:profile.ID
                                                    profile:profile];
    [self sendCommand:cmd];
}

- (void)broadcastProfile:(DIMProfile *)profile {
    DIMLocalUser *user = [self currentUser];
    DIMID *ID = user.ID;
    if (![profile.ID isEqual:ID]) {
        NSAssert(false, @"profile ID not match: %@, %@", ID, profile.ID);
        return ;
    }
    DIMCommand *cmd = [[DIMProfileCommand alloc] initWithID:profile.ID
                                                    profile:profile];
    NSArray<DIMID *> *contacts = user.contacts;
    for (DIMID *contact in contacts) {
        [self sendContent:cmd to:contact];
    }
}

- (void)queryMetaForID:(DIMID *)ID {
    NSAssert(![ID isEqual:_currentStation.ID], @"should not query meta for this station: %@", ID);
    DIMCommand *cmd = [[DIMMetaCommand alloc] initWithID:ID];
    [self sendCommand:cmd];
}

- (void)queryProfileForID:(DIMID *)ID {
    DIMCommand *cmd = [[DIMProfileCommand alloc] initWithID:ID];
    [self sendCommand:cmd];
}

- (void)queryOnlineUsers {
    DIMCommand *cmd = [[DIMCommand alloc] initWithCommand:@"users"];
    [self sendCommand:cmd];
}

- (void)searchUsersWithKeywords:(NSString *)keywords {
    DIMCommand *cmd = [[DIMCommand alloc] initWithCommand:@"search"];
    [cmd setObject:keywords forKey:@"keywords"];
    [self sendCommand:cmd];
}

@end
