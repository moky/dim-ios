//
//  DIMInstantMessage.m
//  DIM
//
//  Created by Albert Moky on 2018/9/30.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "DIMEnvelope.h"
#import "DIMMessageContent.h"

#import "DIMInstantMessage.h"

@interface DIMInstantMessage ()

@property (strong, nonatomic) DIMMessageContent *content;

@end

@implementation DIMInstantMessage

- (instancetype)initWithEnvelope:(const DIMEnvelope *)env {
    NSAssert(false, @"DON'T call me");
    DIMMessageContent *content = nil;
    self = [self initWithContent:content envelope:env];
    return self;
}

- (instancetype)initWithContent:(const DIMMessageContent *)content
                         sender:(const MKMID *)from
                       receiver:(const MKMID *)to
                           time:(const NSDate *)time {
    DIMEnvelope *env = [[DIMEnvelope alloc] initWithSender:from
                                                  receiver:to
                                                      time:time];
    self = [self initWithContent:content envelope:env];
    return self;
}

/* designated initializer */
- (instancetype)initWithContent:(const DIMMessageContent *)content
                       envelope:(const DIMEnvelope *)env {
    NSAssert(content, @"content cannot be empty");
    NSAssert(env, @"envelope cannot be empty");
    if (self = [super initWithEnvelope:env]) {
        // content
        _content = [DIMMessageContent contentWithContent:content];
        [_storeDictionary setObject:_content forKey:@"content"];
    }
    return self;
}

/* designated initializer */
- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if (self = [super initWithDictionary:dict]) {
        dict = _storeDictionary;
        
        // content
        id content = [dict objectForKey:@"content"];
        _content = [DIMMessageContent contentWithContent:content];
    }
    return self;
}

@end
