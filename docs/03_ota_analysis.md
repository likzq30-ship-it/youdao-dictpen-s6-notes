# 03 — OTA 机制分析

## OTA 包格式

### YDIH 头部

`update_4.0.5.img` 使用自定义 YDIH 头部：

```
偏移      内容
0x00      YDIH 魔数
0x04      头部版本
0x88      YDII 分区表
0x100C    HWDEF 文本映射表
```

### 分区表（7个分区）

| 分区 | 说明 |
|------|------|
| fip.bin | ARM Trusted Firmware 引导固件 |
| partition_emmc.xml | eMMC 分区布局 |
| logo.jpg | 启动 Logo |
| install.img | 安装/恢复分区（含 HAL 库和更新脚本） |
| boot.emmc | Linux 内核 |
| rootfs_ext4.emmc | 根文件系统 (delta) |
| (data partition) | 用户数据 |

## Delta OTA 特征

`update_4.0.5.img` 是 **delta OTA**（4.0.4 → 4.0.5），**非完整固件包**。

关键证据：

1. **`all_file_md5.txt`** — 2542 个文件，覆盖完整设备文件系统的 MD5 目录
2. **`update_file_md5.txt`** — 仅 58 个文件，是本次 delta 更新的变更文件
3. 以下关键文件在 `all_file_md5.txt` 中，但**不在** `update_file_md5.txt` 中：
   - `/usr/bin/adb_auth.sh`
   - `/usr/bin/safepowerdown`
   - `/usr/bin/sshd`
   - `/usr/bin/sshd_service`
   - `/etc/shadow`
   - `/etc/passwd`
   - `/etc/init.d/S98usbdevice`

## 签名验证机制

### update_engine 二进制

`install.img`（part1 分区）中包含 `update_engine` 可执行文件。从符号表和链接库分析：

**加密相关符号**（存在于 update_engine）：

- `RSA_*` — RSA 非对称加密
- `X509_*` — X.509 证书链
- `CMS_*` — Cryptographic Message Syntax
- `PKCS7_*` — PKCS#7 签名格式
- `SHA256_*` — SHA256 哈希
- `EVP_*` — OpenSSL EVP 高级加密接口
- `BIO_*` — OpenSSL I/O 抽象

### 验证流程（推断）

```
1. 读取 OTA 包头部
2. 提取 PKCS#7 签名数据
3. 使用 X.509 证书验证签名
4. 通过 CMS 验证内容完整性
5. 验证通过后，check_install_md5.sh 逐文件校验 MD5
6. 逐文件复制到目标分区
```

## OTA 改包为什么不可行

1. **RSA 非对称签名**：OTA 签名使用厂商私钥生成，验证使用固件中硬编码的公钥
2. **没有私钥就无法生成有效签名**
3. 即使修改单个文件并更新 MD5，签名验证环节也会失败
4. `update_engine` 在设计上不允许跳过签名验证

## 0.14% 更新事件复盘

### 背景

早期尝试通过修改 OTA 包并配合 DNS 劫持来让设备安装 modified OTA。

### 实际发生情况

1. 设备（局域网内）请求下载 `update_4.0.5.img`
2. DNS 查询被本地 DNS 服务器响应
3. **但设备实际走了官方 CDN**：`iotdown.mayitek.com` (IP: 122.228.91.185)
4. 网络抓包证实：设备通过 HTTP Range 请求从 CDN 下载了 10MB/88.4MB
5. 服务器响应 `206 Partial Content`

### 结论

- 0.14% 是设备从**官方 CDN** 下载的进度，与 modified OTA 无关
- DNS 劫持**未生效**（设备可能使用了备用 DNS 或缓存的 IP）
- Modified OTA **从未被设备读取**
- **不能证明 OTA 进入了安装阶段**

## 相关文件

| 文件 | MD5 | 说明 |
|------|-----|------|
| `update_4.0.5.img` | `dfe493fdbced6328452b0023f35e1021` | 完整 OTA 包 (88.4MB) |
| `rootfs_ext4.emmc` | (待补充) | delta rootfs |
| `install.img` | (待补充) | 恢复/安装分区 |
| `all_file_md5.txt` | (待补充) | 2542 文件 MD5 目录 |
| `update_file_md5.txt` | (待补充) | 58 变更文件 MD5 列表 |
