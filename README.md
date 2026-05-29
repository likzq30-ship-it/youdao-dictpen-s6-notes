# Youdao Dictionary Pen S6 — 固件分析日志

本项目是对**有道词典笔 S6**（YDPS6-1）固件的逆向分析研究归档。
目标是记录 ADB 认证机制、OTA 安全机制、WebSocket 控制端口及系统调用链，
**不提供破解、刷机、绕过签名、爆破工具**。

## 设备信息

- 型号：Youdao Dictionary Pen S6 / 有道词典笔 S6 (YDPS6-1)
- 芯片：Sophgo/Cvitek CV1826 (ARM Cortex-A53)
- 系统：定制 Linux (非 Android)
- 固件版本（分析对象）：4.0.4
- OTA 包：`update_4.0.5.img` (4.0.4 → 4.0.5 delta)

## 研究目标

1. 分析 ADB (5555) 认证机制及 `/usr/bin/adb_auth.sh`
2. 分析 OTA 固件格式及签名验证机制
3. 分析 WebSocket 9307 端口用途及协议格式
4. 追踪 `setAdbEnable` 调用链（JS → C++ → HAL → shell）
5. 分析 `/usr/bin/safepowerdown` 与 SSH 的关联

## 当前结论摘要

| 主题 | 结论 | 置信度 |
|------|------|--------|
| ADB 5555 端口 | 开放，但 `adb shell` 需要 auth | ✅ 已证实 |
| OTA 签名 | RSA / X.509 / CMS / PKCS7，非对称签名 | ✅ 已证实 |
| OTA 改包 | 不可行，需要私钥签名 | ✅ 已证实 |
| 旧密码 `CherryYoudao` / `x3sbrY1d2@dictpen` | 对 S6 4.0.4 **不适用** (SHA256 哈希不匹配) | ✅ 已证实 |
| `adb_auth.sh` 完整逻辑 | SHA256 验证+绕过文件机制推测存在，但脚本内容未获取 | ❓ 未确认 |
| WebSocket 9307 | RFC 6455 可握手，真实 JSON-RPC payload 格式未确认 | ❓ 未确认 |
| `setAdbEnable` 调用链 | JS → C++ → HAL → shell 完整链路已从符号表恢复 | ✅ 已证实 |
| `safepowerdown` 与 SSH | HAL 层 fork `/usr/bin/safepowerdown`，但不直接启动 SSH | ❓ 未确认 |

## 重要声明

- **本项目不提供 patched OTA 固件**
- **本项目不提供可直接攻击设备的 payload**
- **本项目不鼓励爆破密码、刷改包固件、绕过签名检查**
- **本项目不包含设备唯一标识（SN、MAC）或个人网络信息**
- 所有分析以**离线、只读**方式进行

## 仓库结构

```
youdao-dictpen-s6-notes/
├── README.md                         # 本文件
├── LICENSE                            # CC BY 4.0
├── .gitignore
├── docs/
│   ├── 00_summary.md                  # 结论摘要
│   ├── 01_device_and_environment.md   # 设备信息与环境
│   ├── 02_adb_auth.md                 # ADB 认证分析
│   ├── 03_ota_analysis.md             # OTA 机制分析
│   ├── 04_websocket_9307.md           # WebSocket 9307 分析
│   ├── 05_hal_set_adb_chain.md        # setAdbEnable 调用链
│   ├── 06_safepowerdown.md            # safepowerdown 分析
│   ├── 07_open_questions.md           # 未解问题
│   └── 08_risk_and_safety.md          # 安全边界
├── artifacts/
│   ├── README.md
│   └── hashes.md                      # 关键文件哈希
└── scripts/
    ├── README.md
    ├── safe_strings_search.sh         # 安全信息搜索
    └── safe_extract_notes.sh          # 文件列表整理
```

## 后续社区可补充

- S6 4.0.4 完整 rootfs 镜像（如有合法获取途径）
- `/usr/bin/adb_auth.sh` 完整脚本内容
- `/usr/bin/safepowerdown` 完整脚本/二进制
- 9307 WebSocket 的真实 JSON-RPC 请求格式（来自 JS bundle 提取）
- 旧版固件（2.x/3.x）对比分析
- 官方 debug mode 开启方式（如有文档）

## 参考文献

- PenUniverse/PenMods — 有道词典笔社区研究
- GitHub Discussion #178 — 有道词典笔 S6 刷机探索
- websocketpp — WebSocket C++ 库
- Adups FOTA — OTA 服务商

## License

本仓库文档采用 [CC BY 4.0](LICENSE) 许可。
