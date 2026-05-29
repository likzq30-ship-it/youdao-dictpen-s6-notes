# 05 — setAdbEnable 完整调用链

## 概述

以下调用链从 OTA 固件中的 C++ mangled symbol 表和 HAL 库中的 shell 命令字符串恢复。
所有符号均来自 `rootfs_full.ext4` 和 `part1.ext4`。

## 调用链

```
[1] JS 层
    systemInfo.setAdbEnable(1)
      │
      ▼
[2] Proxy 层 (JS binding)
    JSystemInfoProxy::setAdbEnable(JQFunctionCallbackInfo&)
      │  反编译符号: _ZN16JSystemInfoProxy12setAdbEnableER22JQFunctionCallbackInfo
      │
      ▼
[3] Core API 层 (DAL singleton)
    YDALAPI::YSystemInfoModule::setAdbEnable(int enabled)
      │  反编译符号: _ZN7YDALAPI17YSystemInfoModule12setAdbEnableEi
      │
      ▼
[4] Private Implementation
    YDALAPI::Internal::YSystemInfoModulePrivate::setAdbEnable(int enabled)
      │  反编译符号: _ZN7YDALAPI8Internal24YSystemInfoModulePrivate12setAdbEnableEi
      │
      ▼
[5] Adapter 层
    YADAPTERAPI::YSystemInfoAdapter::setAdbStatus(adb_status&)
      │  反编译符号: _ZN10YADAPTERAPI19YSystemInfoAdapter12setAdbStatusER10adb_status
      │
      ▼
[6] HAL 层 (C 接口)
    youdao_set_adb()
      │  来源: hal_youdao.so 导出符号
      │
      ▼
[7] Shell command execution
    system("grep usb_adb_en /tmp/.usb_config || echo usb_adb_en >> /tmp/.usb_config; /etc/init.d/S98usbdevice restart")
      │  来源: hal_youdao.so 字符串表 @ 0x361d
      │
      ▼
[8] USB gadget 重载
    /etc/init.d/S98usbdevice restart
      重新配置 USB gadget，应用 /tmp/.usb_config 中的设置
```

## JS 层方法绑定

从 `rootfs_full.ext4` 提取的 `JSystemInfoProxy` 方法注册列表：

```
JQFunctionTemplate::SetProtoMethod<JSystemInfoProxy>(...)
```

注册的 JS 方法名（对应 `systemInfo` 对象）：

| 方法名 | C++ 实现 | 说明 |
|--------|----------|------|
| `setAdbEnable` | `JSystemInfoProxy::setAdbEnable` | 开关 ADB (参数 int: 1/0) |
| `getAdbEnable` | `JSystemInfoProxy::getAdbEnable` | 查询 ADB 状态 |
| `getVersion` | `JSystemInfoProxy::getVersion` | 获取系统版本 |
| `getSNInfo` | `JSystemInfoProxy::getSNInfo` | 获取序列号 |
| `getSKU` | `JSystemInfoProxy::getSKU` | 获取 SKU |
| `getDeviceType` | `JSystemInfoProxy::getDeviceType` | 获取设备类型 |
| `getMacInfo` | `JSystemInfoProxy::getMacInfo` | 获取 MAC 地址 |
| `getUUIDInfo` | `JSystemInfoProxy::getUUIDInfo` | 获取 UUID |
| `getDeviceName` | `JSystemInfoProxy::getDeviceName` | 获取设备名称 |
| `getSystemTime` | `JSystemInfoProxy::getSystemTime` | 获取系统时间 |
| `getCompanyMainBody` | `JSystemInfoProxy::getCompanyMainBody` | 获取公司主体 |
| `getCommonParams` | `JSystemInfoProxy::getCommonParams` | 获取通用参数 |
| `getStorageInfo` | `JSystemInfoProxy::getStorageInfo` | 获取存储信息 |
| `getAvailableSpace` | `JSystemInfoProxy::getAvailableSpace` | 获取可用空间 |
| `setHandedness` | `JSystemInfoProxy::setHandedness` | 设置左右手模式 |
| `getHandedness` | `JSystemInfoProxy::getHandedness` | 获取左右手模式 |
| `closeBootLogo` | `JSystemInfoProxy::closeBootLogo` | 关闭开机 Logo |
| `feedWatchdog` | `JSystemInfoProxy::feedWatchdog` | 喂看门狗 |
| `getShakeControlScanModeEnabled` | `JSystemInfoProxy::getShakeControlScanModeEnabled` | 摇动扫描模式 |

JS 模块名：`systemInfo`
JS 源文件：`systemInfoManager-7da3fe4d.js.bin`（已打包/压缩，需解压）

## HAL 层函数

从 `part1.ext4` 中的 HAL 共享库 (`hal_youdao.so`) 提取：

| 函数 | 地址 | 大小 | 说明 |
|------|------|------|------|
| `youdao_set_adb` | 0x1f6c | 0x58 bytes | 写入 usb_adb_en 配置 |
| `youdao_get_usb_status` | 0x1e08 | 0x34 bytes | 读取 USB 状态 |
| `youdao_safe_powerdown` | 0x1e3c | 0x130 bytes | 安全关机 |
| `youdao_set_mtp_readonly` | 0x1fc4 | 0x3c bytes | MTP 只读模式 |
| `youdao_console_run` | 0x1508 | 0x1a0 bytes | 控制台命令执行 |
| `youdao_hal_config_init` | 0x209c | 0x254 bytes | HAL 配置初始化 |
| `youdao_load_sys_config` | 0x1b5c | 0xbc bytes | 加载系统配置 |
| `youdao_save_sys_config` | 0x1aa4 | 0xb8 bytes | 保存系统配置 |

## Shell 命令字符串

来自 `hal_youdao.so` 字符串表：

### ADB 开启
```bash
grep usb_adb_en /tmp/.usb_config || echo usb_adb_en >> /tmp/.usb_config; /etc/init.d/S98usbdevice restart
```
- 检查 `/tmp/.usb_config` 中是否有 `usb_adb_en`
- 没有则追加写入
- 重启 USB 设备管理

### ADB 关闭
```bash
sed -i '/usb_adb_en/d' /tmp/.usb_config; /etc/init.d/S98usbdevice restart
```
- 从 `/tmp/.usb_config` 中删除 `usb_adb_en`
- 重启 USB 设备管理

### MTP 只读
```bash
grep usb_mtp_readonly_en /tmp/.usb_config || echo usb_mtp_readonly_en >> /tmp/.usb_config; /etc/init.d/S98usbdevice restart &
```
- 后台执行

## 状态文件

| 文件 | 用途 | 来源 |
|------|------|------|
| `/tmp/.adbOn` | ADB 开关状态标记 | `YSystemInfoModulePrivate::setAdbEnable` 管理 |
| `/tmp/.usb_config` | USB gadget 配置 | `S98usbdevice` 读取 |
| `/tmp/.adb_auth_verified` | ADB 认证绕过（旧版证实） | `adb_auth.sh` 创建 |

## 重要说明

1. **`setAdbEnable` 可能仅打开 ADB USB 端口配置**，不等于绕过 `adb_auth.sh`
2. 认证仍然由 `adb_auth.sh` 控制
3. 启用 ADB 后仍需通过密码验证才能 `adb shell`
4. 该链路证明厂商**存在 ADB 开关逻辑**，但开关在用户 UI 中的入口未知
