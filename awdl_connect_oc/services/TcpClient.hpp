//
//  TcpClient.hpp
//  awdl_connect_oc
//
//  Created by junjiecui on 2026/4/5.
//

#ifndef TcpClient_hpp
#define TcpClient_hpp

#include <stdio.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <netdb.h>
#include <net/if.h>
#include <string.h>

class TcpClient {
public:
    TcpClient();
    ~TcpClient();
    void connect_ipv6(const char *ipv6_address, const char* interface_name, int port);
    
private:
    int client_fd_;
};

#endif /* TcpClient_hpp */
