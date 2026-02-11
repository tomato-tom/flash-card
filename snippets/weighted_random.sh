#!/bin/bash
# 重み付けランダム（小数対応・最小実装）

weighted_random() {
    local -n _items=$1
    local -n _weights=$2

    # 固定スケールで一律整数化（100万倍 → 6桁の小数まで正確）
    local scale=1000000
    local -a int_weights
    local total=0

    for w in "${_weights[@]}"; do
        # awkで確実に整数化
        local int=$(awk -v w="$w" -v s="$scale" 'BEGIN {printf "%d", w * s}')
        (( int <= 0 )) && { echo "ERROR: weight must be > 0 ('$w')" >&2; return 1; }
        int_weights+=("$int")
        ((total += int))
    done

    # 30ビット乱数（約10億）→ スケール100万なら合計1000まで安全
    local rand=$(( (RANDOM << 15) ^ RANDOM ))
    ((rand %= total))

    # 累積和で選択
    local cum=0
    for i in "${!int_weights[@]}"; do
        ((cum += int_weights[i]))
        if ((rand < cum)); then
            echo "${_items[i]}"
            return 0
        fi
    done
    return 1
}

# ====================
# デモ
# ====================
items=("small" "medium" "large")
weights=(0.1 0.25 1.234)  # 桁数バラバラでもOK

declare -A results=([small]=0 [medium]=0 [large]=0)
trials=1000 # 10000とか桁増やすと時間かかる、1000が現実的な線

for ((i=0; i<trials; i++)); do
    result=$(weighted_random items weights)
    [[ -z "$result" ]] && continue
    ((results[$result]++))
done

echo "=== 抽選結果 ($trials 回) ==="
for item in "${items[@]}"; do
    printf "%-8s: %5d (%5.1f%%)\n" "$item" "${results[$item]}" "$(awk -v c="${results[$item]}" -v t="$trials" 'BEGIN {printf "%.1f", c/t*100}')"
done
