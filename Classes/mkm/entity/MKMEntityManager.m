//
//  MKMEntityManager.m
//  MingKeMing
//
//  Created by Albert Moky on 2018/10/2.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "MKMID.h"
#import "MKMMeta.h"
#import "MKMHistory.h"
#import "MKMEntityDelegate.h"

#import "MKMEntityManager.h"

@interface MKMEntityManager () {
    
    NSMutableDictionary<const MKMID *, MKMMeta *> *_metaTable;
    NSMutableDictionary<const MKMID *, MKMHistory *> *_historyTable;
}

@end

@implementation MKMEntityManager

static MKMEntityManager *s_sharedManager = nil;

+ (instancetype)sharedManager {
    if (!s_sharedManager) {
        s_sharedManager = [[self alloc] init];
    }
    return s_sharedManager;
}

+ (instancetype)alloc {
    NSAssert(!s_sharedManager, @"Attempted to allocate a second instance of a singleton.");
    return [super alloc];
}

- (instancetype)init {
    if (self = [super init]) {
        _metaTable = [[NSMutableDictionary alloc] init];
        _historyTable = [[NSMutableDictionary alloc] init];
        
        // Immortals
        [self loadEntityInfoFromFile:@"mkm_hulk"];
        [self loadEntityInfoFromFile:@"mkm_moki"];
    }
    return self;
}

- (BOOL)loadEntityInfoFromFile:(NSString *)filename {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *path;
    NSDictionary *dict;
    MKMID *ID;
    MKMMeta *meta;
    MKMHistory *history;
    
    path = [bundle pathForResource:filename ofType:@"plist"];
    if (![fm fileExistsAtPath:path]) {
        NSAssert(false, @"cannot load: %@", path);
        return NO;
    }
    dict = [NSDictionary dictionaryWithContentsOfFile:path];
    
    // ID
    ID = [dict objectForKey:@"ID"];
    ID = [MKMID IDWithID:ID];
    NSAssert(ID.isValid, @"invalid ID: %@", path);
    
    // meta
    meta = [dict objectForKey:@"meta"];
    meta = [MKMMeta metaWithMeta:meta];
    NSAssert([meta matchID:ID], @"meta not match: %@", path);
    
    // history
    history = [dict objectForKey:@"history"];
    history = [MKMHistory historyWithHistory:history];
    NSAssert(history, @"history not found: %@", path);
    
    [self setMeta:meta forID:ID];
    [self setHistory:history forID:ID];
    
    return ID.isValid && [meta matchID:ID] && history;
}

- (MKMMeta *)metaWithID:(const MKMID *)ID {
    NSAssert([ID isValid], @"Invalid ID");
    MKMMeta *meta = [_metaTable objectForKey:ID];
    if (!meta && _delegate) {
        meta = [_delegate queryMetaWithID:ID];
        if (meta) {
            [_metaTable setObject:meta forKey:ID];
        }
    }
    return meta;
}

- (void)setMeta:(MKMMeta *)meta forID:(const MKMID *)ID {
    NSAssert([ID isValid], @"Invalid ID");
    if ([meta matchID:ID]) {
        // set meta
        [_metaTable setObject:meta forKey:ID];
    }
}

- (MKMHistory *)historyWithID:(const MKMID *)ID {
    NSAssert(ID, @"ID cannot be empty");
    MKMHistory *history = [_historyTable objectForKey:ID];
    if (!history && _delegate) {
        history = [_delegate queryHistoryWithID:ID];
        if (history) {
            [_historyTable setObject:history forKey:ID];
        }
    }
    return history;
}

- (void)setHistory:(MKMHistory *)history forID:(const MKMID *)ID {
    NSAssert([ID isValid], @"Invalid ID");
    if (history) {
        [_historyTable setObject:history forKey:ID];
    }
}

@end