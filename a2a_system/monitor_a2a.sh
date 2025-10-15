#!/bin/bash
# A2A System Lightweight Monitor
# 軽量プロセス監視・自動復旧スクリプト

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_process() {
    local process_name=$1
    pgrep -f "$process_name" > /dev/null 2>&1
    return $?
}

restart_if_needed() {
    local process_name=$1
    local display_name=$2

    if ! check_process "$process_name"; then
        echo -e "${YELLOW}⚠️  $display_name が停止しています。再起動中...${NC}"
        ./start_a2a.sh all
        sleep 5

        if check_process "$process_name"; then
            echo -e "${GREEN}✅ $display_name 再起動成功${NC}"
        else
            echo -e "${RED}❌ $display_name 再起動失敗${NC}"
        fi
        return 1
    fi
    return 0
}

# メイン監視ループ
case "${1:-check}" in
    watch)
        echo -e "${GREEN}🔍 A2A System 継続監視を開始（Ctrl+Cで停止）${NC}"
        echo ""

        while true; do
            all_ok=true

            if ! check_process "broker.py"; then
                echo -e "${YELLOW}⚠️  Broker 停止検出 - システム全体を再起動${NC}"
                ./start_a2a.sh all
                all_ok=false
            elif ! check_process "claude_bridge.py"; then
                echo -e "${YELLOW}⚠️  Claude Bridge 停止検出 - 再起動中${NC}"
                nohup python3 bridges/claude_bridge.py > claude_bridge.log 2>&1 &
                disown
                all_ok=false
            elif ! check_process "gpt5_worker.py"; then
                echo -e "${YELLOW}⚠️  GPT-5 Worker 停止検出 - 再起動中${NC}"
                nohup python3 workers/gpt5_worker.py > gpt5_worker.log 2>&1 &
                disown
                all_ok=false
            fi

            if $all_ok; then
                echo -e "${GREEN}✓${NC} $(date '+%H:%M:%S') - All processes OK"
            fi

            sleep 30  # 30秒ごとにチェック
        done
        ;;

    check)
        echo -e "${GREEN}🔍 A2A System プロセス状態チェック${NC}"
        echo ""

        all_ok=true

        if check_process "broker.py"; then
            echo -e "${GREEN}✓${NC} Broker: 稼働中"
        else
            echo -e "${RED}✗${NC} Broker: 停止"
            all_ok=false
        fi

        if check_process "gpt5_worker.py"; then
            echo -e "${GREEN}✓${NC} GPT-5 Worker: 稼働中"
        else
            echo -e "${RED}✗${NC} GPT-5 Worker: 停止"
            all_ok=false
        fi

        if check_process "claude_bridge.py"; then
            echo -e "${GREEN}✓${NC} Claude Bridge: 稼働中"
        else
            echo -e "${RED}✗${NC} Claude Bridge: 停止"
            all_ok=false
        fi

        echo ""

        if $all_ok; then
            echo -e "${GREEN}✅ 全プロセス正常稼働中${NC}"
            exit 0
        else
            echo -e "${YELLOW}⚠️  停止プロセスあり - 再起動は './start_a2a.sh all'${NC}"
            exit 1
        fi
        ;;

    auto-restart)
        echo -e "${YELLOW}🔄 停止プロセスを自動検出して再起動${NC}"
        echo ""

        needs_full_restart=false

        if ! check_process "broker.py"; then
            needs_full_restart=true
        fi

        if $needs_full_restart; then
            echo -e "${YELLOW}⚠️  Broker停止のため全体再起動${NC}"
            ./start_a2a.sh all
        else
            # 個別プロセス再起動
            if ! check_process "claude_bridge.py"; then
                echo -e "${YELLOW}⚠️  Claude Bridge 再起動中${NC}"
                nohup python3 bridges/claude_bridge.py > claude_bridge.log 2>&1 &
                disown
            fi

            if ! check_process "gpt5_worker.py"; then
                echo -e "${YELLOW}⚠️  GPT-5 Worker 再起動中${NC}"
                nohup python3 workers/gpt5_worker.py > gpt5_worker.log 2>&1 &
                disown
            fi
        fi

        sleep 3
        ./monitor_a2a.sh check
        ;;

    *)
        echo "使用方法: $0 [check|auto-restart|watch]"
        echo ""
        echo "モード:"
        echo "  check        - プロセス状態を確認（デフォルト）"
        echo "  auto-restart - 停止プロセスを自動再起動"
        echo "  watch        - 継続監視モード（30秒ごと）"
        exit 1
        ;;
esac
