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
tmux send-keys -t worker2-bridge:0.0 "$MESSAGE" || echo "[エラー] メッセージ送信失敗"

# 遅延 - bc の代わりに python3 を使用
SLEEP_TIME=$(python3 -c "print($DELAY / 1000)" 2>/dev/null || echo "0.5")
echo "[デバッグ] 遅延時間: ${SLEEP_TIME}秒"
sleep "$SLEEP_TIME"

# エンターキーを送信
echo "[デバッグ] エンターキーを送信中..."
tmux send-keys -t worker2-bridge:0.0 Enter || echo "[エラー] エンターキー送信失敗"
echo "[デバッグ] エンターキー送信コマンド実行完了"

echo "[Worker3] メッセージ処理開始"
