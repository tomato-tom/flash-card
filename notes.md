# メモ

`view_mermaid.html`
全画面表示で図の上部が見えないときがある

- flash card
    - 難易度モード
        - easy
        - medium
        - hard
    - カードセット作成
- typeng game
    - キーロガー
    - 難易度を統計から計算、目安
        - easy 90%
        - medium 60%
        - hard 30%
- 両方
    - 統計リセット
    - ユーザー
    - 自動プレイ - 実際にUI動かす
    - シミュレーション - データのみ突っ込む、長期データ生成

done
- typeng game セッションごとのロギング


## ブラウザのセキュリティ制限解除

Firefoxでfile://プロトコルのセキュリティ制限を解除する方法：

1. **アドレスバーに以下を入力**：
```
about:config
```

2. **警告を承諾**して進む

3. **以下の設定を検索して変更**：

```
検索: privacy.file_unique_origin
```

- `privacy.file_unique_origin` を **false** に変更（ダブルクリックで切り替え）

4. **必要に応じて以下の設定も変更**（CORS関連）：

```
検索: security.fileuri.strict_origin_policy
```

- `security.fileuri.strict_origin_policy` を **false** に変更


**注意**: 
- `privacy.file_unique_origin = false` にするとfile://からのfetchが可能になります
- セキュリティリスクを理解した上で設定してください

これでfile://プロトコルでもfetchが動くはずです。
