# Worker3 ワークフロー修正計画

**作成**: 2025-10-19 10:45
**ステータス**: 🔴 Worker3 応答ロジックが欠けている
**優先度**: 🔴 最高

---

## 📊 現在のワークフロー状態（Oct 18 ログから）

### ✅ 完全に機能している部分（LINE Bridge）

```
[LINE メッセージ]
       ↓
   Bridge
       ├─ ✅ メッセージ受信
       ├─ ✅ LINE 受付確認返信 (即座に「✅ 受付完了」)
       ├─ ✅ GitHub Issue 作成 (Issue #6)
       ├─ ✅ @claude メンション付き
       ├─ ✅ "LINE-notification" ラベル付き
       ├─ ✅ Claude Code pane (0.1) に通知
       └─ ✅ Inbox に JSON ファイル保存

実際の成功ログ:
INFO:__main__:✅ GitHub Issue作成成功: https://github.com/pj0201/Claude-Code-Communication/issues/6
INFO:__main__:✅ Claude Code ペイン (0.1) に通知送信: Issue #6
```

### ❌ 失敗している部分（Worker3 応答）

```
[Bridge が Outbox を監視]
       ↓
   wait_for_claude_response(timeout=60)
       ├─ Outbox フォルダを監視
       ├─ response_*.json を探す
       └─ 60秒待機...
          ↓
        ⏰ タイムアウト！

実際のタイムアウトログ:
WARNING:__main__:⏰ タイムアウト: line_U9048b21670f64b16508f309a73269051_20251018_153927
```

---

## 🔍 Root Cause Analysis

**ユーザーの指摘と一致**:
> 「2ペイン時も issue の書き込みまではうまくいったが、ワーカーは気づけなかった」

**何が起きているのか**:
1. LINE → GitHub Issue: ✅ 完璧に成功
2. Bridge が Outbox を監視: ✅ 正常に動作
3. **Worker3 が Outbox に応答を書き込まない**: ❌ 問題はここ

**理由**:
- Bridge は Outbox から応答ファイルを待機している
- でも Worker3 が応答ファイルを作成していない
- つまり **Worker3 が Issue を detect & 処理していない**

---

## 🚀 必要な改良（4ペイン構成での Worker3 ロジック）

### Step 1: Claude Code Hook で Issue 通知を受け取る

Worker3 (pane 0.1) が Inbox の通知ファイルを detect：

```json
// Inbox ファイル例: github_issue_created_6_20251018_153927.json
{
  "type": "GITHUB_ISSUE_CREATED",
  "sender": "line_bridge",
  "target": "claude_code",
  "issue_number": 6,
  "issue_url": "https://github.com/pj0201/Claude-Code-Communication/issues/6",
  "message": "テスト送信だ",
  "timestamp": "20251018_153927"
}
```

**Hook で検出**:
```bash
# .claude/hooks/user-prompt-submit.sh で
if [ -f "/tmp/claude_code_line_notification.flag" ]; then
    # Issue 通知を受け取った → 処理開始
fi
```

### Step 2: GitHub Issue を読む

Worker3 が GitHub API で Issue を取得：

```python
# Pseudo code
def read_github_issue(issue_number):
    response = github.get_issue(issue_number)
    return {
        "title": response.title,
        "body": response.body,
        "labels": response.labels
    }
```

### Step 3: タスクをパースして実行

Issue Body から実際のタスクを抽出：

```
Issue Body:
@claude

テスト送信だ

↓

Task extracted: "テスト送信だ"
```

### Step 4: 処理実行

Worker3 が タスクを実行（実装は user 次第）

### Step 5: 結果を Outbox に書き込み

Worker3 が Bridge が待機している response ファイルを作成：

```json
// Outbox ファイル例: response_line_U9048b21670f64b16508f309a73269051_20251018_153927.json
{
  "type": "text",
  "text": "✅ 処理完了しました。テスト送信を受け取りました。",
  "message_id": "line_U9048b21670f64b16508f309a73269051_20251018_153927"
}
```

---

## 📋 修正ロードマップ

### Phase 1: Issue 通知 Detection（Hook レイヤー）
**目標**: Worker3 が Inbox の通知ファイルを detect できる

