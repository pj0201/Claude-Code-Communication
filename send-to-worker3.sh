#!/bin/bash
# Worker2 → Worker3 通信スクリプト
# メッセージ送信 + エンターキー実行

if [ $# -lt 1 ]; then
    echo "使用方法: $0 \"[メッセージ]\" [遅延ミリ秒（デフォルト: 500)]"
    echo ""
    echo "例:"
    echo "  $0 \"テストメッセージ\""
    echo "  $0 \"緊急タスク\" 1000"
    exit 1
fi

MESSAGE="$1"
DELAY="${2:-500}"

# メッセージをペイントに送信してからエンターキーを送信
# （C-m を C-m として認識させるため分離）
tmux send-keys -t gpt5-a2a-line:0.1 -l "$MESSAGE"
tmux send-keys -t gpt5-a2a-line:0.1 C-m

echo "[Worker2] → Worker3 メッセージ送信完了"
