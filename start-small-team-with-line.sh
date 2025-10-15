#!/bin/bash
# スモールチーム完全起動スクリプト
# Claude Code + GPT-5 + LINE連携を1コマンドで起動

REPO_ROOT="/home/planj/Claude-Code-Communication"
A2A_DIR="$REPO_ROOT/a2a_system"

# モード解析
MODE="${1:-start}"

if [ "$MODE" = "stop" ]; then
    echo "============================================================"
    echo "🛑 スモールチーム完全停止中..."
    echo "============================================================"
    echo ""
    pkill -f "broker.py" 2>/dev/null && echo "  ✓ Broker 停止"
    pkill -f "gpt5_worker.py" 2>/dev/null && echo "  ✓ GPT-5 Worker 停止"
    pkill -f "orchestrator.py" 2>/dev/null && echo "  ✓ Orchestrator 停止"
    pkill -f "bridges/claude_bridge.py" 2>/dev/null && echo "  ✓ Claude Bridge 停止"
    pkill -f "claude_code_wrapper.py" 2>/dev/null && echo "  ✓ Wrapper 停止"
    # LINE Webhook Server停止（存在する場合）
    pkill -f "line_webhook_server" 2>/dev/null && echo "  ✓ LINE Webhook Server 停止"
    sleep 1
    echo ""
    echo "✅ 全プロセス停止完了"
    exit 0
fi

echo "============================================================"
echo "🚀 スモールチーム完全起動: Claude Code + GPT-5 + LINE"
echo "============================================================"
echo ""

# .envファイル読み込み
if [ -f "$REPO_ROOT/.env" ]; then
    set -a
    source "$REPO_ROOT/.env"
    set +a
    echo "✅ .envファイル読み込み完了"
else
    echo "⚠️  .envファイルが見つかりません"
    echo "   OPENAI_API_KEY と LINE_CHANNEL_ACCESS_TOKEN を設定してください"
fi
echo ""

# 作業ディレクトリ移動
cd "$A2A_DIR" || exit 1

# 既存プロセスのクリーンアップ
echo "🧹 既存プロセスのクリーンアップ..."
pkill -f "broker.py" 2>/dev/null && echo "  ✓ Broker 停止" || true
pkill -f "gpt5_worker.py" 2>/dev/null && echo "  ✓ GPT-5 Worker 停止" || true
pkill -f "orchestrator.py" 2>/dev/null && echo "  ✓ Orchestrator 停止" || true
pkill -f "bridges/claude_bridge.py" 2>/dev/null && echo "  ✓ Claude Bridge 停止" || true
pkill -f "claude_code_wrapper.py" 2>/dev/null && echo "  ✓ Wrapper 停止" || true
sleep 2
echo ""

# === バックエンドシステム起動 ===

# 1. Broker起動
echo "[1/6] 📡 ZeroMQ Broker 起動中..."
python3 zmq_broker/broker.py >> "$A2A_DIR/broker.log" 2>&1 &
BROKER_PID=$!
sleep 2
if ps -p $BROKER_PID > /dev/null 2>&1; then
    echo "      ✅ 起動成功 (PID: $BROKER_PID)"
else
    echo "      ❌ 起動失敗"
    exit 1
fi
echo ""

# 2. Orchestrator起動
echo "[2/6] 🎯 Orchestrator 起動中..."
python3 orchestrator/orchestrator.py >> "$A2A_DIR/orchestrator.log" 2>&1 &
ORCH_PID=$!
sleep 1
if ps -p $ORCH_PID > /dev/null 2>&1; then
    echo "      ✅ 起動成功 (PID: $ORCH_PID)"
else
    echo "      ⚠️  起動失敗（続行します）"
fi
echo ""

# 3. GPT-5 Worker起動
echo "[3/6] 🤖 GPT-5 Worker 起動中..."
if [ -z "$OPENAI_API_KEY" ]; then
    echo "      ⚠️  OPENAI_API_KEY 未設定 - スキップ"
else
    python3 workers/gpt5_worker.py >> "$A2A_DIR/gpt5_worker.log" 2>&1 &
    GPT5_PID=$!
    sleep 1
    if ps -p $GPT5_PID > /dev/null 2>&1; then
        echo "      ✅ 起動成功 (PID: $GPT5_PID)"
    else
        echo "      ❌ 起動失敗"
    fi
fi
echo ""

# 4. Claude Bridge起動
echo "[4/6] 🌉 Claude Bridge 起動中..."
python3 bridges/claude_bridge.py >> "$A2A_DIR/claude_bridge.log" 2>&1 &
BRIDGE_PID=$!
sleep 2
if ps -p $BRIDGE_PID > /dev/null 2>&1; then
    echo "      ✅ 起動成功 (PID: $BRIDGE_PID)"
else
    echo "      ❌ 起動失敗"
    exit 1
fi
echo ""

# 5. Claude Code Wrapper起動
echo "[5/5] 🔧 Claude Code Wrapper 起動中..."
python3 -u claude_code_wrapper.py >> "$A2A_DIR/claude_code_wrapper.log" 2>&1 &
WRAPPER_PID=$!
sleep 2
if ps -p $WRAPPER_PID > /dev/null 2>&1; then
    echo "      ✅ 起動成功 (PID: $WRAPPER_PID)"
else
    echo "      ❌ 起動失敗"
    exit 1
fi
echo ""

# 最終確認
echo "============================================================"
echo "✅ スモールチーム完全起動完了"
echo "============================================================"
echo ""
echo "📊 起動プロセス:"
echo "  [1] Broker          (PID: $BROKER_PID)"
[ -n "$ORCH_PID" ] && echo "  [2] Orchestrator    (PID: $ORCH_PID)"
[ -n "$GPT5_PID" ] && echo "  [3] GPT-5 Worker    (PID: $GPT5_PID)"
echo "  [4] Claude Bridge   (PID: $BRIDGE_PID)"
echo "  [5] Wrapper         (PID: $WRAPPER_PID)"
echo ""
echo "📋 ログファイル:"
echo "  Broker:     $A2A_DIR/broker.log"
[ -n "$GPT5_PID" ] && echo "  GPT-5:      $A2A_DIR/gpt5_worker.log"
echo "  Bridge:     $A2A_DIR/claude_bridge.log"
echo "  Wrapper:    $A2A_DIR/claude_code_wrapper.log"
echo ""
echo "📌 ログ確認コマンド:"
echo "  tail -f $A2A_DIR/claude_code_wrapper.log  # Wrapperログ（LINE通知受信）"
echo "  tail -f $A2A_DIR/gpt5_worker.log          # GPT-5ログ"
echo ""
echo "🛑 停止コマンド:"
echo "  bash $0 stop"
echo ""
echo "🎯 システム構成:"
echo "  ✅ Claude Code (開発者本人) - Claude Code CLI"
echo "  ✅ GPT-5 (壁打ち相手) - A2Aエージェント"
echo "  ✅ LINE連携 - 遠隔操作システム"
echo ""
echo "🧪 テストコマンド:"
echo "  bash $REPO_ROOT/test-claude-code-zmq-notification.sh"
echo "============================================================"
