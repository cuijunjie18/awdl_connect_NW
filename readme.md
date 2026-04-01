# AWDL协议通信

## 框架

- 网络核心框架：
  - 使用了Apple的官方Network框架,代替旧的Foundation中的NW相关api
  - 使用了POSIX标准的C调用，用于实现ipv6 TCP通信
- UI框架：Swift UI

## 业务流程

```mermaid
graph TD
    A[设备A: Advertiser 启动] -->|NWListener 监听 TCP:50001| B[awdl0 激活, 广播 Bonjour 服务]
    C[设备B: Browser 启动] -->|NWBrowser 扫描| D[awdl0 激活, 发现服务 awdl_cjj]
    D --> E[获取设备A的 IPv6 地址<br/>fe80::xxxx%awdl0]
    E --> F[NWConnection 连接到<br/>fe80::xxxx%awdl0:50001]
    F --> G[TCP 三次握手完成]
    G --> H[双向 TCP 数据传输]
    
    style G fill:#90EE90
    style H fill:#90EE90
```

## 目前代码可能存在的问题

- [ ] 获取awdl接口对应的ipv6地址时，认为一定是awdl0接口，这个在某些情况可能会异常
- [ ] 目前的测试是默认激活了awdl接口，实际上应该等advertiser start后，去动态更新广播的内容(NW框架无法做到)

## 收获

### 项目awdl连接原理

```mermaid
sequenceDiagram
    participant A as 设备A (Advertiser)
    participant AWDL as AWDL 无线信道
    participant B as 设备B (Browser)

    Note over A: startAdvertising()
    A->>A: 激活 awdl0 接口，获得 IPv6 链路本地地址<br/>fe80::xxxx%awdl0
    A->>AWDL: 周期性发送 AWDL Action Frame<br/>(同步帧 + 服务广播)
    
    Note over B: 此时 awdl0 未激活，无法收到帧
    B--xA: ❌ ping6 fe80::xxxx%awdl0 失败

    Note over B: startScanning()
    B->>B: 激活 awdl0 接口
    B->>AWDL: 加入 AWDL 同步窗口
    AWDL->>B: 收到设备A的 Action Frame
    B->>B: mDNS 解析，发现服务 "awdl_cjj"
    
    Note over A,B: 双方 AWDL 窗口已同步
    B->>A: ✅ ping6 fe80::xxxx%awdl0 成功
```