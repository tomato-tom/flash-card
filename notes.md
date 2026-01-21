# メモ

フラッシュカード
英語表示
何かキー押すと日本語表示
0.7秒後に次のフレーズ

自己評価
Easy(e) - わかる
Medium(m) - まあまあ
Hard(h) - わからない

単語・フレーズを自己評価し、e/m/hのキーを押す、それをデータ保存
自己評価の理解度に応じて出題頻度を調整
Easy - 頻度下げ
Medium(m) - 頻度ちょい下げ、忘却曲線による
Hard(h) - 頻度上げ

game data
```
{
  "description" : "Flash card game data",
  "games": [
    {
      "timestamp": "2026-01-18 01:34:09",
      "text": "This is an apple",
      "self_evaluation": "medium",
      "priority": 67
      "time_taken": 1.23
    },
```

text
- word
- phrase
```
{
  "description": "Flash card set",
  "version": "1.0",
  "created": "2026-01-18",
  "content": [
    {
      "id": "p-001",
      "text": "This is an apple",
      "translation": "これはりんごです",
      "pronunciation": "ðɪs ɪz ən ˈæpl",
      "priority": 67,
      "type": "phrase",
      "category": "food",
      "tags": ["basic", "fruit"],
      "created": "2026-01-18",
      "last_reviewed": "2026-01-18",
      "review_count": 3,
      "difficulty_history": ["h", "m", "e"]
    }
  ]
}
```

学習統計
stats.json
```
{
  "description": "Learning statistics",
  "total_sessions": 100,
  "total_reviews": 450,
  "current_streak": 7,
  "evaluation_distribution": {
    "easy": 34,
    "medium": 22,
    "hard": 45
  },
  "accuracy_rate": 65.4,
  "today": {
    "date": "2026-01-18",
    "reviews": 25,
    "new_cards": 5,
    "time_spent": "00:15:30"
  },
  "weekly_progress": [
    {"date": "2026-01-11", "reviews": 30, "accuracy": 68.2},
    {"date": "2026-01-12", "reviews": 28, "accuracy": 70.1}
  ]
}
```
