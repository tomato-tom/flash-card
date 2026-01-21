#!/bin/bash
# 英単語フラッシュカード

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

tput civis
echo "    === Flash Card ==="
easy=0
medium=0
hard=0

source frame.sh
create_frame 1 4 8 35
tput sc

# ランダムに単語を表示
while true; do
    #tput rc
    #tput ed

    # ランダムに単語を選択
    WORD=$(shuf -n 1 "$VOCAB_FILE")
    
    if [ -z "$WORD" ]; then
        break
    fi
    
    english=$(echo "$WORD" | cut -d',' -f1)
    english_line=3
    english_color="\033[38;5;87m"

    write_at $english_line center "$english" "$english_color"
    tput rc
    tput ed

    echo "Do you know？"
    echo "e - Eesy"
    echo "m - Medium"
    echo "h - Hard"
    echo "q - Quit"
    
    read -n 1 input
    if [ "$input" = "q" ]; then
        echo
        break
    elif [ "$input" = "e" ]; then
        ((easy ++))
    elif [ "$input" = "m" ]; then
        ((medium ++))
    elif [ "$input" = "h" ]; then
        ((hard ++))
    else
        ((easy ++))
    fi
    
    japanese=$(echo "$WORD" | cut -d',' -f2)
    japanese_line=6
    japanese_color="\033[0;32m"
    
    write_at $japanese_line center "$japanese" "$japanese_color"

    sleep 0.8

    # 文字をスペースで上書きでクリア
    count="$(echo $english | wc -c)"
    printf -v spaces "%*s" $count ""
    write_at $english_line center "$spaces"

    count="$(echo $japanese | wc -c)"
    printf -v spaces "%*s" $count ""
    write_at $japanese_line center "$spaces"
done

tput rc
tput ed

total=$((easy + medium + hard))
echo "Total: $total"
echo "Easy: $easy"
echo "Medium: $medium"
echo "Hard: $hard"

tput cnorm
