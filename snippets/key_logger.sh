#!/bin/bash
# key_logger_final.sh

LOG_FILE="keys.bin"

> "$LOG_FILE"

# 端末設定保存
original_settings=$(stty -g)

cleanup() {
    stty "$original_settings"
}

trap cleanup EXIT INT TERM

# rawモード設定（エコーなし）
stty raw -echo

echo -e "入力開始、Enterで終了...\r"

while true; do
    # 1文字読み込み
    key=$(dd bs=1 count=1 2>/dev/null)
    
    timestamp=$((10#$(date +%s)$(date +%3N)))
    keycode=$(printf "%d" "'$key")
    
    printf "%016x%02x" $timestamp $keycode | xxd -r -p >> "$LOG_FILE"
    
    # 表示
    case "$key" in
        $'\x0d'|$'\x0a')     # Enterキーで終了
            printf "\r\n\n記録完了: %s (%d バイト)\r\n" "$LOG_FILE" $(wc -c < "$LOG_FILE")
            break
            ;;
        $'\x09') printf "\t" ;; # タブ
        $'\x20') printf " " ;; # スペース
        $'\x7f') printf "\b\033[0K" ;;
        *) printf "%s" "$key" ;;
    esac
done
