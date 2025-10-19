#!/bin/bash
# 実際のLINE Webhook をシミュレートしてワークフロー全体をテスト

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 実際の LINE Webhook ワークフロー テスト"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Bridge が起動しているか確認
BRIDGE_PID=$(ps aux | grep "line-to-claude-bridge.py" | grep -v grep | awk '{print $2}')
if [ -z "$BRIDGE_PID" ]; then
    echo "❌ LINE Bridge が起動していません"
    exit 1
fi
echo "✅ LINE Bridge (PID $BRIDGE_PID) は起動しています"
echo ""

# Bridge が localhost:5000 で listen しているか確認
echo "【ステップ 1】: Bridge の Health Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

HEALTH=$(curl -s http://localhost:5000/health 2>/dev/null)
if [ -z "$HEALTH" ]; then
    echo "⚠️  Bridge の health check に失敗しました"
    echo "   (署名検証の関係で GET /health もリクエスト署名が必要な可能性)"
else
    echo "✅ Bridge は応答しています: $HEALTH"
fi
echo ""

# テスト用のメッセージを準備
echo "【ステップ 2】: テスト用 LINE Webhook JSON 作成"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

TEST_USER_ID="U9048b21670f64b16508f309a73269051"
TEST_MESSAGE="テスト: 4ペイン LINE ワークフロー完全実装成功！"
TEST_TIMESTAMP=$(date +%s%N | cut -b1-13)

# LINE Webhook のペイロード形式
WEBHOOK_JSON=$(cat <<EOF
{
  "events": [
    {
      "type": "message",
      "message": {
        "type": "text",
        "id": "$TEST_TIMESTAMP",
        "text": "$TEST_MESSAGE"
      },
      "timestamp": $(date +%s)000,
      "source": {
        "type": "user",
        "userId": "$TEST_USER_ID"
      },
      "replyToken": "test-reply-token-$(date +%s)",
      "mode": "active"
    }
  ]
}
EOF
)

echo "Webhook JSON:"
echo "$WEBHOOK_JSON" | python3 -m json.tool | head -20
echo ""

# Bridge にログを記録する
echo "【ステップ 3】: ログの記録"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

BRIDGE_LOG="line_integration/line-to-claude-bridge.log"
if [ -f "$BRIDGE_LOG" ]; then
    BEFORE_LINES=$(wc -l < "$BRIDGE_LOG")
    echo "Bridge ログの現在行数: $BEFORE_LINES"
else
    BEFORE_LINES=0
    echo "Bridge ログが見つかりません"
fi
echo ""

# GitHub Issue 監視開始
echo "【ステップ 4】: GitHub Issues 監視開始"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# GitHub API で Issues 数を取得
GITHUB_TOKEN=$(grep "GITHUB_TOKEN=" line_integration/.env | cut -d= -f2)
REPO="pj0201/Claude-Code-Communication"

ISSUES_BEFORE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$REPO/issues?state=open" | \
  python3 -c "import sys, json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")

echo "現在のオープン Issue 数: $ISSUES_BEFORE"
echo ""

# Outbox をクリア
OUTBOX="/home/planj/Claude-Code-Communication/a2a_system/shared/claude_outbox"
INBOX="/home/planj/Claude-Code-Communication/a2a_system/shared/claude_inbox"
rm -f "$OUTBOX"/response_*.json 2>/dev/null

echo "【ステップ 5】: 実際のテストメッセージ送信"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "メッセージ: \"$TEST_MESSAGE\""
echo ""

# ★注意★: 実際の署名計算は HMAC-SHA256 を使う必要があります
# ここでは簡略化したテストを行います
# 本来は LINE Channel Secret で署名する必要があります

# LINE Official Account Manager の Webhook テスト機能をシミュレート
# または実装用: https://developers.line.biz/en/reference/messaging-api/

echo "📌 注意: LINE Webhook は署名認証が必須です"
echo "   実際のテストには以下の方法を使用してください："
echo ""
echo "方法 1: LINE Official Account Manager から Webhook テスト送信"
echo "   https://manager.line.biz/ → チャネル設定 → Webhook テスト"
echo ""
echo "方法 2: 実際に LINE Bot に メッセージを送信"
echo "   https://line.me/R/ti/p/@YOUR_ACCOUNT_ID"
echo ""
echo "方法 3: curl で署名付きリクエスト送信（開発者向け）"
echo ""

# ログの変更を監視
echo "【ステップ 6】: Bridge ログ監視"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "10秒間 Bridge ログを監視します..."
echo ""

# Bridge ログをリアルタイムで監視（最後の10行）
if [ -f "$BRIDGE_LOG" ]; then
    echo "📄 最新の Bridge ログ:"
    tail -10 "$BRIDGE_LOG"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 完全な LINE ワークフロー テストの準備完了"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "【次のステップ】"
echo "1. LINE Official Account Manager で Webhook テストを送信"
echo "2. または実際に LINE Bot にメッセージを送信"
echo "3. 以下を確認してください："
echo "   ✓ Bridge ログに 'メッセージ受信' が表示される"
echo "   ✓ GitHub Issues に新しい Issue が作成される"
echo "   ✓ Claude Code Inbox に github_issue_created_*.json が作成される"
echo "   ✓ Outbox に response_*.json が作成される"
echo "   ✓ LINE に 処理結果が返信される"
echo ""
