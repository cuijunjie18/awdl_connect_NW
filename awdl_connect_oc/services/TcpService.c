//
//  TcpService.c
//  awdl_connect_oc
//
//  Created by junjiecui on 2026/4/5.
//

#include "TcpService.h"

int tcp_server_start(const char *interface_name, int port){
    // 创建 socket
    int server_socket = socket(AF_INET6, SOCK_STREAM, 0);
    if (server_socket == -1) {
        perror("[TcpServer] Socket creation failed.\n");
        return -1;
    }

    // 允许重用地址，避免 TIME_WAIT 状态导致 bind 失败
    int opt = 1;
    setsockopt(server_socket, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    // Bind socket to the specified interface (e.g. awdl0)
    // On Apple platforms, AWDL is a special P2P interface that requires explicit binding
    unsigned int ifindex = if_nametoindex(interface_name);
    if (ifindex == 0) {
        perror("[TcpServer] if_nametoindex() failed");
        close(server_socket);
        return -1;
    }
    if (setsockopt(server_socket, IPPROTO_IPV6, IPV6_BOUND_IF, &ifindex, sizeof(ifindex)) < 0) {
        perror("[TcpServer] setsockopt(IPV6_BOUND_IF) failed");
        close(server_socket);
        return -1;
    }
    printf("[TcpServer] Bound to interface %s (index %u)\n", interface_name, ifindex);

    // 设置服务器地址结构体
    struct sockaddr_in6 server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin6_family = AF_INET6;
    server_addr.sin6_addr = in6addr_any; // 本地任意 IPv6 地址
    server_addr.sin6_port = htons(port); // 端口号

    // 绑定 socket
    if (bind(server_socket, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
        perror("[TcpServer] Bind failed.\n");
        return -1;
    }

    // 开始监听
    if (listen(server_socket, 1) < 0) {
        perror("[TcpServer] Listen failed.\n");
        return -1;
    }
    
    printf("[TcpServer] Server is listening on port %d...\n", port);

    // 接受客户端连接
    struct sockaddr_in6 client_addr;
    socklen_t client_len = sizeof(client_addr);
    int connect_socket = accept(server_socket, (struct sockaddr*)&client_addr, &client_len);
    if (connect_socket < 0) {
        perror("[TcpServer] Accept failed.\n");
        return -1;
    }
    
    char client_ip[INET6_ADDRSTRLEN];
    inet_ntop(AF_INET6, &client_addr.sin6_addr, client_ip, sizeof(client_ip));
    printf("[TcpServer] Client connected from %s\n",client_ip);
    
    char buffer[1024];
    int bytes_received = (int) recv(connect_socket, buffer, sizeof(buffer), 0);
    if (bytes_received > 0) {
        buffer[bytes_received] = '\0';
        printf("[TcpServer] Received message: %s\n", buffer);
        send(connect_socket, buffer, bytes_received, 0);
    } else {
        perror("[TcpServer] Receive failed.\n");
    }

    // 关闭连接
    close(connect_socket);
    close(server_socket);

    return 0;
}

int tcp_client_connect(const char *ipv6_address, const char* interface_name, int port) {
    // 创建 socket
    int client_socket = socket(AF_INET6, SOCK_STREAM, 0);
    if (client_socket == -1) {
        perror("[TcpClient] socket() failed");
        return -1;
    }

    // Bind client socket to the specified interface (e.g. awdl0)
    // On Apple platforms, AWDL is a special P2P interface that requires explicit binding
    unsigned int ifindex = if_nametoindex(interface_name);
    if (ifindex == 0) {
        perror("[TcpClient] if_nametoindex() failed");
        close(client_socket);
        return -1;
    }
    if (setsockopt(client_socket, IPPROTO_IPV6, IPV6_BOUND_IF, &ifindex, sizeof(ifindex)) < 0) {
        perror("[TcpClient] setsockopt(IPV6_BOUND_IF) failed");
        close(client_socket);
        return -1;
    }
    printf("[TcpClient] Bound to interface %s (index %u)\n", interface_name, ifindex);

    // 设置服务器地址结构体
    struct sockaddr_in6 server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin6_family = AF_INET6;
    server_addr.sin6_port = htons(port);

    if (inet_pton(AF_INET6, ipv6_address, &server_addr.sin6_addr) <= 0) {
        perror("[TcpClient] Invalid address/ Address not supported\n");
        return -1;
    }

    // 链路本地地址（fe80::）需要指定 scope_id（接口索引），否则系统无法确定从哪个接口发送
    server_addr.sin6_scope_id = if_nametoindex(interface_name);

    // 连接服务器
    if (connect(client_socket, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
        perror("[TcpClient] connect() failed");
        close(client_socket);
        return -1;
    }
    
    printf("[TcpClient] Connected to server at [%s]:%d\n", ipv6_address, port);
    
    char buffer[1024] = "Hello, I'm IPhone!";
    send(client_socket, buffer, strlen(buffer), 0);
    int bytes_received = (int) recv(client_socket, buffer, sizeof(buffer),0);
    if (bytes_received > 0) {
        buffer[bytes_received] = '\0'; // 添加字符串结束符
        printf("[TcpClient] Received from server: %s\n", buffer);
    } else {
        printf("[TcpClient] Receive failed\n");
    }

    // 关闭连接
    close(client_socket);

    return 0;
}

