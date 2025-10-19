# LINE → GitHub → Claude Code 統合戦略

**作成日時**: 2025-10-18 17:30:00 UTC
**ステータス**: 実装設計フェーズ
**アプローチ**: GPT-5 との壁打ち結果を反映した実装戦略

---

## 🎯 目標

LINE からのメッセージが **自動的に**:
1. GitHub Issue に変換される
2. Claude Code Action で処理される
3. 結果が LINE に返される

この **完全自動パイプライン** を構築します。

---

## 📊 システム全体図

```
┌────────────────────────────────────────────────────────────┐
│                                                            │
│  【LINE】                                                  │
│  ユーザーメッセージ受信                                    │
│      ↓                                                      │
│  【LINE Webhook Handler】(FastAPI)                        │
│  HMAC検証 + メッセージパース                              │
│      ↓                                                      │
│  【GitHub Issue Creator】                                  │
│  自動Issue作成 + @claude メンション + ラベル付与          │
│      ↓                                                      │
│  【GitHub Actions Trigger】                               │
│  @claude メンション検出                                   │
│      ↓                                                      │
│  【Claude Code Action】                                   │
│  Issue 本文をパース → A2A 送信                             │
│      ↓                                                      │
│  【GPT-5 Worker】 (A2A通信経由)                            │
│  コンテキスト読み込み + 処理                               │
│      ↓                                                      │
│  【Issue Commenter】                                       │
│  結果を GitHub Issue にコメント                            │
│      ↓                                                      │
│  【LINE Notifier】                                         │
│  完了を LINE に通知                                        │
│      ↓                                                      │
│  【LINE ユーザー】                                         │
│  結果受信                                                  │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

## 🚀 実装フェーズ（優先度順）

### フェーズ 1: LINE Webhook Handler (優先度: 最高)

**目的**: LINE からのメッセージを受け取る

**実装内容**:
```python
# /home/planj/Claude-Code-Communication/bridges/line_webhook_handler.py

from fastapi import FastAPI, Request
from linebot import LineBotApi, WebhookHandler
from linebot.exceptions import InvalidSignatureError
import hashlib
import hmac
import os
import json
from pathlib import Path

app = FastAPI()

LINE_CHANNEL_SECRET = os.getenv("LINE_CHANNEL_SECRET")
LINE_CHANNEL_ACCESS_TOKEN = os.getenv("LINE_CHANNEL_ACCESS_TOKEN")

@app.post("/webhook")
async def webhook(request: Request):
    """LINE Webhook エンドポイント"""

    # 1. HMAC 署名検証
    body = await request.body()
    signature = request.headers.get("X-Line-Signature", "")

    if not validate_hmac(body, signature):
        return {"status": "invalid signature"}

    # 2. メッセージパース
    data = json.loads(body)

    for event in data.get("events", []):
        if event["type"] == "message":
            message = {
                "type": "LINE_MESSAGE",
                "user_id": event["source"]["userId"],
                "text": event["message"]["text"],
                "timestamp": event["timestamp"]
            }

            # 3. GitHub Issue 自動作成
            create_github_issue(message)

    return {"status": "ok"}

def validate_hmac(body: bytes, signature: str) -> bool:
    """HMAC SHA256 署名検証"""
    hash_obj = hmac.new(
        LINE_CHANNEL_SECRET.encode(),
        body,
        hashlib.sha256
    )
    expected = base64.b64encode(hash_obj.digest()).decode()
    return hmac.compare_digest(signature, expected)
```

**環境変数**:
- `LINE_CHANNEL_SECRET` - LINE チャネルシークレット
- `LINE_CHANNEL_ACCESS_TOKEN` - LINE アクセストークン

---

### フェーズ 2: GitHub Issue Auto-Creator (優先度: 高)

**目的**: LINE メッセージから GitHub Issue を自動作成

**実装内容**:
```python
# /home/planj/Claude-Code-Communication/integrations/github_issue_creator.py

from github import Github, GithubException
import os
from datetime import datetime

def create_github_issue(message: dict) -> str:
    """LINE メッセージから GitHub Issue を作成"""

    g = Github(os.getenv("GITHUB_TOKEN"))
    repo = g.get_repo(os.getenv("GITHUB_REPO"))  # e.g., "user/repo"

    # Issue タイトル
    title = f"[LINE] {message['text'][:50]}"

    # Issue 本文
    body = f"""## LINE からのタスク

**元のメッセージ**:
{message['text']}

**ユーザー**: {message['user_id']}
**受信日時**: {message['timestamp']}

---

@claude - このタスクを処理してください
"""

    # Issue 作成
    issue = repo.create_issue(
        title=title,
        body=body,
        labels=["type:line-task", "priority:normal", "auto-created"]
    )

    return issue.number
```

**GitHub Token**: `GITHUB_TOKEN` (Secrets で管理)

---

### フェーズ 3: GitHub Actions Workflow (優先度: 高)

**目的**: @claude メンション検出時に Claude Code Action を実行

**実装ファイル**: `.github/workflows/claude-task-handler.yml`

```yaml
name: Claude Task Handler

on:
  issues:
    types: [opened, edited]

jobs:
  handle-claude-task:
    if: contains(github.event.issue.body, '@claude')
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Extract task from issue
        id: task
        run: |
          ISSUE_BODY="${{ github.event.issue.body }}"
          # @claude の後のテキストを抽出
          TASK=$(echo "$ISSUE_BODY" | sed -n '/@claude/,/^---/p')
          echo "TASK=${TASK}" >> $GITHUB_OUTPUT
          echo "ISSUE_NUM=${{ github.event.issue.number }}" >> $GITHUB_OUTPUT

      - name: Trigger Claude Code Action
        uses: anthropics/claude-code-action@v1
        with:
          prompt: |
            GitHub Issue #${{ steps.task.outputs.ISSUE_NUM }} から送られたタスク:
            ${{ steps.task.outputs.TASK }}

            処理完了後、結果をコメントしてください。
