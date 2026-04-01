# AWDL协议通信

## 框架

使用了Apple的官方Network框架,代替旧的Foundation中的NW相关api

## 目前情况

目前实现了advertiser与browser,这两个类start后会激活awdl窗口

一台设备开启了adcertiser后,其会激活awdl接口,这个接口有一个ipv6的地址,另一台设备还不能ping6到这个地址,开启browser后,扫描到对应的awdl信号后即可ping6通
