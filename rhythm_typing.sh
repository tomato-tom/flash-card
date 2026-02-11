#!/bin/bash
# リズム・タイピング
# まともに動かないけど、流れはこんな感じに

# ==============================
# ゲーム設定（トップに集約）
# ==============================
TARGET_POSITION=40
SPEED=0.1
GAME_DURATION=30
FIXED_ROW=10
ADD_INTERVAL=1.0
RENDER_INTERVAL=0.05
KEY_CHECK_INTERVAL=0.01
ANIMATION_CHECK_INTERVAL=0.05

# ==============================
# グローバル変数（全体的に参照）
# ==============================
SCORE=0
MISSED=0
GAME_START_TIME=0
TERMINAL_WIDTH=0
TERMINAL_HEIGHT=0
FIFO_PATH=""

# 文字データの管理
declare -a letters_x     # 文字のX座標
declare -a letters_active # 文字がアクティブかどうか (0=非アクティブ, 1=アクティブ)
NEXT_ID=0

# ==============================
# 関数定義
# ==============================

# 終了時のクリーンアップ
cleanup() {
    tput cnorm
    stty echo
    rm -f "$FIFO_PATH"
    clear
    echo "ゲーム終了！"
    echo "スコア: $SCORE"
    echo "ミス: $MISSED"
    exit 0
}

# キー入力処理用の関数
key_input_handler() {
    local key
    while true; do
        # キー入力を読み取り、FIFOに書き込む
        if read -rsn1 -t $KEY_CHECK_INTERVAL key; then
            echo "$key" > "$FIFO_PATH" &
        fi
        sleep 0.001
    done
}

# アニメーション処理用の関数
animation_handler() {
    local current_time
    local elapsed
    local last_add_time=$GAME_START_TIME
    
    while true; do
        current_time=$(date +%s)
        elapsed=$((current_time - GAME_START_TIME))
        
        # ゲーム時間チェック
        if [ $elapsed -ge $GAME_DURATION ]; then
            echo "GAME_OVER" > "$FIFO_PATH" &
            break
        fi
        
        # 定期的に新しい文字を追加
        if [ $((current_time - last_add_time)) -ge $ADD_INTERVAL ]; then
            # 新しい文字のIDを生成
            letters_x[$NEXT_ID]=$TERMINAL_WIDTH
            letters_active[$NEXT_ID]=1
            NEXT_ID=$((NEXT_ID + 1))
            
            last_add_time=$current_time
        fi
        
        # 文字を移動
        for ((id=0; id<NEXT_ID; id++)); do
            if [ "${letters_active[$id]:-0}" -eq 1 ]; then
                # X座標を更新
                letters_x[$id]=$((letters_x[$id] - 1))
                
                # 画面外に出たらミスとしてマーク
                if [ ${letters_x[$id]} -le 0 ]; then
                    if [ "${letters_active[$id]}" -eq 1 ]; then
                        letters_active[$id]=0
                        echo "MISS" > "$FIFO_PATH" &
                    fi
                fi
            fi
        done
        
        # アニメーション速度
        sleep $SPEED
    done
}

# 画面描画用の関数
render_screen() {
    # 画面をクリア
    clear
    
    # 残り時間計算
    local current_time=$(date +%s)
    local remaining_time=$((GAME_DURATION - (current_time - GAME_START_TIME)))
    if [ $remaining_time -lt 0 ]; then
        remaining_time=0
    fi
    
    # ヘッダー表示
    echo "┌────────────────────────────────────────────────────────────┐"
    echo "│ リズムタイピングゲーム（シンプル版）                           │"
    printf "│ スコア: %-4d  ミス: %-4d  残り時間: %3d秒                 │\n" $SCORE $MISSED $remaining_time
    echo "└────────────────────────────────────────────────────────────┘"
    echo ""
    echo "  文字 'a' が右から流れてきます。"
    echo "  文字が中央の線にきたら 'a' キーを押してください。"
    echo ""
    
    # ターゲットラインを表示
    for ((i=0; i<TARGET_POSITION-3; i++)); do
        echo -n " "
    done
    echo "│目標│"
    echo ""
    
    # 文字を表示する行（固定行）までの空行
    for ((i=0; i<FIXED_ROW-8; i++)); do
        echo ""
    done
    
    # 文字の行を表示
    echo -n " "
    for ((i=1; i<=TERMINAL_WIDTH; i++)); do
        local char_to_show=" "
        
        # この位置に文字があるかチェック
        for ((id=0; id<NEXT_ID; id++)); do
            if [ "${letters_active[$id]:-0}" -eq 1 ] && [ "${letters_x[$id]}" -eq "$i" ]; then
                char_to_show="a"
                break
            fi
        done
        
        # ターゲット位置のマーカー
        if [ "$i" -eq "$TARGET_POSITION" ]; then
            if [ "$char_to_show" = " " ]; then
                echo -n "|"
            else
                # 文字とマーカーが重なる場合は文字を優先
                echo -n "a"
            fi
        else
            echo -n "$char_to_show"
        fi
    done
}

# キー入力処理
process_key_input() {
    local key_press="$1"
    
    # ゲーム終了チェック
    if [ "$key_press" = "GAME_OVER" ]; then
        return 1
    fi
    
    # ミス処理
    if [ "$key_press" = "MISS" ]; then
        MISSED=$((MISSED + 1))
        return 0
    fi
    
    # キー入力処理（'a'キーのみ）
    if [ "$key_press" = "a" ]; then
        local hit_id=-1
        local closest_distance=1000
        
        # 'a'キーが押されたとき、最もターゲットに近い文字を探す
        for ((id=0; id<NEXT_ID; id++)); do
            if [ "${letters_active[$id]:-0}" -eq 1 ]; then
                local x=${letters_x[$id]}
                local distance=$((x - TARGET_POSITION))
                
                # 絶対距離を計算
                if [ $distance -lt 0 ]; then
                    distance=$((-distance))
                fi
                
                # ターゲット付近（±3以内）にある文字を検出
                if [ $distance -le 3 ]; then
                    if [ $distance -lt $closest_distance ]; then
                        closest_distance=$distance
                        hit_id=$id
                    fi
                fi
            fi
        done
        
        # ヒットした文字を処理
        if [ $hit_id -ge 0 ]; then
            SCORE=$((SCORE + 10))
            letters_active[$hit_id]=0
        else
            # ターゲット付近に文字がないのにキーを押した
            SCORE=$((SCORE - 5))
        fi
    fi
    
    return 0
}

# ==============================
# メイン処理
# ==============================

# 初期化
trap cleanup EXIT INT TERM
tput civis
stty -echo
clear

# 端末サイズを取得
TERMINAL_WIDTH=$(tput cols)
TERMINAL_HEIGHT=$(tput lines)

# FIFOの設定
FIFO_PATH="/tmp/typing_game_fifo_$$"
mkfifo "$FIFO_PATH"

# ゲーム開始時間を設定
GAME_START_TIME=$(date +%s)

# キー入力ハンドラーをバックグラウンドで起動
key_input_handler &

# アニメーションハンドラーをバックグラウンドで起動
animation_handler &

# メインループ（描画と入力処理）
while true; do
    # 画面描画
    render_screen
    
    # FIFOからキー入力を読み取り（非ブロッキング）
    if read -t $ANIMATION_CHECK_INTERVAL key_press < "$FIFO_PATH"; then
        # キー入力処理
        if ! process_key_input "$key_press"; then
            break  # ゲーム終了
        fi
    fi
    
    # 描画間隔
    sleep $RENDER_INTERVAL
done

# 重複実行？
cleanup
