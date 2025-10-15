#!/bin/bash
# LINE通知チェック用Hookスクリプト（一本化版）
# user-prompt-submit時に実行
#
# ワークフロー（一本化）:
# LINE Webhook → ZeroMQ Broker → claude_code_wrapper.py → /tmp/claude_code_notification.txt → このhook

trap 'exit 0' ERR

NOTIFICATION_FILE="/tmp/claude_code_notification.txt"

# 通知ファイルの存在と内容をチェック
if [ -f "$NOTIFICATION_FILE" ] && [ -s "$NOTIFICATION_FILE" ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📱 新着LINEメッセージ"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # ファイル内容を表示
    while IFS='=' read -r key value; do
        case "$key" in
            timestamp)
                echo "⏰ $value"
                ;;
            user_id)
                echo "👤 From: $value"
                ;;
            text)
                echo "💬 Message: $value"
                ;;
        esac
    done < "$NOTIFICATION_FILE"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "💡 LINE返信が必要な場合は対応してください"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # 通知ファイルをクリア（既読扱い）
    > "$NOTIFICATION_FILE"
fi

exit 0
