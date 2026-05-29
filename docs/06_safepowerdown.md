# 06 — safepowerdown 分析

## 文件信息

### /usr/bin/safepowerdown

| 属性 | 值 |
|------|-----|
| 路径 | `/usr/bin/safepowerdown` |
| MD5 | `42a4f110d2be6c50ffa333f64f428bea` |
| 来源 | `all_file_md5.txt` (2542 文件目录) |
| 文件类型 | 未知（可能为 shell 脚本或 ELF 二进制） |
| 获取状态 | **未获取** — 不在 delta OTA 包中 |

### /usr/bin/safe_powerdown

另有一个独立文件：

| 属性 | 值 |
|------|-----|
| 路径 | `/usr/bin/safe_powerdown` |
| MD5 | `df8ac827365d117e9116522ea49e` |
| 说明 | 与 `safepowerdown` 是不同的文件（下划线分隔） |

## HAL 层分析

### youdao_safe_powerdown() 反汇编

从 `part1.ext4` 提取 `hal_youdao.so` (ARM 32-bit ELF)，使用 capstone 反汇编工具分析。

函数位于 VA 0x1e3c，大小 0x130 字节 (ARM 模式)。

**C 等价代码**（从反汇编恢复）：

```c
int youdao_safe_powerdown(int delay_value) {
    char proc_buf[0x400];    // 进程状态缓冲区 (r6 = sp+0x40)
    char logger_buf[0x1000]; // logger 命令缓冲区 (r5 = sp+0x440)
    char cmd_buf[...];       // 命令缓冲区 (r4 = sp)

    // 1. 清零缓冲区
    memset(proc_buf, 0, 0x400);
    memset(logger_buf, 0, 0x1000);

    // 2. 获取当前进程信息用于日志
    int pid = getpid();  // 或其他获取 PID 的函数
    sprintf(cmd_buf, "cat /proc/%d/status | grep Name | awk '{print $2}'", pid);
    if (system(cmd_buf) != 0) {
        // 错误路径: 记录 console run failed
        system("logger -p 1 youdao_safe_powerdown console run failed!");
        goto skip_log;
    }

    // 3. 记录安全关机日志
    sprintf(logger_buf, "logger -p 1 youdao_safe_powerdown [%s].", proc_buf);
    system(logger_buf);

skip_log:
    // 4. 后台执行 safepowerdown，最多重试 6 次
    sprintf(cmd_buf, "safepowerdown %d &", delay_value);
    for (int retry = 6; retry > 0; retry--) {
        if (system(cmd_buf) == 0)
            break;
    }
    return result;
}
```

**反汇编证据（关键指令）**：

```
0x1e3c: push {r4, r5, r6, r7, r8, lr}
0x1e84: bl   #0x1214              ; → memset(buf1, 0, 0x400)
0x1e94: bl   #0x1214              ; → memset(buf2, 0, 0x1000)
0x1e98: bl   #0x12a4              ; → getpid/time
0x1eac: bl   #0x1298              ; → sprintf(cmd, "cat /proc/%d/status...", pid)
0x1eb8: bl   #0x1088              ; → system(cmd) [第一个命令]
0x1ec0: bne  #0x1f48             ; → 出错则跳错误处理
0x1ed4: bl   #0x1298              ; → sprintf(buf2, "logger -p 1 ...", name)
0x1ee0: bl   #0x1088              ; → system(buf2) [第二个命令]
0x1ee4: mov  r5, #6              ; → retry = 6
0x1f18: bl   #0x1298              ; → sprintf(cmd, "safepowerdown %d &", delay)
0x1f20: beq  #0x1f38             ; → 重试完成
0x1f2c: bl   #0x1088              ; → system(cmd) [第三个命令 - 重试循环]
0x1f34: bne  #0x1f1c             ; → 失败则继续重试
```

## 字符串表分析

HAL 库中与 safepowerdown 相关的所有字符串（按文件偏移排列）：

| 偏移 | 字符串 | 用途 |
|------|--------|------|
| 0x3536 | `cat /proc/%d/status \| grep Name \| awk '{print $2}'` | 获取进程名 |
| 0x3569 | `logger -p 1 youdao_safe_powerdown [%s].` | 日志记录 |
| 0x3591 | `logger -p 1 youdao_safe_powerdown console run failed!` | 错误日志 |
| 0x35c7 | `safepowerdown %d &` | 后台执行 safepowerdown |
| 0x35da | `find /usr/bin/ -name sshd_service && /usr/bin/sshd_service restart` | **⚠️ 无代码引用** |
| 0x361d | `grep usb_adb_en /tmp/.usb_config \|\| echo usb_adb_en >> ...` | ADB 开启 |
| 0x3687 | `sed -i '/usb_adb_en/d' /tmp/.usb_config; ...` | ADB 关闭 |

## 关键发现

### sshd_service restart 字符串

- 字符串 `find /usr/bin/ -name sshd_service && /usr/bin/sshd_service restart` 位于 HAL 库偏移 0x35da
- **该字符串在 12 个 part1.ext4 ELF 文件中均无任何代码引用**
- 字符串紧邻 `safepowerdown %d &`（偏移 0x35c7），属于同一字符串域
- 可能的解释：
  1. 死代码（开发过程中添加但未使用的字符串）
  2. 引用代码在库的截断部分
  3. 由其他编译单元引用（不在 part1.ext4 中）
  4. 由 `/usr/bin/safepowerdown` 脚本本身使用（字符串被复制到库中）

### safepowerdown 会启动 SSH 吗？

**不能断言。** 理由：

1. HAL 层 `youdao_safe_powerdown()` **不直接** 执行 `sshd_service restart`
2. 它 fork 执行的是 `/usr/bin/safepowerdown <delay> &` 作为后台进程
3. `/usr/bin/safepowerdown`（真正的脚本/二进制）**不在 OTA 包中**，无法分析
4. `sshd_service restart` 字符串在库中存在，但未找到引用它的代码

## 未解问题

1. `/usr/bin/safepowerdown` 的完整内容（脚本还是二进制？）
2. `/usr/bin/safepowerdown` 是否会启动 `sshd_service`？
3. `youdao_safe_powerdown` 在什么场景下被调用？（正常关机？低电量？）
4. 如果获取 rootfs，能否提取到完整的 `safepowerdown` 文件？
