# LINEメッセージ受信ワークフロー（完全最適化版）

## 📋 概要

LINEからのメッセージをWorker3（Claude Code）が受信する**完全に一本化された**最適ワークフロー。

**重要**: GPT-5やUnix Socketは使用しません。ファイルベース通信のみ。

---

## 🎯 ワークフロー（完全一本化）

```
LINE Webhook (外部)
    ↓
新ペイン: line-to-claude-bridge.py
    ↓ JSONファイル作成
claude_inbox/line_*.json
    ↓ watchdog監視
Claude Bridge (Python)
    ↓ 通知作成
claude_outbox/notification_line_*.json
    ↓ user-prompt-submit時
line_notification_hook.sh
    ↓ 通知表示
Worker3（Claude Code）が対応
```

**処理時間**: 数秒以内（ファイルベース）

---

## 🔧 システム構成（3コンポーネントのみ）

### 1. 新ペイン: LINE Webhook受信（外部・常時動作）

**場所**: `/home/planj/claudecode-wind/line-integration/line-to-claude-bridge.py`

**役割**:
- LINE Webhookを受信（Flask）
- JSONを`claude_inbox/line_*.json`に保存
- LINEに受付確認を即座に返信

**プロセス確認**:
```bash
ps aux | grep "line-to-claude-bridge.py" | grep -v grep
```

**起動方法**: (自動起動済み・触らない)

---

### 2. Claude Bridge（必須・常時動作）

**場所**: `/home/planj/Claude-Code-Communication/a2a_system/bridges/claude_bridge.py`

**役割**:
- `claude_inbox/`をwatchdog監視
- `line_*.json`を検知
- `notification_line_*.json`を`claude_outbox/`に作成
- 処理済みファイルを`processed/`に移動

**状態確認**:
```bash
ps aux | grep claude_bridge | grep -v grep
tail -20 /tmp/claude_bridge_restart.log
```

**起動方法**:
```bash
cd /home/planj/Claude-Code-Communication/a2a_system
python3 bridges/claude_bridge.py > /tmp/claude_bridge_restart.log 2>&1 &
```

---

### 3. user-prompt-submit Hook（必須・自動実行）

**場所**: `~/.claude/hooks/user-prompt-submit.sh`

**内容**:
```bash
#!/bin/bash
/home/planj/Claude-Code-Communication/line_notification_hook.sh 2>/dev/null || true
exit 0
```

**役割**: ユーザー入力時に自動実行

**確認方法**:
```bash
cat ~/.claude/hooks/user-prompt-submit.sh
```

---

### 4. LINE通知Hook（必須・自動実行）

**場所**: `/home/planj/Claude-Code-Communication/line_notification_hook.sh`

**役割**:
- `claude_outbox/notification_line_*.json`をチェック
- 存在すれば内容を表示
- 読み取り後は`read/`に移動

**手動テスト**:
```bash
/home/planj/Claude-Code-Communication/line_notification_hook.sh
```

---

## 🚀 動作確認

### 手動テスト
```bash
# 1. Hookスクリプトを手動実行
/home/planj/Claude-Code-Communication/line_notification_hook.sh

# 2. Claude Bridgeログ確認
tail -20 /tmp/claude_bridge_restart.log

# 3. 通知ファイル確認
ls -lt /home/planj/Claude-Code-Communication/a2a_system/shared/claude_outbox/notification_line_*.json
```

### 自動動作
ユーザーがClaude Codeに何か入力すると、自動的に新着LINEメッセージが表示されます。

---

## 📂 ディレクトリ構造

```
a2a_system/shared/
├── claude_inbox/           # Claude Bridge監視対象
│   ├── line_*.json        # 新ペインが作成（処理待ち）
│   └── processed/         # 処理済み（自動移動）
│
└── claude_outbox/         # Worker3 Hook監視対象
    ├── notification_line_*.json  # Claude Bridge作成（未読）
    └── read/              # 読み取り済み（自動移動）
```

---

## 🔍 トラブルシューティング

### 通知が表示されない

1. **Claude Bridgeの確認**:
   ```bash
   ps aux | grep claude_bridge
   tail -20 /tmp/claude_bridge_restart.log
   ```

