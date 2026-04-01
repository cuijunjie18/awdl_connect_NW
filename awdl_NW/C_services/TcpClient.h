//
//  TcpClient.h
//  awdl_NW
//
//  Created by junjiecui on 2026/4/1.
//

#ifndef TcpClient_h
#define TcpClient_h

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <net/if.h>
#include <errno.h>

int tcp_client_connect(const char *ipv6_address, const char* interface_name, int port);

#endif /* TcpClient_h */
