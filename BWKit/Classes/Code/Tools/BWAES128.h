//
//  BWAES128.h
//  BWKit
//
//  Created by yuhua on 2020/5/27.
//  Copyright © 2020 bw. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BWAES128 : NSObject

/**
 进行aes128加密

 @param pwd 密码
 @param random 随机码，没有填nil
 @param key 密钥
 @return 返回十六进制的字符串
 */
+ (NSString *)aes128Encryption:(NSString *)pwd random:(NSString *)random key:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