2. **通知ファイルの確認**:
   ```bash
   ls -lt /home/planj/Claude-Code-Communication/a2a_system/shared/claude_outbox/notification_line_*.json
   ```

3. **Hookの手動実行**:
   ```bash
   /home/planj/Claude-Code-Communication/line_notification_hook.sh
   ```

### Claude Bridgeが動いていない

```bash
# a2a_systemディレクトリで再起動
cd /home/planj/Claude-Code-Communication/a2a_system
python3 bridges/claude_bridge.py > /tmp/claude_bridge_restart.log 2>&1 &
```

---

## ⚠️ 削除済みの不要なワークフロー

以下のファイル・プロセスは削除されました（不要・重複のため）:

### GPT-5関連（完全削除）
- ❌ `ask-gpt5.sh` - 遅くて使わない
- ❌ `send-to-gpt5.sh` - 遅くて使わない
- ❌ `get-gpt5-answer.sh` - 遅くて使わない
- ❌ `gpt5-chat.py` - 遅くて使わない
- ❌ `start-gpt5-with-a2a.sh` - 遅くて使わない

### Unix Socket関連（完全削除）
- ❌ `line_socket_server.py` - ファイルベースで十分
- ❌ `line_socket_client.py` - ファイルベースで十分

### 失敗した過去の実装（完全削除）
- ❌ `line_realtime_processor.py` - ゴーストプロセス
- ❌ `line_to_a2a_bridge.sh` - 二重処理
- ❌ `line_notification_monitor.sh` - ファイル競合
- ❌ `write-line-message.sh` - 不要な中間層
- ❌ `line-realtime-monitor.sh` - 複雑化
- ❌ `setup-line-monitor.sh` - 不要な設定
- ❌ `check_line_signal.py` - 不要
- ❌ `check_new_line_messages.py` - 不要
- ❌ `line_sidecar.py` - 不要
- ❌ `line_simple_receiver.py` - 不要
- ❌ `claude_code_subscriber.py` - 不要
- ❌ `claude_inbox_watcher.py` - Claude Bridgeで十分
- ❌ `send_line_message.py` - 不要

---

## ✅ 利点

1. **シンプル** - 3つのコンポーネントのみ
2. **堅牢** - Claude Bridgeの既存機能を活用
3. **保守しやすい** - ワークフローが1本化
4. **競合なし** - ファイル奪い合いが発生しない
5. **再起動に強い** - ファイルベース
6. **高速** - 数秒以内に通知表示
7. **GPT-5不要** - 遅いGPT-5を使わない

---

## 📊 システム状態

現在の状態（2025-10-14）:

- ✅ Claude Bridge: 動作中（PID 23032）
- ✅ user-prompt-submit Hook: 設定済み
- ✅ line_notification_hook.sh: 最適化完了
- ✅ ワークフロー: 完全一本化完了
- ✅ 不要ファイル: 20個以上削除完了
- ✅ GPT-5関連: 完全削除
- ✅ Unix Socket関連: 完全削除
- ✅ ゴーストプロセス: 停止完了

---

## 🎯 重要なパス一覧（ファイル探索不要）

**すぐにアクセスできる主要ファイル**:

| 役割 | パス |
|------|------|
| Claude Bridge | `/home/planj/Claude-Code-Communication/a2a_system/bridges/claude_bridge.py` |
| 新ペイン（LINE受信） | `/home/planj/claudecode-wind/line-integration/line-to-claude-bridge.py` |
| LINE通知Hook | `/home/planj/Claude-Code-Communication/line_notification_hook.sh` |
| user-prompt-submit Hook | `~/.claude/hooks/user-prompt-submit.sh` |
| inbox | `/home/planj/Claude-Code-Communication/a2a_system/shared/claude_inbox/` |
| outbox | `/home/planj/Claude-Code-Communication/a2a_system/shared/claude_outbox/` |
| Claude Bridgeログ | `/tmp/claude_bridge_restart.log` |

---

**最終更新**: 2025-10-14
**実装者**: Worker3 (Claude Code)
**状態**: ✅ 完全最適化完了・本番運用中