**実装場所**: `.claude/hooks/user-prompt-submit.sh`

**やること**:
1. `/tmp/claude_code_line_notification.flag` を監視
2. `a2a_system/shared/claude_inbox/github_issue_created_*.json` を監視
3. 検出したら Claude Code 内で処理開始シグナルを出す

### Phase 2: GitHub Issue Read（API レイヤー）
**目標**: Worker3 が GitHub から Issue を取得できる

**実装場所**: Claude Code 内で実行

**やること**:
1. GitHub token を使用して Issue を GET
2. Title, Body, Labels を抽出
3. @claude メンション確認

### Phase 3: Task Parse & Execute（ビジネスロジック）
**目標**: Worker3 が Issue から タスクを抽出して実行

**実装場所**: Claude Code 内で実行

**やること**:
1. Issue Body をパース
2. 実際のタスク（ユーザーの依頼）を抽出
3. タスクを実行
4. 結果を取得

### Phase 4: Result を Outbox に書き込み（通信レイヤー）
**目標**: Bridge が待機している Outbox に応答ファイルを作成

**実装場所**: Claude Code 内 / または shell script

**やること**:
1. `a2a_system/shared/claude_outbox/response_*.json` を作成
2. JSON フォーマット: `{"type": "text", "text": "結果テキスト"}`
3. Bridge が読み込めるタイミングで作成（同期）

---

## 🔧 具体的な実装例

### Bridge の Outbox 監視ロジック（既存・既に動作中）

```python
# line-to-claude-bridge.py: line 209-280
def wait_for_claude_response(message_id, timeout=60):
    start_time = time.time()
    while time.time() - start_time < timeout:
        # Outbox をチェック
        all_responses = glob.glob(os.path.join(CLAUDE_OUTBOX, "response_*.json"))

        if all_responses:
            # 最新のファイルを選択
            response_file = max(all_responses, key=os.path.getmtime)

            with open(response_file, 'r', encoding='utf-8') as f:
                response = json.load(f)

            # ファイル削除（処理済み）
            os.remove(response_file)

            # 応答テキストを返す
            return response.get('text', '')

        time.sleep(1)

    # タイムアウト
    return "⏰ タイムアウト"
```

**Bridge は既にこの監視をしている** ✅

**Worker3 がやることは**：
```python
# Outbox に response ファイルを作成
response_data = {
    "type": "text",
    "text": "処理結果テキスト"
}

response_file = os.path.join(
    CLAUDE_OUTBOX,
    f"response_{message_id}.json"
)

with open(response_file, 'w') as f:
    json.dump(response_data, f, ensure_ascii=False, indent=2)
```

---

## ✅ 完了条件

完全なワークフロー達成：

1. ✅ LINE メッセージ送信
2. ✅ LINE 即座に「受付完了」返信
3. ✅ GitHub Issue 自動作成
4. ✅ Claude Code pane (0.1) に通知送信
5. **✅ Worker3 が通知を検出**
6. **✅ Worker3 が GitHub Issue を読む**
7. **✅ Worker3 がタスクを実行**
8. **✅ Worker3 が Outbox に応答を書き込み**
9. ✅ Bridge が Outbox から応答を読み込み
10. ✅ LINE に結果を返信

---

## 📝 次のステップ

ユーザーが実装すべき部分：

**Phase 1: Hook Detection 実装**
- `.claude/hooks/user-prompt-submit.sh` を修正
- Inbox ファイルを監視
- 通知を Claude Code ペイン (0.1) に送る

**Phase 2-4: Worker3 ロジック実装**
- GitHub API との通信
- Issue パース
- タスク実行
- Outbox への書き込み

---

## 🔗 参考情報

- **成功している実装**: `line_integration/line-to-claude-bridge.py`
- **待機ロジック**: Line 209-280
- **Inbox 通知**: `a2a_system/shared/claude_inbox/`
- **Outbox 応答**: `a2a_system/shared/claude_outbox/`
- **Hook システム**: `.claude/hooks/user-prompt-submit.sh`

---

**結論**: LINE Bridge は完璧に動作している。改良が必要な部分は **Worker3 側のタスク処理・応答ロジック**です。

