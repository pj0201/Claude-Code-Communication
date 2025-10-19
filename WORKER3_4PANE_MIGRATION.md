# Worker3 4ペイン構成への移行 - プロジェクト進行管理

**最終更新**: 2025-10-19 10:12:37
**ステータス**: 🔄 進行中（何度も落ちている - 復帰困難状態）
**ブランチ**: `master` (18コミット先行)

---

## 📋 タスク定義（ゴール）

### 目的
2ペイン構成から4ペイン構成へ移行し、**LINE → GitHub Issue → Claude Code → LINE** の完全自動化ワークフローを実現

### 最終的な成功の定義
✅ **最終目標に到達したら、このファイルを削除**

1. **LINEからメッセージ送信**
   - ユーザーが LINE で「〇〇をしてほしい」とメッセージ送信

2. **GitHub Issue に自動作成**
   - LINE Webhook → GitHub Issue 作成
   - @claude メンション付きで作成される

3. **ワーカー3が自律的に受信**
   - HOOK、ファイル監視等から GitHub Issue の @claude メンションを自動検出
   - Issue 内容をパース

4. **タスク実行**
   - Issue に記載されたタスクを完了
   - 結果をコメント記載

5. **LINE に完了メッセージ送信**
   - send-line-reply.sh で LINE に結果を返信

---

## 🏗️ 4ペイン構成の詳細

### tmux セッション: `gpt5-a2a-line`

| ペイン | 役割 | プロセス | 状態 |
|--------|------|---------|------|
| 0.0 | GPT-5 チャット | `gpt5-chat.py` | ⏸️ |
| 0.1 | **ワーカー3（Claude Code）** | Claude Code | ✅ 現在アクティブ |
| 0.2 | LINE Bridge | `line-to-claude-bridge.py` | ✅ ポート5000 |
| 0.3 | Bridge ログ監視 | `tail -f /tmp/bridge.log` | ✅ |

### 起動スクリプト
- `start-small-team.sh` - 統合起動スクリプト
- `.claude/hooks/user-prompt-submit.sh` - Hook 通知用スクリプト

---

## ⚠️ 現在の問題点（何度も落ちた原因）

### 問題1: LINE 受付確認が返ってこない ❌
**症状**: LINE からメッセージ送信 → 何も返ってこない（以前は即座に「✅ 受付完了」と返信があった）

**原因推定**:
- `line_webhook_handler.py` が起動していない
- ポート 5000 は `line-to-claude-bridge.py` が使用中（競合）
- webhook からの受け取りフローが 4ペイン構成で変更されていない

**関連ファイル**:
- `bridges/line_webhook_handler.py` - LINE 受付確認送信機能あり
- `line-to-claude-bridge.py` - ポート5000リッスン中

---

### 問題2: GitHub Actions が @claude を検出していない ❌
**症状**: LINE から送信 → GitHub Issue 作成されない

**原因推定**:
- `.github/workflows/claude-assistant.yml` の @claude 検出ロジックが変更された
- `claude-task-handler.yml` では Issue 作成時に @claude が必須
- LINE webhook → GitHub Issue 自動作成の仲介役がいない

**関連ファイル**:
- `.github/workflows/claude-assistant.yml` (Oct 18 20:56 修正)
- `.github/workflows/claude-task-handler.yml` (Oct 18 18:45 修正)
- `bridges/line_webhook_handler.py` (Oct 18 20:58 修正)

---

### 問題3: 複数エージェントが Issue を読んでいる ❌
**症状**: ワーカー3を指定していないため、GPT-5 等他のエージェントも反応する可能性

**原因推定**:
- GitHub Actions → Claude Code Action → 全エージェントに通知
- ワーカー3 (Claude Code pane 0.1) を特定できない
- 2ペイン構成では問題なかったが、4ペイン構成では混乱の元

**解決方法**:
- ワーカー3 を明示的に指定
- Issue ラベルに `worker3-task` を付与
- GitHub Actions コメントで `@Worker3` メンション

---

## 🔧 修正計画（実装ロードマップ）

### Phase 1: LINE Webhook 受付確認の修復 🔴 必須
**目標**: LINE からメッセージ → 即座に「✅ 受付完了」が返ってくる

1. **ポート 5000 の競合を解決**
   - Option A: `line-to-claude-bridge.py` を別ポート (5001) に変更
   - Option B: `line_webhook_handler.py` を統合して同一プロセスに

2. **LINE 受付確認メッセージの送信**
   - `send_line_acknowledgment()` が正常に動作することを確認
   - Hook で claude_code に通知

