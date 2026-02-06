#!/bin/bash
# improve_translation.sh
# Improve translations using Gemini API with JSON Schema

# settings
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && git rev-parse --show-toplevel)"
INPUT_CSV="$PROJECT_ROOT/card/oxford_phrase_en_ja.csv"
OUTPUT_JSON="$PROJECT_ROOT/card/improved_translations.json"
LOG_FILE="$PROJECT_ROOT/data/improvement_translations.log"
BATCH_SIZE=8  # バッチサイズを設定

# for testing
cat "$INPUT_CSV" | shuf -n 2 > "/tmp/test.csv"
INPUT_CSV="$PROJECT_ROOT/test/oxford_phrase_en_ja.csv"
OUTPUT_JSON="$PROJECT_ROOT/test/improved_translations.json"
LOG_FILE="$PROJECT_ROOT/test/improvement_translations.log"
rm -f "$OUTPUT_JSON" "$LOG_FILE" "$INPUT_CSV"
cat /tmp/test.csv > "$INPUT_CSV"

source "$HOME/.env"

# 出力ファイルの初期化
echo '[' > "$OUTPUT_JSON"
first=true
current_batch=()
batch_count=0
total_processed=0

echo "Starting batch processing with batch size: $BATCH_SIZE" >> "$LOG_FILE"

# 一時ファイルの作成
temp_output=$(mktemp)

# CSVを読み込みながらバッチ処理
process_batch() {
    local batch_items=""
    local batch_size=$1
    shift
    local batch_items_array=("$@")
    
    # バッチアイテムを結合
    for ((i=0; i<batch_size; i++)); do
        if [ -n "$batch_items" ]; then
            batch_items="$batch_items\n"
        fi
        batch_items="${batch_items}${batch_items_array[$i]}"
    done
    
    echo "Processing batch $((batch_count + 1)) with $batch_size items..." >> "$LOG_FILE"
    
    response=$(curl -s -X POST \
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent" \
        -H "x-goog-api-key: $GEMINI_API_KEY" \
        -H 'Content-Type: application/json' \
        -d "$(cat <<EOF
{
  "contents": [{
    "parts": [{
      "text": "Improve Japanese translations if unnatural. Keep 誰か for 'sb', 何か for 'sth'. Only improve if:\n1. Literal translation sounds awkward\n2. English idiom needs Japanese equivalent\n3. Katakana loanword sounds unnatural\n\nIf translation is already natural, skip it.\n\n$batch_items"
    }]
  }],
  "generationConfig": {
    "responseMimeType": "application/json",
    "responseJsonSchema": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "english": {"type": "string"},
          "original": {"type": "string"},
          "improved": {"type": "string"}
        },
        "required": ["english", "original", "improved"]
      }
    }
  }
}
EOF
)")
    
    # APIレスポンスの確認
    if [ $? -ne 0 ]; then
        echo "Error: API call failed for batch $((batch_count + 1))" >> "$LOG_FILE"
        return 1
    fi
    
    # 結果の抽出
    result=$(echo "$response" | jq -r '.candidates[0].content.parts[0].text // empty' 2>/dev/null)
    
    if [ -n "$result" ] && [ "$result" != "null" ]; then
        # 一時ファイルに結果を追加
        echo "$result" | jq -c '.[]' | while read -r item; do
            if [ "$first" = false ]; then
                echo "," >> "$temp_output"
            fi
            echo "$item" >> "$temp_output"
            first=false
        done
        
        total_processed=$((total_processed + batch_size))
        echo "Batch $((batch_count + 1)) completed: processed $batch_size items (total: $total_processed)" >> "$LOG_FILE"
    else
        echo "Warning: No valid response for batch $((batch_count + 1))" >> "$LOG_FILE"
        # 元のアイテムをそのまま出力（改善されていないバージョン）
        for ((i=0; i<batch_size; i++)); do
            # バッチアイテムから元のデータを復元
            item="${batch_items_array[$i]}"
            eng=$(echo "$item" | cut -d '|' -f 1 | sed 's/English: //')
            jap=$(echo "$item" | cut -d '|' -f 2 | sed 's/Current: //')
            
            # JSON形式で出力
            json_item="{\"english\":\"$eng\",\"original\":\"$jap\",\"improved\":\"$jap\"}"
            
            if [ "$first" = false ]; then
                echo "," >> "$temp_output"
            fi
            echo "$json_item" >> "$temp_output"
            first=false
        done
    fi
    
    batch_count=$((batch_count + 1))
    return 0
}

# メイン処理ループ
while IFS= read -r line; do
    # CSV行の解析
    IFS=',' read -r eng jap level <<< "$line"
    eng=$(echo "$eng" | tr -d '"')
    jap=$(echo "$jap" | tr -d '"')
    level=$(echo "$level" | tr -d '"')
    
    # バッチにアイテムを追加
    current_batch+=("English: $eng | Current: $jap")
    
    # バッチサイズに達したら処理
    if [ ${#current_batch[@]} -eq $BATCH_SIZE ]; then
        process_batch $BATCH_SIZE "${current_batch[@]}"
        current_batch=()  # バッチをクリア
    fi

    sleep 0.5
done < "$INPUT_CSV"

# 残りのアイテムを処理
if [ ${#current_batch[@]} -gt 0 ]; then
    process_batch ${#current_batch[@]} "${current_batch[@]}"
fi

# 一時ファイルの内容を出力ファイルに追加
cat "$temp_output" >> "$OUTPUT_JSON"
rm -f "$temp_output"

echo ']' >> "$OUTPUT_JSON"
echo "Processing completed: $total_processed items processed in $batch_count batches" >> "$LOG_FILE"
echo "Saved to: $OUTPUT_JSON" >> "$LOG_FILE"
echo "Processing completed. Total items: $total_processed, Batches: $batch_count"
echo "Saved to: $OUTPUT_JSON"
