#!/bin/bash
# Claude Code ZeroMQ通知シミュレーションテスト
# claude_bridge.pyからclaude_codeへQUESTIONメッセージを送信するシミュレーション

REPO_ROOT="/home/planj/Claude-Code-Communication"

echo "🧪 Claude Code ZeroMQ通知テスト"
echo "========================================"
echo ""

# テストメッセージを作成（claude_codeへのQUESTION）
TIMESTAMP=$(date -Iseconds)
TEST_FILE="$REPO_ROOT/a2a_system/shared/claude_inbox/test_claude_code_notification_$(date +%Y%m%d_%H%M%S).json"

cat > "$TEST_FILE" <<EOF
{
  "type": "QUESTION",
  "sender": "claude_bridge",
  "target": "claude_code",
  "question": "【LINE通知テスト】新着LINEメッセージが届きました。\n\nユーザー: テストユーザー\nメッセージ: これはZeroMQ DEALER経由の通知テストです。",
  "line_data": {
    "user_id": "U9048b21670f64b16508f309a73269051",
    "text": "これはZeroMQ DEALER経由の通知テストです。Claude Codeが自律的に受信できるかテスト中。",
    "timestamp": "$TIMESTAMP"
  },
  "reply_to": "line",
  "timestamp": "$TIMESTAMP"
}
EOF

echo "✅ テストメッセージ作成完了"
echo "   ファイル: $(basename $TEST_FILE)"
echo ""

# watchdogトリガー
touch "$TEST_FILE"

echo "⏳ Claude Bridgeが処理してbrokerに送信するのを待機..."
sleep 3

echo ""
echo "📋 Brokerログ確認:"
tail -5 "$REPO_ROOT/a2a_system/broker.log"

echo ""
echo "========================================"
echo "✅ テスト送信完了"
echo ""
echo "📺 claude_code_zmq_client_simulation.py の出力を確認してください"
echo ""
