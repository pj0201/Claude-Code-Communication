# LINEアカウント連携セットアップガイド

あなたの個人LINEアカウントからClaude Codeに指示を送るための設定手順

---

## 🎯 全体像

```
[あなたのスマホLINE]
        ↓
[LINE Bot（友だち追加）]
        ↓
[Webhookサーバー（このPC）]
        ↓
[Claude Code（Worker3）]
```

**重要:** あなたの個人LINEアカウントは変更不要です。新しく「LINE Bot」を作成し、それを友だち追加するだけです。

---

## 📋 ステップ1: LINE Developersアカウント作成

### 1-1. LINE Developersにアクセス

ブラウザで以下にアクセス:
```
https://developers.line.biz/
```

### 1-2. ログイン

- 「ログイン」ボタンをクリック
- **あなたの個人LINEアカウント**でログイン
  - スマホのLINEアプリで認証
  - または、メールアドレス/パスワードでログイン

### 1-3. 利用規約に同意

- 「LINE Developers Agreement」に同意
- 開発者情報を入力（名前・メールアドレス）

---

## 📋 ステップ2: プロバイダー作成

### 2-1. プロバイダー作成

LINE Developersコンソールで:
1. 「作成」→「プロバイダーを作成」
2. プロバイダー名を入力:
   ```
   Claude Code Tasks
   ```
3. 「作成」ボタンをクリック

**プロバイダーとは:** アプリの提供者情報（あなた個人でOK）

---

## 📋 ステップ3: Messaging APIチャネル作成

### 3-1. チャネル作成

1. 作成したプロバイダーをクリック
2. 「チャネルを作成」→「Messaging API」を選択
3. 以下の情報を入力:

| 項目 | 入力内容 |
|------|---------|
| チャネル名 | `Claude Code Bot` |
| チャネル説明 | `スマホからClaude Codeにタスク指示` |
| 大業種 | `個人` |
| 小業種 | `個人（その他）` |
| メールアドレス | あなたのメールアドレス |

4. 利用規約に同意してチェック
5. 「作成」ボタンをクリック

---

## 📋 ステップ4: チャネル設定

### 4-1. チャネルアクセストークン発行

1. 作成したチャネルをクリック
2. 「Messaging API設定」タブを開く
3. 下にスクロールして「チャネルアクセストークン（長期）」を見つける
4. 「発行」ボタンをクリック
5. トークンが表示される（後で使用）

**重要:** このトークンは他人に見せないでください

### 4-2. チャネルシークレット取得

1. 「チャネル基本設定」タブを開く
2. 「チャネルシークレット」をコピー（後で使用）

### 4-3. Webhook設定

**後で設定するので、今はスキップしてOK**
（ngrok起動後に設定します）

---

## 📋 ステップ5: PC側の設定

### 5-1. 環境変数設定

ターミナルで以下を実行:

```bash
# 環境変数をファイルに追加
echo 'export LINE_CHANNEL_ACCESS_TOKEN="ここにチャネルアクセストークンを貼り付け"' >> ~/.bashrc
echo 'export LINE_CHANNEL_SECRET="ここにチャネルシークレットを貼り付け"' >> ~/.bashrc

# 反映
source ~/.bashrc
```

**例:**
```bash
export LINE_CHANNEL_ACCESS_TOKEN="ABC123xyz..."
export LINE_CHANNEL_SECRET="def456uvw..."
```

### 5-2. 依存パッケージインストール

```bash
cd /home/planj/claudecode-wind/line-integration

# Pythonパッケージをインストール
pip install flask line-bot-sdk requests
```

---

## 📋 ステップ6: サーバー起動

### 6-1. Claude Code（スモールチーム）起動

**重要:** LINEからのメッセージを処理するには、Worker3が起動している必要があります。

```bash
cd /home/planj/claudecode-wind

# スモールチーム起動
./startup-integrated-system.ps1 3agents

# または、Worker3のみ起動
python a2a_system/workers/worker3.py &
```

### 6-2. LINE Bridgeサーバー起動

別のターミナルで:

```bash
cd /home/planj/claudecode-wind/line-integration

# Flaskサーバー起動
python line-to-claude-bridge.py
```

以下のログが表示されればOK:
```
🚀 LINE to Claude Code Bridge起動
📍 Webhook URL: http://localhost:5000/webhook
📁 Claude Inbox: /home/planj/claudecode-wind/a2a_system/shared/claude_inbox
📁 Claude Outbox: /home/planj/claudecode-wind/a2a_system/shared/claude_outbox
📁 Image Storage: /home/planj/claudecode-wind/line-integration/images
```

### 6-3. ngrokでローカルサーバーを公開

さらに別のターミナルで:

```bash
# ngrokインストール（初回のみ）
# Windowsの場合
# https://ngrok.com/download からダウンロード

# ngrok起動
ngrok http 5000
```

以下のような出力が表示されます:
```
Forwarding  https://abc123.ngrok.io -> http://localhost:5000
```

**この `https://abc123.ngrok.io` をコピーしてください**

---

## 📋 ステップ7: Webhook URL設定

### 7-1. LINE DevelopersでWebhook URL設定

1. LINE Developersコンソールに戻る
2. チャネル → 「Messaging API設定」タブ
3. 「Webhook URL」欄に以下を入力:
   ```
   https://abc123.ngrok.io/webhook
   ```
   （`abc123`の部分はngrokで表示されたURLに置き換え）

