// license: https://mit-license.org
//
//  DIM-SDK : Decentralized Instant Messaging Software Development Kit
//
//                               Written in 2019 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2019 Albert Moky
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
//  DIMFileServer.h
//  DIMClient
//
//  Created by Albert Moky on 2019/4/4.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface DIMFileServer : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate>

@property (strong, nonatomic, nullable) NSString *userAgent; // default is nil

// @"https://sechat.dim.chat/{ID}}/upload"
@property (strong, nonatomic) NSString *uploadAPI;

// @"https://sechat.dim.chat/download/{ID}/{filename}"
@property (strong, nonatomic) NSString *downloadAPI;

// @"https://sechat.dim.chat/avatar/{ID}/{filename}"
@property (strong, nonatomic) NSString *avatarAPI;

+ (instancetype)sharedInstance;

- (NSURL *)uploadEncryptedData:(NSData *)data
                      filename:(nullable NSString *)name
                        sender:(id<MKMID>)from;

- (nullable NSData *)downloadEncryptedDataFromURL:(NSURL *)url;

- (nullable NSData *)decryptDataFromURL:(NSURL *)url
                               filename:(NSString *)name
                                wityKey:(id<MKMSymmetricKey>)key;

- (BOOL)saveData:(NSData *)data filename:(NSString *)name;
- (NSData *)loadDataWithFilename:(NSString *)name;

- (BOOL)saveThumbnail:(NSData *)data filename:(NSString *)name;
- (NSData *)loadThumbnailWithFilename:(NSString *)name;

-(NSString *)cachePathForFilename:(NSString *)filename;

#pragma mark Avatar

- (NSURL *)uploadAvatar:(NSData *)data
               filename:(nullable NSString *)name
                 sender:(id<MKMID>)ID;

@end

NS_ASSUME_NONNULL_END
