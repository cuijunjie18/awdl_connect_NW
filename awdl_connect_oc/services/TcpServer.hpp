//
//  TcpServer.hpp
//  awdl_connect_oc
//
//  Created by junjiecui on 2026/4/5.
//

#ifndef TcpServer_hpp
#define TcpServer_hpp

#include <stdio.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <netdb.h>
#include <net/if.h>
#include <string.h>

class TcpServer {
public:
    TcpServer(int port);
    ~TcpServer();
    void start(const char* interface);

private:
    int port_;
    int server_fd_;
    int client_fd_;
};

#endif /* TcpServer_hpp */
