# 📱 LINE Bridge 応答ポリシー改定

**Date**: 2025-10-19
**Status**: ✅ 実装完了
**Impact**: LINE Bridge のメッセージ返信ロジック改善

---

## 🎯 改修の背景

以前は、Claude Code がタスク処理をしている間、Bridge が無条件に60秒待ってタイムアウト応答を送信していました。

**問題点**:
- 不要な「処理結果」メッセージが自動で送信される
- ユーザーが複数のメッセージを受け取ることになる
- Claude Code がまだ処理中でも返信が来る

---

## ✅ 新しいポリシー

LINE Bridge は以下の場合**のみ** LINE にメッセージを送信します：

### 1️⃣ **受付確認**（常に送信）
```
メッセージ受信時
    ↓
「✅ 受付完了」をすぐに返信
```
- **タイミング**: メッセージ受信直後
- **内容**: 受付完了 + 依頼内容の確認
- **送信方法**: `reply_message` （即座）

### 2️⃣ **タスク完了報告**（Claude Code が作成時のみ）
```
Claude Code が Outbox に応答ファイルを作成
    ↓
Bridge が検出
    ↓
LINE にメッセージを送信
```
- **トリガー**: `response_line_*.json` が Outbox に作成された
- **内容**: Claude Code が response ファイルに記載した `text` フィールド
- **使用例**:
  ```json
  {
    "type": "LINE_RESPONSE",
    "status": "success",  // or "in_progress" or "error"
    "text": "✅ タスク完了！\n..."
  }
  ```

### 3️⃣ **進行中で停止**（Claude Code が中断報告時）
```
Claude Code が進行中だが次のステップ待機中
    ↓
Outbox に status="in_progress" の応答ファイルを作成
    ↓
Bridge が検出して LINE に送信
```
- **例**: 「GPT-5との壁打ち待機中」「ユーザー確認待ち」など
- **応答例**:
  ```json
  {
    "status": "in_progress",
    "text": "⏳ GPT-5との壁打ち待機中です。\n回答が届いたら実装を開始します。"
  }
  ```

### 4️⃣ **エラー発生**（Claude Code がエラー報告時）
```
Claude Code がエラーを検出
    ↓
Outbox に status="error" の応答ファイルを作成
    ↓
Bridge が検出して LINE に送信
```
- **応答例**:
  ```json
  {
    "status": "error",
    "text": "❌ エラーが発生しました。\n\n【詳細】\n..."
  }
  ```

### 5️⃣ **質問・確認**（Claude Code が質問時）
```
Claude Code がタスク内容に質問・確認事項がある
    ↓
Outbox に status="question" の応答ファイルを作成
    ↓
Bridge が検出して LINE に送信
```
- **トリガー**: タスク実行に際して、曖昧な部分や確認が必要な場合
- **応答例**:
  ```json
  {
    "status": "question",
    "text": "❓ 質問があります。\n\n【質問】\nこのタスクの 'スキル統合' について、以下の2つの実装方法が考えられます：\n1. 段階的実装（Phase 1-A, 1-B に分割）\n2. 完全統合実装（全コンポーネント一度に）\n\nどちらの方針を希望されますか？"
  }
  ```

---

## 🔄 応答ファイル検出の流れ

```
Bridge がテキストメッセージ受信
    ↓
「✅ 受付完了」を送信
    ↓
GitHub Issue を作成
    ↓
Claude Code ペイン(0.1)に /process-issue を送信
    ↓
Claude Code へのメッセージを Inbox に保存
    ↓
[バックグラウンド実行]
Bridge が Outbox をポーリング（2秒ごと）
    ├ response_line_*.json が見つかった？
    │  ├ YES → LINE に送信 → ファイル削除 → 終了
    │  └ NO  → 2秒待機
    └ タイムアウト（600秒）→ ログのみ（LINE には返信しない）
```

---

## 📊 タイムライン比較

### 以前（改修前）
```
時刻      イベント
00秒      ユーザーがLINEにメッセージ送信
00秒      受付確認を返信 ✅
01秒      GitHub Issue 作成
02秒      Claude Code ペイン実行
03秒      Claude Code 処理開始
          ...処理中...
60秒      タイムアウト → 自動で「処理結果」を返信 ❌
          (Claude Code はまだ処理中の可能性)
```

