#!/bin/bash

# CUIカラーピッカー
show_color() {
    # 色を表示（ANSIエスケープシーケンス使用）
    echo -e "\033[48;2;${r};${g};${b}m    \033[0m RGB(${r}, ${g}, ${b})"
    echo -e "\033[38;2;${r};${g};${b}mText Color\033[0m"
    echo "HEX: #$(printf "%02x%02x%02x" $r $g $b)"
    echo "ANSI: \\033[38;2;${r};${g};${b}m"
    echo
}

while :; do
    # R/G/B数字入力で色選択
    echo "q to quit"
    echo "r g b (0-255): "
    read r g b

    [ "$r" = "q" ] && break
    show_color
done

