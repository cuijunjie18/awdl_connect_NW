//
//  Advertiser.m
//  awdl_connect_oc
//
//  Created by junjiecui on 2026/4/3.
//
#import "Advertiser.h"
#import <string.h>
#import "../utils/NetworkManager.h"
#include "../services/TcpServer.hpp"

@interface Advertiser () <NSNetServiceDelegate>

@property (nonatomic, copy, readonly) NSString *serviceName;
@property (nonatomic, copy, readonly) NSString *serviceType;
@property (nonatomic, copy, readonly) NSString *serviceDomain;

@property (nonatomic, strong) NSNetService *publishingService;
@property (nonatomic, assign) os_log_t logger;

@end

@implementation Advertiser

- (instancetype)init {
    self = [super init];
    if (self) {
        _serviceName = @"awdl_cjj";
        _serviceType = @"_wechat-chatlog._tcp";
        _serviceDomain = @"local.";
        _logger = os_log_create("com.awdl.advertiser", "Advertiser");
    }
    return self;
}

- (void)startAdvertising {
    int port = 50001;
    self.publishingService = [[NSNetService alloc] initWithDomain:self.serviceDomain type:self.serviceType name:self.serviceName port:port];
    self.publishingService.delegate = self;
    self.publishingService.includesPeerToPeer = YES;

    [self.publishingService scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [self.publishingService publish];
    os_log_info(self.logger, "Started advertising");
}

- (void)stopAdvertising {
    if (self.publishingService) {
        [self.publishingService stop];
        [self.publishingService removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        self.publishingService = nil;
    }
    os_log_info(self.logger, "Stopped advertising");
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        TcpServer server = TcpServer(50001);
        server.start("awdl0");
    });
}

#pragma mark - NSNetServiceDelegate

- (void)netServiceDidPublish:(NSNetService *)sender {
    os_log_info(self.logger, "Service published successfully: %@", sender.name);
    [NetworkManager logAWDLIPv6Addresses];
//    [sender resolveWithTimeout:5.0]; // 加上才能获取解析结果
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary<NSString *, NSNumber *> *)errorDict {
    os_log_error(self.logger, "Failed to publish service: %@", errorDict);
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender {
    // 激活AWDL即可，不需要处理解析结果
    os_log_info(self.logger, "Service resolved successfully");
        
    // 获取并打印所有解析到的地址（通常包括 AWDL 接口的地址）
    NSArray<NSData *> *addresses = [sender addresses];
    for (NSData *addrData in addresses) {
        NSString *ipString = [self stringFromAddressData:addrData];
        if (ipString) {
            os_log_info(self.logger, "Resolved address: %@", ipString);
        }
    }
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary<NSString *, NSNumber *> *)errorDict {
    // 激活AWDL即可，不需要处理解析失败
    os_log_error(self.logger, "Failed to resolve service: %@", errorDict);
}

- (void)netServiceDidStop:(NSNetService *)sender {
    os_log_info(self.logger, "Service stopped");
}

# pragma mark - Private Helpers

// 辅助方法：将 sockaddr 二进制数据转换为 IP 字符串
- (NSString *)stringFromAddressData:(NSData *)data {
    struct sockaddr *addr = (struct sockaddr *)data.bytes;
    char host[NI_MAXHOST];
    if (getnameinfo(addr, (socklen_t)data.length, host, NI_MAXHOST, NULL, 0, NI_NUMERICHOST) == 0) {
        return [NSString stringWithUTF8String:host];
    }
    return nil;
}

@end
