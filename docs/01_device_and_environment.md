# 01 — 设备信息与分析环境

## 目标设备

- **型号**：Youdao Dictionary Pen S6 / 有道词典笔 S6
- **型号代码**：YDPS6-1
- **芯片**：Sophgo / Cvitek CV1826
  - 架构：ARM Cortex-A53 (32-bit ARMv7)
  - 集成了 AI 推理单元（用于 OCR/翻译加速）
- **操作系统**：定制 Linux
  - 内核：Linux (具体版本待确认)
  - **非 Android 系统**
  - 使用 ext4 文件系统
- **分析固件版本**：4.0.4
- **OTA 包**：`update_4.0.5.img` (delta from 4.0.4 to 4.0.5)

## 网络端口

### ADB (5555)

- 5555 端口开放（标准 ADB over TCP 端口）
- `adb connect <device_ip>:5555` 可建立连接
- `adb shell` 返回要求认证：`login with "adb shell auth" to continue`

### WebSocket (9307)

- 9307 端口开放，运行 WebSocket 服务
- 协议：RFC 6455，使用 Hybi13 握手
- WebSocket 库：定制版 `yd_base_websocketpp`（基于 websocketpp）
- 接受任意路径的 WebSocket 连接
- 所有 JSON 格式的消息返回空 `{"id": X, "result": {}}`

## OTA 下载行为

- OTA 服务商：Adups FOTA
  - API：`iotapi.abupdate.com`
  - CDN：`iotdown.mayitek.com`
- 传输协议：HTTP (Range 请求)，分块下载
- 验证机制：`update_engine` + `check_install_md5.sh`

## 本地分析环境

- 分析完全基于**离线读取**已下载的 OTA 固件
- 使用工具：
  - Python 3 — ext4 解析、hash 计算
  - e2fsprogs — ext4 文件系统读取
  - capstone — ARM 反汇编
  - Docker (Alpine) — SHA256 crypt 验证
  - `gh` CLI — GitHub 社区搜索
  - `curl` / `wget` — OTA 下载
- 分析过程中**未对设备进行写入操作**
- 分析过程中**未向设备发送未知 payload**

## 固件文件清单（OTA 提取）

| 分区 | 文件 | 说明 |
|------|------|------|
| fip.bin | ARM Trusted Firmware | 引导固件 |
| partition_emmc.xml | eMMC 分区表 | 分区布局 |
| logo.jpg | 启动 Logo | 图片 |
| install.img | 安装/恢复分区 | 含 HAL 库和更新脚本 |
| boot.emmc | 内核 | Linux 内核 |
| rootfs_ext4.emmc | 根文件系统 (delta) | 仅含 58 个变更文件 |

## 分析限制

- OTA 包为 **delta 更新**（4.0.4 → 4.0.5），仅包含变更的文件
- 未持有 S6 4.0.4 的完整 rootfs 镜像
- 以下关键文件不在 delta OTA 中：
  - `/usr/bin/adb_auth.sh`
  - `/usr/bin/safepowerdown`
  - `/usr/bin/sshd`
  - `/usr/bin/sshd_service`
  - `/etc/shadow` 等
- 上述文件的存在和 MD5 由 `all_file_md5.txt` 证实，但**内容未获取**
