#!/bin/bash

# CUIカラーピッカー
sample_color(){
    local r g b

    if [ $3 = "r" ]; then
        color="Red"
    elif [ $3 = "g" ]; then
        color="Green"
    elif [ $3 = "b" ]; then
        color="Blue"
    else
        color="Unknown"
    fi

    echo "$color increases by one square"
    for i in 0 {31..255..32}; do
        printf "%9s" "$2 $i"
        printf " "
    done
    echo

    for i in 0 {31..255..32}; do
        for j in 0 {31..255..32}; do
            for k in 0 {31..255..32}; do
                if [ $1 = "r" ]; then
                    r=$i
                elif [ $2 = "r" ]; then
                    r=$j
                elif [ $3 = "r" ]; then
                    r=$k
                fi

                if [ $1 = "g" ]; then
                    g=$i
                elif [ $2 = "g" ]; then
                    g=$j
                elif [ $3 = "g" ]; then
                    g=$k
                fi

                if [ $1 = "b" ]; then
                    b=$i
                elif [ $2 = "b" ]; then
                    b=$j
                elif [ $3 = "b" ]; then
                    b=$k
                fi

                echo -en "\033[48;2;${r};${g};${b}m "

                if [ $k -eq 255 ]; then
                    if [ $j -eq 255 ]; then
                        printf "\033[0m $1 "
                        printf "%3s" "$i"
                        echo
                    else
                        echo -ne "\033[0m "
                    fi
                fi
            done
        done
    done
    echo -e "\033[0m"
}

show_color() {
    # 色を表示（ANSIエスケープシーケンス使用）
    echo -e "\033[48;2;${r};${g};${b}m    \033[0m RGB(${r}, ${g}, ${b})"
    echo -e "\033[38;2;${r};${g};${b}mText Color\033[0m"
    echo "HEX: #$(printf "%02x%02x%02x" $r $g $b)"
    echo "ANSI: \\033[38;2;${r};${g};${b}m"
    echo
}

echo "q to quit"
echo "s to show sample"

while :; do
    # R/G/B数字入力で色選択
    echo -n "r g b (0-255): "
    read r g b

    [ "$r" = "q" ] && break
    [ "$r" = "s" ] && {
        sample_color g r b
        sample_color r b g
        continue
    }
    show_color
done

