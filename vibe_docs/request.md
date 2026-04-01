# 需求文档

这是一个试图使用awdl协议进行设备广播与发现的demo，但是目前似乎存在问题，测试机为IPhone 16，iOS版本为18

Advertiser start日志报错
```log
Started advertising
nw_path_evaluator_create_flow_inner failed NECP_CLIENT_ACTION_ADD_FLOW (null) evaluator parameters: generic, definite, server, attribution: developer, context: Default Network Context (private), proc: A0C3C93A-807F-31E0-BCCB-A289DA764360, use awdl, local address: ::.50001
nw_path_evaluator_create_flow_inner NECP_CLIENT_ACTION_ADD_FLOW 39B5F672-5829-46F9-9B0C-CC607FBAC81E [22: Invalid argument]
nw_path_evaluator_create_flow_inner failed NECP_CLIENT_ACTION_ADD_FLOW (null) evaluator parameters: generic, definite, server, attribution: developer, context: Default Network Context (private), proc: A0C3C93A-807F-31E0-BCCB-A289DA764360, use awdl, local address: ::.50001
nw_path_evaluator_create_flow_inner NECP_CLIENT_ACTION_ADD_FLOW 39B5F672-5829-46F9-9B0C-CC607FBAC81E [22: Invalid argument]
nw_path_evaluator_create_flow_inner failed NECP_CLIENT_ACTION_ADD_FLOW (null) evaluator parameters: generic, definite, server, attribution: developer, context: Default Network Context (private), proc: A0C3C93A-807F-31E0-BCCB-A289DA764360, use awdl, local address: ::.50001
nw_path_evaluator_create_flow_inner NECP_CLIENT_ACTION_ADD_FLOW 39B5F672-5829-46F9-9B0C-CC607FBAC81E [22: Invalid argument]
nw_path_evaluator_create_flow_inner failed NECP_CLIENT_ACTION_ADD_FLOW (null) evaluator parameters: generic, definite, server, attribution: developer, context: Default Network Context (private), proc: A0C3C93A-807F-31E0-BCCB-A289DA764360, use awdl, local address: ::.50001
nw_path_evaluator_create_flow_inner NECP_CLIENT_ACTION_ADD_FLOW 39B5F672-5829-46F9-9B0C-CC607FBAC81E [22: Invalid argument]
nw_path_evaluator_create_flow_inner failed NECP_CLIENT_ACTION_ADD_FLOW (null) evaluator parameters: generic, definite, server, attribution: developer, context: Default Network Context (private), proc: A0C3C93A-807F-31E0-BCCB-A289DA764360, use awdl, local address: ::.50001
nw_path_evaluator_create_flow_inner NECP_CLIENT_ACTION_ADD_FLOW 39B5F672-5829-46F9-9B0C-CC607FBAC81E [22: Invalid argument]
nw_path_evaluator_create_flow_inner failed NECP_CLIENT_ACTION_ADD_FLOW (null) evaluator parameters: generic, definite, server, attribution: developer, context: Default Network Context (private), proc: A0C3C93A-807F-31E0-BCCB-A289DA764360, use awdl, local address: ::.50001
nw_path_evaluator_create_flow_inner NECP_CLIENT_ACTION_ADD_FLOW 39B5F672-5829-46F9-9B0C-CC607FBAC81E [22: Invalid argument]
-[nw_listener_inbox_socket initWithParameters:delegate:] Cannot create listener with IP Protocol 0
nw_listener_reconcile_inboxes_on_queue [L1] failed to create listener inbox with parameters generic, local: ::.50001, definite, attribution: developer, server
Listener state: failed
```

Browser start报错日志
```log
Start scanning
nw_browser_fail_on_dns_error_locked [B1] DNSServiceBrowse failed: NoAuth(-65555)
Browser failed
```

分析我的项目存在的问题，并解决

