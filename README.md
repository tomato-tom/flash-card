---
title:  Flash Card
update: 2026-02-11
status: wip
tags:
- english-learning
- anki
genai:
- deepseek web
- gemini web/API/CLI
---
# CLI Flash Card

bash と `jq` で動作するシンプルな英単語フラッシュカード

## 構成

* `flash_card.sh`
* `flash_card_stats.sh`: 学習統計表示
* `card/contents.json`: カードデータ（JSON）
* `data/sessions/`: セッションログ

## 依存ツール

* `jq`: JSONパース
* `bc`: 数値計算
* `gtts-cli`: 読み上げ（オプション）
* `ffplay`: 音声再生（オプション）

## 使い方

1. `card/contents.json` に単語を登録

2. スクリプトを実行：
```bash
./flash_card.sh
```

3. 学習結果の確認：
```bash
./flash_card_stats.sh
```


## 設計メモ

* **出題ロジック**: `priority`（重み）に基づいたランダム抽出。
* **自己評価**: `e` (Easy: x0.7), `m` (Medium: x1.2), `h` (Hard: x1.5) で出現頻度が変動。
* **ログ**: セッションごとに `data/sessions/` へ JSON を保存し、マスターの `priority` を更新。

## その他

タイピングゲーム
typing.sh
typing_stats.sh

