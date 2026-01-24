#!/bin/bash

# 色見本を表示
sample_color() {
    local dim1 dim2 dim3 dim1_name dim2_name dim3_name
    
    # 次元の設定
    case "$1" in
        r) dim1_name="Red" ;;
        g) dim1_name="Green" ;;
        b) dim1_name="Blue" ;;
    esac
    
    case "$2" in
        r) dim2_name="Red" ;;
        g) dim2_name="Green" ;;
        b) dim2_name="Blue" ;;
    esac
    
    case "$3" in
        r) dim3_name="Red" ;;
        g) dim3_name="Green" ;;
        b) dim3_name="Blue" ;;
    esac
    
    echo "=== Color Gradient Preview ==="
    echo "$dim1_name varies horizontally, $dim2_name vertically, $dim3_name between blocks"
    echo
    
    # ヘッダー
    printf "%-12s" " "
    for dim1 in 0 {31..255..32}; do
        printf "%-8s" "$dim1"
    done
    echo
    
    # カラーグリッド
    local block=0
    for dim3 in 0 128 255; do
        echo "--- Block: $dim3_name=$dim3 ---"
        for dim2 in 0 {31..255..32}; do
            printf "%-8s" "$dim2"
            for dim1 in 0 {31..255..32}; do
                # RGB値を計算
                local r=0 g=0 b=0
                case "$1" in r) r=$dim1 ;; g) g=$dim1 ;; b) b=$dim1 ;; esac
                case "$2" in r) r=$dim2 ;; g) g=$dim2 ;; b) b=$dim2 ;; esac
                case "$3" in r) r=$dim3 ;; g) g=$dim3 ;; b) b=$dim3 ;; esac
                
                printf "\033[48;2;%d;%d;%dm  \033[0m" $r $g $b
            done
            echo
        done
        echo
    done
}

# 色情報を表示
show_color() {
    local r=$1 g=$2 b=$3
    local hex=$(printf "#%02x%02x%02x" $r $g $b)
    
    echo "=== Color Information ==="
    
    # カラープレビュー（大きめ）
    echo "Preview:"
    printf "  \033[48;2;%d;%d;%dm        \033[0m\n" $r $g $b
    printf "  \033[48;2;%d;%d;%d;38;2;255;255;255m  TEXT  \033[0m\n" $r $g $b
    echo
    
    # 色情報
    echo "Values:"
    echo "  RGB:    ($r, $g, $b)"
    echo "  HEX:    $hex"
    echo "  ANSI:   \\033[38;2;${r};${g};${b}m"
    echo
    
    # 類似色
    echo "Similar colors:"
    printf "  Darker:  \033[48;2;%d;%d;%dm  \033[0m " $((r*2/3)) $((g*2/3)) $((b*2/3))
    printf "\033[48;2;%d;%d;%dm  \033[0m " $((r/2)) $((g/2)) $((b/2))
    printf "\033[48;2;%d;%d;%dm  \033[0m\n" $((r/3)) $((g/3)) $((b/3))
    
    printf "  Lighter: \033[48;2;%d;%d;%dm  \033[0m " $((r + (255-r)/3)) $((g + (255-g)/3)) $((b + (255-b)/3))
    printf "\033[48;2;%d;%d;%dm  \033[0m " $((r + (255-r)/2)) $((g + (255-g)/2)) $((b + (255-b)/2))
    printf "\033[48;2;%d;%d;%dm  \033[0m\n" $((r + (255-r)*2/3)) $((g + (255-g)*2/3)) $((b + (255-b)*2/3))
    echo
}

# HSL計算（簡易版）
calculate_hsl() {
    local r=$1 g=$2 b=$3
    local max=$((r > g ? (r > b ? r : b) : (g > b ? g : b)))
    local min=$((r < g ? (r < b ? r : b) : (g < b ? g : b)))
    local l=$(((max + min) / 2))
    local s=0
    local h=0
    
    if [ $max -ne $min ]; then
        local delta=$((max - min))
        s=$((delta * 100 / (l > 127 ? (510 - max - min) : (max + min))))
        
        case $max in
            $r) h=$(((g - b) * 60 / delta)) ;;
            $g) h=$((120 + (b - r) * 60 / delta)) ;;
            $b) h=$((240 + (r - g) * 60 / delta)) ;;
        esac
        
        if [ $h -lt 0 ]; then
            h=$((h + 360))
        fi
    fi
    
    echo "  HSL:    (${h}°, ${s}%, ${l}%)"
}

# メインループ
main() {
    echo "=== CUI Color Picker ==="
    echo "Commands:"
    echo "  q              - Quit"
    echo "  s              - Show color samples"
    echo "  r g b (0-255)  - Set color"
    echo "  random         - Random color"
    echo "  grayscale      - Grayscale ramp"
    echo "  help           - Show this help"
    echo
    
    while true; do
        echo -n "> "
        read -r cmd arg1 arg2 arg3
        
        case "$cmd" in
            q|quit|exit)
                echo "Goodbye!"
                break
                ;;
                
            s|sample)
                sample_color r g b
                continue
                ;;
                
            random)
                local r=$((RANDOM % 256))
                local g=$((RANDOM % 256))
                local b=$((RANDOM % 256))
                show_color $r $g $b
                continue
                ;;
                
            grayscale)
                echo "Grayscale ramp:"
                for i in {0..255..16}; do
                    printf "\033[48;2;%d;%d;%dm  \033[0m" $i $i $i
                done
                echo -e "\n"
                continue
                ;;
                
            help)
                echo "Commands: q, s, random, grayscale, help, or enter RGB values"
                continue
                ;;
        esac
        
        # RGB値として解釈を試みる
        if [[ "$cmd" =~ ^[0-9]+$ ]] && [[ "$arg1" =~ ^[0-9]+$ ]] && [[ "$arg2" =~ ^[0-9]+$ ]]; then
            local r=$cmd g=$arg1 b=$arg2
            
            # 範囲チェック
            if [ $r -lt 0 ] || [ $r -gt 255 ] || [ $g -lt 0 ] || [ $g -gt 255 ] || [ $b -lt 0 ] || [ $b -gt 255 ]; then
                echo "Error: Values must be between 0-255"
                continue
            fi
            
            show_color $r $g $b
            calculate_hsl $r $g $b
        else
            echo "Unknown command or invalid RGB values"
            echo "Try: 'help' for commands, or enter three numbers (0-255)"
        fi
    done
}

# 実行
main
