//
//  DIMClient.h
//  DIMC
//
//  Created by Albert Moky on 2018/10/16.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "DIMCore.h"

NS_ASSUME_NONNULL_BEGIN

@class DIMServiceProvider;

@interface DIMClient : NSObject

@property (strong, nonatomic) MKMUser *currentUser;

@property (strong, nonatomic) DIMServiceProvider *serviceProvider;

@property (readonly, nonatomic) NSString *userAgent;

+ (instancetype)sharedInstance;

- (void)addUser:(MKMUser *)user;
- (void)removeUser:(MKMUser *)user;

@end

NS_ASSUME_NONNULL_END