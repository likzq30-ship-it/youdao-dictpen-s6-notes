# 02 — ADB 认证分析

## ADB 连接行为

```
$ adb connect <device>:5555
connected to <device>:5555

$ adb shell
error: device unauthorized.
This adb server's $ADB_VENDOR_KEYS is not set
Try 'adb kill-server' if that seems wrong.
Otherwise check for a confirmation dialog on your device.
```

设备端日志提示用户通过 `adb shell auth` 命令进行认证（而非 Android 的 RSA key 授权弹窗）。

## 认证脚本：/usr/bin/adb_auth.sh

### MD5 信息

来自 `all_file_md5.txt`（2542 文件完整目录）：

```
./usr/bin/adb_auth.sh c09a6776c26b21c7ce00c5f4e752e9ac
```

### 文件获取状态

- **未获取** — 脚本不在 OTA delta 包 (`update_4.0.5.img`) 中
- delta OTA 仅包含 58 个变更文件，`adb_auth.sh` 不在其中
- GitHub / PenUniverse 搜索未找到 S6 4.0.4 版本的完整脚本

## 已知密码演进

### 一代（2.0.0 之后）

- 明文密码：`CherryYoudao`
- 验证方式：直接字符串比较
- 来源：PenUniverse/PenMods 社区

### 二代（2.7.0 之后）

- 明文密码：`x3sbrY1d2@dictpen`
- 验证方式：直接字符串比较
- 来源：PenUniverse/PenMods 社区

### 三代（2023年1月之后）

- 验证方式：SHA256(password) 与脚本内存储的哈希值比较
- 社区公开的存储哈希值：`9de0341eb0ac432ecf39b72a0ddf4ac9a5dfb01828c0728dee474a573810a51f`
- 来源：PenUniverse Discussion #178

### S6 4.0.4

- root password hash：`$5$AJHlidNYDE.C$rSU09Q4KJsAKs5pRFOuGQQ32xCMS4oSaJwAggWkWApC`
- SHA-256 crypt 格式 (`$5$` prefix)
- **已知密码均不匹配**：

| 密码 | SHA256 Crypt 输出 |
|------|-------------------|
| `CherryYoudao` | `$5$AJHlidNYDE.C$Zc2vb4dfbeapnBuvcpDtYBahIG0aWxgbo8OSnElqIj/` |
| `x3sbrY1d2@dictpen` | `$5$AJHlidNYDE.C$Hwn3Oy.8Surg3JmuP08CK3sBCUZpzeLuOHgnxnZMQ22` |
| S6 4.0.4 root hash | `$5$AJHlidNYDE.C$rSU09Q4KJsAKs5pRFOuGQQ32xCMS4oSaJwAggWkWApC` |

## 绕过文件：/tmp/.adb_auth_verified

旧版 `adb_auth.sh` 逻辑（来源：社区公开的旧版脚本）：

```bash
VERIFIED=/tmp/.adb_auth_verified

if [ -f "$VERIFIED" ]; then
    echo "success."
    return
fi
```

- 如果 `/tmp/.adb_auth_verified` 文件存在，则**跳过密码验证**
- 该绕过文件在首次密码验证成功后由脚本创建：`touch $VERIFIED`
- **但 S6 4.0.4 的 `adb_auth.sh` 是否保留此逻辑未被证实**

## 三次尝试机制

旧版 `adb_auth.sh` 中的尝试循环：

```bash
for i in $(seq 1 3); do
    read -p "$(hostname -s)'s password: " PASSWD
    if [ "$PASSWD" = "CherryYoudao" ]; then
        echo "success."
        touch $VERIFIED
        return
    fi
    echo "password incorrect!"
done
false
```

- 最多 3 次密码尝试
- 新版将明文比较替换为 `[ "$(echo -n "$PASSWD" | sha256sum | cut -d' ' -f1)" = "STORED_HASH" ]`

## 安全建议

- **不建议爆破**：SHA256 哈希强度足够，3次限制使爆破不可行
- 获取正确密码的最实际途径是获取完整 `adb_auth.sh` 脚本，提取存储的 SHA256 哈希
- 即使拿到哈希，密码为 12 位随机字符时的搜索空间为 62^12，不可计算

## 未解问题

1. S6 4.0.4 `adb_auth.sh` 的完整脚本内容（包括存储的 SHA256 哈希值）
2. `/tmp/.adb_auth_verified` 绕过在当前版本是否仍存在
3. 是否有其他机制（debug flag、系统属性）可触发 passwordless auth
