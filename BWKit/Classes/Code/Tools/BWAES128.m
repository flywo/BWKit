//
//  BWAES128.m
//  BWKit
//
//  Created by yuhua on 2020/5/27.
//  Copyright © 2020 bw. All rights reserved.
//

#import "BWAES128.h"
#import <CommonCrypto/CommonCryptor.h>

@implementation BWAES128

+ (NSString *)aes128Encryption:(NSString *)pwd random:(NSString *)random key:(NSString *)key {
    
    //密钥
    char keyPtr[kCCKeySizeAES128+1];
    memset(keyPtr, 0, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSASCIIStringEncoding];
    
    //待加密密码
    char pwdPtr[16] = {};
    int x = 0;
    while (x<16) {
        if (x == 0) {
            pwdPtr[0] = pwd.length;
        }
        else if (x<=pwd.length) {
            pwdPtr[x] = [pwd characterAtIndex:x-1];
        }else if (x<=pwd.length+random.length/2) {
            int y = x-(int)pwd.length-1;
            pwdPtr[x] = [BWAES128 changeToInteger:[random substringWithRange:NSMakeRange(y*2, 2)]];
        }else {
            pwdPtr[x] = 0x00;
        }
        x++;
    }
    NSData* data = [NSData dataWithBytes:pwdPtr length:16];
    NSUInteger dataLength = [data length];
    NSInteger diff = kCCKeySizeAES128 - (dataLength % kCCKeySizeAES128);
    NSInteger newSize = 0;
    if(diff > 0)
    {
        newSize = dataLength + diff;
    }
    char dataPtr[newSize];
    memcpy(dataPtr, [data bytes], [data length]);
    for(int i = 0; i < diff; i++) {
        dataPtr[i + dataLength] = 0x00;
    }
    
    //输出
    size_t bufferSize = newSize + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    memset(buffer, 0, bufferSize);
    size_t numBytesCrypted = 0;
    
    //开始加密
    CCCryptorStatus status = CCCrypt(kCCEncrypt,
                                      kCCAlgorithmAES128,
                                      ccNoPadding,
                                      keyPtr,
                                      kCCKeySizeAES128,
                                      NULL,
                                      dataPtr,
                                      sizeof(dataPtr),
                                      buffer,
                                      bufferSize,
                                      &numBytesCrypted);
    
    if (status == kCCSuccess) {
        return [BWAES128 changeDataToHexStr:[NSData dataWithBytes:buffer length:16]];
    }else {
        return nil;
    }
}

/*!将NSDATA转成十六进制字符串*/
+ (NSString *)changeDataToHexStr:(NSData *)data {
    if (!data || [data length] == 0) {
        return @"";
    }
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[data length]];
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        unsigned char *dataBytes = (unsigned char*)bytes;
        for (NSInteger i = 0; i < byteRange.length; i++) {
            NSString *hexStr = [NSString stringWithFormat:@"%x", (dataBytes[i]) & 0xff];
            if ([hexStr length] == 2) {
                [string appendString:hexStr];
            } else {
                [string appendFormat:@"0%@", hexStr];
            }
        }
    }];
    return string;
}

+ (NSInteger)changeToInteger:(NSString *)string {
    return strtoul([string UTF8String], 0, 16);
}

@end
