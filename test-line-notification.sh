#!/bin/bash
# LINE通知システムテストスクリプト
# シミュレーションファイルを作成してZeroMQ PUSH通知をテスト

OUTBOX_DIR="/home/planj/Claude-Code-Communication/a2a_system/shared/claude_outbox"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILENAME="notification_line_TEST_${TIMESTAMP}.json"

echo "🧪 LINE通知システムテスト"
echo "======================================"
echo ""

# テストメッセージ
TEST_MESSAGE="【テスト送信】
これはZeroMQ PUSH通知のテストです。

Slack-GitHub統合パターンの実装により:
1. line_notification_daemon.pyがファイル検知
2. ZeroMQ PUSHでtmux_notification_display.pyに送信
3. tmuxペインに視覚的通知表示
4. Claude Code hookで確認可能

$(date '+%Y-%m-%d %H:%M:%S')"

# JSONファイル作成
cat > "$OUTBOX_DIR/$FILENAME" <<EOF
{
  "type": "LINE_NOTIFICATION",
  "original_message": {
    "user_id": "U9048b21670f64b16508f309a73269051",
    "text": "$TEST_MESSAGE",
    "timestamp": "$(date -Iseconds)"
  },
  "message_id": "test_simulation_$TIMESTAMP",
  "timestamp": "$(date -Iseconds)"
}
EOF

echo "✅ テストファイル作成: $FILENAME"
echo ""
echo "📱 通知ディスプレイを確認してください:"
echo "  tmux select-window -t line-notifications"
echo ""
echo "⏳ 3秒後に結果を確認..."
sleep 3

# ログ確認
echo ""
echo "📋 デーモンログ（最新10行）:"
tail -10 /tmp/line_daemon.log 2>/dev/null || echo "ログファイルが見つかりません"

echo ""
echo "🔍 処理済みファイルチェック:"
if [ -f "$OUTBOX_DIR/read/$FILENAME" ]; then
    echo "✅ ファイルが処理されました: read/$FILENAME"
else
    echo "⚠️ ファイルがまだ処理されていません"
    ls -lh "$OUTBOX_DIR/$FILENAME" 2>/dev/null || echo "ファイルが見つかりません"
fi

echo ""
echo "======================================"
echo "テスト完了"
echo "======================================"
