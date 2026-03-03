#!/bin/bash

# 色の定義
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

word="dog and cat"
total_len=${#word}
typed=""
position=0
correct=0

# 端末設定保存
original_settings=$(stty -g)

cleanup() {
    stty "$original_settings"
    tput cnorm
    echo -e "${NC}"
}

trap cleanup EXIT INT TERM

tput civis  # カーソル非表示

clear
echo -e "${BOLD}Typing Game${NC}"
echo -e "${YELLOW}CPS: ${NC}"
echo -e "----------------"
echo -e "Type this：$word\n\n"
echo -n "> "

stty raw -echo # rawモード設定

# メインループ
while :; do
    current_char="${word:$position:1}"
    
    # 入力を1文字受け取る
    key=$(dd bs=1 count=1 2>/dev/null)
    
    case "$key" in
        $'\x0d'|$'\x0a')     # Enterキーで強制終了
            echo
            break
            ;;
        $'\x7f'|$'\b')       # バックスペース
            if [ $position -gt 0 ]; then
                printf "\b\033[0K"
                ((position--))
                typed="${typed:0:$position}"
            fi
            ;;
        $'\x20')             # スペース
            typed+=" "

            if [ "$current_char" = " " ]; then
                echo -ne "${GREEN} "
            else
                echo -ne "${RED}_"
            fi
            ((position++))
            ;;
        *)
            typed+="$key"

            if [ "$current_char" = "$key" ]; then
                echo -ne "${GREEN}$key"
            else
                echo -ne "${RED}$key"
            fi
            ((position++))
            ;;
    esac


    if [[ "$typed" == "$word" ]]; then
        break
    fi
    
done

cleanup

# 正解数を計算
correct=0
for ((i=0; i<$total_len; i++)); do
    if [ "${typed:$i:1}" = "${word:$i:1}" ]; then
        ((correct++))
    fi
done

accuracy=$((correct * 100 / total_len))

# 最終結果
echo -e "\n\n${BOLD}=== 結果 ===${NC}"
echo -e "入力: $typed"
echo -e "正解: $word"
echo -e "${GREEN}accuracy: ${NC}${accuracy}"
