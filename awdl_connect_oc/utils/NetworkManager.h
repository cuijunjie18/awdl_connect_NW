//
//  NetworkManager.h
//  awdl_connect_oc
//
//  Created by junjiecui on 2026/4/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NetworkManager : NSObject

+ (instancetype)sharedManager;

/// 获取并打印 AWDL 接口（awdl0）的 IPv6 地址
+ (void)logAWDLIPv6Addresses;

/// 获取指定网络接口的所有 IPv6 地址
/// @param interfaceName 接口名称，例如 @"awdl0"
/// @return IPv6 地址字符串数组
+ (NSArray<NSString *> *)getIPv6AddressesForInterface:(NSString *)interfaceName;

@end

NS_ASSUME_NONNULL_END
