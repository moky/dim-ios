//
//  MKMECCPrivateKey.h
//  DIMClient
//
//  Created by Albert Moky on 2018/9/30.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import <MingKeMing/MingKeMing.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  ECC Private Key
 *
 *      keyInfo format: {
 *          algorithm: "ECC",
 *          curve: "secp256k1",
 *          data: "..."         // base64
 *      }
 */
@interface MKMECCPrivateKey : MKMPrivateKey

@end

NS_ASSUME_NONNULL_END
