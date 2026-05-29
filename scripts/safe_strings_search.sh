#!/bin/bash
#
# safe_strings_search.sh
# ======================
# 对本地固件提取目录做只读 strings/grep 搜索。
# 不会写入或修改设备，不会发送网络请求。
#
# 用法：
#   chmod +x safe_strings_search.sh
#   ./safe_strings_search.sh /path/to/extracted/rootfs
#
# 示例：
#   ./safe_strings_search.sh /tmp/youdao_ota/firmware
#

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <extracted_firmware_dir>"
    echo ""
    echo "对本地固件提取目录做安全的信息搜索。"
    echo "所有操作均为只读，不涉及网络或设备。"
    exit 1
fi

FIRMWARE_DIR="$1"

if [ ! -d "$FIRMWARE_DIR" ]; then
    echo "Error: directory '$FIRMWARE_DIR' not found"
    exit 1
fi

echo "=== 固件目录信息 ==="
echo "路径: $FIRMWARE_DIR"
echo "大小: $(du -sh "$FIRMWARE_DIR" 2>/dev/null | cut -f1)"
echo "文件数: $(find "$FIRMWARE_DIR" -type f 2>/dev/null | wc -l)"
echo ""

# ---- 搜索关键词列表 ----
# 仅搜索用于分析的信息，不包含 exploit payload

echo "=== 搜索: ADB 相关字符串 ==="
grep -r "adb_auth\|adb shell\|setAdbEnable\|getAdbEnable\|\.adbOn\|adb_en" \
    "$FIRMWARE_DIR" --include="*.txt" --include="*.sh" --include="*.cfg" \
    --include="*.conf" 2>/dev/null | head -30 || echo "  (无结果)"
echo ""

echo "=== 搜索: SSH 相关字符串 ==="
grep -r "sshd\|sshd_service\|dropbear\|openssh" \
    "$FIRMWARE_DIR" --include="*.txt" --include="*.sh" --include="*.cfg" \
    --include="*.conf" 2>/dev/null | head -30 || echo "  (无结果)"
echo ""

echo "=== 搜索: safepowerdown 相关字符串 ==="
grep -r "safepowerdown\|safe_powerdown\|powerdown" \
    "$FIRMWARE_DIR" --include="*.txt" --include="*.sh" --include="*.cfg" \
    --include="*.conf" 2>/dev/null | head -30 || echo "  (无结果)"
echo ""

echo "=== 搜索: WebSocket 相关字符串 ==="
grep -r "websocket\|WebSocket\|ws://\|wss://\|9307\|callNative" \
    "$FIRMWARE_DIR" --include="*.txt" --include="*.sh" --include="*.cfg" \
    --include="*.conf" 2>/dev/null | head -30 || echo "  (无结果)"
echo ""

echo "=== 搜索: OTA 相关字符串 ==="
grep -r "update_engine\|check_install\|YDIH\|YDII\|adups\|fota\|abupdate" \
    "$FIRMWARE_DIR" --include="*.txt" --include="*.sh" --include="*.cfg" \
    --include="*.conf" 2>/dev/null | head -20 || echo "  (无结果)"
echo ""

echo "=== 搜索: RSA/签名相关字符串 ==="
grep -r "RSA\|X509\|PKCS7\|CMS_verify\|signature\|public.key" \
    "$FIRMWARE_DIR" --include="*.txt" --include="*.sh" --include="*.cfg" \
    --include="*.conf" 2>/dev/null | head -20 || echo "  (无结果)"
echo ""

echo "=== 搜索: debug 相关字符串 ==="
grep -r "debug.cfg\|debugmode\|debug_mode\|DEBUGCONFIG" \
    "$FIRMWARE_DIR" --include="*.txt" --include="*.sh" --include="*.cfg" \
    --include="*.conf" 2>/dev/null | head -20 || echo "  (无结果)"
echo ""

echo "=== 搜索: HAL 层函数字符串 ==="
grep -r "youdao_safe_powerdown\|youdao_set_adb\|youdao_get_usb\|youdao_console" \
    "$FIRMWARE_DIR" --include="*.txt" --include="*.sh" --include="*.cfg" \
    --include="*.conf" 2>/dev/null | head -20 || echo "  (无结果)"
echo ""

echo "=== 搜索: shadow/passwd ==="
grep -r "shadow\|passwd\|password\|login" \
    "$FIRMWARE_DIR" --include="*.txt" --include="*.cfg" \
    --include="*.conf" 2>/dev/null | head -20 || echo "  (无结果)"
echo ""

echo "Done."
echo "所有搜索均为只读操作，未修改任何文件。"