4. 「更新」ボタンをクリック
5. 「検証」ボタンをクリック
   - 「成功」と表示されればOK

### 7-2. Webhookの利用をONに

1. 同じページの「Webhookの利用」をONにする
2. 「応答メッセージ」をOFFにする（重要！）
   - これをOFFにしないと、自動応答メッセージが邪魔になります

---

## 📋 ステップ8: スマホで友だち追加

### 8-1. QRコードを表示

1. LINE Developers → Messaging API設定
2. 下にスクロールして「QRコード」を見つける

### 8-2. スマホのLINEアプリで読み取り

1. スマホでLINEアプリを開く
2. 「ホーム」→「友だち追加」→「QRコード」
3. PCの画面に表示されているQRコードを読み取る
4. 「追加」をタップ

### 8-3. 友だちリストに追加完了

- 友だちリストに「Claude Code Bot」が追加されます
- このBotにメッセージを送ると、Claude Codeが応答します

---

## 📋 ステップ9: テスト

### 9-1. 最初のメッセージを送信

スマホのLINEで「Claude Code Bot」のトークを開き、以下を送信:

```
テスト
```

### 9-2. 応答を確認

以下のような応答があればOK:

```
📝 受付中...

テスト

Claude Codeに転送しています。
```

その後、Claude Codeから応答が返ってきます:

```
🤖 Claude Code:

テストメッセージを受信しました。
システムは正常に動作しています。
```

---

## 🎉 完了！

これで、あなたのスマホLINEからClaude Codeに指示を送れるようになりました！

---

## 💬 使い方

### テキストメッセージ

```
バックアップしておいて
```

```
今のプロジェクトの状態を教えて
```

```
host-friendly-checkinのテストを実行して
```

### 画像メッセージ

- スクリーンショットを送るだけでOK
- 特定のコマンドは不要
- Claude Codeが自動で分析します

---

## 🔧 トラブルシューティング

### Q1: Webhook検証が失敗する

**原因:**
- ngrokが起動していない
- LINE Bridgeサーバーが起動していない
- URLが間違っている

**解決策:**
```bash
# ngrokとサーバーが起動しているか確認
ps aux | grep ngrok
ps aux | grep line-to-claude-bridge

# 再起動
ngrok http 5000
python line-to-claude-bridge.py
```

### Q2: メッセージが返ってこない

**原因:**
- Worker3が起動していない

**解決策:**
```bash
# Worker3が起動しているか確認
ps aux | grep worker3

# 起動していない場合
cd /home/planj/claudecode-wind
python a2a_system/workers/worker3.py &
```

### Q3: ngrokのURLが変わってしまう

**原因:**
- ngrok無料版は再起動のたびにURLが変わります

**解決策:**
1. ngrokを起動
2. 新しいURLをコピー
3. LINE DevelopersのWebhook URLを更新

**恒久的な解決策:**
- ngrok有料版を契約（固定URL）
- または、VPSに固定IPを設定

### Q4: 画像が受け取れない

**確認事項:**
```bash
# imagesディレクトリが存在するか
ls /home/planj/claudecode-wind/line-integration/images/

# 権限があるか
ls -la /home/planj/claudecode-wind/line-integration/
```

---

## 🔒 セキュリティ

### アクセス制限（オプション）

特定のLINEユーザーのみ許可する場合:

1. LINE Botにメッセージを送信
2. サーバーログでUser IDを確認:
   ```bash
   tail -f /tmp/line-webhook.log
   # 💬 メッセージ受信: テスト (from U1234567890abcdef)
   ```

3. `line-to-claude-bridge.py` に以下を追加:

```python
# line-to-claude-bridge.py の先頭付近に追加
ALLOWED_USERS = ['U1234567890abcdef']  # あなたのUser ID

# handle_text_message() の最初に追加
@handler.add(MessageEvent, message=TextMessage)
def handle_text_message(event):
    user_id = event.source.user_id

    # アクセス制限チェック
    if user_id not in ALLOWED_USERS:
        line_bot_api.reply_message(
            event.reply_token,
            TextSendMessage(text="このボットは許可されたユーザーのみ使用できます。")
        )
        return

    # 以降は既存のコード
    text = event.message.text
    ...
```

---

## 💰 コスト

### 無料で使える範囲

- **LINE Messaging API:** 無料（月1000通まで）
- **ngrok:** 無料プラン使用可能（再起動でURL変更）
- **サーバー:** 既存のPC使用

### 本番運用する場合

- **ngrok有料版:** $5/月（固定URL）
- **VPS:** $5-10/月（固定IP、24時間稼働）

---

## 📝 注意事項

1. **ngrok無料版の制限**
   - 8時間でセッションタイムアウト
   - 再起動のたびにURLが変わる
   - 本番運用には不向き

2. **Worker3の起動**
   - LINEからメッセージを送る前に必ずWorker3を起動
   - 起動していないと「タイムアウト」エラーになります

3. **環境変数の設定**
   - 環境変数は再起動後も保持されます（~/.bashrcに追加したため）
   - 別のターミナルを開く場合は `source ~/.bashrc` を実行

---

**これで完了です！スマホから快適にClaude Codeを操作できます！**
