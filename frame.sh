#!/bin/bash

# カーソル現在位置を取得
get_pos() {
    IFS=';' read -sdR -p $'\E[6n' row col
    echo "${row#*[} ${col}"
}

# 枠が端末内に収まるかチェック
check_frame_fits() {
    local term_rows=$(tput lines)
    local term_cols=$(tput cols)
    
    # 下にはみ出さないかチェック
    if [ $((frame_start_row + frame_rows)) -ge $term_rows ]; then
        return 1
    fi
    # 右にはみ出さないかチェック
    if [ $((frame_start_col + frame_cols)) -ge $term_cols ]; then
        return 1
    fi

    return 0
}


# 枠を作成
create_frame() {
    frame_start_row=$1 # 相対座標
    frame_start_col=$2 # 相対座標
    frame_rows=$3
    frame_cols=$4

    local fill_char=${5:-" "}  # デフォルトは空白

    # 開始位置を絶対座標に変換
    read current_row current_col < <(get_pos)
    ((frame_start_row += current_row))
    ((frame_start_col += current_col))

    check_frame_fits || return 1

    # 移動
    tput cup $frame_start_row $frame_start_col
    tput dim

    # 上枠を描画
    echo -n " ┌"
    for ((i=0; i<frame_cols; i++)); do
        echo -n "─"
    done
    echo "┐"
    
    # サイド枠を描画
    for ((j=1; j<=frame_rows; j++)); do
        tput cup $((frame_start_row + j)) $frame_start_col
        echo -n " │"
        
        tput sgr0
        for ((i=0; i<frame_cols; i++)); do
            echo -n "$fill_char"
        done
        tput dim
        
        echo "│"
    done
    
    # 下枠を描画
    tput cup $((frame_start_row + frame_rows + 1)) $frame_start_col
    echo -n " └"
    for ((i=0; i<frame_cols; i++)); do
        echo -n "─"
    done
    echo "┘"
    
    tput sgr0
}

# フレーム内指定位置にテキストを出力
# 予めフレーム描画する必要ある
write_at() {
    local row=$1
    local col=$2
    local text=$3
    local color=$4
    local text_size=$(echo -n "$text" | wc -c)

    [ -z $frame_rows ] && return 1  # フレーム描画済みチェック
    
    # 行位置が文字指定の場合
    if [ "$row" == "top" ]; then
        row=1
    elif [ "$row" == "middle" ]; then
        row=$((frame_rows / 2))
    elif [ "$row" == "bottom" ]; then
        row=$((frame_rows))
    fi

    # マスが文字指定の場合
    if [ "$col" == "left" ]; then
        col=1
    elif [ "$col" == "center" ]; then
        col=$((frame_cols / 2 - text_size / 2))
    elif [ "$col" == "right" ]; then
        col=$((frame_cols - text_size))
    fi

    # 描画を枠内に制限
    if [ $row -gt $frame_rows ]; then
        row=$((frame_rows - 1))
    elif [ $((col + text_size)) -gt $frame_cols ]; then
        col=$((frame_cols - text_size))
    fi

    # 枠相対位置から端末絶対位置に変換
    ((row += frame_start_row))
    ((col += frame_start_col + 1))

    tput cup $row $col
    if [ -n "$color" ]; then
        echo -ne "$color$text\033[0m"
    else
        echo -n "$text"
    fi
}

# 使用例
#
# 枠の開始位置（相対位置）、枠の大きさ指定で描画
# create_frame Y X H W
# echo "Create frame"
# create_frame 3 3 10 33 || exit 1
# tput sc

# 枠内にテキスト表示テスト
# write_at row col text
# row: num/top/middle/bottom
# col: num/left/center/right
# write_at middle left "middle left"
# write_at top center "top center"
# write_at bottom right "bottom right"
# write_at 3 3 "at 3-3"

# カーソル位置を枠描画後の位置に移動
# tput rc
# echo "Enter to end"
# read
