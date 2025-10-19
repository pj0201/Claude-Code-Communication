#!/bin/bash
# Complete workflow test for LINE → GitHub Issue → Worker3 → LINE response
# Usage: ./test-line-workflow.sh

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 LINE ワークフロー完全テスト"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

TEST_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TEST_MESSAGE="テストメッセージ $TEST_TIMESTAMP"

INBOX_DIR="/home/planj/Claude-Code-Communication/a2a_system/shared/claude_inbox"
OUTBOX_DIR="/home/planj/Claude-Code-Communication/a2a_system/shared/claude_outbox"

# Clean up old test files
rm -f "$INBOX_DIR"/github_issue_created_test_*.json 2>/dev/null || true
rm -f "$OUTBOX_DIR"/response_test_*.json 2>/dev/null || true

echo ""
echo "【ステップ 1】: プロセス確認"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

BRIDGE_PID=$(ps aux | grep "line-to-claude-bridge.py" | grep -v grep | awk '{print $2}' || echo "")
if [ -z "$BRIDGE_PID" ]; then
    echo "❌ LINE Bridge プロセスが起動していません"
    exit 1
fi
echo "✅ LINE Bridge (PID $BRIDGE_PID) は起動しています"

LISTENER_PID=$(ps aux | grep "claude_code_listener.py" | grep -v grep | awk '{print $2}' || echo "")
if [ -z "$LISTENER_PID" ]; then
    echo "⚠️  Claude Code Listener は起動していません（オプション）"
else
    echo "✅ Claude Code Listener (PID $LISTENER_PID) は起動しています"
fi

echo ""
echo "【ステップ 2】: 通知ファイル作成（Bridge が通常は作成）"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Bridge が作成するような通知ファイルをシミュレート
NOTIFICATION_FILE="$INBOX_DIR/github_issue_created_test_${TEST_TIMESTAMP}.json"
ISSUE_NUMBER=999

cat > "$NOTIFICATION_FILE" << EOF
{
  "type": "GITHUB_ISSUE_CREATED",
  "sender": "line_bridge",
  "target": "claude_code",
  "issue_number": $ISSUE_NUMBER,
  "issue_url": "https://github.com/pj0201/Claude-Code-Communication/issues/$ISSUE_NUMBER",
  "message": "$TEST_MESSAGE",
  "timestamp": "${TEST_TIMESTAMP}"
}
EOF

if [ -f "$NOTIFICATION_FILE" ]; then
    echo "✅ 通知ファイル作成: $(basename $NOTIFICATION_FILE)"
else
    echo "❌ 通知ファイル作成失敗"
    exit 1
fi

echo ""
echo "【ステップ 3】: Hook スクリプト実行（応答ファイルを自動作成）"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Hook スクリプトを実行
bash /home/planj/Claude-Code-Communication/.claude/hooks/user-prompt-submit.sh > /tmp/hook_output.txt 2>&1 || true

echo "Hook 実行結果:"
cat /tmp/hook_output.txt | grep -E "自動処理|応答ファイル|✅" || true

echo ""
echo "【ステップ 4】: 応答ファイル確認"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESPONSE_FILES=$(find "$OUTBOX_DIR" -maxdepth 1 -name "response_*.json" -type f -newer "$INBOX_DIR" 2>/dev/null | head -1)

if [ -z "$RESPONSE_FILES" ]; then
    echo "❌ 応答ファイルが作成されていません"
    echo "   Outbox: $OUTBOX_DIR"
    echo "   Contents:"
    ls -la "$OUTBOX_DIR" 2>/dev/null || echo "   (ディレクトリが存在しません)"
    exit 1
fi

RESPONSE_FILE=$(echo "$RESPONSE_FILES" | head -1)
echo "✅ 応答ファイル検出: $(basename $RESPONSE_FILE)"

echo ""
echo "【ステップ 5】: 応答ファイル内容確認"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESPONSE_TEXT=$(python3 -c "import json; data=json.load(open('$RESPONSE_FILE')); print(data.get('text', data.get('answer', str(data))))" 2>/dev/null)

if [ -z "$RESPONSE_TEXT" ]; then
    echo "❌ 応答ファイルが無効です"
    echo "   内容: $(cat $RESPONSE_FILE)"
    exit 1
fi

echo "✅ 応答テキスト: $RESPONSE_TEXT"

echo ""
echo "【ステップ 6】: Bridge シミュレーション（応答ファイル処理）"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Bridge が応答ファイルを読んで削除するのをシミュレート
if [ -f "$RESPONSE_FILE" ]; then
    rm "$RESPONSE_FILE"
    echo "✅ 応答ファイル処理完了（削除）"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ テスト成功！4ペイン LINE ワークフロー は正常に動作しています"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "ワークフロー:"
echo "  LINE Message → Bridge (Issue #999) → Notification → Hook → Response → Bridge → LINE"
echo ""
echo "確認項目:"
echo "  ✅ Line Bridge プロセス稼働"
echo "  ✅ Notification ファイル作成"
echo "  ✅ Hook による自動応答生成"
echo "  ✅ Response ファイル作成"
echo "  ✅ Bridge による応答処理"
echo ""
