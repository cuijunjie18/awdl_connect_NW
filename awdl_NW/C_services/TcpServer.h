//
//  TcpServer.h
//  awdl_NW
//
//  Created by junjiecui on 2026/4/1.
//

#ifndef TcpServer_h
#define TcpServer_h

#include <stdio.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <netdb.h>
#include <net/if.h>
#include <string.h>

int tcp_server_start(int port);

#endif /* TcpServer_h */