3. **テスト**
   ```bash
   # Terminal 1: 各プロセス起動確認
   ./start-small-team.sh

   # Terminal 2: LINE からテスト送信
   # 「テスト送信」と送信 → 即座に「✅ 受付完了」が返ってくることを確認
   ```

---

### Phase 2: GitHub Actions の @claude 検出修復 🔴 必須
**目標**: GitHub Issue に @claude メンションがあれば、Claude Code Action が起動

1. **claude-assistant.yml の動作確認**
   - @claude メンション検出ロジックが正常に動作か確認
   - テスト Issue を作成して確認

2. **ワーカー3 指定ロジックの追加**
   - Issue にラベル `worker3-task` を自動付与
   - GitHub Actions でワーカー3 への直接通知を実装

3. **テスト**
   ```bash
   # GitHub Issue 作成（手動）
   # Title: "Test issue"
   # Body: "これはテストです @claude"

   # claude-assistant.yml が起動することを確認
   ```

---

### Phase 3: LINE → GitHub Issue 自動作成パイプラインの確立 🔴 必須
**目標**: LINE メッセージ → 自動的に GitHub Issue (@claude 付き) が作成される

1. **line_webhook_handler.py の修正**
   - メッセージ受け取り後、GitHub Issue を直接作成
   - または `github_action_handler.py` 経由で Issue 作成

2. **GitHub Issue 作成の実装**
   ```python
   # line_webhook_handler.py 内で
   - LINE メッセージを受け取り
   - GitHub REST API で Issue 作成
   - @claude を自動付与
   ```

3. **テスト**
   ```bash
   # Terminal: LINE からテスト送信
   # 「LINEテスト」と送信

   # GitHub Issues に自動作成されることを確認
   # Issue Title: "LINEテスト"
   # Issue Body: "LINEテスト \n\n @claude"
   ```

---

### Phase 4: ワーカー3 の自律的受信と処理 🟡 重要
**目標**: GitHub Issue の @claude メンションをワーカー3が自動検出 → タスク実行

1. **Hook 通知の確認**
   - `.claude/hooks/user-prompt-submit.sh` が通知を受け取るか確認
   - `/tmp/claude_code_line_notification.flag` が作成されるか確認

2. **Issue 内容の自動読み込み**
   - ワーカー3 が Issue のタイトル・本文をパース
   - タスク内容を抽出

3. **テスト**
   ```bash
   # Terminal: ワーカー3 ペイン (0.1) でログを確認
   # tmux capture-pane -t gpt5-a2a-line:0.1 -p

   # GitHub Issue の更新を自動検出するか確認
   ```

---

### Phase 5: LINE への完了メッセージ送信 🟡 重要
**目標**: タスク完了 → LINE に結果送信

1. **ワーカー3 から send-line-reply.sh を呼び出し**
   - 完了情報を取得
   - ユーザーID + メッセージで LINE に送信

2. **テスト**
   ```bash
   # ワーカー3 内で
   ./send-line-reply.sh "U9048b21670f64b16508f309a73269051" "タスク完了しました！"

   # LINE で「タスク完了しました！」が受け取れるか確認
   ```

---

## 📁 関連ファイル一覧

### GitHub Actions ワークフロー
- `.github/workflows/claude-assistant.yml` - @claude メンション検出 ⚠️ 要修正
- `.github/workflows/claude-task-handler.yml` - Issue → Claude 通知 ⚠️ 要修正

### LINE Webhook 関連
- `bridges/line_webhook_handler.py` - LINE メッセージ受け取り ⚠️ ポート競合
- `bridges/line-to-claude-bridge.py` - ポート5000リッスン ⚠️ 競合原因
- `line_integration/.env` - LINE 認証情報
- `integrations/line_notifier.py` - LINE 通知送信

### Claude Code 連携
- `bridges/claude_bridge.py` - Claude Code ↔ ZMQ 変換
- `bridges/claude_code_listener.py` - Claude Code 受信リスナー
- `.claude/hooks/user-prompt-submit.sh` - Hook 通知スクリプト ⚠️ 4ペイン対応要確認
- `.claude/settings.json` - Claude Code 設定

### ワーカー3 応答
- `send-line-reply.sh` - LINE 返信スクリプト
- `line-realtime-monitor.sh` - LINE リアルタイム監視

### 設定・ドキュメント
- `start-small-team.sh` - 統合起動スクリプト
- `.tmux.conf` - tmux 設定（4ペイン構成定義）
- `COMMUNICATION_PROTOCOL.md` - 通信プロトコル
- `CLAUDE.md` - チーム運営ガイド

