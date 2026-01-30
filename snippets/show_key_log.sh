#!/bin/bash
# show_key_log.sh
# key_logger.shで保存したログを表示

if [[ -z "$1" ]]; then
    echo "使用方法: $0 <file>"
    exit 1
fi

FILE="$1"

echo "=== ログ表示 ==="
echo "ファイル: $FILE"
echo "レコードサイズ: 9バイト"
echo ""

xxd -p -c 9 "$FILE" 2>/dev/null | while read hex_line; do
    [[ ${#hex_line} -ne 18 ]] && continue
    
    timestamp_hex=${hex_line:0:16}
    key_hex=${hex_line:16:2}
    
    # 16進数 → 10進数
    timestamp=$((0x$timestamp_hex))
    key_code=$((0x$key_hex))
    
    # ミリ秒を含むタイムスタンプから秒とミリ秒を分離
    seconds=$((timestamp / 1000))
    millis=$((timestamp % 1000))
    
    # 時刻表示
    time_str=$(date -d "@$seconds" "+%H:%M:%S" 2>/dev/null || printf "%02d:%02d:%02d" \
        $((seconds / 3600 % 24)) \
        $((seconds / 60 % 60)) \
        $((seconds % 60)))
    
    # キー表示
    case $key_code in
        10|13)  key_display="[ENTER]" ;;
        32)  key_display="[SPACE]" ;;
        9)   key_display="[TAB]" ;;
        127) key_display="[BS]" ;;
        27)  key_display="[ESC]" ;;
        *)
            if [[ $key_code -ge 32 ]] && [[ $key_code -le 126 ]]; then
                key_display=$(printf "\\x$key_hex")
            else
                key_display="[0x$key_hex]"
            fi
            ;;
    esac
    
    printf "%s.%03d | %3d (0x%02x) | %s\n" \
        "$time_str" "$millis" "$key_code" "$key_code" "$key_display"
done
