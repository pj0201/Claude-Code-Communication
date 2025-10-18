#!/bin/bash
# スモールチーム統合起動スクリプト
# GPT-5 + A2A + LINE連携を1コマンドで起動（4ペイン横1列構成）

REPO_ROOT="/home/planj/Claude-Code-Communication"
A2A_DIR="$REPO_ROOT/a2a_system"
SESSION_NAME="gpt5-a2a-line"

COMMAND="${1:-start}"

if [ "$COMMAND" = "stop" ]; then
    echo "=========================================================="
    echo "🛑 スモールチーム完全停止中..."
    echo "=========================================================="
    echo ""

    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        tmux kill-session -t "$SESSION_NAME"
        echo "  ✓ tmuxセッション停止"
    fi

    pkill -f "broker.py" 2>/dev/null && echo "  ✓ Broker 停止"
    pkill -f "gpt5_worker.py" 2>/dev/null && echo "  ✓ GPT-5 Worker 停止"
    pkill -f "orchestrator.py" 2>/dev/null && echo "  ✓ Orchestrator 停止"
    pkill -f "bridges/claude_bridge.py" 2>/dev/null && echo "  ✓ Claude Bridge 停止"
    pkill -f "github_issue_reader.py" 2>/dev/null && echo "  ✓ GitHub Issue Reader 停止"

    sleep 1
    echo ""
    echo "✅ 全プロセス停止完了"
    exit 0
fi

echo "=========================================================="
echo "🚀 スモールチーム統合起動"
echo "=========================================================="
echo ""

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    tmux kill-session -t "$SESSION_NAME"
    sleep 1
fi

if [ -f "$REPO_ROOT/.env" ]; then
    set -a
    source "$REPO_ROOT/.env"
    set +a
    echo "✅ .envファイル読み込み完了"
fi
echo ""

cd "$A2A_DIR" || exit 1

echo "[1/2] バックエンドシステム起動中..."
echo ""

pkill -f "broker.py" 2>/dev/null && echo "  ✓ Broker 停止" || true
pkill -f "gpt5_worker.py" 2>/dev/null && echo "  ✓ GPT-5 Worker 停止" || true
pkill -f "orchestrator.py" 2>/dev/null && echo "  ✓ Orchestrator 停止" || true
pkill -f "bridges/claude_bridge.py" 2>/dev/null && echo "  ✓ Claude Bridge 停止" || true
pkill -f "github_issue_reader.py" 2>/dev/null && echo "  ✓ GitHub Issue Reader 停止" || true
sleep 2
echo ""

echo "[1/5] 📡 ZeroMQ Broker 起動中..."
python3 zmq_broker/broker.py >> "$A2A_DIR/broker.log" 2>&1 &
BROKER_PID=$!
sleep 2
echo "      ✅ 起動成功 (PID: $BROKER_PID)"
echo ""

echo "[2/5] 🎯 Orchestrator 起動中..."
python3 orchestrator/orchestrator.py >> "$A2A_DIR/orchestrator.log" 2>&1 &
ORCH_PID=$!
sleep 1
echo "      ✅ 起動成功 (PID: $ORCH_PID)"
echo ""

echo "[3/5] 🤖 GPT-5 Worker 起動中..."
if [ -z "$OPENAI_API_KEY" ]; then
    echo "      ⚠️  OPENAI_API_KEY 未設定 - スキップ"
else
    python3 workers/gpt5_worker.py >> "$A2A_DIR/gpt5_worker.log" 2>&1 &
    GPT5_PID=$!
    sleep 1
    echo "      ✅ 起動成功 (PID: $GPT5_PID)"
fi
echo ""

echo "[4/5] 🌉 Claude Bridge 起動中..."
python3 bridges/claude_bridge.py >> "$A2A_DIR/claude_bridge.log" 2>&1 &
BRIDGE_PID=$!
sleep 2
echo "      ✅ 起動成功 (PID: $BRIDGE_PID)"
echo ""

echo "[5/5] 📖 GitHub Issue Reader 起動中..."
python3 github_issue_reader.py >> "$A2A_DIR/github_issue_reader.log" 2>&1 &
ISSUE_READER_PID=$!
sleep 2
echo "      ✅ 起動成功 (PID: $ISSUE_READER_PID)"
echo ""

echo ""
echo "=========================================================="
echo "✅ バックエンド起動完了"
echo "=========================================================="
echo ""

echo "[2/2] tmuxセッション作成中..."
sleep 2

# tmuxセッション作成 - Worker2 で初期化
tmux new-session -d -s "$SESSION_NAME" -n "team" -c "$REPO_ROOT"
tmux send-keys -t "$SESSION_NAME:team.0" "clear; echo '====== Worker2 ======'; claude" C-m

sleep 1

# ペイン分割1 (Worker2 を 1/3、右に 2/3) - 80列→27+53
tmux split-window -h -l 53 -t "$SESSION_NAME:team.0"
sleep 0.5
tmux send-keys -t "$SESSION_NAME:team.1" "cd $REPO_ROOT && clear && echo '====== Worker3 ======' && claude" C-m

sleep 1

# ペイン分割2 (Worker3 を 1/3、GPT-5+Bridge を 1/3) - 53列→27+26
tmux split-window -h -l 26 -t "$SESSION_NAME:team.1"
sleep 0.5
tmux send-keys -t "$SESSION_NAME:team.2" "cd $REPO_ROOT && clear && echo '====== GPT-5 Chat ======' && python3 gpt5-chat.py" C-m

sleep 1

# ペイン分割3 (GPT-5 を 1/6、Bridge を 1/6) - 26列→13+13
tmux split-window -h -l 13 -t "$SESSION_NAME:team.2"
sleep 0.5
tmux send-keys -t "$SESSION_NAME:team.3" "cd $A2A_DIR && clear && echo '====== Bridge ======' && tail -f claude_bridge.log" C-m

echo ""
echo "=========================================================="
echo "✅ スモールチーム起動完了"
echo "=========================================================="
echo ""
echo "📊 tmuxセッション:"
echo "  セッション名: $SESSION_NAME"
echo ""
echo "📺 ペイン構成:"
echo "  ┌──────────┬──────────┬──────────┬──────────┐"
echo "  │ Worker2  │ Worker3  │ GPT-5    │ Bridge   │"
echo "  │ (1/3)    │ (1/3)    │ (1/6)    │ (1/6)    │"
echo "  └──────────┴──────────┴──────────┴──────────┘"
echo ""
echo "🔌 接続方法:"
echo "  tmux attach -t $SESSION_NAME"
echo ""
echo "🛑 停止方法:"
echo "  bash $0 stop"
echo ""
