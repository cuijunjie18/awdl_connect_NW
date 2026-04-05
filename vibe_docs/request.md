# 需求文档

现在完成了awdl协议通信app，iphone端监听，mac端连接报错，但是可以pin6通

[TcpClient] Bound to interface awdl0 (index 17)
[TcpClient] connect() failed: No route to host

ping6 fe80::4452:baff:fed2:89ae%awdl0                                                                                               ─╯
PING6(56=40+8+8 bytes) fe80::58d0:aff:fe9d:dede%awdl0 --> fe80::4452:baff:fed2:89ae%awdl0
16 bytes from fe80::4452:baff:fed2:89ae%awdl0, icmp_seq=0 hlim=64 time=152.208 ms
16 bytes from fe80::4452:baff:fed2:89ae%awdl0, icmp_seq=1 hlim=64 time=178.207 ms
16 bytes from fe80::4452:baff:fed2:89ae%awdl0, icmp_seq=2 hlim=64 time=221.577 ms
16 bytes from fe80::4452:baff:fed2:89ae%awdl0, icmp_seq=3 hlim=64 time=266.261 ms
16 bytes from fe80::4452:baff:fed2:89ae%awdl0, icmp_seq=4 hlim=64 time=313.625 ms
^C
--- fe80::4452:baff:fed2:89ae%awdl0 ping6 statistics ---
5 packets transmitted, 5 packets received, 0.0% packet loss
round-trip min/avg/max/std-dev = 152.208/226.376/313.625/58.391 ms

分析解决