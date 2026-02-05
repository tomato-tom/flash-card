#!/bin/bash
# test05_simple_integration.sh
# 簡易統合テスト（手動キー入力版）

TARGET_POSITION=40
SPEED=0.2
TERMINAL_WIDTH=$(tput cols)
SCORE=0
MISSED=0

declare -a letters_x
declare -a letters_active
NEXT_ID=0

# 文字生成
add_letter() {
    letters_x[$NEXT_ID]=$TERMINAL_WIDTH
    letters_active[$NEXT_ID]=1
    NEXT_ID=$((NEXT_ID + 1))
}

# 文字移動
move_letters() {
    for ((id=0; id<NEXT_ID; id++)); do
        if [ "${letters_active[$id]:-0}" -eq 1 ]; then
            letters_x[$id]=$((letters_x[$id] - 1))
            
            if [ ${letters_x[$id]} -le 0 ]; then
                letters_active[$id]=0
                MISSED=$((MISSED + 1))
            fi
        fi
    done
}

# 判定
check_hit() {
    local hit_id=-1
    local closest_distance=1000
    
    for ((id=0; id<NEXT_ID; id++)); do
        if [ "${letters_active[$id]:-0}" -eq 1 ]; then
            local x=${letters_x[$id]}
            local distance=$((x - TARGET_POSITION))
            
            if [ $distance -lt 0 ]; then
                distance=$((-distance))
            fi
            
            if [ $distance -le 3 ]; then
                if [ $distance -lt $closest_distance ]; then
                    closest_distance=$distance
                    hit_id=$id
                fi
            fi
        fi
    done
    
    if [ $hit_id -ge 0 ]; then
        SCORE=$((SCORE + 10))
        letters_active[$hit_id]=0
    else
        SCORE=$((SCORE - 5))
    fi
}

# 描画
render_screen() {
    clear
    echo "=== 簡易統合テスト ==="
    printf "スコア: %-4d  ミス: %-4d\n" $SCORE $MISSED
    echo ""
    echo "'a'キーを押してヒット判定（qで終了）"
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
}

# クリーンアップ
cleanup() {
    tput cnorm
    stty echo
    clear
    echo "テスト終了"
    echo "最終スコア: $SCORE"
    echo "最終ミス: $MISSED"
    exit 0
}
trap cleanup EXIT INT TERM

tput civis
stty -echo

# 初期文字を生成
add_letter

# メインループ
frame=0
while true; do
    move_letters
    render_screen
    
    # 3フレームごとに新しい文字を追加
    if [ $((frame % 15)) -eq 0 ]; then
        add_letter
    fi
    
    # キー入力チェック（非ブロッキング）
    if read -rsn1 -t $SPEED key; then
        if [ "$key" = "a" ]; then
            check_hit
        elif [ "$key" = "q" ]; then
            break
        fi
    fi
    
    frame=$((frame + 1))
done

cleanup
