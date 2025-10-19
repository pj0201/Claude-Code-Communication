# LINE → GitHub Issue → Claude Code タスク実行システム

**Status**: ✅ 本番運用中
**Last Updated**: 2025-10-19
**Author**: Claude Code + Worker3

---

## 🎯 システム概要

LINE から送信されたメッセージを GitHub Issue として自動作成し、Claude Code が検出・処理して LINE に完了報告を返すシステムです。

```
LINE ユーザー
    ↓ メッセージ送信
LINE Bridge (Flask @ Port 5000)
    ├ Webhook 受信・署名検証
    ├ GitHub Issue 自動作成 (@claude メンション付き)
    └ /process-issue コマンドを tmux pane 0.1 に送信
         ↓
GitHub Issue
    ├ Issue #N として記録
    └ @claude メンション（Claude Code が自動検出）
         ↓
Claude Code (Worker3)
    ├ Issue を /process-issue で表示
    ├ メッセージを Inbox から検出
    ├ タスク実行・完了確認
    ├ 実行結果を検証
    └ 応答ファイルを Outbox に作成
         ↓
LINE Bridge
    ├ Outbox から応答ファイル検出
    ├ メッセージ内容を抽出
    └ LINE に返信送信
         ↓
LINE ユーザー
    └ タスク完了報告を受信
```

---

## 📱 ユーザー視点（LINE 操作）

### 1️⃣ メッセージ送信
LINE 公式アカウントにメッセージを送信するだけ：

```
例：「さっきIssueにGPT５の、ファインチューニングとclaudeの新たなシステム「スキル」について、
書いてと伝えたが、それぞれをIssueに書いてください」
```

### 2️⃣ 即座に受付確認
```
✅ 受付完了

【依頼内容】
さっきIssueに...

処理を開始します。
完了次第、結果をお送りします。
```

### 3️⃣ タスク処理中
- Bridge が GitHub Issue を自動作成
- Claude Code がタスク検出・実行
- 処理中...

### 4️⃣ 完了報告
```
✅ タスク完了！

【作成・確認済み Issue】
✓ Issue #18: GPT-5 ファインチューニング最適化
✓ Issue #19: Claude スキルシステム統合

【内容】
...

【リンク】
https://github.com/pj0201/Claude-Code-Communication/issues/18
https://github.com/pj0201/Claude-Code-Communication/issues/19
```

---

## 🔧 システム技術仕様

### コンポーネント構成

| コンポーネント | ファイル | 責務 |
|---------------|---------|------|
| **LINE Bridge** | `line_integration/line-to-claude-bridge.py` | Webhook 受信、Issue 作成、コマンド送信 |
| **/process-issue** | `/home/planj/bin/process-issue` | GitHub API で Issue 詳細取得・表示 |
| **Claude Code Listener** | `a2a_system/bridges/claude_code_listener.py` | Inbox 監視、メッセージ検出、応答作成 |
| **Inbox/Outbox** | `a2a_system/shared/claude_inbox/processed/` | メッセージ永続化、状態管理 |

### 環境変数

```bash
# 必須
LINE_CHANNEL_ACCESS_TOKEN=<LINE Bot token>
LINE_CHANNEL_SECRET=<LINE Channel secret>
GITHUB_TOKEN=<GitHub personal access token>

# オプション
GITHUB_REPO=pj0201/Claude-Code-Communication  # デフォルト値
```

### tmux セッション構成

```
セッション名: gpt5-a2a-line
├ Pane 0.0: Worker（bash）
├ Pane 0.1: Claude Code（メッセージ処理）
├ Pane 0.2: GPT-5 Chat
└ Pane 0.3: Bridge ログ監視
```

---

## 📋 完全なタスク処理フロー

### Step 1: LINE メッセージ受信
**場所**: `line_integration/line-to-claude-bridge.py:217-355`

