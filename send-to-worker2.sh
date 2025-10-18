#!/bin/bash
# Worker3 → Worker2 メッセージ送信スクリプト
# Worker3 が Worker2（私）に通信する

if [ $# -lt 1 ]; then
    echo "使用方法: $0 \"[メッセージ]\" [遅延ミリ秒（デフォルト: 500）]"
    echo ""
    echo "例:"
    echo "  $0 \"Worker2へのメッセージ\""
    exit 1
fi

MESSAGE="$1"
DELAY="${2:-500}"

# Worker2のペイン（worker2-bridge:0.0）にメッセージを送信
echo "[Worker3] メッセージ送信: $MESSAGE"
tmux send-keys -t worker2-bridge:0.0 "$MESSAGE"

# 遅延 - bc の代わりに python3 を使用
sleep $(python3 -c "print($DELAY / 1000)" 2>/dev/null || echo "0.5")

# エンターキーを送信
tmux send-keys -t worker2-bridge:0.0 C-m

echo "[Worker3] エンターキー送信完了。メッセージ処理中..."
