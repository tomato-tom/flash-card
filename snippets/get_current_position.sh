#!/bin/bash

# 現在位置取得
get_pos() {
    IFS=';' read -sdR -p $'\E[6n' row col
    row="${row#*[}"
    # 位置調整
    printf "%s %s" "$row" "$col"
}

clear
    
read row col < <(get_pos)
echo "row: $row"
echo "col: $col"

tput cup 3 5
read row col < <(get_pos)
echo "row: $row"
echo "col: $col"
