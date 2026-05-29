#!/bin/bash
#
# safe_extract_notes.sh
# =====================
# 从固件提取目录整理文件列表和 MD5 哈希。
# 不修改任何文件，不连接设备或网络。
#
# 用法：
#   chmod +x safe_extract_notes.sh
#   ./safe_extract_notes.sh /path/to/extracted/rootfs [output_dir]
#
# 示例：
#   ./safe_extract_notes.sh /tmp/youdao_ota/firmware ./output
#

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <extracted_firmware_dir> [output_dir]"
    echo ""
    echo "从本地固件提取目录整理文件列表和 MD5 哈希。"
    echo "所有操作均为只读，不涉及网络或设备。"
    exit 1
fi

FIRMWARE_DIR="$1"
OUTPUT_DIR="${2:-./extract_notes_output}"

if [ ! -d "$FIRMWARE_DIR" ]; then
    echo "Error: directory '$FIRMWARE_DIR' not found"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

OUTPUT_FILE="$OUTPUT_DIR/file_list.txt"
HASH_FILE="$OUTPUT_DIR/md5_hashes.txt"
INTERESTING_FILE="$OUTPUT_DIR/interesting_files.txt"

echo "=== 生成文件列表 ==="
find "$FIRMWARE_DIR" -type f -exec ls -la {} \; > "$OUTPUT_FILE" 2>/dev/null
echo "文件列表: $OUTPUT_FILE ($(wc -l < "$OUTPUT_FILE") 项)"

echo ""
echo "=== 计算 MD5 哈希 (仅小于 10MB 的文件) ==="
> "$HASH_FILE"
find "$FIRMWARE_DIR" -type f -size -10M | while read -r f; do
    md5=$(md5sum "$f" 2>/dev/null || md5 -q "$f" 2>/dev/null)
    if [ -n "$md5" ]; then
        echo "$md5  $(basename "$f")" >> "$HASH_FILE"
    fi
done 2>/dev/null
echo "MD5 哈希: $HASH_FILE ($(wc -l < "$HASH_FILE") 项)"

echo ""
echo "=== 提取关键文件列表 ==="
> "$INTERESTING_FILE"
{
    echo "# 关键文件列表"
    echo "# 生成时间: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo "# 来源目录: $FIRMWARE_DIR"
    echo ""
    echo "## 搜索关键词: adb_auth"
    find "$FIRMWARE_DIR" -type f -name "*adb_auth*" 2>/dev/null
    echo ""
    echo "## 搜索关键词: safepowerdown"
    find "$FIRMWARE_DIR" -type f -name "*safepowerdown*" -o -name "*safe_powerdown*" 2>/dev/null
    echo ""
    echo "## 搜索关键词: sshd"
    find "$FIRMWARE_DIR" -type f -name "*sshd*" 2>/dev/null
    echo ""
    echo "## 搜索关键词: debug"
    find "$FIRMWARE_DIR" -type f -name "*debug*" 2>/dev/null
    echo ""
    echo "## 搜索关键词: update_engine / ota"
    find "$FIRMWARE_DIR" -type f -name "*update_engine*" -o -name "*check_install*" 2>/dev/null
    echo ""
    echo "## 搜索关键词: websocket / ws"
    find "$FIRMWARE_DIR" -type f -name "*websocket*" -o -name "*ws_*" 2>/dev/null
    echo ""
    echo "## 搜索关键词: shadow / passwd"
    find "$FIRMWARE_DIR" -type f -name "*shadow*" -o -name "*passwd*" 2>/dev/null
    echo ""
    echo "## 搜索关键词: init.d"
    find "$FIRMWARE_DIR" -path "*/init.d/*" -type f 2>/dev/null
} >> "$INTERESTING_FILE"
echo "关键文件: $INTERESTING_FILE"

echo ""
echo "=== 输出 ==="
echo "文件列表:   $OUTPUT_FILE"
echo "MD5 哈希:   $HASH_FILE"
echo "关键文件:   $INTERESTING_FILE"
echo ""
echo "Done. 所有操作均为只读。"
