#!/bin/bash

MAX_CHAR=${1:-5}   # 最大文字数
COUNT=${2:-8}      # 出力数

# 文字リスト作成
word_list=($(ls /usr/bin | grep -E "^.{1,$MAX_CHAR}$"))
word_list+=($(ls /usr/sbin | grep -E "^.{1,$MAX_CHAR}$"))

echo --- 統計 ---
echo "Max Char: $MAX_CHAR"
echo "Count: $COUNT"
echo "Files: ${#word_list[@]}"
echo ---
echo

# 結果
echo "ランダムに$COUNT個表示"
for (( i=0; i<$COUNT; i++ )); do
    index=$((RANDOM % ${#word_list[@]}))
    echo "${word_list[$index]}"
done

