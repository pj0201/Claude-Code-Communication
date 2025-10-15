#!/bin/bash
# 完全統一A2Aシステム起動スクリプト
# Broker + Bridge + A2Aエージェント + Claude Code Wrapper を一発起動

REPO_ROOT="/home/planj/Claude-Code-Communication"
A2A_DIR="$REPO_ROOT/a2a_system"

echo "============================================================"
echo "🚀 完全統一A2Aシステム起動"
echo "============================================================"
echo ""

# 作業ディレクトリ移動
cd "$A2A_DIR" || exit 1

# 1. 既存プロセスのクリーンアップ
echo "🧹 既存プロセスのクリーンアップ..."
pkill -f "zmq_broker/broker.py" 2>/dev/null
pkill -f "bridges/claude_bridge.py" 2>/dev/null
pkill -f "claude_code_wrapper.py" 2>/dev/null
pkill -f "workers/gpt5_worker.py" 2>/dev/null
sleep 2
echo "✅ クリーンアップ完了"
echo ""

# 2. Broker起動
echo "📡 Broker起動中..."
python3 zmq_broker/broker.py >> "$A2A_DIR/broker.log" 2>&1 &
BROKER_PID=$!
sleep 2

if ps -p $BROKER_PID > /dev/null 2>&1; then
    echo "✅ Broker起動成功 (PID: $BROKER_PID)"
else
    echo "❌ Broker起動失敗"
    exit 1
fi
echo ""

# 3. Claude Bridge起動
echo "🌉 Claude Bridge起動中..."
python3 bridges/claude_bridge.py >> "$A2A_DIR/claude_bridge.log" 2>&1 &
BRIDGE_PID=$!
sleep 2

if ps -p $BRIDGE_PID > /dev/null 2>&1; then
    echo "✅ Claude Bridge起動成功 (PID: $BRIDGE_PID)"
else
    echo "❌ Claude Bridge起動失敗"
    exit 1
fi
echo ""

# 4. GPT-5 Worker起動
echo "🤖 GPT-5 Worker起動中..."
python3 workers/gpt5_worker.py >> "$A2A_DIR/gpt5_worker.log" 2>&1 &
GPT5_PID=$!
sleep 2

if ps -p $GPT5_PID > /dev/null 2>&1; then
    echo "✅ GPT-5 Worker起動成功 (PID: $GPT5_PID)"
else
    echo "⚠️  GPT-5 Worker起動失敗 (API Key未設定の可能性)"
fi
echo ""

# 5. Claude Code Wrapper起動
echo "🔧 Claude Code Wrapper起動中..."
python3 -u claude_code_wrapper.py >> "$A2A_DIR/claude_code_wrapper.log" 2>&1 &
WRAPPER_PID=$!
sleep 2

if ps -p $WRAPPER_PID > /dev/null 2>&1; then
    echo "✅ Claude Code Wrapper起動成功 (PID: $WRAPPER_PID)"
else
    echo "❌ Claude Code Wrapper起動失敗"
    exit 1
fi
echo ""

# 7. 最終確認
echo "============================================================"
echo "📊 システム状態確認"
echo "============================================================"
echo ""

echo "Broker:"
ps aux | grep "zmq_broker/broker.py" | grep -v grep | awk '{print "  ✓ PID: "$2}' || echo "  ✗ 停止中"

echo ""
echo "Claude Bridge:"
ps aux | grep "bridges/claude_bridge.py" | grep -v grep | awk '{print "  ✓ PID: "$2}' || echo "  ✗ 停止中"

echo ""
echo "GPT-5 Worker:"
ps aux | grep "workers/gpt5_worker.py" | grep -v grep | awk '{print "  ✓ PID: "$2}' || echo "  ✗ 停止中"

echo ""
echo "Claude Code Wrapper:"
ps aux | grep "claude_code_wrapper.py" | grep -v grep | awk '{print "  ✓ PID: "$2}' || echo "  ✗ 停止中"

echo ""
echo "============================================================"
echo "✅ システム起動完了"
echo "============================================================"
echo ""

echo "📋 ログファイル:"
echo "  Broker:  $A2A_DIR/broker.log"
echo "  Bridge:  $A2A_DIR/claude_bridge.log"
echo "  GPT-5:   $A2A_DIR/gpt5_worker.log"
echo "  Wrapper: $A2A_DIR/claude_code_wrapper.log"
echo ""

echo "📌 ログ確認コマンド:"
echo "  tail -f $A2A_DIR/broker.log               # Broker"
echo "  tail -f $A2A_DIR/claude_bridge.log        # Bridge"
echo "  tail -f $A2A_DIR/gpt5_worker.log          # GPT-5"
echo "  tail -f $A2A_DIR/claude_code_wrapper.log  # Wrapper"
echo ""

echo "🛑 停止コマンド:"
echo "  pkill -f 'zmq_broker/broker.py' && pkill -f 'bridges/claude_bridge.py' && pkill -f 'workers/gpt5_worker.py' && pkill -f 'claude_code_wrapper.py'"
echo ""

echo "🧪 テストコマンド:"
echo "  bash $REPO_ROOT/test-claude-code-zmq-notification.sh"
echo ""
