#!/bin/bash

# 絶対位置で枠を作成する関数
create_frame() {
    local start_row=$1
    local start_col=$2
    local rows=$3
    local cols=$4
    local fill_char=${5:-" "}  # デフォルトは空白
    
    tput dim
    
    # 上枠を描画
    tput cup $start_row $start_col
    echo -n " ┌"
    for ((i=0; i<cols; i++)); do
        echo -n "─"
    done
    echo "┐"
    
    # サイド枠を描画
    for ((j=1; j<=rows; j++)); do
        tput cup $((start_row + j)) $start_col
        echo -n " │"
        
        tput sgr0
        for ((i=0; i<cols; i++)); do
            echo -n "$fill_char"
        done
        tput dim
        
        echo "│"
    done
    
    # 下枠を描画
    tput cup $((start_row + rows + 1)) $start_col
    echo -n " └"
    for ((i=0; i<cols; i++)); do
        echo -n "─"
    done
    echo "┘"
    
    tput sgr0
}

# フレーム内指定位置にテキストを出力
write_at() {
    local row=$1
    local col=$2
    local text=$3
    local text_size=$(echo -n "$text" | wc -c)
    
    # 描画を枠内に制限
    if [ $row -gt $frame_rows ]; then
        row=$((frame_rows - 1))
    elif [ $((col + text_size)) -gt $frame_cols ]; then
        col=$((frame_cols - text_size))
    fi

    # 枠相対位置から端末絶対位置に変換
    ((row += frame_start_row))
    ((col += frame_start_col))

    tput cup $row $col
    echo -n "$text"
}

# フレーム内のほぼ中央にテキスト描画
write_center() {
    set -x
    row=$((frame_start_row + frame_rows /2))
    col=$((frame_start_col + frame_cols /2))
    tput cup $((frame_start_row + 4)) $((frame_start_col + 8))
    tput blink && tput setaf 5 && echo -n "Hello!"

    set +x
}

# カーソル位置を取得
get_pos() {
    IFS=';' read -sdR -p $'\E[6n' row col
    echo "${row#*[} ${col}"
}

# メイン処理
clear  # 画面をクリア

# 現在位置を取得
read row col < <(get_pos)
echo Create frame
echo "初期位置 - Row: $row, Col: $col"

# 枠を絶対位置に描画 (行5, 列10から開始)
frame_start_row=5
frame_start_col=10
frame_rows=7
frame_cols=30

create_frame $frame_start_row $frame_start_col $frame_rows $frame_cols
tput sc

write_at 100 100 hello

tput rc
# 終了前にカーソル位置を下に移動
echo "Enterキーを押すと終了します"
read
echo "終了しました"

