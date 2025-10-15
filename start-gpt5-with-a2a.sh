#!/bin/bash
# GPT-5 + A2A + LINE統合起動スクリプト（Slack-GitHub統合パターン対応版）
# 独立tmuxセッション・全プロセスtmux表示 + ZeroMQ PUSH通知システム

REPO_ROOT="/home/planj/Claude-Code-Communication"
SESSION_NAME="gpt5-a2a-line"

echo "=========================================================="
echo "🚀 GPT-5 with A2A + LINE + ZeroMQ通知システム起動"
echo "=========================================================="

# 1. 既存プロセス停止
echo ""
echo "🛑 既存プロセス停止中..."
pkill -f "zmq_broker/broker.py" 2>/dev/null || true
pkill -f "workers/gpt5_worker.py" 2>/dev/null || true
pkill -f "bridges/claude_bridge.py" 2>/dev/null || true
pkill -f "line-to-claude-bridge.py" 2>/dev/null || true
pkill -f "line_message_handler.py" 2>/dev/null || true
pkill -f "gpt5-chat.py" 2>/dev/null || true
pkill -f "line_notification_daemon.py" 2>/dev/null || true
pkill -f "tmux_notification_display.py" 2>/dev/null || true
sleep 2

# 2. LINE Bridge起動（バックグラウンド）
echo ""
echo "📱 LINE Bridge 起動..."
cd /home/planj/claudecode-wind/line-integration
export LINE_CHANNEL_ACCESS_TOKEN='UckUbyqRYPfLGj4XwUer3s8SxNnbGad42z7ZsZK1NLWCBdntbRUir50pzkBGF3zT2gUcnnYJD4tYUdOii/IN/CMAh6ezTi4Yhz0UrNxH+hL1VVdQfcKSEIe6484aWKhmz9Xd9leV2NkS8Fecn6giyQdB04t89/1O/w1cDnyilFU='
export LINE_CHANNEL_SECRET='434a82d0fdbae98118211adf6d90a234'
nohup python3 line-to-claude-bridge.py > /tmp/line_bridge.log 2>&1 &
LINE_BRIDGE_PID=$!
echo "✅ LINE Bridge起動完了 (PID: $LINE_BRIDGE_PID)"
sleep 2

# 3. LINE Message Handler起動（バックグラウンド）
echo ""
echo "📬 LINE Message Handler 起動..."
cd "$REPO_ROOT/a2a_system"
nohup python3 line_message_handler.py > line_message_handler.log 2>&1 &
HANDLER_PID=$!
echo "✅ LINE Message Handler起動完了 (PID: $HANDLER_PID)"
sleep 1

# 3.5. LINE通知デーモン起動（ZeroMQ PUSH送信 - Slack-GitHub統合パターン）
echo ""
echo "🔔 LINE通知デーモン 起動（ZeroMQ PUSH）..."
cd "$REPO_ROOT/a2a_system"
nohup python3 line_notification_daemon.py > /tmp/line_notification_daemon.log 2>&1 &
DAEMON_PID=$!
echo "✅ LINE通知デーモン起動完了 (PID: $DAEMON_PID)"
echo "   ログ: /tmp/line_notification_daemon.log"
sleep 2

# 4. 既存tmuxセッションを削除
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "📺 既存セッション削除: $SESSION_NAME"
    tmux kill-session -t "$SESSION_NAME"
    sleep 1
fi

# 5. 新規tmuxセッション作成（4ペイン: 上2つ + 下2つ）
echo "📺 新規セッション作成: $SESSION_NAME (4ペイン)"
tmux new-session -d -s "$SESSION_NAME" -x 80 -y 40

# 上下分割
tmux split-window -v -t "$SESSION_NAME:0.0"
# 上ペインを左右分割
tmux split-window -h -t "$SESSION_NAME:0.0"
# 下ペインを左右分割
tmux split-window -h -t "$SESSION_NAME:0.2"

# レイアウト調整（均等分割）
tmux select-layout -t "$SESSION_NAME:0" tiled
sleep 1

# 6. GPT-5 Chat起動（左上ペイン）
echo "💬 GPT-5 Chat 起動（左上ペイン）..."
tmux send-keys -t "$SESSION_NAME:0.0" "cd $REPO_ROOT" C-m
sleep 1
tmux send-keys -t "$SESSION_NAME:0.0" "python3 gpt5-chat.py" C-m
sleep 2

# 7. ZeroMQ通知ディスプレイ起動（右上ペイン - Slack-GitHub統合パターン）
echo "🔔 ZeroMQ通知ディスプレイ 起動（右上ペイン）..."
tmux send-keys -t "$SESSION_NAME:0.1" "cd $REPO_ROOT/a2a_system" C-m
sleep 1
tmux send-keys -t "$SESSION_NAME:0.1" "python3 tmux_notification_display.py" C-m
sleep 2

# 8. A2A System一括起動（左下ペイン - Small Team）
echo "📊 A2A Small Team 起動（左下ペイン）..."
tmux send-keys -t "$SESSION_NAME:0.2" "cd $REPO_ROOT/a2a_system" C-m
sleep 1
tmux send-keys -t "$SESSION_NAME:0.2" "./start_small_team.sh" C-m
sleep 3

# 9. LINE通知監視（右下ペイン）
echo "📱 LINE Bridge監視 起動（右下ペイン）..."
tmux send-keys -t "$SESSION_NAME:0.3" "tail -f /tmp/line_bridge.log" C-m
sleep 2

echo ""
echo "=========================================================="
echo "✅ 起動完了 - 4ペイン表示に切り替えます..."
echo "=========================================================="
echo ""
echo "📺 tmuxレイアウト:"
echo "  ┌─────────────────┬─────────────────┐"
echo "  │ GPT-5 Chat      │ 🔔 LINE通知     │ ← ZeroMQ PULL"
echo "  │ (左上)          │ ディスプレイ    │"
echo "  ├─────────────────┼─────────────────┤"
echo "  │ A2A System      │ LINE Bridge監視 │"
echo "  │ (左下)          │ (右下)          │"
echo "  └─────────────────┴─────────────────┘"
echo ""
echo "📱 LINE通知が届くと右上ペインに自動表示されます（Slack-GitHub統合パターン）"
echo ""
echo "🧪 テスト実行: ./test-line-notification.sh"
echo "📖 アーキテクチャ: LINE_NOTIFICATION_ARCHITECTURE.md"
echo ""
sleep 2

# 自動的に4ペイン表示に切り替え
exec tmux attach -t $SESSION_NAME
