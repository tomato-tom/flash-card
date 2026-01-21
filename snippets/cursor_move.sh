#!/bin/bash

# 現在位置取得
get_pos() {
    IFS=';' read -sdR -p $'\E[6n' row col
    echo "${row#*[} ${col}"
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

# 端末サイズ取得
term_rows=$(tput lines)
term_cols=$(tput cols)

# 使用例
echo "Term size: Rows ${term_rows}, Cols ${term_cols}"
echo "Current Pos: $(get_pos)"

# 右に移動
steps=300
text="Move right $steps"
text_size=$(echo "$text" | wc -c)
# はみ出る場合は調整
[ $((steps + text_size)) -gt $term_cols ] && steps=$((term_cols - text_size))
move right $steps
tput sc
echo -n "$text"
sleep 1
tput rc

# 下に移動
steps=14
move down $steps
echo -n "Move down $steps"
read