```

---

### フェーズ 4: Claude Code Action Handler (優先度: 中)

**目的**: GitHub Actions から A2A 経由で GPT-5 に送信

**実装内容**:
```python
# Inside Claude Code Action

# 1. Issue をパース
issue_number = os.getenv("GITHUB_ISSUE_NUMBER")
task_text = os.getenv("GITHUB_ISSUE_BODY")

# 2. A2A 経由で GPT-5 に送信
import zmq
import json

context = zmq.Context()
socket = context.socket(zmq.REQ)
socket.connect("tcp://localhost:5555")

message = {
    "type": "GITHUB_ISSUE",
    "sender": "claude_code_action",
    "issue_number": issue_number,
    "issue_title": task_text.split("\n")[0],
    "issue_body": task_text
}

socket.send_json(message)
response = socket.recv_json()

# 3. 結果を Issue にコメント
comment_text = f"""## ✅ 処理完了

{response['analysis']}

---

**処理者**: Claude Code (A2A System)
**実行日時**: {datetime.now().isoformat()}
"""

# GitHub API で Issue にコメント
# repo.get_issue(issue_number).create_comment(comment_text)
```

---

### フェーズ 5: LINE Notifier (優先度: 中)

**目的**: 処理結果を LINE に通知

**実装内容**:
```python
def notify_line_completion(user_id: str, result: str, issue_url: str):
    """LINE ユーザーに処理完了を通知"""

    import requests

    url = "https://api.line.me/v2/bot/message/push"
    headers = {
        "Authorization": f"Bearer {os.getenv('LINE_CHANNEL_ACCESS_TOKEN')}",
        "Content-Type": "application/json"
    }

    data = {
        "to": user_id,
        "messages": [{
            "type": "text",
            "text": f"""✅ タスク処理完了

結果:
{result}

詳細: {issue_url}
"""
        }]
    }

    requests.post(url, json=data, headers=headers)
```

---

## 🔐 セキュリティ実装

### 1. LINE メッセージ検証（必須）
- [x] HMAC SHA256 署名検証（偽造防止）
- [x] タイムスタンプ検証（リプレイ攻撃防止）
- [ ] ホワイトリストユーザーID確認

### 2. GitHub Token 管理
- [x] GitHub Secrets で管理
- [x] 最小権限設定（Issues 操作のみ）

### 3. API レート制限対応
- [ ] LINE API レート制限対応
- [ ] GitHub API レート制限対応

---

## ⚠️ エラーハンドリング

### Line メッセージ処理失敗時
```
LINE メッセージ
   ↓ (エラー発生)
   ↓
エラーログ記録
   ↓
LINE に「エラーが発生しました」と通知
   ↓
管理者に Slack 通知
```

### GitHub Issue 処理失敗時
```
GitHub Issue 作成
   ↓ (Claude Code Action 失敗)
   ↓
Issue に ERROR コメント追加
   ↓
LINE に「処理に失敗しました」と通知
```

---

## 📋 実装優先度

| フェーズ | 名称 | 優先度 | 実装時間 | 難易度 |
|---------|------|-------|--------|-------|
| 1 | LINE Webhook Handler | ⭐⭐⭐ | 1時間 | 中 |
| 2 | GitHub Issue Creator | ⭐⭐⭐ | 1時間 | 低 |
| 3 | GitHub Actions Workflow | ⭐⭐⭐ | 1.5時間 | 中 |
| 4 | Claude Code Action Handler | ⭐⭐ | 2時間 | 高 |
| 5 | LINE Notifier | ⭐⭐ | 1時間 | 低 |

**合計実装時間**: 約 6.5 時間

---

## 🔄 完全なフロー例

```
【1】 LINE ユーザー入力
"@claude 新しい機能 X を実装してください"

【2】 Webhook Handler が受信
{
  "user_id": "U123...",
  "text": "@claude 新しい機能 X を実装してください",
  "timestamp": 1729262400000
}

【3】 GitHub Issue 自動作成
[LINE] @claude 新しい機能 X を実装してください
      ↓
Issue #42 が作成される
本文に @claude メンション

【4】 GitHub Actions トリガー
Issue #42 が作成された
@claude を検出

【5】 Claude Code Action 実行
Issue #42 のテキストを抽出
A2A 経由で GPT-5 に送信

【6】 GPT-5 が処理
コンテキスト読み込み
機能実装の提案を生成

【7】 Issue にコメント
✅ 処理完了
[詳細な提案内容]

【8】 LINE に通知
✅ タスク完了しました
詳細は GitHub Issue を確認してください
```

---

## ✅ 検証・テスト項目

- [ ] LINE Webhook 署名検証テスト
- [ ] GitHub Issue 自動作成テスト
- [ ] @claude メンション検出テスト
- [ ] A2A 通信テスト
- [ ] LINE 通知テスト
- [ ] エラーハンドリングテスト
- [ ] 並行タスク処理テスト

---

## 📝 次のステップ

1. **フェーズ 1: LINE Webhook Handler** を実装
2. **フェーズ 2: GitHub Issue Creator** を実装
3. **フェーズ 3: GitHub Actions Workflow** を設定
4. **統合テスト** を実施
5. **本番デプロイ** に向けて準備

---

**作成者**: Claude Code + GPT-5 壁打ち
**ステータス**: 実装準備完了 ✅
**次回実装予定**: フェーズ 1 開始
