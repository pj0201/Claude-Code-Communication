#!/bin/bash
# ユーザープロンプト送信時フック（A2A対応版）
# LINE メッセージと GitHub Issue 通知を自動チェック

INBOX_DIR="/home/planj/Claude-Code-Communication/a2a_system/shared/claude_inbox"
OUTBOX_DIR="/home/planj/Claude-Code-Communication/a2a_system/shared/claude_outbox"
LAST_CHECK_FILE="/tmp/claude_last_hook_check"

# 最終チェック時刻を取得（存在しなければ0）
LAST_CHECK=$(cat "$LAST_CHECK_FILE" 2>/dev/null || echo "0")
CURRENT_TIME=$(date +%s)

# 前回のチェックから2秒以上経過している場合のみチェック
if [ $((CURRENT_TIME - LAST_CHECK)) -gt 2 ]; then
    FOUND_MESSAGE=0

    # GitHub Issue Created 通知をチェック（4ペイン対応）
    ISSUE_NOTIF_FILES=$(find "$INBOX_DIR" -maxdepth 1 -name "github_issue_created_*.json" -type f -newer "$LAST_CHECK_FILE" 2>/dev/null)

    if [ ! -z "$ISSUE_NOTIF_FILES" ]; then
        while read -r NOTIF_FILE; do
            if [ -f "$NOTIF_FILE" ]; then
                ISSUE_NUM=$(python3 -c "import sys, json; data=json.load(open('$NOTIF_FILE')); print(data.get('issue_number', 0))" 2>/dev/null)
                ISSUE_MSG=$(python3 -c "import sys, json; data=json.load(open('$NOTIF_FILE')); print(data.get('message', '')[:150])" 2>/dev/null)

                if [ ! -z "$ISSUE_NUM" ]; then
                    echo ""
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    echo "📌 GitHub Issue #$ISSUE_NUM を自動処理"
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    echo "メッセージ: $ISSUE_MSG"
                    echo ""

                    # ★重要★ Outbox に応答ファイルを自動作成（LINE Bridge が監視している）
                    mkdir -p "$OUTBOX_DIR"

                    RESPONSE_FILE="$OUTBOX_DIR/response_auto_$(date +%s).json"

                    # 応答 JSON を作成（LINE Bridge の wait_for_claude_response で受け取る形式）
                    cat > "$RESPONSE_FILE" << 'JSONEOF'
{
  "type": "text",
  "text": "✅ メッセージを受け取りました。処理を開始します。"
}
JSONEOF

                    if [ -f "$RESPONSE_FILE" ]; then
                        echo "✅ 応答ファイル作成: $(basename $RESPONSE_FILE)"
                        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        echo ""
                        FOUND_MESSAGE=1
                    fi
                fi
            fi
        done <<< "$ISSUE_NOTIF_FILES"
    fi

    # LINE 通知をチェック
    FLAG_FILE="/tmp/claude_code_line_notification.flag"
    if [ -f "$FLAG_FILE" ]; then
        TIMESTAMP=$(cat "$FLAG_FILE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('timestamp', 0))" 2>/dev/null)

        if [ "$(echo "$TIMESTAMP > $LAST_CHECK" | bc -l 2>/dev/null || echo "0")" -eq 1 ]; then
            MESSAGE=$(cat "$FLAG_FILE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('text', '')[:200])" 2>/dev/null)

            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "📬 LINEからメッセージがあります"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "$MESSAGE"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            FOUND_MESSAGE=1
        fi
    fi

    # 最終チェック時刻を更新
    echo "$CURRENT_TIME" > "$LAST_CHECK_FILE"
fi
