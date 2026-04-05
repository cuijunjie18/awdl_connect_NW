//
//  TcpServer.cpp
//  awdl_connect_oc
//
//  Created by junjiecui on 2026/4/5.
//

#include "TcpServer.hpp"

TcpServer::TcpServer(int port): port_(port) {}
TcpServer::~TcpServer() {
    if (client_fd_ > 0) {
        close(client_fd_);
        client_fd_ = -1;
    }
    if (server_fd_ > 0) {
        close(server_fd_);
        server_fd_ = -1;
    }
}
void TcpServer::start(const char* interface) {
    // 创建 socket
    server_fd_ = socket(AF_INET6, SOCK_STREAM, 0);
    if (server_fd_) {
        perror("Socket creation failed.\n");
        return;
    }

    // 允许重用地址，避免 TIME_WAIT 状态导致 bind 失败
    int opt = 1;
    setsockopt(server_fd_, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    // Bind socket to the specified interface (e.g. awdl0)
    // On Apple platforms, AWDL is a special P2P interface that requires explicit binding
    #if defined(__APPLE__)
    unsigned int ifindex = if_nametoindex(interface);
    if (ifindex == 0) {
        perror("[TcpServer] if_nametoindex() failed");
        close(server_fd_);
        return;
    }
    if (setsockopt(server_fd_, IPPROTO_IPV6, IPV6_BOUND_IF, &ifindex, sizeof(ifindex)) < 0) {
        perror("[TcpServer] setsockopt(IPV6_BOUND_IF) failed");
        return;
    }
    printf("[TcpServer] Bound to interface %s (index %u)\n", interface, ifindex);
    #endif

    // 设置服务器地址结构体
    struct sockaddr_in6 server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin6_family = AF_INET6;
    server_addr.sin6_addr = in6addr_any; // 本地任意 IPv6 地址
    server_addr.sin6_port = htons(port_); // 端口号

    // 绑定 socket
    if (bind(server_fd_, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
        perror("Bind failed.\n");
        return;
    }

    // 开始监听
    if (listen(server_fd_, 1) < 0) {
        perror("Listen failed.\n");
        return;
    }
    
    printf("Server is listening on port %d...\n", port_);

    // 接受客户端连接
    struct sockaddr_in6 client_addr;
    socklen_t client_len = sizeof(client_addr);
    client_fd_ = accept(server_fd_, (struct sockaddr*)&client_addr, &client_len);
    if (client_fd_ < 0) {
        perror("Accept failed.\n");
        return;
    }
    
    char client_ip[INET6_ADDRSTRLEN];
    inet_ntop(AF_INET6, &client_addr.sin6_addr, client_ip, sizeof(client_ip));
    printf("Client connected from %s\n",client_ip);
    
    char buffer[1024];
    int bytes_received = (int) recv(client_fd_, buffer, sizeof(buffer), 0);
    if (bytes_received > 0) {
        buffer[bytes_received] = '\0';
        printf("Received message: %s\n", buffer);
        send(client_fd_, buffer, bytes_received, 0);
    } else {
        perror("Receive failed.\n");
    }
    return;
}
