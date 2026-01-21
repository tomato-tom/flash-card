# tputの使い方

`tput` は端末の機能を制御したり、端末の情報を取得するためのコマンドです。
主にシェルスクリプトで端末の色付け、カーソル制御、画面クリアなどに使われます。

## 主な使い方

### 1. 色の設定（最も一般的な使い方）
```bash
# 色の設定
tput setaf 色番号   # 文字色を設定 (0-7)
tput setab 色番号   # 背景色を設定 (0-7)

# 例：
tput setaf 2        # 緑色の文字
tput setab 4        # 青色の背景
tput sgr0           # 色設定をリセット
```

色番号の対応表：
- 0: 黒
- 1: 赤
- 2: 緑
- 3: 黄
- 4: 青
- 5: マゼンタ
- 6: シアン
- 7: 白

### 2. テキスト属性の設定
```bash
tput bold           # 太字
tput dim            # 薄く表示
tput rev            # 反転表示
tput smul           # 下線開始
tput rmul           # 下線終了
tput blink          # 点滅
```

### 3. 画面制御
```bash
tput clear          # 画面クリア
tput ed             # カーソル位置以降をクリア
tput cup Y X        # カーソルをY行X列に移動 (例: tput cup 5 10)
tput sc             # カーソル位置を保存
tput rc             # 保存したカーソル位置に戻る
tput civis          # カーソルを非表示
tput cnorm          # カーソルを表示
```

### tputにない機能

おそらくtput標準では無い機能で、tputと合わせて使いそうな
```
# 現在位置取得
get_pos() {
    IFS=';' read -sdR -p $'\E[6n' row col
    echo "${row#*[} ${col}"
}
read row col < <(get_pos)
echo "Row: $row, Col: $col"

# 相対移動
cursor_up() { printf '\033[%sA' "${1:-1}"; }
cursor_down() { printf '\033[%sB' "${1:-1}"; }
cursor_right() { printf '\033[%sC' "${1:-1"; }
cursor_left() { printf '\033[%sD' "${1:-1}"; }

# 使用例
read row col < <(get_pos)

## 可能ならばカーソルを上に移動
[ row -eq 1 ] || cursor_up

## 可能な範囲でカーソルを上に移動
rows=3
[ $row -ge $rows ] && cursor_up $rows || tput cup 1 $col
```


### 4. 端末情報の取得
```bash
tput cols             # 端末の幅（列数）を取得
tput lines            # 端末の高さ（行数）を取得
tput longname         # 端末の長い名前を表示
tput -T $TERM colors  # 色数を確認

