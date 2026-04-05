//
//  TcpService.h
//  awdl_connect_oc
//
//  Created by junjiecui on 2026/4/5.
//

#ifndef TcpService_h
#define TcpService_h

#include <stdio.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <netdb.h>
#include <net/if.h>
#include <string.h>

int tcp_server_start(const char *interface_name, int port);
int tcp_client_connect(const char *ipv6_address, const char* interface_name, int port);
#endif /* TcpService_h */
