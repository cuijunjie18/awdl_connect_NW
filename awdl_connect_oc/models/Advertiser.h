//
//  Advertiser.h
//  awdl_connect_oc
//
//  Created by junjiecui on 2026/4/3.
//
#import <Foundation/Foundation.h>
#import <Network/Network.h>
#import <os/log.h>
#import <netdb.h>
#import <sys/socket.h>

NS_ASSUME_NONNULL_BEGIN

@interface Advertiser : NSObject

- (void)startAdvertising;
- (void)stopAdvertising;

@end

NS_ASSUME_NONNULL_END

