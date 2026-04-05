//
//  Browser.m
//  awdl_connect_oc
//
//  Created by junjiecui on 2026/4/3.
//

#import "Browser.h"

@interface Browser () <NSNetServiceBrowserDelegate>

@property (nonatomic, copy, readonly) NSString *serviceName;
@property (nonatomic, copy, readonly) NSString *serviceType;
@property (nonatomic, copy, readonly) NSString *serviceDomain;

@property (nonatomic, strong) NSNetServiceBrowser *serviceBrowser;
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
    os_log_info(self.logger, "Stopped browsing");
}

#pragma mark - NSNetServiceBrowserDelegate

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing {
    os_log_info(self.logger, "didFindService %@", service.name);
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing {
    os_log_info(self.logger, "didRemoveService %@", service.name);
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didNotSearch:(NSDictionary<NSString *, NSNumber *> *)errorDict {
    os_log_error(self.logger, "didNotSearch %@", errorDict);
}



@end
