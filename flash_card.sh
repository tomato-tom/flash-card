#!/bin/bash
# 英単語フラッシュカード

SPEECH=true  # 読み上げスイッチ true/false

# 単語帳ファイル（CSV形式: 英単語,日本語訳）
VOCAB_FILE="card/vocab.txt"
if [ ! -f "$VOCAB_FILE" ] || [ ! -s $VOCAB_FILE ]; then
    exit 1
fi
# 後ほどjsonにするか

# 英語読み上げ
speech() {
    local text="$@"
    local tmp="/tmp/say.mp3"
    local speed="${SPEED:-1.0}"    # 環境変数で速度指定

    gtts-cli "$text" --output "$tmp"
    ffplay -autoexit -nodisp -loglevel quiet -af "atempo=$speed" "$tmp"

    [ -f "$tmp" ] && rm "$tmp"
}


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
    $SPEECH && speech "$english" &

    write_at $english_line center "$english" "$english_color"
    tput rc
    tput ed

    echo "Any key to show answer"
    read -n 1 -t 3 -s input

    if [ "$input" = "q" ]; then
        echo
        break
    fi

    japanese=$(echo "$WORD" | cut -d',' -f2)
    japanese_line=6
    japanese_color="\033[0;32m"
    
    write_at $japanese_line center "$japanese" "$japanese_color"
    tput rc
    tput ed

    echo "e - Eesy"
    echo "m - Medium"
    echo "h - Hard"
    echo "q - Quit"
    
    read -n 1 -s input
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

    # 文字をスペースで上書きでクリア
    count="$(echo $english | wc -c)"
    printf -v spaces "%*s" $count ""
    write_at $english_line center "$spaces"

    count="$(echo $japanese | wc -c)"
    printf -v spaces "%*s" $count ""
    write_at $japanese_line center "$spaces"

    sleep 0.7
done

tput rc
tput ed

total=$((easy + medium + hard))
echo "Total: $total"
echo "Easy: $easy"
echo "Medium: $medium"
echo "Hard: $hard"

tput cnorm
