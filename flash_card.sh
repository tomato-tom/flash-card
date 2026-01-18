#!/bin/bash

# 単語帳ファイル（CSV形式: 英単語,日本語訳）
VOCAB_FILE="vocab.txt"

# 単語帳ファイルがなければ作成
if [ ! -f "$VOCAB_FILE" ] || [ ! -s $VOCAB_FILE ]; then
    echo "apple,りんご" >> "$VOCAB_FILE"
    echo "book,本" >> "$VOCAB_FILE"
    echo "cat,猫" >> "$VOCAB_FILE"
    echo "dog,犬" >> "$VOCAB_FILE"
    echo "water,水" >> "$VOCAB_FILE"
fi

echo "=== 英単語フラッシュカード ==="
echo
count=0

tput sc

# ランダムに単語を表示
while true; do
    tput rc
    tput ed

    # ランダムに単語を選択
    WORD=$(shuf -n 1 "$VOCAB_FILE")
    
    if [ -z "$WORD" ]; then
        echo "単語が登録されていません"
        break
    fi
    
    ENGLISH=$(echo "$WORD" | cut -d',' -f1)
    JAPANESE=$(echo "$WORD" | cut -d',' -f2)
    
    echo -e "英単語: \033[38;5;87m$ENGLISH\033[0m"
    echo
    echo "意味がわかりますか？ (Enter: 答え表示, q: 終了)"
    
    read -n 1 input
    if [ "$input" = "q" ]; then
        echo
        break
    fi
    
    echo
    echo -e "答え: \033[0;32m$JAPANESE\033[0m"
    echo

    ((count ++))
    sleep 0.7
done

echo "学習終了！"
echo "Count: $count"
