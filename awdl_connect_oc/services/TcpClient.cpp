//
//  TcpClient.cpp
//  awdl_connect_oc
//
//  Created by junjiecui on 2026/4/5.
//

#include "TcpClient.hpp"

TcpClient::TcpClient() {}
TcpClient::~TcpClient() {
    if (client_fd_ > 0) {
        close(client_fd_);
    }
}
void TcpClient::connect_ipv6(const char *ipv6_address, const char* interface_name, int port) {
    // 创建 socket
    client_fd_ = socket(AF_INET6, SOCK_STREAM, 0);
    if (client_fd_ == -1) {
        perror("[TcpClient] socket() failed");
        return;
    }

    // Bind client socket to the specified interface (e.g. awdl0)
    // On Apple platforms, AWDL is a special P2P interface that requires explicit binding
    #if defined(__APPLE__)
    unsigned int ifindex = if_nametoindex(interface_name);
    if (ifindex == 0) {
        perror("[TcpClient] if_nametoindex() failed");
        return;
    }
    if (setsockopt(client_fd_, IPPROTO_IPV6, IPV6_BOUND_IF, &ifindex, sizeof(ifindex)) < 0) {
        perror("[TcpClient] setsockopt(IPV6_BOUND_IF) failed");
        return;
    }
    printf("[TcpClient] Bound to interface %s (index %u)\n", interface_name, ifindex);
    #endif

    // 设置服务器地址结构体
    struct sockaddr_in6 server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin6_family = AF_INET6;
    server_addr.sin6_port = htons(port);

    if (inet_pton(AF_INET6, ipv6_address, &server_addr.sin6_addr) <= 0) {
        perror("Invalid address/ Address not supported\n");
        return;
    }

    // 链路本地地址（fe80::）需要指定 scope_id（接口索引），否则系统无法确定从哪个接口发送
    server_addr.sin6_scope_id = if_nametoindex(interface_name);

    // 连接服务器
    if (connect(client_fd_, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
        perror("[TcpClient] connect() failed");
        return;
    }
    
    printf("[TcpClient] Connected to server at [%s]:%d\n", ipv6_address, port);
    
    char buffer[1024] = "Hello, I'm IPhone!";
    send(client_fd_, buffer, strlen(buffer), 0);
    int bytes_received = (int) recv(client_fd_, buffer, sizeof(buffer),0);
    if (bytes_received > 0) {
        buffer[bytes_received] = '\0'; // 添加字符串结束符
        printf("[TcpClient] Received from server: %s\n", buffer);
    } else {
        printf("[TcpClient] Receive failed\n");
    }
    return;
}