```python
@handler.add(MessageEvent, message=TextMessage)
def handle_text_message(event):
    """テキストメッセージ受信時の処理"""
    user_id = event.source.user_id
    text = event.message.text

    # 1. 受付確認を即座に返信
    line_bot_api.reply_message(event.reply_token, TextSendMessage(...))

    # 2. Claude Code に転送（バックグラウンド処理）
    message_id = send_to_claude(text, user_id)

    # 3. 応答を待機（60-600秒）
    response = wait_for_claude_response(message_id, timeout=60)

    # 4. LINE に返信送信
    line_bot_api.push_message(user_id, TextSendMessage(...))
```

### Step 2: GitHub Issue 自動作成
**場所**: `line_integration/line-to-claude-bridge.py:47-121`

```python
def create_github_issue(user_message, user_id, timestamp):
    """GitHub Issue を作成し、Claude Code に通知"""

    # GitHub API で Issue 作成
    response = requests.post(
        f"https://api.github.com/repos/{GITHUB_REPO}/issues",
        headers=headers,
        json={
            "title": f"📱 LINE通知 ({timestamp})",
            "body": f"@claude\n\n## LINE通知\n\n{user_message}",
            "labels": ["LINE-notification"]
        }
    )

    # Issue 作成成功 → Claude Code ペイン 0.1 に /process-issue コマンド送信
    if response.status_code == 201:
        issue_number = response.json().get('number')
        send_to_claude_pane(issue_number)  # ← tmux send-keys 実行
        return issue_url, issue_number
```

### Step 3: /process-issue スクリプト実行
**場所**: `/home/planj/bin/process-issue`

**動作**:
```bash
/process-issue #18

# 出力:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 【Issue #18 の詳細】
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

【Issue #18】
タイトル: 📱 LINE通知 (20251019_122556)
URL: https://github.com/pj0201/Claude-Code-Communication/issues/18
作成者: pj0201

【本文】
@claude

## LINE通知

**受信時刻**: 20251019_122556
**ユーザー**: `...73269051`

### メッセージ内容

さっきIssueに...
```

**実装**:
- curl + GitHub API v3 を使用
- jq/grep ハイブリッドパーサで最大互換性
- フォールバック: gh CLI が利用可能なら優先使用

### Step 4: Claude Code が Inbox から検出

**ファイル形式**:
```json
{
  "type": "LINE_MESSAGE",
  "sender": "line_user",
  "target": "claude_code",
  "message_id": "line_U9048b21670f64b16508f309a73269051_20251019_122556",
  "text": "さっきIssueに...",
  "user_id": "U9048b21670f64b16508f309a73269051",
  "source": "LINE",
  "timestamp": "20251019_122556",
  "github_issue": "https://github.com/pj0201/Claude-Code-Communication/issues/18",
  "issue_number": 18
}
```

**場所**: `a2a_system/shared/claude_inbox/processed/`

### Step 5: タスク処理と検証

**処理順序**（重要）:

1. ✅ Inbox からメッセージを読む
2. ✅ タスク内容を解析
3. ✅ 実行（例：Issue 作成）
4. ✅ **実行結果を API で二重確認**
5. ✅ 確認完了を確認
6. ✅ **初めて応答ファイルを作成**（タスク完了した場合のみ）

**検証ロジック**:
```python
# Issue 作成
issue_number = create_issue(...)

# 戻り値から番号を取得
if not issue_number:
    return False  # 応答ファイルを作成しない

# GET API で二重確認
verify = get_issue(issue_number)
if verify != issue_number:
    return False  # 応答ファイルを作成しない

# 確認完了 → 応答ファイル作成
create_response_file({
    "status": "success",
    "verified_and_confirmed": True,
    "issues_created_and_verified": [issue_number]
})
```

### Step 6: 応答ファイル作成と LINE 送信

**ファイル形式**:
```json
{
  "type": "LINE_RESPONSE",
  "message_id": "line_U9048b21670f64b16508f309a73269051_20251019_122556",
  "text": "✅ タスク完了！\n...",
  "status": "success",
  "verified_and_confirmed": true,
  "issues_created_and_verified": [18, 19],
  "verification_method": "double_check_api_get"
}
```

**場所**: `a2a_system/shared/claude_outbox/response_line_*.json`

