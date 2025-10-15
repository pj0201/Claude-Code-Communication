#!/bin/bash
# Claude Code アイドル時フック
# LINEメッセージの自動チェック

FLAG_FILE="/tmp/claude_code_line_notification.flag"

if [ -f "$FLAG_FILE" ]; then
    # フラグファイルが存在する場合、内容を表示
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📬 新しいLINEメッセージがあります"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # JSONをパース
    MESSAGE=$(cat "$FLAG_FILE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('text', ''))" 2>/dev/null)
    USER_ID=$(cat "$FLAG_FILE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('user_id', ''))" 2>/dev/null)

    echo "送信者: $USER_ID"
    echo ""
    echo "内容:"
    echo "$MESSAGE"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # フラグファイルを削除（一度だけ表示）
    rm "$FLAG_FILE"
fi
