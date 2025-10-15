#!/bin/bash
# Claude Code起動済み環境に GPT-5 + A2A を追加するスクリプト
# 使用方法: Claude Code起動中に別ターミナルで実行

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION_NAME="team-support"

# .envファイルから環境変数を読み込み
if [ -f "$REPO_ROOT/.env" ]; then
    export $(grep -v '^#' "$REPO_ROOT/.env" | xargs)
    echo "✅ .envファイルから環境変数を読み込みました"
fi

# 環境変数チェック
if [ -z "$OPENAI_API_KEY" ]; then
    echo "❌ OPENAI_API_KEYが設定されていません"
    echo ""
    echo "設定方法:"
    echo "  1. $REPO_ROOT/.env ファイルを作成"
    echo "  2. OPENAI_API_KEY=your-key を記載"
    exit 1
fi

# 既存セッション削除
tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true

echo "🚀 チームサポート起動中..."
echo ""
echo "📌 構成:"
echo "  ペイン1: GPT-5 独立チャット"
echo "  ペイン2: A2A システム"
echo ""

# tmux設定を読み込んでセッション作成
tmux new-session -d -s "$SESSION_NAME" -c "$REPO_ROOT"
tmux source-file ~/.tmux.conf 2>/dev/null || true

# ペイン1: GPT-5チャット
tmux send-keys -t "$SESSION_NAME:0.0" "cd $REPO_ROOT" C-m
tmux send-keys -t "$SESSION_NAME:0.0" "echo '🤖 GPT-5 独立チャット起動中...'" C-m
tmux send-keys -t "$SESSION_NAME:0.0" "sleep 1" C-m
tmux send-keys -t "$SESSION_NAME:0.0" "python3 gpt5-chat.py" C-m

# ペイン2: A2Aシステム（下に分割）
tmux split-window -v -t "$SESSION_NAME:0" -c "$REPO_ROOT/a2a_system"
tmux send-keys -t "$SESSION_NAME:0.1" "cd $REPO_ROOT/a2a_system" C-m
tmux send-keys -t "$SESSION_NAME:0.1" "echo '🔧 A2A システム起動中...'" C-m
tmux send-keys -t "$SESSION_NAME:0.1" "sleep 2" C-m
tmux send-keys -t "$SESSION_NAME:0.1" "./start_a2a.sh all" C-m

# レイアウト調整（上60%、下40%）
tmux resize-pane -t "$SESSION_NAME:0.0" -y 60%

# GPT-5チャットペインにフォーカス
tmux select-pane -t "$SESSION_NAME:0.0"

echo ""
echo "✅ チームサポート起動完了！"
echo ""
echo "📺 画面構成:"
echo "  ┌──────────────────┐"
echo "  │  GPT-5 Chat      │ (60%)"
echo "  ├──────────────────┤"
echo "  │  A2A System      │ (40%)"
echo "  └──────────────────┘"
echo ""
echo "📌 操作方法:"
echo "  Ctrl+b → o       : ペイン切り替え"
echo "  Ctrl+b → ↑/↓     : ペイン移動"
echo "  Ctrl+b → d       : デタッチ（バックグラウンド化）"
echo ""
echo "📌 Claude Codeとの連携:"
echo "  - Claude Code は別ターミナルで起動済み"
echo "  - A2A通信: a2a_system/shared/claude_inbox/*.json"
echo "  - GPT-5直接相談: このウィンドウで入力"
echo ""
echo "🔄 再接続:"
echo "  tmux attach -t $SESSION_NAME"
echo ""
echo "🚪 終了:"
echo "  tmux kill-session -t $SESSION_NAME"
echo ""

tmux attach-session -t "$SESSION_NAME"
