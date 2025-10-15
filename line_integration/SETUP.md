# LINE → Claude Code（スモールチーム）連携

スマホのLINEから、今動いているClaude Code（スモールチーム）に口語プロンプトで指示

---

## 🎯 システム構成

```
┌─────────────┐
│   スマホ     │
│   (LINE)    │
└──────┬──────┘
       │ 「バックアップしておいて」
       ↓
┌──────────────────────┐
│ LINE Webhook Bridge  │ ← ngrok経由
│ (Python Flask)       │
└──────┬───────────────┘
       │ a2a_system経由で転送
       ↓
┌──────────────────────┐
│ Claude Code          │
│ (スモールチーム)      │
│ - Worker3 (メイン)   │
│ - Worker2 (サブ)     │
│ - Manager            │
└──────┬───────────────┘
       │ タスク実行
       ↓
┌──────────────────────┐
│ プロジェクト          │
│ (claudecode-wind)    │
└──────┬───────────────┘
       │ 実行結果
       ↓
┌──────────────────────┐
│ LINE通知             │
│ 「✅ 完了しました」   │
└──────────────────────┘
```

---

## 📋 セットアップ手順

**詳細な手順は [LINE_ACCOUNT_SETUP.md](./LINE_ACCOUNT_SETUP.md) を参照してください**

以下は簡易版です:

### 1. LINE Developers設定

1. https://developers.line.biz/ にアクセス
2. **あなたの個人LINEアカウント**でログイン
3. プロバイダー作成 → チャネル作成（Messaging API）
4. チャネルアクセストークン発行
5. チャネルシークレット取得

### 2. 環境変数設定

```bash
# ~/.bashrc に追加
export LINE_CHANNEL_ACCESS_TOKEN="your_token_here"
export LINE_CHANNEL_SECRET="your_secret_here"

# 反映
source ~/.bashrc
```

### 3. 依存パッケージインストール

```bash
pip install flask line-bot-sdk
```

### 4. スモールチーム起動（重要！）

```bash
cd /home/planj/claudecode-wind

# スモールチーム起動
./startup-integrated-system.ps1 3agents

# または
python a2a_system/workers/worker3.py &
```

**LINEから指示を受けるには、スモールチームが起動している必要があります。**

### 5. LINE Bridgeサーバー起動

```bash
cd /home/planj/claudecode-wind/line-integration

# サーバー起動
python line-to-claude-bridge.py
```

### 6. ngrokで公開

```bash
# 別ターミナルで
ngrok http 5000
```

### 7. Webhook URL設定

1. ngrokの `https://xxxx.ngrok.io` をコピー
2. LINE Developers → Webhook URL: `https://xxxx.ngrok.io/webhook`
3. 「Webhookの利用」をON

### 8. LINEで友だち追加

LINE Developers → QRコードをスマホで読み取り

---

## 🚀 使い方

### スマホからLINEでメッセージ送信

```
あなた: 今のプロジェクトの状態を教えて
```

### システムの動き

1. LINE Bridge が受信
2. `a2a_system/shared/claude_inbox/` にメッセージ保存
3. Claude Code（Worker3）が処理
4. `a2a_system/shared/claude_outbox/` に応答保存
5. LINE Bridge が応答を取得
6. LINEに返信

### 応答例

```
🤖 Claude Code:

現在の状態を確認しました。

✅ システム正常
変更なし、全てコミット済みです。
```

---

## 💬 使用例

### テキストメッセージ

```
あなた: バックアップしておいて

Claude: 了解しました。バックアップを実行します。
        ✅ バックアップ完了！
```

```
あなた: テスト走らせてくれる？

Claude: テストを実行します。
        ✅ テスト成功！全て通りました。
```

```
あなた: host-friendly-checkinのバックアップを作って

Claude: host-friendly-checkinリポジトリのバックアップを作成します。
        ✅ 完了しました。
```

### 画像メッセージ

```
あなた: [スクリーンショットを送信]

Claude: 📷 画像を受信しました。
        Claude Codeに転送しています...

Claude: 🤖 Claude Code:

        このスクリーンショットはエラー画面ですね。
        スタックトレースを確認すると...
```

**画像で送信できるもの:**
- スクリーンショット（エラー画面、コード画面）
- 手書きメモ・図解
- UIデザイン案
- データベース設計図

---

## 🔧 トラブルシューティング

### 1. 応答がない

```bash
# スモールチームが起動しているか確認
ps aux | grep worker3

# 起動していない場合
cd /home/planj/claudecode-wind
python a2a_system/workers/worker3.py &
```

### 2. タイムアウト

- デフォルト60秒でタイムアウト
- 長時間タスクの場合は `line-to-claude-bridge.py` の `timeout` を増やす

### 3. メッセージが届かない

```bash
# inboxにファイルがあるか確認
ls /home/planj/claudecode-wind/a2a_system/shared/claude_inbox/

# outboxに応答があるか確認
ls /home/planj/claudecode-wind/a2a_system/shared/claude_outbox/
```

---

## 📊 ファイル構成

```
line-integration/
├── line-to-claude-bridge.py  ← メインサーバー
├── SETUP.md                   ← このファイル
├── README.md                  ← 詳細ドキュメント
└── images/                    ← 受信した画像の保存先

a2a_system/shared/
├── claude_inbox/              ← LINEからのメッセージ
└── claude_outbox/             ← Claude Codeからの応答
```

---

## 🎨 カスタマイズ

### タイムアウト変更

```python
# line-to-claude-bridge.py
response = wait_for_claude_response(message_id, timeout=120)  # 120秒に変更
```

### メッセージフォーマット変更

```python
# line-to-claude-bridge.py の send_to_claude()
message = {
    "message_id": message_id,
    "from": "LINE_USER",
    "to": "CLAUDE_WORKER3",  # ← Worker2に変更可能
    # ...
}
```

---

## 💰 コスト

- **LINE Messaging API**: 無料（月1000通まで）
- **ngrok**: 無料プラン使用可能
- **OpenAI API**: 不要（Claude Code使用）

---

## 🔒 セキュリティ

### アクセス制限

特定ユーザーのみ許可：

```python
# line-to-claude-bridge.py に追加
ALLOWED_USERS = ['Uxxxxx', 'Uyyyyy']

if user_id not in ALLOWED_USERS:
    line_bot_api.reply_message(
        event.reply_token,
        TextSendMessage(text="許可されていません")
    )
    return
```

---

## ✅ まとめ

**システム:**
- LINE → LINE Bridge → a2a_system → Claude Code（スモールチーム）

**必要なもの:**
1. ✅ LINE Developer設定
2. ✅ スモールチーム起動
3. ✅ LINE Bridgeサーバー起動
4. ✅ ngrok起動

**メリット:**
- GPT-4不要（既存のClaude Code使用）
- 追加コストなし
- 口語プロンプトで指示可能
- スモールチームの全機能が使える

---

これで**今動いているClaude Code（スモールチーム）**をLINEから使えます！
