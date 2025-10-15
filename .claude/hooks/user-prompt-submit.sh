#!/bin/bash
# ユーザープロンプト送信時フック
# LINEメッセージを自動チェック

FLAG_FILE="/tmp/claude_code_line_notification.flag"
LAST_CHECK_FILE="/tmp/claude_last_line_check"

# 最終チェック時刻を取得（存在しなければ0）
LAST_CHECK=$(cat "$LAST_CHECK_FILE" 2>/dev/null || echo "0")
CURRENT_TIME=$(date +%s)

# 前回のチェックから5秒以上経過している場合のみチェック（スパム防止）
if [ $((CURRENT_TIME - LAST_CHECK)) -gt 5 ]; then
    if [ -f "$FLAG_FILE" ]; then
        TIMESTAMP=$(cat "$FLAG_FILE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('timestamp', 0))" 2>/dev/null)

        # フラグファイルのタイムスタンプが最終チェック後の場合のみ表示
        if [ "$(echo "$TIMESTAMP > $LAST_CHECK" | bc -l 2>/dev/null || echo "0")" -eq 1 ]; then
            MESSAGE=$(cat "$FLAG_FILE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('text', '')[:200])" 2>/dev/null)

            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "📬 LINEからメッセージがあります"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "$MESSAGE"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
        fi
    fi

    # 最終チェック時刻を更新
    echo "$CURRENT_TIME" > "$LAST_CHECK_FILE"
fi
