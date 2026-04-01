# 需求文档

项目概述：当前应用核心功能是通过Network框架使Apple设备的awdl接口激活，具体的实现是使用advertiser发送信号，browser发现信号，设备间连接到同一awdl窗口，各自对应的awdl接口分配了一个ipv6地址。
现在的问题是：client端与server端在awdl协议上可以互相发现，且client端可以通过server端的<ipv6地址>%<awdl0> ping6通server，但是在tcp连接层无法建立tcp连接，卡在了perror("[TcpClient] connect() failed");

分析问题所在，并且修复代码