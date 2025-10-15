#!/bin/bash
# A2A System Startup Script for Linux
# エージェント間通信システム起動スクリプト

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# .envファイルから環境変数を読み込み
if [ -f "$SCRIPT_DIR/../.env" ]; then
    # シェルスクリプトで安全に.envを読み込む
    set -a
    source "$SCRIPT_DIR/../.env"
    set +a
    echo -e "${GREEN}✅ .envファイルから環境変数を読み込みました${NC}"
fi

# 環境変数チェック
check_api_keys() {
    local missing=0

    if [ -z "$OPENAI_API_KEY" ]; then
        echo -e "${RED}❌ OPENAI_API_KEY が設定されていません${NC}"
        missing=1
    fi

    if [ -z "$XAI_API_KEY" ]; then
        echo -e "${YELLOW}⚠️  XAI_API_KEY が設定されていません（Grok4は動作しません）${NC}"
    fi

    if [ $missing -eq 1 ]; then
        echo ""
        echo "設定方法:"
        echo "  1. $SCRIPT_DIR/../.env ファイルを作成"
        echo "  2. OPENAI_API_KEY=your-key を記載"
        exit 1
    fi
}

# モード解析
MODE="${1:-all}"

case "$MODE" in
    broker)
        echo -e "${BLUE}🚀 ZeroMQ Broker を起動中...${NC}"
        python3 zmq_broker/broker.py
        ;;

    workers)
        echo -e "${BLUE}🚀 Workers を起動中...${NC}"
        python3 workers/gpt5_worker.py &
        python3 workers/grok4_worker.py &
        wait
        ;;

    all)
        check_api_keys

        echo -e "${BLUE}╔═══════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║   A2A System Starting...              ║${NC}"
        echo -e "${BLUE}╚═══════════════════════════════════════╝${NC}"
        echo ""

        # 既存プロセスをクリーンアップ
        pkill -f "broker.py" 2>/dev/null || true
        pkill -f "gpt5_worker.py" 2>/dev/null || true
        pkill -f "grok4_worker.py" 2>/dev/null || true
        pkill -f "orchestrator.py" 2>/dev/null || true
        pkill -f "claude_bridge.py" 2>/dev/null || true
        sleep 1

        # 1. Broker起動（nohupで永続化）
        echo -e "${GREEN}[1/5]${NC} ZeroMQ Broker 起動中..."
        nohup python3 zmq_broker/broker.py > broker.log 2>&1 &
        BROKER_PID=$!
        disown
        sleep 2

        # 2. Orchestrator起動（nohupで永続化）
        echo -e "${GREEN}[2/5]${NC} Orchestrator 起動中..."
        nohup python3 orchestrator/orchestrator.py > orchestrator.log 2>&1 &
        ORCH_PID=$!
        disown
        sleep 1

        # 3. GPT-5 Worker起動（nohupで永続化）
        echo -e "${GREEN}[3/5]${NC} GPT-5 Worker 起動中..."
        nohup python3 workers/gpt5_worker.py > gpt5_worker.log 2>&1 &
        GPT5_PID=$!
        disown
        sleep 1

        # 4. Grok4 Worker起動（nohupで永続化）
        if [ -n "$XAI_API_KEY" ]; then
            echo -e "${GREEN}[4/5]${NC} Grok4 Worker 起動中..."
            nohup python3 workers/grok4_worker.py > grok4_worker.log 2>&1 &
            GROK_PID=$!
            disown
        else
            echo -e "${YELLOW}[4/5]${NC} Grok4 Worker スキップ（APIキー未設定）"
        fi
        sleep 1

        # 5. Claude Bridge起動（nohupで永続化）
        echo -e "${GREEN}[5/5]${NC} Claude Bridge 起動中..."
        nohup python3 bridges/claude_bridge.py > claude_bridge.log 2>&1 &
        BRIDGE_PID=$!
        disown
        sleep 1

        echo ""
        echo -e "${GREEN}✅ A2A System 起動完了！${NC}"
        echo ""
        echo -e "${BLUE}📊 プロセス情報:${NC}"
        echo "  Broker PID: $BROKER_PID"
        echo "  Orchestrator PID: $ORCH_PID"
        echo "  GPT-5 Worker PID: $GPT5_PID"
        [ -n "$GROK_PID" ] && echo "  Grok4 Worker PID: $GROK_PID"
        echo "  Claude Bridge PID: $BRIDGE_PID"
        echo ""
        echo -e "${BLUE}📝 ログファイル:${NC}"
        echo "  tail -f broker.log"
        echo "  tail -f gpt5_worker.log"
        echo "  tail -f claude_bridge.log"
        echo ""
        echo -e "${BLUE}🛑 停止方法:${NC}"
        echo "  ./start_a2a.sh stop"
        echo "  または: pkill -f 'broker.py|gpt5_worker.py|grok4_worker.py|orchestrator.py|claude_bridge.py'"
        echo ""
        echo -e "${GREEN}✅ プロセスは永続化されました（ターミナルを閉じても動作継続）${NC}"
        echo -e "${BLUE}📊 状態確認:${NC}"
        echo "  ps aux | grep -E '(broker|gpt5_worker|claude_bridge)' | grep python"
        echo ""
        ;;

    stop)
        echo -e "${BLUE}🛑 A2A System を停止中...${NC}"
        echo ""

        pkill -f "broker.py" 2>/dev/null && echo "  ✓ Broker 停止"
        pkill -f "gpt5_worker.py" 2>/dev/null && echo "  ✓ GPT-5 Worker 停止"
        pkill -f "grok4_worker.py" 2>/dev/null && echo "  ✓ Grok4 Worker 停止"
        pkill -f "orchestrator.py" 2>/dev/null && echo "  ✓ Orchestrator 停止"
        pkill -f "claude_bridge.py" 2>/dev/null && echo "  ✓ Claude Bridge 停止"

        sleep 1
        echo ""
        echo -e "${GREEN}✅ A2A System 停止完了${NC}"
        ;;

    test)
        echo -e "${BLUE}🧪 テストメッセージを送信中...${NC}"
        python3 test_client.py
        ;;

    *)
        echo "使用方法: $0 [all|broker|workers|test|stop]"
        echo ""
        echo "モード:"
        echo "  all      - 全コンポーネントを起動（デフォルト）"
        echo "  broker   - ブローカーのみ起動"
        echo "  workers  - ワーカーのみ起動"
        echo "  test     - テストメッセージを送信"
        echo "  stop     - 全プロセスを停止"
        exit 1
        ;;
esac
