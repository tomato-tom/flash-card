#!/bin/bash
# test04_hit_detection.sh
# タイミング判定のテスト

TARGET_POSITION=40
SCORE=0

declare -a letters_x
declare -a letters_active
NEXT_ID=0

# テスト用に文字を配置
setup_test() {
    # ターゲットからの距離でテストケースを配置
    letters_x[0]=37  # 距離3（ヒット範囲内）
    letters_active[0]=1
    
    letters_x[1]=40  # 距離0（完璧）
    letters_active[1]=1
    
    letters_x[2]=43  # 距離3（ヒット範囲内）
    letters_active[2]=1
    
    letters_x[3]=50  # 距離10（範囲外）
    letters_active[3]=1
    
    letters_x[4]=30  # 距離10（範囲外）
    letters_active[4]=1
    
    NEXT_ID=5
}

# 判定処理
check_hit() {
    local hit_id=-1
    local closest_distance=1000
    
    for ((id=0; id<NEXT_ID; id++)); do
        if [ "${letters_active[$id]:-0}" -eq 1 ]; then
            local x=${letters_x[$id]}
            local distance=$((x - TARGET_POSITION))
            
            # 絶対値
            if [ $distance -lt 0 ]; then
                distance=$((-distance))
            fi
            
            echo "  文字[$id] x=$x, 距離=$distance"
            
            # ±3以内
            if [ $distance -le 3 ]; then
                if [ $distance -lt $closest_distance ]; then
                    closest_distance=$distance
                    hit_id=$id
                fi
            fi
        fi
    done
    
    if [ $hit_id -ge 0 ]; then
        echo "→ ヒット! ID=$hit_id, 距離=$closest_distance"
        SCORE=$((SCORE + 10))
        letters_active[$hit_id]=0
        return 0
    else
        echo "→ ミス（範囲内に文字なし）"
        SCORE=$((SCORE - 5))
        return 1
    fi
}

echo "=== タイミング判定テスト ==="
echo "ターゲット位置: $TARGET_POSITION"
echo "判定範囲: ±3"
echo ""

setup_test

echo "初期配置:"
for ((id=0; id<NEXT_ID; id++)); do
    if [ "${letters_active[$id]:-0}" -eq 1 ]; then
        local dist=$((letters_x[$id] - TARGET_POSITION))
        if [ $dist -lt 0 ]; then
            dist=$((-dist))
        fi
        echo "  文字[$id]: x=${letters_x[$id]} (距離=$dist)"
    fi
done
echo ""

echo "--- テスト1: 最初の判定 ---"
check_hit
echo "スコア: $SCORE"
echo ""

echo "--- テスト2: 2回目の判定 ---"
check_hit
echo "スコア: $SCORE"
echo ""

echo "--- テスト3: 3回目の判定 ---"
check_hit
echo "スコア: $SCORE"
echo ""

echo "--- テスト4: 範囲外のみの判定 ---"
check_hit
echo "スコア: $SCORE"
echo ""

echo "最終スコア: $SCORE"
