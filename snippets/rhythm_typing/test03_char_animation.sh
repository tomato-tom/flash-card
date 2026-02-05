#!/bin/bash
# test03_char_animation.sh
# 文字の生成と移動アニメーション

TERMINAL_WIDTH=$(tput cols)
TARGET_POSITION=40
SPEED=0.1

declare -a letters_x
declare -a letters_active
NEXT_ID=0

# 文字を生成
add_letter() {
    letters_x[$NEXT_ID]=$TERMINAL_WIDTH
    letters_active[$NEXT_ID]=1
    echo "文字[$NEXT_ID]を生成 (x=$TERMINAL_WIDTH)"
    NEXT_ID=$((NEXT_ID + 1))
}

# 全文字を移動
move_letters() {
    for ((id=0; id<NEXT_ID; id++)); do
        if [ "${letters_active[$id]:-0}" -eq 1 ]; then
            letters_x[$id]=$((letters_x[$id] - 1))
            
            if [ ${letters_x[$id]} -le 0 ]; then
                letters_active[$id]=0
                echo "文字[$id]が画面外に消えました"
            fi
        fi
    done
}

# 文字を描画
render_letters() {
    clear
    echo "=== 文字移動アニメーション ==="
    echo "ターゲット位置: $TARGET_POSITION"
    echo ""
    
    # ターゲットライン
    for ((i=0; i<TARGET_POSITION-3; i++)); do
        echo -n " "
    done
    echo "│目標│"
    echo ""
    
    # 文字の行
    echo -n " "
    for ((i=1; i<=TERMINAL_WIDTH; i++)); do
        local char_to_show=" "
        
        for ((id=0; id<NEXT_ID; id++)); do
            if [ "${letters_active[$id]:-0}" -eq 1 ] && [ "${letters_x[$id]}" -eq "$i" ]; then
                char_to_show="a"
                break
            fi
        done
        
        if [ "$i" -eq "$TARGET_POSITION" ]; then
            if [ "$char_to_show" = " " ]; then
                echo -n "|"
            else
                echo -n "a"
            fi
        else
            echo -n "$char_to_show"
        fi
    done
    echo ""
    echo ""
    
    # デバッグ情報
    echo "アクティブな文字:"
    for ((id=0; id<NEXT_ID; id++)); do
        if [ "${letters_active[$id]:-0}" -eq 1 ]; then
            echo "  ID=$id, X=${letters_x[$id]}"
        fi
    done
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
echo "文字を3つ生成して移動させます（Ctrl+Cで終了）"
sleep 2

# 文字を3つ生成（間隔をあけて）
add_letter
sleep 1
add_letter
sleep 1
add_letter

# アニメーション
for ((i=0; i<100; i++)); do
    move_letters
    render_letters
    sleep $SPEED
done

cleanup
