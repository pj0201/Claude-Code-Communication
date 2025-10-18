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
tmux send-keys -t gpt5-a2a-line:0.1 "$MESSAGE" || echo "[エラー] メッセージ送信失敗"

# 遅延（タイミング調整）- bc の代わりに python3 を使用
SLEEP_TIME=$(python3 -c "print($DELAY / 1000)" 2>/dev/null || echo "0.5")
echo "[デバッグ] 遅延時間: ${SLEEP_TIME}秒"
sleep "$SLEEP_TIME"

# エンターキーを送信してメッセージを処理
echo "[デバッグ] エンターキーを送信中..."
tmux send-keys -t gpt5-a2a-line:0.1 Enter || echo "[エラー] エンターキー送信失敗"
echo "[デバッグ] エンターキー送信コマンド実行完了"

echo "[Worker2] メッセージ処理開始"
