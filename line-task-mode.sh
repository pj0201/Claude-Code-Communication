#!/bin/bash
# LINEタスクモード切替スクリプト
#
# 使い方:
#   ./line-task-mode.sh start  - LINEタスクモード開始
#   ./line-task-mode.sh stop   - LINEタスクモード終了
#   ./line-task-mode.sh status - 現在のモード確認

LINE_MODE_FLAG="/tmp/line_task_mode_active"
LAST_CHECK_FILE="/tmp/line_last_check_size"

case "$1" in
    start)
        if [ -f "$LINE_MODE_FLAG" ]; then
            echo "⚠️ LINEタスクモードは既に有効です"
        else
            touch "$LINE_MODE_FLAG"
            echo "0" > "$LAST_CHECK_FILE"
            echo "✅ LINEタスクモード開始"
            echo ""
            echo "📱 /tmp/line_bridge.log のモニタリングを開始しました"
            echo "💡 user-prompt-submit時に自動的に新着メッセージをチェックします"
            echo ""
            echo "終了するには: ./line-task-mode.sh stop"
        fi
        ;;

    stop)
        if [ ! -f "$LINE_MODE_FLAG" ]; then
            echo "⚠️ LINEタスクモードは現在無効です"
        else
            rm -f "$LINE_MODE_FLAG" "$LAST_CHECK_FILE"
            echo "🛑 LINEタスクモード終了"
            echo ""
            echo "📱 ログモニタリングを停止しました"
        fi
        ;;

    status)
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📊 LINEタスクモード ステータス"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""

        if [ -f "$LINE_MODE_FLAG" ]; then
            echo "Status: ✅ 有効（モニタリング中）"
            echo ""
            echo "設定:"
            echo "  - フラグファイル: $LINE_MODE_FLAG"
            echo "  - サイズ記録: $LAST_CHECK_FILE"

            if [ -f "$LAST_CHECK_FILE" ]; then
                LAST_SIZE=$(cat "$LAST_CHECK_FILE" 2>/dev/null || echo "0")
                echo "  - 最終チェックサイズ: $LAST_SIZE bytes"
            fi

            echo ""
            echo "監視対象:"
            echo "  - /tmp/line_bridge.log"

            if [ -f "/tmp/line_bridge.log" ]; then
                CURRENT_SIZE=$(stat -f%z "/tmp/line_bridge.log" 2>/dev/null || stat -c%s "/tmp/line_bridge.log" 2>/dev/null)
                echo "  - 現在のログサイズ: $CURRENT_SIZE bytes"
            else
                echo "  - ⚠️ ログファイルが見つかりません"
            fi
        else
            echo "Status: ⭕ 無効（モニタリング停止中）"
            echo ""
            echo "開始するには: ./line-task-mode.sh start"
        fi

        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        ;;

    *)
        echo "使い方: $0 {start|stop|status}"
        echo ""
        echo "コマンド:"
        echo "  start  - LINEタスクモードを開始"
        echo "  stop   - LINEタスクモードを終了"
        echo "  status - 現在のモード状態を確認"
        echo ""
        echo "LINEタスクモードについて:"
        echo "  有効時、user-prompt-submit毎に /tmp/line_bridge.log を"
        echo "  自動チェックし、新着LINEメッセージを通知します。"
        exit 1
        ;;
esac

exit 0
