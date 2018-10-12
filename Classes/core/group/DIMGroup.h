//
//  DIMGroup.h
//  DIM
//
//  Created by Albert Moky on 2018/9/30.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "MingKeMing.h"

NS_ASSUME_NONNULL_BEGIN

@class DIMInstantMessage;
@class DIMSecureMessage;

@protocol DIMGroup <NSObject>

- (DIMSecureMessage *)encryptMessage:(const DIMInstantMessage *)msg;

@end

@interface DIMGroup : MKMGroup <DIMGroup>

+ (instancetype)groupWithID:(const MKMID *)ID;

@end

NS_ASSUME_NONNULL_END
