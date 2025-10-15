# LINE → Claude Code（スモールチーム）連携

スマホのLINEから、今動いているClaude Code（スモールチーム）に口語プロンプトで指示できるシステム

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
あなた: 今のプロジェクトの状態を教えて

Claude: 現在の状態を確認しました。
        ✅ システム正常
        変更なし、全てコミット済みです。
```

### 画像メッセージ

```
あなた: [スクリーンショットを送信]

Claude: 📷 画像を受信しました。
        Claude Codeに転送しています...

Claude: 🤖 Claude Code:

        このスクリーンショットはエラー画面ですね。
        TypeError: Cannot read property 'name' of undefined

        コードを確認して修正方法を提案します...
```

**画像で送れるもの:**
- エラー画面のスクリーンショット
- コード画面
- 手書きメモや図解
- UIデザイン案
- データベース設計図

---

## 📋 セットアップ手順

**📱 スマホ側の操作:** [LINE_SMARTPHONE_GUIDE.md](./LINE_SMARTPHONE_GUIDE.md)
**💻 PC側の詳細設定:** [LINE_ACCOUNT_SETUP.md](./LINE_ACCOUNT_SETUP.md)

### クイックスタート

1. **LINE Developers設定**
   - https://developers.line.biz/ にログイン
   - **あなたの個人LINEアカウント**でログイン
   - Messaging APIチャネル作成
   - トークンとシークレット取得

2. **環境変数設定**
   ```bash
   export LINE_CHANNEL_ACCESS_TOKEN="your_token"
   export LINE_CHANNEL_SECRET="your_secret"
   ```

3. **サーバー起動**
   ```bash
   # スモールチーム起動
   ./startup-integrated-system.ps1 3agents

   # LINE Bridge起動
   python line-to-claude-bridge.py

   # ngrok起動
   ngrok http 5000
   ```

4. **Webhook設定 & 友だち追加**
   - ngrokのURLをLINE DevelopersのWebhook URLに設定
   - QRコードでBotを友だち追加

**重要:**
- あなたの個人LINEアカウントは変更不要
- 新しく作る「LINE Bot」を友だち追加するだけ
- そのBotにメッセージを送ると、Claude Codeが応答します

---

## 🚀 動作原理

### メッセージフロー

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
├── SETUP.md                   ← 詳細セットアップガイド
├── README.md                  ← このファイル
└── images/                    ← 受信した画像の保存先

a2a_system/shared/
├── claude_inbox/              ← LINEからのメッセージ
└── claude_outbox/             ← Claude Codeからの応答
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
