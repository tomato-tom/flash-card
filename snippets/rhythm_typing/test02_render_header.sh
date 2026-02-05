#!/bin/bash
# test02_render_header.sh
# 画面描画とヘッダー表示のテスト

SCORE=0
MISSED=0
GAME_DURATION=30
GAME_START_TIME=$(date +%s)
TARGET_POSITION=40
TERMINAL_WIDTH=$(tput cols)

# 描画関数
render_header() {
    clear
    
    local current_time=$(date +%s)
    local remaining_time=$((GAME_DURATION - (current_time - GAME_START_TIME)))
    if [ $remaining_time -lt 0 ]; then
        remaining_time=0
    fi
    
    echo "┌────────────────────────────────────────────────────────────┐"
    echo "│ リズムタイピングゲーム（シンプル版）                           │"
    printf "│ スコア: %-4d  ミス: %-4d  残り時間: %3d秒                 │\n" $SCORE $MISSED $remaining_time
    echo "└────────────────────────────────────────────────────────────┘"
    echo ""
    echo "  文字 'a' が右から流れてきます。"
    echo "  文字が中央の線にきたら 'a' キーを押してください。"
    echo ""
    
    # ターゲットライン
    for ((i=0; i<TARGET_POSITION-3; i++)); do
        echo -n " "
    done
    echo "│目標│"
    echo ""
}

# クリーンアップ
cleanup() {
    tput cnorm
    clear
    echo "テスト終了"
    exit 0
}
trap cleanup EXIT INT TERM

tput civis
echo "=== 画面描画テスト ==="
echo "スコアとミスをカウントアップします（Ctrl+Cで終了）"
sleep 2

for ((i=0; i<10; i++)); do
    SCORE=$((SCORE + 10))
    MISSED=$((MISSED + 1))
    render_header
    echo "更新 $i: スコア=$SCORE, ミス=$MISSED"
    sleep 1
done

cleanup
