//
//  NetworkManager.m
//  awdl_connect_oc
//
//  Created by junjiecui on 2026/4/5.
//

#import "NetworkManager.h"
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <net/if.h>
#import <netdb.h>
#include <sys/socket.h>

// 使用 NSLog 进行日志输出（可替换为 os_log 如果需要）
#define LOG_INFO(fmt, ...) NSLog((fmt), ##__VA_ARGS__)
#define LOG_WARNING(fmt, ...) NSLog((@"⚠️ " fmt), ##__VA_ARGS__)
#define LOG_ERROR(fmt, ...) NSLog((@"❌ " fmt), ##__VA_ARGS__)

@implementation NetworkManager

+ (instancetype)sharedManager {
    static NetworkManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

+ (void)logAWDLIPv6Addresses {
    NSArray<NSString *> *addresses = [self getIPv6AddressesForInterface:@"awdl0"];
    if (addresses.count == 0) {
        LOG_WARNING(@"No IPv6 address found on awdl0 interface");
    } else {
        for (NSString *addr in addresses) {
            LOG_INFO(@"AWDL IPv6 address: %@", addr);
        }
    }
}

+ (NSArray<NSString *> *)getIPv6AddressesForInterface:(NSString *)interfaceName {
    NSMutableArray<NSString *> *addresses = [NSMutableArray array];
    struct ifaddrs *ifaddr = NULL;
    
    if (getifaddrs(&ifaddr) != 0) {
        LOG_ERROR(@"getifaddrs failed");
        return addresses;
    }
    
    for (struct ifaddrs *ifa = ifaddr; ifa != NULL; ifa = ifa->ifa_next) {
        NSString *name = [NSString stringWithUTF8String:ifa->ifa_name];
        if (![name isEqualToString:interfaceName]) {
            continue;
        }
        
        struct sockaddr *sa = ifa->ifa_addr;
        if (sa == NULL || sa->sa_family != AF_INET6) {
            continue;
        }
        
        char host[NI_MAXHOST];
        socklen_t salen = (socklen_t)sa->sa_len;
        if (getnameinfo(sa, salen, host, sizeof(host), NULL, 0, NI_NUMERICHOST) == 0) {
            NSString *addrString = [NSString stringWithUTF8String:host];
            [addresses addObject:addrString];
        }
    }
    freeifaddrs(ifaddr);
    return addresses;
}

@end