**Bridge の検出**:
```python
pattern = os.path.join(CLAUDE_OUTBOX, f"response_*{message_id}*.json")
response_files = glob.glob(pattern)

if response_files:
    with open(response_files[0]) as f:
        response = json.load(f)

    # LINE に返信
    line_bot_api.push_message(
        user_id,
        TextSendMessage(text=f"🤖 処理結果:\n\n{response['text']}")
    )
```

---

## ⏱️ タイムライン（参考値）

| ステップ | 実行時間 | 説明 |
|---------|---------|------|
| LINE 受信 | 0 秒 | ユーザーがメッセージ送信 |
| 受付確認送信 | 0.5 秒 | Bridge が即座に受付確認を返信 |
| Issue 作成 | 2-3 秒 | GitHub API で Issue 作成 |
| /process-issue 実行 | 0.5-1 秒 | CLI でスクリプト実行 |
| Claude Code 処理 | 5-60 秒 | タスク内容に依存 |
| 応答ファイル作成 | 0.1 秒 | Outbox にファイル作成 |
| Bridge が検出 | 1-5 秒 | Outbox をポーリング |
| LINE 返信送信 | 1-2 秒 | API で返信送信 |
| **合計** | **10-75 秒** | タスク複雑度に依存 |

---

## 🚀 運用ガイド

### Bridge の起動
```bash
cd /home/planj/Claude-Code-Communication
python3 line_integration/line-to-claude-bridge.py
# または
./start-small-team.sh
```

### ログ監視
```bash
# Bridge ログをリアルタイム監視
tail -f /tmp/line_bridge.log

# Inbox/Outbox をリアルタイム監視
ls -lR /home/planj/Claude-Code-Communication/a2a_system/shared/claude_inbox/
ls -lR /home/planj/Claude-Code-Communication/a2a_system/shared/claude_outbox/
```

### トラブルシューティング

**症状**: LINE が返信を受け取らない
**原因**: Claude Code が応答ファイルを作成していない
**確認**:
1. Inbox に メッセージが存在するか？
2. Outbox に応答ファイルが存在するか？
3. Bridge ログにエラーがないか？

**症状**: GitHub Issue が作成されない
**原因**: GITHUB_TOKEN が無効または Bridge が起動していない
**確認**:
1. `echo $GITHUB_TOKEN` で トークンが設定されているか
2. Bridge プロセスが実行中か `pgrep -f line-to-claude-bridge`
3. Bridge ログでエラーを確認

---

## 📊 ファイル構成

```
Claude-Code-Communication/
├ line_integration/
│  └ line-to-claude-bridge.py          # LINE Webhook + GitHub Issue 作成
├ a2a_system/
│  ├ shared/
│  │  ├ claude_inbox/                  # メッセージ受信
│  │  │  └ processed/                  # 処理済みメッセージ
│  │  └ claude_outbox/                 # 応答ファイル
│  └ bridges/
│     └ claude_code_listener.py        # Inbox 監視・応答作成
├ bin/
│  └ process-issue                     # GitHub Issue 詳細取得スクリプト
└ LINE_ISSUE_TASK_SYSTEM.md            # このドキュメント
```

---

## ✅ 実装完了チェックリスト

- [x] LINE Webhook エンドポイント実装
- [x] GitHub Issue 自動作成機能
- [x] /process-issue スクリプト（curl + API ベース）
- [x] tmux send-keys でペイン 0.1 にコマンド送信
- [x] Inbox メッセージ検出・処理
- [x] タスク完了検証（二重確認）
- [x] Outbox 応答ファイル作成
- [x] Bridge による応答ファイル検出・LINE 返信
- [x] エンドツーエンドテスト成功

---

## 🎯 今後の拡張

### Phase 1: 画像処理
- 画像メッセージからの OCR 処理
- 画像ベースのタスク実行

### Phase 2: GPT-5 との連携
- GPT-5 への自動壁打ち相談
- 複雑なタスクの自動分解

### Phase 3: スキルシステム統合
- Claude Official Skills との自動統合
- タスク・ファイルタイプ別の自動スキル選択

---

**System Status**: ✅ **完成・本番運用中**

*最終更新: 2025-10-19 12:30 UTC*
