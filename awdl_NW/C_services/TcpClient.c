//
//  TcpClient.c
//  awdl_NW
//
//  Created by junjiecui on 2026/4/1.
//

#include "TcpClient.h"

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
        perror("Invalid address/ Address not supported\n");
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
