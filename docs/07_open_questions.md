# 07 — 未解问题

## 高优先级

### 1. S6 4.0.4 完整 adb_auth.sh
- **现状**：只从 `all_file_md5.txt` 确认了文件存在和 MD5 (`c09a6776c26b21c7ce00c5f4e752e9ac`)
- **需要**：完整脚本内容，包括存储的 SHA256 哈希值
- **获取途径**：完整 rootfs 镜像、官方固件包、从设备提取（需要先获得 ADB root）

### 2. S6 4.0.4 完整 safepowerdown
- **现状**：只确认 `/usr/bin/safepowerdown` 和 `/usr/bin/safe_powerdown` 两个文件存在
- **需要**：文件内容（脚本或二进制）
- **关键问题**：是否会在后台启动 SSH？
- **获取途径**：同 adb_auth.sh

### 3. 完整 rootfs 镜像
- **现状**：只有 delta OTA (58/2542 文件)
- **需要**：S6 4.0.4 完整文件系统镜像
- **获取途径**：
  - 官方售后固件下载链接
  - 社区共享（PenUniverse）
  - 从设备通过已知漏洞提取

### 4. 9307 WebSocket JSON-RPC 格式
- **现状**：协议栈已确认，但具体 JSON 消息格式未知
- **需要**：
  - `systemInfoManager-7da3fe4d.js.bin` 的解压和反编译
  - 或其他 JS bundle 文件内容
- **获取途径**：rootfs 中的 JS 文件或从设备 Web 资源提取
- **注意**：不建议通过 blind fuzz 探索

## 中等优先级

### 5. 无需密码的 ADB/SSH 入口
- 是否存在 debug flag / property 绕过 adb_auth？
- `/etc/debug.cfg` (MD5: `210f167ca51bc3fcb0c39b20d067baf5`) 的内容是什么？
- 是否存在特殊的启动模式（recovery mode、factory mode）直接启用 SSH？

### 6. 官方 debug mode
- 设备 UI 是否存在隐藏的"开发者选项"或"调试模式"开关？
- 键盘/触摸组合键是否可以触发 debug mode？
- debug mode 是否会开放 ADB 密码或直接启用 SSH？

### 7. 密码猜测方向
- S6 4.0.4 默认 ADB 密码是否为产品批次相关的派生密码？
- 能否通过设备 S/N 或 MAC 逆推密码？
- 是否有已知的密码生成算法？

## 低优先级

### 8. 旧固件对比
- 获取 2.x / 3.x 固件的完整 rootfs
- 对比 `adb_auth.sh` 的演变过程
- 追踪密码从明文到 SHA256 的时间线

### 9. JS bundle 解压
- `*.js.bin` 的打包/压缩格式是什么？
- 是否有已知的 Youdao HaaS UI 工具链可解压？

### 10. 其他未探索的端口和服务
- 是否有未发现的端口（UDP、其他 TCP）？
- `sshd_service` 和 `dropbear_service` 是否在其他端口监听？
- 系统中是否有未记录的服务进程？

## 已排除的方向

以下方向经分析后确认为不可行或低效：

- ❌ OTA 改包 → RSA 签名不可绕过
- ❌ 密码爆破 → SHA256 强度足够
- ❌ DNS 劫持 → 设备使用 CDN 直连，HTTPS 保护
- ❌ WebSocket blind fuzz → 9307 处于 stub 状态

## 获取材料渠道建议

1. **官方渠道**（最安全）：
   - 有道官网是否有固件下载页面？
   - FOTA 后台是否有公开的完整固件包 URL？
   - 售后工具（如刷机工具）是否包含完整固件？

2. **社区渠道**：
   - PenUniverse GitHub 组织
   - 有道词典笔吧/论坛
   - 海外 XDA-Developers 类似论坛

3. **设备提取**（如已有 root）：
   - `dd` 或 `adb pull` 整个 `/usr` 分区
   - 重点关注 `/usr/bin/adb_auth.sh`, `/usr/bin/safepowerdown`, `/etc/debug.cfg`
