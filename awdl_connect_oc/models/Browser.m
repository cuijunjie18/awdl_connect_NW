//
//  Browser.m
//  awdl_connect_oc
//
//  Created by junjiecui on 2026/4/3.
//

#import "Browser.h"
#include "../services/TcpService.h"

@interface Browser () <NSNetServiceBrowserDelegate, NSNetServiceDelegate>

@property (nonatomic, copy, readonly) NSString *serviceName;
@property (nonatomic, copy, readonly) NSString *serviceType;
@property (nonatomic, copy, readonly) NSString *serviceDomain;

@property (nonatomic, strong) NSNetServiceBrowser *serviceBrowser;
@property (nonatomic, strong) NSNetService *resolvedService;
@property (nonatomic, assign) os_log_t logger;

@end

@implementation Browser

- (instancetype)init {
    self = [super init];
    if (self) {
        _serviceName = @"awdl_cjj";
        _serviceType = @"_wechat-chatlog._tcp";
        _serviceDomain = @"local.";
        _logger = os_log_create("com.awdl.browser", "Browser");
    }
    return self;
}

- (void)startBrowsing {
    self.serviceBrowser = [[NSNetServiceBrowser alloc] init];
    self.serviceBrowser.delegate = self;
    self.serviceBrowser.includesPeerToPeer = YES;
    
    [self.serviceBrowser searchForServicesOfType:self.serviceType inDomain:self.serviceDomain];
    os_log_info(self.logger, "Started browsing");
}

- (void)stopBrowsing {
    if (self.serviceBrowser) {
        [self.serviceBrowser stop];
        self.serviceBrowser = nil;
    }
    if (self.resolvedService) {
        [self.resolvedService stop];
        self.resolvedService = nil;
    }
    os_log_info(self.logger, "Stopped browsing");
}

#pragma mark - NSNetServiceBrowserDelegate

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing {
    os_log_info(self.logger, "didFindService %{public}@", service.name);
    
    // Resolve the service to trigger AWDL route establishment and get TXT Record.
    // This is critical: resolving forces the system to maintain the AWDL route,
    // which is why NWBrowser (Swift version) works but raw connect() after NSNetServiceBrowser fails.
    self.resolvedService = service;
    service.delegate = self;
    service.includesPeerToPeer = YES;
    [service resolveWithTimeout:10.0];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing {
    os_log_info(self.logger, "didRemoveService %{public}@", service.name);
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didNotSearch:(NSDictionary<NSString *, NSNumber *> *)errorDict {
    os_log_error(self.logger, "didNotSearch %@", errorDict);
}

#pragma mark - NSNetServiceDelegate

// 该回调会在创建一个 NSNetService 对象时触发，通常是当 NSNetServiceBrowser 发现一个服务时，创建一个 NSNetService 对象。
- (void)netServiceDidResolveAddress:(NSNetService *)sender {
    os_log_info(self.logger, "Service resolved: %{public}@", sender.name);
    
    // Extract AWDL IPv6 address and interface name from TXT Record
    NSData *txtData = [sender TXTRecordData];
    if (!txtData) {
        os_log_error(self.logger, "No TXT Record data available");
        return;
    }
    
    NSDictionary<NSString *, NSData *> *txtDict = [NSNetService dictionaryFromTXTRecordData:txtData];
    NSString *ipv6 = nil;
    NSString *iface = nil;
    
    if (txtDict[@"awdl_ipv6"]) {
        ipv6 = [[NSString alloc] initWithData:txtDict[@"awdl_ipv6"] encoding:NSUTF8StringEncoding];
    }
    if (txtDict[@"awdl_interface"]) {
        iface = [[NSString alloc] initWithData:txtDict[@"awdl_interface"] encoding:NSUTF8StringEncoding];
    }
    
    if (!ipv6 || !iface) {
        os_log_error(self.logger, "TXT Record missing awdl_ipv6 or awdl_interface");
        return;
    }
    
    os_log_info(self.logger, "Peer address from TXT: %{public}@%%%{public}@", ipv6, iface);
    
    // Dispatch TCP connect to a background thread to avoid blocking the RunLoop.
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        tcp_client_connect([ipv6 UTF8String], [iface UTF8String], 50001);
    });
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary<NSString *, NSNumber *> *)errorDict {
    os_log_error(self.logger, "Failed to resolve service: %@", errorDict);
}

@end
