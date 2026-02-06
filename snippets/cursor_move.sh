#!/bin/bash

# 現在位置取得
get_pos() {
    IFS=';' read -sdR -p $'\E[6n' row col
    row="${row#*[}"
    # 位置調整
    ((row--))
    ((col--))
    printf "%s %s" "$row" "$col"
}

# 相対移動
move() {
    local direction=$1
    local steps=${2:-1}
    
    read current_row current_col < <(get_pos)


    case $direction in
        up)
            new_row=$((current_row - steps))
            [ "$new_row" -lt 1 ] && new_row=1
            tput cup "$new_row" "$current_col"
            ;;
        down)
            new_row=$((current_row + steps))
            [ "$new_row" -gt "$term_rows" ] && new_row=$term_rows
            tput cup "$new_row" "$current_col"
            ;;
        right)
            new_col=$((current_col + steps))
            [ "$new_col" -gt "$term_cols" ] && new_col=$term_cols
            tput cup "$current_row" "$new_col"
            ;;
        left)
            new_col=$((current_col - steps))
            [ "$new_col" -lt 1 ] && new_col=1
            tput cup "$current_row" "$new_col"
            ;;
    esac
}

text_move() {
    local current_text_size=$1
    local direction=$2
    local text="$3"
    local step=${4:-1}

    read row col < <(get_pos)

    if [ $direction = left ]; then
        [ $row -eq 1 ] && return
    elif [ $direction = right ]; then
        [ $((col + text_size)) -gt $term_cols ] && return
    fi

    tput sc
    printf "%${current_text_size}s" " " # 元の文字を消去
    tput rc

    move $direction $step
    tput sc
    printf "%s" "$text"
    tput rc
}

# 端末サイズ取得
term_rows=$(tput lines)
term_cols=$(tput cols)
clear

# 使用例
echo "Term size: Rows ${term_rows}, Cols ${term_cols}"
echo "Current Pos: $(get_pos)"
tput sc
text_size=

while true; do
    read -rsn1 key
    case "$key" in
        h) # ←
            direction="left"
            ;;
        j) # ↓
            direction="down"
            ;;
        k) # ↑
            direction="up"
            ;;
        l) # →
            direction="right"
            ;;
        '') # Enter
            break
            ;;
    esac

    text="Move $direction"
    text_move "$text_size" "$direction" "$text"
    text_size="$(echo $text | wc -c)"
done

