//
//  MKMConsensus.h
//  MingKeMing
//
//  Created by Albert Moky on 2018/10/11.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "MKMEntityHistoryDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MKMConsensus : NSObject <MKMEntityHistoryDelegate>

@property (weak, nonatomic, nullable) id<MKMEntityHistoryDelegate> accountHistoryDelegate;
@property (weak, nonatomic, nullable) id<MKMEntityHistoryDelegate> groupHistoryDelegate;

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