### 改修後（現在）
```
時刻      イベント
00秒      ユーザーがLINEにメッセージ送信
00秒      受付確認を返信 ✅
01秒      GitHub Issue 作成
02秒      Claude Code ペイン実行
03秒      Claude Code 処理開始
          ...処理中...
25秒      Claude Code が タスク完了 or エラー検出
          → response_line_*.json を Outbox に作成
25秒      Bridge が検出 → LINE に送信 ✅
          (不要な自動返信なし)
```

---

## 🔧 実装詳細

### テキストメッセージ処理（改修前後比較）

**改修前**:
```python
def handle_text_message(event):
    # 受付確認
    reply_message(..., "✅ 受付完了\n完了次第、結果をお送りします")

    # タスク処理
    message_id = send_to_claude(text, user_id)

    # バックグラウンド: 60秒待機 → タイムアウト応答送信 ❌
    response = wait_for_claude_response(message_id, timeout=60)
    push_message(..., f"🤖 処理結果:\n{response}")  # 常に送信
```

**改修後**:
```python
def handle_text_message(event):
    # 受付確認のみ
    reply_message(..., "✅ 受付完了\n処理を開始します。")

    # タスク処理
    message_id = send_to_claude(text, user_id)

    # バックグラウンド: Outbox をポーリング
    def detect_and_send_response():
        while time < timeout:
            if response_file exists:  # Claude Code が応答ファイルを作成
                push_message(...)      # その時だけ LINE に送信
                return
            time.sleep(2)
        # タイムアウト時は LINE に送信しない ✅
```

---

## 📋 Claude Code 実装要件

Claude Code 側で以下のいずれかの場合に `response_line_*.json` を Outbox に作成する必要があります：

### パターン1: タスク完了
```json
{
  "type": "LINE_RESPONSE",
  "message_id": "line_U...",
  "status": "success",
  "text": "✅ タスク完了！\n\n【実行結果】\n..."
}
```

### パターン2: 進行中で停止（待機中）
```json
{
  "type": "LINE_RESPONSE",
  "message_id": "line_U...",
  "status": "in_progress",
  "text": "⏳ 進行中\n\n【現在の状態】\n次のステップ: GPT-5との壁打ち待機中"
}
```

### パターン3: エラー発生
```json
{
  "type": "LINE_RESPONSE",
  "message_id": "line_U...",
  "status": "error",
  "text": "❌ エラーが発生しました。\n\n【詳細】\nGitHub APIエラー: 401 Unauthorized"
}
```

---

## ✨ メリット

| 項目 | 効果 |
|------|------|
| **ユーザー体験** | 不要なメッセージが減る。返信は必要な時だけ |
| **透明性** | 「進行中」「エラー」など状態が明確 |
| **制御** | Claude Code が応答タイミングを完全制御 |
| **スケーラビリティ** | 処理時間が長くなってもタイムアウト制約なし |

---

## ⚙️ 動作パラメータ

| パラメータ | 値 | 説明 |
|-----------|-----|------|
| **ポーリング間隔** | 2秒 | Bridge が Outbox をチェックする間隔 |
| **タイムアウト** | 600秒 | 10分（長時間処理対応） |
| **タイムアウト動作** | ログのみ | 応答ファイルなし → LINE に返信しない |

---

## 🚀 次のステップ

### Claude Code 側の実装
1. タスク完了時に `response_line_*.json` を作成
2. エラー時に `response_line_*.json` を作成（status: error）
3. 進行中だが停止時に `response_line_*.json` を作成（status: in_progress）

**例**: Issue #20 のタスク（GPT-5との壁打ち待機中）
```json
{
  "type": "LINE_RESPONSE",
  "message_id": "line_U9048b21670f64b16508f309a73269051_20251019_123929",
  "status": "in_progress",
  "text": "⏳ Issue #20 処理状況レポート\n\n...詳細...\n\n【待機中】\n⏳ GPT-5 からの回答待機中"
}
```

---

## ✅ 検証チェックリスト

- [x] テキストメッセージの受付確認のみ送信確認
- [x] 画像メッセージの受付確認のみ送信確認
- [x] Outbox ポーリング間隔を2秒に設定
- [x] タイムアウト時にログのみ（LINE送信なし）
- [x] 応答ファイル削除機能を実装
- [ ] Claude Code 側で response_line_*.json 作成実装（Next）
- [ ] エンドツーエンドテスト（Next）

---

**Status**: ✅ Bridge 側改修完了
**Next**: Claude Code 側で応答ファイル作成ロジックの実装

