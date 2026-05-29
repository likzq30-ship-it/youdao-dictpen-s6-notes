# 00 — 最终结论摘要

## 已证实 (✅)

### ADB 5555 端口
- 设备监听 5555 端口，`adb connect` 可以连接
- `adb shell` 提示需要通过 `adb shell auth` 进行认证
- ADB 守护进程 `/usr/bin/adbd` 存在且运行

### OTA 签名验证
- OTA 包使用 YDIH 自定义头部格式
- `update_engine` 二进制包含 OpenSSL / RSA / X.509 / CMS / PKCS7 符号
- 签名验证采用非对称加密，无法绕过签名安装 modified OTA
- OTA 改包路线**基本不可行**：需要厂商 RSA 私钥

### 密码过期
- 旧版固件已知密码：
  - 2.0.0 之后：`CherryYoudao`
  - 2.7.0 之后：`x3sbrY1d2@dictpen`
- 以上密码的 SHA256 crypt 输出**不匹配** S6 4.0.4 的 root password hash
- root password hash: `$5$AJHlidNYDE.C$rSU09Q4KJsAKs5pRFOuGQQ32xCMS4oSaJwAggWkWApC`

### setAdbEnable 调用链
- 完整调用链已从 C++ mangled symbol 和 HAL 字符串恢复：
  ```
  systemInfo.setAdbEnable(1)
    → JSystemInfoProxy::setAdbEnable()
    → YSystemInfoModule::setAdbEnable(int)
    → YSystemInfoModulePrivate::setAdbEnable(int)
    → YSystemInfoAdapter::setAdbStatus()
    → youdao_set_adb()
    → shell: grep usb_adb_en ...; /etc/init.d/S98usbdevice restart
  ```

### /tmp/.adbOn 与 /tmp/.usb_config
- `/tmp/.adbOn` 文件用于标记 ADB 开关状态
- `/tmp/.usb_config` 中的 `usb_adb_en` 条目控制 USB ADB 配置
- `S98usbdevice restart` 重新加载 USB gadget 配置

---

## 推断 (⚠️)

### adb_auth.sh 机制
- 旧版（2023年前）使用明文密码比较
- 新版使用 SHA256(password) 哈希比较
- 两版均有 `/tmp/.adb_auth_verified` 绕过文件机制
- **但 S6 4.0.4 的完整脚本未获取**

### safepowerdown
- HAL 层 `youdao_safe_powerdown()` 执行 `safepowerdown <delay> &`
- HAL 字符串表中存在 `sshd_service restart` 字符串
- 但该字符串**未被任何已知代码引用**
- `/usr/bin/safepowerdown` 本身不在 OTA delta 包中

---

## 未确认 (❓)

1. S6 4.0.4 的 `/usr/bin/adb_auth.sh` 完整内容
2. S6 4.0.4 的 `/usr/bin/safepowerdown` 完整内容
3. WebSocket 9307 的真实 JSON-RPC payload 格式
4. 是否存在无需 adb auth 的 SSH/ADB 调试入口
5. 是否有官方 debug mode 开关方式
6. `/tmp/.adb_auth_verified` 绕过在当前固件是否有效

---

## 已推翻 (❌)

1. **DNS 劫持可拦截 OTA 下载** → 推翻。设备优先使用 CDN，备用域名也使用 HTTPS
2. **旧密码对 S6 有效** → 推翻。SHA256 哈希不匹配
3. **9307 WebSocket 有可直接调用的 JSON-RPC 接口** → 推翻。所有方法均返回空 result，处于 stub 状态
4. **OTA 签名可绕过** → 推翻。RSA + X.509 + CMS + PKCS7 完整链验证

---

## 关键缺口

要推进分析，最需要的材料（优先级从高到低）：

1. **S6 4.0.4 完整 rootfs 镜像** — 合法获取途径（如售后固件、官方下载链接）
2. **`/usr/bin/adb_auth.sh` 脚本内容** — 可从 rootfs 提取
3. **`/usr/bin/safepowerdown` 脚本/二进制** — 可从 rootfs 提取
4. **JS bundle (`systemInfoManager-*.js.bin`) 解压** — 需确认压缩格式
5. **旧版 S6 固件对比** — 可追踪 `adb_auth.sh` 的演变
