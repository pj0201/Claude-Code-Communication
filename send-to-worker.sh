#!/bin/bash
# Worker への通信スクリプト - エンター自動付き
# 使用方法: ./send-to-worker.sh [0-3] "[メッセージ]"

PANE_NUM="$1"
MESSAGE="$2"

if [ -z "$PANE_NUM" ] || [ -z "$MESSAGE" ]; then
    echo "使用方法: $0 [0-3] \"[メッセージ]\""
    echo ""
    echo "ペイン番号："
    echo "  0 = Claude Code"
    echo "  1 = Worker3"
    echo "  2 = GPT-5"
    echo "  3 = Bridge"
    exit 1
fi

# ペイン確認
if ! tmux has-session -t "gpt5-a2a-line" 2>/dev/null; then
    echo "エラー: tmux セッション 'gpt5-a2a-line' が見つかりません"
    exit 1
fi

# メッセージ送信（エンター必須）
tmux send-keys -t "gpt5-a2a-line:team.$PANE_NUM" "$MESSAGE" C-m

echo "✅ ペイン$PANE_NUM に送信完了（エンター付き）"
