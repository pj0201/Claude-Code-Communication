# クイックスタートガイド - GPT-5 + A2A + LINE通知システム

## 🚀 1コマンド起動

```bash
cd /home/planj/Claude-Code-Communication
./start-gpt5-with-a2a.sh
```

これだけで**全システムが起動**します！

## 📺 起動後のtmuxレイアウト（4ペイン）

```
┌─────────────────────────┬─────────────────────────┐
│ GPT-5 Chat              │ 🔔 LINE通知             │ ← ZeroMQ PULL受信
│ (左上)                  │ ディスプレイ            │   リアルタイム表示
│                         │ (右上)                  │
├─────────────────────────┼─────────────────────────┤
│ A2A System              │ LINE Bridge監視         │
│ - Broker                │ (右下)                  │
│ - GPT-5 Worker          │                         │
│ - Claude Bridge         │                         │
│ (左下)                  │                         │
└─────────────────────────┴─────────────────────────┘
```

## 🎯 システム構成

### バックグラウンドプロセス
- **LINE Bridge** - LINE Webhook受信 (PID表示あり)
- **LINE Message Handler** - メッセージ処理 (PID表示あり)
- **LINE通知デーモン** - ZeroMQ PUSH送信 (PID表示あり)
  - ログ: `/tmp/line_notification_daemon.log`

### tmuxペイン
1. **左上 - GPT-5 Chat**: GPT-5との対話インターフェース
2. **右上 - LINE通知ディスプレイ**: **★ここが重要★**
   - ZeroMQ PULLでリアルタイム通知受信
   - 赤背景で視覚的に表示
   - 通知音再生
   - tmuxステータスバー点滅
   - **ユーザーが何もしなくても通知が見える**
3. **左下 - A2A System**: Broker + Workers + Bridge
4. **右下 - LINE Bridge監視**: LINE Webhook受信ログ

## 📱 LINE通知の流れ（Slack-GitHub統合パターン）

```
LINE Webhook
  ↓
LINE Bridge (line-to-claude-bridge.py)
  ↓
Claude Bridge (notification_line_*.json作成)
  ↓ watchdog検知
line_notification_daemon.py
  ↓ ZeroMQ PUSH (tcp://localhost:5556)
tmux_notification_display.py (右上ペイン)
  ↓ 視覚的表示
✅ ユーザーは何もしなくても通知に気づく
```

## 🧪 テスト方法

### 1. シミュレーションテスト
```bash
./test-line-notification.sh
```

右上ペインに通知が表示されることを確認。

### 2. 実際のLINE送信
LINEアプリからメッセージを送信すると、右上ペインに自動的に表示されます。

## 📋 よく使うコマンド

```bash
# システム状態確認
ps aux | grep -E '(broker|gpt5_worker|claude_bridge|line_notification)'

# 各種ログ確認
tail -f /tmp/line_bridge.log                     # LINE Bridge
tail -f /tmp/line_notification_daemon.log        # 通知デーモン
tail -f a2a_system/broker.log                    # ZMQ Broker
tail -f a2a_system/claude_bridge.log             # Claude Bridge

# tmuxペイン切り替え
tmux select-pane -t 0  # 左上 (GPT-5 Chat)
tmux select-pane -t 1  # 右上 (LINE通知ディスプレイ)
tmux select-pane -t 2  # 左下 (A2A System)
tmux select-pane -t 3  # 右下 (LINE Bridge監視)
```

## 🛑 システム停止

```bash
# tmuxセッションを終了
tmux kill-session -t gpt5-a2a-line

# バックグラウンドプロセスも自動停止されますが、念のため:
pkill -f line_notification_daemon
pkill -f line-to-claude-bridge
pkill -f broker.py
```

## 📖 詳細ドキュメント

- **LINE_NOTIFICATION_ARCHITECTURE.md** - Slack-GitHub統合パターンの完全な解説
- **KABEUCHI_GUIDE.md** - GPT-5との壁打ち方法
- **CLAUDE.md** - システム全体の構成

## 🔍 トラブルシューティング

### 通知が表示されない
```bash
# 1. プロセス確認
ps aux | grep line_notification_daemon

# 2. ログ確認
tail -f /tmp/line_notification_daemon.log

# 3. ZeroMQ接続確認
netstat -an | grep 5556
```

### tmux起動失敗
```bash
# 既存セッション削除してリトライ
tmux kill-session -t gpt5-a2a-line
./start-gpt5-with-a2a.sh
```

## 💡 重要ポイント

1. **右上ペインが通知の要**
   - ZeroMQ PULL socketで常時待機
   - LINE通知が届くと自動的に赤背景で表示
   - Slack-GitHub統合と同じ動作

2. **Claude Code CLIの制約を克服**
   - `line_notification_daemon.py`が独立動作
   - ZeroMQ PUSHでpush型通知
   - ユーザーは何もしなくてよい

3. **1コマンドで全て起動**
   - `./start-gpt5-with-a2a.sh` だけでOK
   - バックグラウンドプロセス + tmux 4ペインが自動構成

## 🎉 これで完璧！

「完璧ちゃうわ！」と言われない、確実なリアルタイム通知システムです。
