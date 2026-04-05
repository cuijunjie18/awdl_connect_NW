//
//  Advertiser.m
//  awdl_connect_oc
//
//  Created by junjiecui on 2026/4/3.
//
#import "Advertiser.h"
#import <string.h>
#import "../utils/NetworkManager.h"
#include "../services/TcpService.h"

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

    // Publish AWDL IPv6 address and interface name via TXT Record,
    // so the Browser side can dynamically obtain the peer's address (same as Swift version).
    NSArray<NSString *> *awdlAddresses = [NetworkManager getIPv6AddressesForInterface:@"awdl0"];
    if (awdlAddresses.count > 0) {
        NSString *fullAddr = awdlAddresses[0]; // e.g. "fe80::xxxx%awdl0"
        NSArray<NSString *> *parts = [fullAddr componentsSeparatedByString:@"%"];
        NSString *ipv6 = parts[0];
        NSString *iface = (parts.count > 1) ? parts[1] : @"awdl0";
        
        NSDictionary *txtDict = @{
            @"DisplayName": @"CJJ_debug_iphone",
            @"awdl_ipv6": ipv6,
            @"awdl_interface": iface
        };
        NSData *txtData = [NSNetService dataFromTXTRecordDictionary:
            [self encodeTXTRecordDictionary:txtDict]];
        [self.publishingService setTXTRecordData:txtData];
        os_log_info(self.logger, "TXT Record set: ipv6=%{public}@, interface=%{public}@", ipv6, iface);
    } else {
        os_log_error(self.logger, "No AWDL IPv6 address found, TXT Record not set");
    }

    [self.publishingService scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [self.publishingService publish];
    os_log_info(self.logger, "Started advertising");
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        os_log_info(self.logger, "Tcp server started");
        tcp_server_start("awdl0", 50001);
    });
}

- (void)stopAdvertising {
    if (self.publishingService) {
        [self.publishingService stop];
        [self.publishingService removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        self.publishingService = nil;
    }
    os_log_info(self.logger, "Stopped advertising");
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

// Helper: convert NSDictionary<NSString*, NSString*> to NSDictionary<NSString*, NSData*> for TXT record
- (NSDictionary<NSString *, NSData *> *)encodeTXTRecordDictionary:(NSDictionary<NSString *, NSString *> *)dict {
    NSMutableDictionary<NSString *, NSData *> *result = [NSMutableDictionary dictionary];
    for (NSString *key in dict) {
        result[key] = [dict[key] dataUsingEncoding:NSUTF8StringEncoding];
    }
    return result;
}

// Helper: convert sockaddr binary data to IP string
- (NSString *)stringFromAddressData:(NSData *)data {
    struct sockaddr *addr = (struct sockaddr *)data.bytes;
    char host[NI_MAXHOST];
    if (getnameinfo(addr, (socklen_t)data.length, host, NI_MAXHOST, NULL, 0, NI_NUMERICHOST) == 0) {
        return [NSString stringWithUTF8String:host];
    }
    return nil;
}

@end
