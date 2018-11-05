//
//  MKMSocialEntity.m
//  MingKeMing
//
//  Created by Albert Moky on 2018/9/28.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "MKMPublicKey.h"

#import "MKMID.h"
#import "MKMMeta.h"

#import "MKMSocialEntity.h"

@interface MKMSocialEntity ()

@property (strong, nonatomic) MKMID *founder;

@property (strong, nonatomic) NSArray<const MKMID *> *members;

@end

@implementation MKMSocialEntity

- (instancetype)initWithID:(const MKMID *)ID {
    MKMID *founderID = nil;
    self = [self initWithID:ID founderID:founderID];
    return self;
}

/* designated initializer */
- (instancetype)initWithID:(const MKMID *)ID
                 founderID:(const MKMID *)founderID {
    if (self = [super initWithID:ID]) {
        _founder = [founderID copy];
        _owner = nil;
        _members = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    MKMSocialEntity *social = [super copyWithZone:zone];
    if (social) {
        social.founder = _founder;
        social.owner = _owner;
        social.members = _members;
    }
    return social;
}

- (BOOL)isFounder:(const MKMID *)ID {
    NSAssert(ID.isValid, @"Invalid ID");
    NSAssert(_founder, @"founder not set yet");
    return [_founder isEqual:ID];
}

- (BOOL)isOwner:(const MKMID *)ID {
    NSAssert(ID.isValid, @"Invalid ID");
    NSAssert(_owner, @"owner not set yet");
    return [_owner isEqual:ID];
}

- (void)addMember:(const MKMID *)ID {
    NSAssert(ID.isValid, @"Invalid ID");
    if ([self isMember:ID]) {
        // don't add same member twice
        return;
    }
    [_members addObject:ID];
}

- (void)removeMember:(const MKMID *)ID {
    NSAssert([self isMember:ID], @"no such member found");
    [_members removeObject:ID];
}

- (BOOL)isMember:(const MKMID *)ID {
    NSAssert(ID.isValid, @"Invalid ID");
    return [_members containsObject:ID];
}

@end
