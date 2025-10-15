#!/bin/bash
# スモールチーム完全起動スクリプト（tmux統合版）
# バックエンド起動 + tmuxで2ペイン（GPT-5ログ + LINE通知ログ）監視

REPO_ROOT="/home/planj/Claude-Code-Communication"
SESSION_NAME="small_team"

# 既存セッション確認
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "⚠️  既存のセッション '$SESSION_NAME' が存在します"
    echo "停止しますか？ (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        tmux kill-session -t "$SESSION_NAME"
        echo "✅ セッション停止完了"
    else
        echo "❌ 起動をキャンセルしました"
        exit 1
    fi
fi

echo "============================================================"
echo "🚀 スモールチーム完全起動"
echo "============================================================"
echo ""
echo "構成:"
echo "  📊 バックエンド: Broker + GPT-5 + Bridge + Wrapper + LINE (自動起動)"
echo "  👁️  監視画面: GPT-5ログ + LINE通知ログ (2ペイン均等)"
echo ""

# 1. バックエンド起動
echo "[1/2] バックエンドシステム起動中..."
bash "$REPO_ROOT/start-small-team-with-line.sh"
if [ $? -ne 0 ]; then
    echo "❌ バックエンド起動失敗"
    exit 1
fi
echo ""

# 2. tmuxセッション作成
echo "[2/2] tmuxセッション作成中..."
sleep 2

# tmuxセッション作成（2ペイン: GPT-5 + LINE通知監視）
tmux new-session -d -s "$SESSION_NAME" -n "monitor"

# 水平分割で2ペイン作成
tmux split-window -h -t "$SESSION_NAME:monitor.0"

# 均等レイアウトに変更
tmux select-layout -t "$SESSION_NAME:monitor" even-horizontal

# ペイン0: GPT-5 Worker ログ監視
tmux send-keys -t "$SESSION_NAME:monitor.0" "cd $REPO_ROOT" C-m
tmux send-keys -t "$SESSION_NAME:monitor.0" "clear" C-m
tmux send-keys -t "$SESSION_NAME:monitor.0" "echo '============================================================'" C-m
tmux send-keys -t "$SESSION_NAME:monitor.0" "echo '🤖 GPT-5 Worker ログ監視'" C-m
tmux send-keys -t "$SESSION_NAME:monitor.0" "echo '============================================================'" C-m
tmux send-keys -t "$SESSION_NAME:monitor.0" "tail -f a2a_system/gpt5_worker.log" C-m

# ペイン1: LINE通知 Wrapper Daemon ログ監視
tmux send-keys -t "$SESSION_NAME:monitor.1" "cd $REPO_ROOT" C-m
tmux send-keys -t "$SESSION_NAME:monitor.1" "clear" C-m
tmux send-keys -t "$SESSION_NAME:monitor.1" "echo '============================================================'" C-m
tmux send-keys -t "$SESSION_NAME:monitor.1" "echo '📱 LINE通知 Wrapper Daemon ログ監視'" C-m
tmux send-keys -t "$SESSION_NAME:monitor.1" "echo '============================================================'" C-m
tmux send-keys -t "$SESSION_NAME:monitor.1" "tail -f a2a_system/claude_code_wrapper.log" C-m

echo ""
echo "============================================================"
echo "✅ スモールチーム起動完了"
echo "============================================================"
echo ""
echo "📊 tmuxセッション:"
echo "  セッション名: $SESSION_NAME"
echo "  ペイン構成: 2ペイン均等レイアウト"
echo "    - ペイン0: GPT-5 Worker ログ (tail -f)"
echo "    - ペイン1: LINE通知 Wrapper ログ (tail -f)"
echo ""
echo "🔌 接続方法:"
echo "  tmux attach -t $SESSION_NAME"
echo ""
echo "🛑 停止方法:"
echo "  1. tmux: tmux kill-session -t $SESSION_NAME"
echo "  2. バックエンド: bash $REPO_ROOT/start-small-team-with-line.sh stop"
echo ""
echo "💡 使い方:"
echo "  1. tmux attach -t $SESSION_NAME でログ監視画面を表示"
echo "  2. LINEから指示送信 → ペイン1でリアルタイム受信表示"
echo "  3. GPT-5が応答 → ペイン0でリアルタイム表示"
echo "  4. 遠隔操作でシステムをコントロール"
echo "============================================================"

# 自動接続
tmux attach -t "$SESSION_NAME"
