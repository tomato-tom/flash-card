#!/bin/bash

# 枠を描画する関数
create_frame_at() {
    local start_row=$1
    local start_col=$2
    local rows=$3
    local cols=$4
    local fill_char=${5:-" "}
    
    # グローバル変数に設定
    frame_start_row=$start_row
    frame_start_col=$start_col
    frame_rows=$rows
    frame_cols=$cols
    
    tput dim
    
    # 上枠
    tput cup $start_row $start_col
    echo -n " ┌"
    for ((i=0; i<cols; i++)); do echo -n "─"; done
    echo "┐"
    
    # サイド
    for ((j=1; j<=rows; j++)); do
        tput cup $((start_row + j)) $start_col
        echo -n " │"
        for ((i=0; i<cols; i++)); do echo -n "$fill_char"; done
        echo "│"
    done
    
    # 下枠
    tput cup $((start_row + rows + 1)) $start_col
    echo -n " └"
    for ((i=0; i<cols; i++)); do echo -n "─"; done
    echo "┘"
    
    tput sgr0
}

# テキスト出力関数（修正版）
write_at() {
    local row=$1
    local col=$2
    local text=$3
    local text_size=$(echo -n "$text" | wc -c)
    
    # 範囲チェック
    if [ $row -ge $frame_rows ]; then
        row=$((frame_rows - 1))
    fi
    
    if [ $col -ge $frame_cols ]; then
        col=$((frame_cols - text_size))
        if [ $col -lt 0 ]; then col=0; fi
    elif [ $((col + text_size)) -gt $frame_cols ]; then
        col=$((frame_cols - text_size))
        if [ $col -lt 0 ]; then
            col=0
            text=${text:0:$frame_cols}
        fi
    fi
    
    # 絶対位置に変換（+1は枠の境界線分）
    ((row += frame_start_row + 1))
    ((col += frame_start_col + 2))
    
    tput cup $row $col
    echo -n "$text"
}

# メイン
clear

# 枠を作成（行5、列10から10行×30列）
create_frame_at 5 10 10 30

# テスト
write_at 0 0 "upper-left"        # 枠内左上
write_at 0 25 "upper-right"       # 枠内右上
write_at 5 0 "bottom"    # 枠内下方
write_at 2 10 "center"       # 枠内中央
write_at 0 28 "right"   # 右端近く

# カーソルを下に移動
tput cup 20 0
echo "テスト完了。Enterキーで終了。"
read
