#!/bin/bash
# Oxford Phrase List を”en,ja”のリストに変換
# CSV保存

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && git rev-parse --show-toplevel)"
count=0

source_file="$PROJECT_ROOT/card/oxford_phrase.list"
target_file="$PROJECT_ROOT/card/oxford_phrase_en_ja.csv"
level=""

rm "$target_file"

cat "$source_file" | \
while read -r phrase; do
    echo -en "count: $count"

    # 空行やコメント行をスキップ
    if [[ -z "$phrase" || "$phrase" =~ ^# ]]; then
        continue
    fi

    # レベル情報を抽出
    if [[ "$phrase" =~ ^(A1|A2|B1|B2|C1) ]]; then
        level="${BASH_REMATCH[1]}"
        # レベル行自体はスキップまたは別途処理
        continue
    fi

    # 翻訳
    japanese="$(echo "$phrase" |
        sed -E 's/\bsb/somebody/g; s/\bsth/something/g' |
        trans -br :ja 2>/dev/null)"
        # transコマンドは直訳過ぎる場合がある、汎用AIがいい

    # CSVに書き込み
    echo "\"$phrase\",\"$japanese\",\"$level\"" >> "$target_file"

    ((count++))

    # API制限や負荷を考慮して遅延
    sleep 0.2
    echo -en "\r\033[K"
done

