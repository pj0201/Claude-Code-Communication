#!/bin/bash
# 統合システム起動スクリプト
# A2A System + LINE Bridge + Claude Code Wrapper を一発起動

REPO_ROOT="/home/planj/Claude-Code-Communication"
A2A_DIR="$REPO_ROOT/a2a_system"
WRAPPER_LOG="$A2A_DIR/claude_code_wrapper.log"
BRIDGE_LOG="$A2A_DIR/claude_bridge.log"
BROKER_LOG="$A2A_DIR/broker.log"
GPT5_LOG="$A2A_DIR/gpt5_worker.log"
GROK4_LOG="$A2A_DIR/grok4_worker.log"
LINE_DAEMON_LOG="$A2A_DIR/line_daemon.log"

# モード解析
MODE="${1:-start}"

if [ "$MODE" = "stop" ]; then
    echo "============================================================"
    echo "🛑 統合システム停止中..."
    echo "============================================================"
    echo ""
    pkill -f "broker.py" 2>/dev/null && echo "  ✓ Broker 停止"
    pkill -f "gpt5_worker.py" 2>/dev/null && echo "  ✓ GPT-5 Worker 停止"
    pkill -f "orchestrator.py" 2>/dev/null && echo "  ✓ Orchestrator 停止"
    pkill -f "bridges/claude_bridge.py" 2>/dev/null && echo "  ✓ Claude Bridge 停止"
    pkill -f "claude_code_wrapper.py" 2>/dev/null && echo "  ✓ Wrapper 停止"
    pkill -f "line_notification_daemon.py" 2>/dev/null && echo "  ✓ LINE Daemon 停止"
    sleep 1
    echo ""
    echo "✅ 全プロセス停止完了"
    exit 0
fi

echo "============================================================"
echo "🚀 統合システム起動: A2A + LINE + Claude Code Wrapper"
echo "============================================================"
echo ""

# 0. .envファイル読み込み
if [ -f "$REPO_ROOT/.env" ]; then
    set -a
    source "$REPO_ROOT/.env"
    set +a
    echo "✅ .envファイル読み込み完了"
else
    echo "⚠️  .envファイルが見つかりません"
    echo "   OPENAI_API_KEY と XAI_API_KEY を設定してください"
fi
echo ""

# 作業ディレクトリ移動
cd "$A2A_DIR" || exit 1

# 1. 既存の全プロセスをクリーンアップ
echo "🧹 既存プロセスのクリーンアップ..."
pkill -f "broker.py" 2>/dev/null && echo "  ✓ Broker 停止" || true
pkill -f "gpt5_worker.py" 2>/dev/null && echo "  ✓ GPT-5 Worker 停止" || true
pkill -f "orchestrator.py" 2>/dev/null && echo "  ✓ Orchestrator 停止" || true
pkill -f "bridges/claude_bridge.py" 2>/dev/null && echo "  ✓ Claude Bridge 停止" || true
pkill -f "claude_code_wrapper.py" 2>/dev/null && echo "  ✓ Wrapper 停止" || true
pkill -f "line_notification_daemon.py" 2>/dev/null && echo "  ✓ LINE Daemon 停止" || true
sleep 2
echo ""

# 2. Broker起動
echo "[1/7] 📡 ZeroMQ Broker 起動中..."
python3 zmq_broker/broker.py >> "$BROKER_LOG" 2>&1 &
BROKER_PID=$!
sleep 2
if ps -p $BROKER_PID > /dev/null 2>&1; then
    echo "      ✅ 起動成功 (PID: $BROKER_PID)"
else
    echo "      ❌ 起動失敗"
    exit 1
fi
echo ""

# 3. Orchestrator起動
echo "[2/7] 🎯 Orchestrator 起動中..."
python3 orchestrator/orchestrator.py >> "$A2A_DIR/orchestrator.log" 2>&1 &
ORCH_PID=$!
sleep 1
if ps -p $ORCH_PID > /dev/null 2>&1; then
    echo "      ✅ 起動成功 (PID: $ORCH_PID)"
