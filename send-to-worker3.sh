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

# メッセージをWorker3ペインに送信
echo "[Worker2] メッセージ送信: $MESSAGE"
tmux send-keys -t gpt5-a2a-line:0.1 "$MESSAGE"

# 遅延（タイミング調整）
sleep $(echo "scale=3; $DELAY / 1000" | bc)

# エンターキーを送信してメッセージを処理
tmux send-keys -t gpt5-a2a-line:0.1 C-m

echo "[Worker2] エンターキー送信完了。メッセージ処理中..."
