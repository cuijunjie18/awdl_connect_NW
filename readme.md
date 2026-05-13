# AWDL协议通信

## 框架

- 网络核心框架：
  - Apple官方的NetworkSevice，NW框架，包含在Foundation.h中
  - 使用了POSIX标准的C调用，用于实现ipv6 TCP通信

- UI框架：OC的UIKit

## 收获

- 遇到报错无法解决的，注意apple应用的权限问题

- NS框架不会自动维护awdl路由，需要通过回调

核心文件: Browser.m  
新增 NSNetServiceDelegate 协议：支持服务解析回调  
**didFindService 中先 resolve 服务：调用 [service resolveWithTimeout:10.0]，这会触发系统建立 AWDL 路由**  
在 netServiceDidResolveAddress: 回调中从 TXT Record 动态获取对端地址：不再硬编码 IP  
TCP 连接放到后台线程：dispatch_async 避免阻塞 RunLoop  
