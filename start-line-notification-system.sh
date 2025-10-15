#!/bin/bash
# LINE通知システム起動スクリプト（Slack-GitHub統合パターン）
#
# アーキテクチャ:
# LINE Webhook → LINE Bridge → Claude Bridge → notification_line_*.json
#   ↓ (watchdog)
# line_notification_daemon.py
#   ↓ (ZeroMQ PUSH)
# tmux_notification_display.py (tmux別ペイン)
#   ↓ (視覚的通知)
# Claude Code CLI (user-prompt-submit時にhookで確認)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
A2A_DIR="$SCRIPT_DIR/a2a_system"

echo "=========================================="
echo "🚀 LINE通知システム起動"
echo "=========================================="
echo ""

# 既存プロセスチェック
if pgrep -f "tmux_notification_display.py" > /dev/null; then
    echo "⚠️ tmux通知ディスプレイが既に起動しています"
    echo "停止する場合: pkill -f tmux_notification_display"
else
    echo "📺 tmux通知ディスプレイを起動中..."
    cd "$A2A_DIR"
    tmux new-window -n "line-notifications" "python3 tmux_notification_display.py" 2>/dev/null || {
        echo "⚠️ tmuxセッションが見つかりません"
        echo "新しいtmuxセッションを作成して実行してください:"
        echo "  tmux new -s notifications"
        echo "  python3 $A2A_DIR/tmux_notification_display.py"
    }
fi

sleep 2

# デーモンチェック
if pgrep -f "line_notification_daemon.py" > /dev/null; then
    echo "⚠️ LINE通知デーモンが既に起動しています"
    PID=$(pgrep -f "line_notification_daemon.py")
    echo "PID: $PID"
    echo "ログ確認: tail -f /tmp/line_daemon.log"
else
    echo "🔍 LINE通知デーモンを起動中..."
    cd "$A2A_DIR"
    nohup python3 line_notification_daemon.py > /tmp/line_daemon.log 2>&1 &
    DAEMON_PID=$!
    echo "✅ デーモン起動完了 (PID: $DAEMON_PID)"
    echo "ログ: tail -f /tmp/line_daemon.log"
fi

echo ""
echo "=========================================="
echo "✅ LINE通知システム起動完了"
echo "=========================================="
echo ""
echo "📋 確認コマンド:"
echo "  ps aux | grep -E '(line_notification|tmux_notification)'"
echo ""
echo "📺 tmux通知ペインに切り替え:"
echo "  tmux select-window -t line-notifications"
echo ""
echo "🛑 システム停止:"
echo "  pkill -f line_notification_daemon"
echo "  pkill -f tmux_notification_display"
echo ""
echo "🧪 テスト送信:"
echo "  ./test-line-notification.sh"
echo ""
