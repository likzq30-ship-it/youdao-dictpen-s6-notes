# 04 — WebSocket 9307 分析

## 端口发现

设备在 9307 端口运行 WebSocket 服务：

```
$ nc -vz <device> 9307
Connection to <device> port 9307 [tcp] succeeded!
```

## 协议确认

### WebSocket 握手验证

```
GET / HTTP/1.1
Host: <device>:9307
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Key: <base64-key>
Sec-WebSocket-Version: 13

HTTP/1.1 101 Switching Protocols
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Accept: <accept-hash>
```

- 协议：RFC 6455
- 握手版本：Hybi13 (Sec-WebSocket-Version: 13)
- 接受**所有路径**（`/`, `/any`, `/test` 均可握手成功）

### 消息行为

发送任意 JSON 格式消息，服务器均返回：

```json
{"id": <echoed_id>, "result": {}}
```

- `id` 字段回显
- `result` 始终为空对象
- 无视 `method`、`params` 等 RPC 字段

**这表明 9307 WebSocket 处于 stub/未完成状态**，未实现实际 RPC 逻辑。

## 固件中发现的通信层

### WebSocket 库

从 rootfs 和 install 分区提取：

- `libwebsockets.so` / `libwebsockets.so.17` — 底层 WebSocket 库
- `yd_base_websocketpp` — 定制版 WebSocket++ (C++ 库)
- `YWebSocket` / `YWebSocketPrivate` — 有道封装的 WebSocket 类

### 服务端类层次

```
websocket::WSServer<Server, Server::CMDConnData, false, 4096>
websocket::WSConnection<Server, Server::CMDConnData, false, 4096, false>
```

- 命令连接类型：`CMDConnData`
- 缓冲区大小：4096 字节
- 无 TLS（plain WebSocket）

### 消息分发层

```
DLink::onMessage(string, string)
DLink::cmd(string, string)
DLinkPoint::onCmd(string, string)
Server::onWSMsg
```

### JS Bridge

```
JQuick::JSBridge::callNativeModule(instanceId, module, method)
JQuick::JSBridge::callNativeComponent(instanceId, ref, method)
```

调用日志格式：`callNativeModule instanceId=%s module=%s method=%s`

### JSON 处理

- `JS_JSONStringify` — JavaScript 引擎的 JSON 序列化
- `params must be json format!` — 参数验证错误消息
- `parse json failed, param:` — 解析失败日志

## 端口来源

- 固件字符串中**未发现**对 9307 的直接引用
- WebSocket 启动消息为：`WS Server started ws://127.0.0.1:`（端口部分为运行时追加）
- 9307 可能来自：
  - 外部配置脚本 (`/etc/init.d/*`)
  - 运行时参数
  - 硬编码在已编译的 C++ 中（但字符串表不包含）

## 已知服务器命令

从固件字符串表发现：

```
login password
echo str
```

表明存在简单的文本命令接口，可能用于 debug console。

## 安全建议

- **不建议对设备进行 blind fuzz**（盲目发送随机 payload）
- 9307 绑定在 `127.0.0.1`，理论上不应被外部网络访问（但端口对外可达待确认）
- 如果未来获得完整 JS bundle（`systemInfoManager-*.js.bin`），可反编译确认调用格式

## 未解问题

1. 9307 的真实 JSON-RPC payload 格式（method/params/id 的 JSON 结构）
2. `systemInfoManager-7da3fe4d.js.bin` 的解压方法和完整内容
3. `login password` 命令的认证机制
4. 服务端是否实现了 `setAdbEnable` 的 WebSocket 远程调用
