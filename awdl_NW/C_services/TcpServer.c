//
//  TcpServer.c
//  awdl_NW
//
//  Created by junjiecui on 2026/4/1.
//

#include "TcpServer.h"

int tcp_server_start(int port){
    // 创建 socket
    int server_socket = socket(AF_INET6, SOCK_STREAM, 0);
    if (server_socket == -1) {
        perror("Socket creation failed.\n");
        return -1;
    }

    // 允许重用地址，避免 TIME_WAIT 状态导致 bind 失败
//     int opt = 1;
//     setsockopt(server_socket, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    // 设置服务器地址结构体
    struct sockaddr_in6 server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin6_family = AF_INET6;
    server_addr.sin6_addr = in6addr_any; // 本地任意 IPv6 地址
    server_addr.sin6_port = htons(port); // 端口号

    // 绑定 socket
    if (bind(server_socket, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
        perror("Bind failed.\n");
        return -1;
    }

    // 开始监听
    if (listen(server_socket, 1) < 0) {
        perror("Listen failed.\n");
        return -1;
    }
    
    printf("Server is listening on port %d...\n", port);

    // 接受客户端连接
    struct sockaddr_in6 client_addr;
    socklen_t client_len = sizeof(client_addr);
    int connect_socket = accept(server_socket, (struct sockaddr*)&client_addr, &client_len);
    if (connect_socket < 0) {
        perror("Accept failed.\n");
        return -1;
    }
    
    char client_ip[INET6_ADDRSTRLEN];
    inet_ntop(AF_INET6, &client_addr.sin6_addr, client_ip, sizeof(client_ip));
    printf("Client connected from %s\n",client_ip);
    
    char buffer[1024];
    int bytes_received = (int) recv(connect_socket, buffer, sizeof(buffer), 0);
    if (bytes_received > 0) {
        buffer[bytes_received] = '\0';
        printf("Received message: %s\n", buffer);
        send(connect_socket, buffer, bytes_received, 0);
    } else {
        perror("Receive failed.\n");
    }

    // 关闭连接
    close(connect_socket);
    close(server_socket);

    return 0;
}
