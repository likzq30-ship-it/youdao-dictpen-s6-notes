# 关键文件哈希

以下哈希值来自 OTA 固件包 `update_4.0.5.img` 中的 `all_file_md5.txt`。
该文件包含设备完整文件系统 (2542 文件) 的 MD5 校验值。

## 系统安全文件

| 文件 | MD5 | 说明 |
|------|-----|------|
| `/etc/passwd` | `727648f64ef894897821bd6ec5e56764` | 用户数据库 |
| `/etc/shadow` | `ebfc5edf4e2788b5d637b84bec981bd7` | 密码哈希 (SHA-256 crypt) |
| `/etc/debug.cfg` | `210f167ca51bc3fcb0c39b20d067baf5` | Debug 配置 |
| `/etc/init.d/S98usbdevice` | `d7d3e563cd0568a0da73fd8ecfbf8191` | USB gadget 管理脚本 |
| `/etc/init.d/.usb_config` | `079f10cf6faddeedcd4d69df9939f4be` | USB 配置模板 |

## ADB 相关

| 文件 | MD5 | 说明 |
|------|-----|------|
| `/usr/bin/adb_auth.sh` | `c09a6776c26b21c7ce00c5f4e752e9ac` | ADB 认证脚本 |
| `/usr/bin/adbd` | `91003b5bcb9e27da3e55eab0c4286d09` | ADB 守护进程 |

## 关机/电源管理

| 文件 | MD5 | 说明 |
|------|-----|------|
| `/usr/bin/safepowerdown` | `42a4f110d2be6c50ffa333f64f428bea` | 安全关机 |
| `/usr/bin/safe_powerdown` | `df8ac827365d117e9116522ea49e` | 安全关机 (备用) |

## SSH 服务

| 文件 | MD5 | 说明 |
|------|-----|------|
| `/usr/sbin/sshd` | `8f0b10794cce5307454720d3cab23392` | SSH 守护进程 (OpenSSH?) |
| `/usr/bin/sshd_service` | `ca994e9f1d15a1fa439e9c36fe729421` | SSH 服务管理脚本 |
| `/usr/bin/dropbear_service` | `c445390118f5d058dd372a8b2beb25a8` | Dropbear SSH 服务脚本 |

## HAL 库

| 文件 | 信息 | 说明 |
|------|------|------|
| `hal_youdao.so` | ARM 32-bit ELF shared object | 从 part1.ext4 提取 |
| 大小 | ~19,344 bytes | 包含 13 个导出函数 |
| 架构 | ARMv7 EABI | 动态链接 |
| 来源 | `part1.ext4` (install/recovery 分区) | |

## OTA 固件包

| 文件 | MD5 | 大小 |
|------|-----|------|
| `update_4.0.5.img` | `dfe493fdbced6328452b0023f35e1021` | 88.4 MB |

> 注：固件文件**未包含**在本仓库中。如需获取，请从官方渠道下载。

## root password hash

```
$5$AJHlidNYDE.C$rSU09Q4KJsAKs5pRFOuGQQ32xCMS4oSaJwAggWkWApC
```

- 格式：SHA-256 crypt (`$5$` prefix)
- Salt: `AJHlidNYDE.C`
- 已知密码 `CherryYoudao` 和 `x3sbrY1d2@dictpen` 不匹配

## adb_auth.sh 推测存储哈希

来自 PenUniverse Discussion #178 的社区情报（非 S6 4.0.4 确认）：

```
9de0341eb0ac432ecf39b72a0ddf4ac9a5dfb01828c0728dee474a573810a51f
```

> ⚠️ 此哈希值来自社区讨论，**未在 S6 4.0.4 固件中确认**。