---

## 🔍 デバッグチェックリスト

### Step 1: プロセス確認
```bash
ps aux | grep -E "line|webhook|bridge" | grep -v grep
netstat -tlnp 2>/dev/null | grep 5000

# Expected:
# - line_webhook_handler.py: ✓ または別ポートで起動
# - line-to-claude-bridge.py: ✓ ポート5000
# - line_notifier.py: ✓
```

### Step 2: tmux ペイン確認
```bash
tmux list-panes -t gpt5-a2a-line -a

# Expected:
# 0.0: [history] Claude Code
# 0.1: [active] Claude Code (Worker3)
# 0.2: [history] LINE Bridge
# 0.3: [history] Tail log
```

### Step 3: ファイルシステム監視
```bash
# Hook フラグの作成確認
ls -la /tmp/claude_code_line_notification.flag

# メッセージ保存確認
ls -lah a2a_system/shared/claude_inbox/line_message_*.json
```

### Step 4: ログ確認
```bash
# LINE Webhook ハンドラログ
tail -50 line_webhook_handler.log

# GitHub Actions 実行
# → https://github.com/pj0201/Claude-Code-Communication/actions

# Bridge ログ
tail -50 /tmp/bridge.log
```

---

## 📝 前回の作業記録（参考）

### 10/16 以前（成功した 2ペイン構成）
- LINE メッセージ受信 → 即座に「✅ 受付完了」返信 ✅
- GitHub Issue 自動作成 ✅
- ワーカー3 自動受信 ✅
- 完了メッセージ返信 ✅

### 10/18 - 10/19（4ペイン移行中）
- 4ペイン構成に変更開始
- GitHub Actions ワークフロー修正
- line_webhook_handler.py に新機能追加
- **↓ 問題発生**
- LINE 受付確認が返ってこない ❌
- GitHub Issue 自動作成されない ❌
- **↓ 何度も落ちる**

---

## 💾 保存されたスナップショット

### コード状態（Oct 19 10:12:37）
```bash
git log --oneline -5
# dea92e1 fix: Improve GitHub Actions workflow trigger detection for @claude mentions
# e6be25c fix: Add GitHub Issue Monitor to LINE → GitHub → Claude pipeline
# 732adfc fix: Add LINE Bridge startup to start-small-team.sh for 4-pane team setup
# 5642f2b docs: Update Worker2 and Worker3 role definitions
# 6ef5e78 refactor: Simplify COMMUNICATION_PROTOCOL.md - keep only successful logic
```

### 未コミット変更
```bash
git diff --stat
# 複数のドキュメント・設定ファイルが修正中
```

---

## 🎯 次のアクション（復帰時に実行）

### 1. 現状確認
```bash
# Branch・commit 状態確認
git status
git log --oneline -5

# プロセス確認
./start-small-team.sh status

# または直接確認
ps aux | grep -E "line|webhook"
```

### 2. Phase 1: LINE 受付確認の修復から開始
- ポート 5000 の競合解決
- LINE メッセージ送信テスト

### 3. 各 Phase を順序通り進める
- Phase 1 ✓ → Phase 2 ✓ → Phase 3 → Phase 4 → Phase 5

### 4. テスト実行
- LINE テスト送信
- GitHub Issue 作成確認
- ワーカー3 自動受信確認
- LINE 返信確認

---

## ✅ 完了条件

このファイルを削除できるのは、以下の全てが達成された時：

1. ✅ LINE メッセージ送信 → 即座に「✅ 受付完了」が返ってくる
2. ✅ GitHub Issue に自動作成される（@claude 付き）
3. ✅ ワーカー3 が自動検出
4. ✅ タスク実行・完了
5. ✅ LINE に結果メッセージが返ってくる

**この全てが 3 回以上連続成功したら、このファイルを削除 → タスク完了**

---

## 📌 重要な注意事項

⚠️ **何度も落ちている理由**:
- 複数の非同期処理が同時に走っている
- ポート競合でプロセスが立ち上がらない
- GitHub Actions との連携がうまくいっていない

💡 **復帰のコツ**:
- 1 つの Phase を完全に完成させてから次に進む
- テストしながら進める（デバッグチェックリストを毎回実行）
- 落ちたら、このファイルに現象を記録
- 必要に応じてロールバック (`git reset --soft HEAD~1`)

---

**作成者**: Worker3
**最終更新**: 2025-10-19 10:12:37
**進捗**: 🔴 Phase 1 前（ポート競合解決待ち）
