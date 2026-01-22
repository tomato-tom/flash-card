# カードセット作成プロンプト

`man` ページから実用的なカードセットを生成するための、AI用プロンプトを提案します。

このプロンプトのコツは、AIに**「エンジニアとしての視点」**を持たせ、単なる直訳ではなく**「そのコマンドの文脈での意味」**を抽出させることです。


### 🤖 manページ解析用プロンプト

ChatGPTやClaude、Ollamaなどに以下の文章を貼り付けて、その後に `man [コマンド]` のテキストを流し込んでください。

---
**Role:** > あなたはベテランのLinuxシステム管理者兼、英語講師です。
**Task:** > 提供するコマンドの `man` ページから、学習価値の高い英単語やフレーズを抽出し、指定のJSON形式で出力してください。
**Selection Criteria:**
1. コマンドの動作（再帰、排他、同期など）を説明する重要な技術用語。
2. オプションの説明文でよく使われる定型的なフレーズ。
3. 日本人が間違いやすい、あるいはIT現場で特有の意味を持つ語彙。


**Output Format (JSON Only):**
以下の構造を持つJSON配列のみを出力してください。`priority` は 1.0, `type` は word または phrase、`created` は 2026-01-22 としてください。
```json
[
  {
    "card-id": "gen-001",
    "english": "term or phrase",
    "japanese": "意味（文脈に即したもの）",
    "priority": 1.0,
    "type": "word",
    "tags": ["tech", "command_name"],
    "created": "2026-01-22",
    "last_reviewed": null,
    "review_count": 0
  }
]

```


**Target Text:**
(ここに man ページの内容を貼り付け)

---

### 💡 効率よくやるための小技

`man` ページは長すぎる場合があるので、以下のように特定のセクションだけを抽出して AI に渡すと精度が上がります。

```bash
# DESCRIPTION セクションだけを抽出
man ls | col -b | sed -n '/DESCRIPTION/,/^[A-Z]/p'

```