else
    echo "      ⚠️  起動失敗（続行します）"
fi
echo ""

# 4. GPT-5 Worker起動
echo "[3/7] 🤖 GPT-5 Worker 起動中..."
if [ -z "$OPENAI_API_KEY" ]; then
    echo "      ⚠️  OPENAI_API_KEY 未設定 - スキップ"
else
    python3 workers/gpt5_worker.py >> "$GPT5_LOG" 2>&1 &
    GPT5_PID=$!
    sleep 1
    if ps -p $GPT5_PID > /dev/null 2>&1; then
        echo "      ✅ 起動成功 (PID: $GPT5_PID)"
    else
        echo "      ❌ 起動失敗"
    fi
fi
echo ""


# 6. LINE Notification Daemon起動
echo "[5/7] 📱 LINE Notification Daemon 起動中..."
if [ -f "line_notification_daemon.py" ]; then
    python3 line_notification_daemon.py >> "$LINE_DAEMON_LOG" 2>&1 &
    LINE_PID=$!
    sleep 1
    if ps -p $LINE_PID > /dev/null 2>&1; then
        echo "      ✅ 起動成功 (PID: $LINE_PID)"
    else
        echo "      ⚠️  起動失敗（続行します）"
    fi
else
    echo "      ⚠️  line_notification_daemon.py が見つかりません - スキップ"
fi
echo ""

# 7. Claude Bridge起動
echo "[6/7] 🌉 Claude Bridge 起動中..."
python3 bridges/claude_bridge.py >> "$BRIDGE_LOG" 2>&1 &
BRIDGE_PID=$!
sleep 2
if ps -p $BRIDGE_PID > /dev/null 2>&1; then
    echo "      ✅ 起動成功 (PID: $BRIDGE_PID)"
else
    echo "      ❌ 起動失敗"
    exit 1
fi
echo ""

# 8. Claude Code Wrapper起動
echo "[7/7] 🔧 Claude Code Wrapper 起動中..."
python3 -u claude_code_wrapper.py >> "$WRAPPER_LOG" 2>&1 &
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
echo "✅ 統合システム起動完了"
echo "============================================================"
echo ""
echo "📊 起動プロセス（スモールチーム構成）:"
echo "  [1] Broker          (PID: $BROKER_PID)"
[ -n "$ORCH_PID" ] && echo "  [2] Orchestrator    (PID: $ORCH_PID)"
[ -n "$GPT5_PID" ] && echo "  [3] GPT-5 Worker    (PID: $GPT5_PID)"
[ -n "$LINE_PID" ] && echo "  [4] LINE Daemon     (PID: $LINE_PID)"
echo "  [5] Claude Bridge   (PID: $BRIDGE_PID)"
echo "  [6] Wrapper         (PID: $WRAPPER_PID)"
echo ""
echo "📋 ログファイル:"
echo "  Broker:     $BROKER_LOG"
[ -n "$GPT5_PID" ] && echo "  GPT-5:      $GPT5_LOG"
[ -n "$LINE_PID" ] && echo "  LINE:       $LINE_DAEMON_LOG"
echo "  Bridge:     $BRIDGE_LOG"
echo "  Wrapper:    $WRAPPER_LOG"
echo ""
echo "📌 ログ確認コマンド:"
echo "  tail -f $WRAPPER_LOG    # Wrapperログ（LINE通知受信）"
echo "  tail -f $BRIDGE_LOG     # Bridgeログ"
echo "  tail -f $GPT5_LOG       # GPT-5ログ"
echo ""
echo "🛑 停止コマンド:"
echo "  bash $REPO_ROOT/start-claude-code-zmq-wrapper.sh stop"
echo ""
echo "🎯 次のステップ:"
echo "  1. tmuxでClaude Code CLIペインを起動"
echo "  2. LINEからメッセージ送信"
echo "  3. Wrapperが自律的に検知してログに記録"
echo "============================================================"
