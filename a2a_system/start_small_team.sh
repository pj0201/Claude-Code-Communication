#!/bin/bash
# A2A Small Team Startup Script (前景表示版)
# Broker, GPT-5 Worker, Claude Bridgeのみ（Orchestratorなし）

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 色定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   A2A Small Team Starting...          ║${NC}"
echo -e "${BLUE}║   (Broker + GPT-5 + Claude Bridge)    ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════╝${NC}"
echo ""

# 既存プロセスをクリーンアップ
pkill -f "broker.py" 2>/dev/null || true
pkill -f "gpt5_worker.py" 2>/dev/null || true
pkill -f "claude_bridge.py" 2>/dev/null || true
sleep 1

# 1. Broker起動（バックグラウンド）
echo -e "${GREEN}[1/3]${NC} ZeroMQ Broker 起動中..."
nohup python3 zmq_broker/broker.py > broker.log 2>&1 &
BROKER_PID=$!
echo "  ✓ Broker PID: $BROKER_PID"
sleep 2

# 2. GPT-5 Worker起動（バックグラウンド）
echo -e "${GREEN}[2/3]${NC} GPT-5 Worker 起動中..."
nohup python3 workers/gpt5_worker.py > gpt5_worker.log 2>&1 &
GPT5_PID=$!
echo "  ✓ GPT-5 Worker PID: $GPT5_PID"
sleep 2

# 3. Claude Bridge起動（バックグラウンド）
echo -e "${GREEN}[3/3]${NC} Claude Bridge 起動中..."
nohup python3 bridges/claude_bridge.py > claude_bridge.log 2>&1 &
BRIDGE_PID=$!
echo "  ✓ Claude Bridge PID: $BRIDGE_PID"
sleep 2

echo ""
echo -e "${GREEN}✅ A2A Small Team 起動完了！${NC}"
echo ""
echo -e "${BLUE}📊 プロセス情報:${NC}"
echo "  Broker PID: $BROKER_PID"
echo "  GPT-5 Worker PID: $GPT5_PID"
echo "  Claude Bridge PID: $BRIDGE_PID"
echo ""
echo -e "${BLUE}📝 ログ監視:${NC}"
echo "  tail -f broker.log"
echo "  tail -f gpt5_worker.log"
echo "  tail -f claude_bridge.log"
echo ""

# ログを表示し続ける
echo -e "${BLUE}📊 Broker ログ監視開始...${NC}"
echo ""
tail -f broker.log
