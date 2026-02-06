#!/bin/bash
# test01_fifo_basic.sh
# FIFO通信の基本動作確認

echo "=== FIFO通信テスト ==="
echo "キーを押すとFIFO経由で受信します（qで終了）"
echo ""

FIFO_PATH="/tmp/test_fifo_$$"
mkfifo "$FIFO_PATH"

# クリーンアップ
cleanup() {
    # バックグラウンドプロセスを終了
    jobs -p | xargs -r kill 2>/dev/null
    rm -f "$FIFO_PATH"
    stty echo  # エコーを戻す
    echo ""
    echo "終了"
    exit 0
}
trap cleanup EXIT INT TERM

# エコーを無効化（キー入力が画面に表示されないように）
stty -echo

# キー入力ハンドラー（/dev/ttyから直接読み取り）
key_handler() {
    local key
    echo "[デバッグ] key_handler開始 (PID=$$)" >&2
    while true; do
        # /dev/ttyから読み取る（バックグラウンドでも動作）
        if read -rsn1 -t 0.01 key < /dev/tty; then
            echo "[デバッグ] キー検出: '$key'" >&2
            echo "$key" > "$FIFO_PATH"
        fi
        sleep 0.001
    done
}

# バックグラウンドで起動
key_handler &
KEY_HANDLER_PID=$!
echo "key_handler起動完了 (PID=$KEY_HANDLER_PID)"
sleep 0.5

# メインループ
counter=0
echo "キー入力待機中..."
while true; do
    if read -t 0.02 key_press < "$FIFO_PATH"; then
        counter=$((counter + 1))
        echo "[$counter] 受信: '$key_press'"
        
        if [ "$key_press" = "q" ]; then
            echo "終了キー検出"
            break
        fi
    fi
done

