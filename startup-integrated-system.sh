#!/bin/bash
# Claude-Code-Communication統合システム起動スクリプト
# 5エージェント構成: PRESIDENT, O3, GROK4, WORKER2, WORKER3

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION_PRESIDENT="president"
SESSION_MULTIAGENT="multiagent"

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ヘルプ表示
show_help() {
    echo -e "${BLUE}=== Claude-Code-Communication 統合システム起動スクリプト ===${NC}"
    echo ""
    echo "使用方法:"
    echo "  $0 [コマンド]"
    echo ""
    echo "コマンド:"
    echo "  5agents    - 5エージェント構成で起動（PRESIDENT + O3 + GROK4 + WORKER2 + WORKER3）"
    echo "  status     - システム状態確認"
    echo "  stop       - システム停止"
    echo "  help       - このヘルプを表示"
    echo ""
    echo "例:"
    echo "  $0 5agents    # 5エージェント起動"
    echo "  $0 status     # 状態確認"
    echo "  $0 stop       # 停止"
}

# システム状態確認
check_status() {
    echo -e "${BLUE}=== システム状態確認 ===${NC}"
    echo ""

    # A2Aシステム確認
    echo -e "${BLUE}📡 A2Aシステム:${NC}"
    local a2a_running=0

    if pgrep -f "broker.py" > /dev/null; then
        echo -e "  ${GREEN}✓${NC} Broker: 稼働中"
        ((a2a_running++))
    else
        echo -e "  ${RED}✗${NC} Broker: 停止中"
    fi

    if pgrep -f "orchestrator.py" > /dev/null; then
        echo -e "  ${GREEN}✓${NC} Orchestrator: 稼働中"
        ((a2a_running++))
    else
        echo -e "  ${RED}✗${NC} Orchestrator: 停止中"
    fi

    if pgrep -f "gpt5_worker.py" > /dev/null; then
        echo -e "  ${GREEN}✓${NC} GPT-5 Worker: 稼働中"
        ((a2a_running++))
    else
        echo -e "  ${RED}✗${NC} GPT-5 Worker: 停止中"
    fi

    if pgrep -f "grok4_worker.py" > /dev/null; then
        echo -e "  ${GREEN}✓${NC} Grok4 Worker: 稼働中"
        ((a2a_running++))
    else
        echo -e "  ${YELLOW}⚠${NC} Grok4 Worker: 停止中（APIキー未設定の可能性）"
    fi

    if pgrep -f "claude_bridge.py" > /dev/null; then
        echo -e "  ${GREEN}✓${NC} Claude Bridge: 稼働中"
        ((a2a_running++))
    else
        echo -e "  ${RED}✗${NC} Claude Bridge: 停止中"
    fi

    if [ $a2a_running -ge 3 ]; then
        echo -e "  ${GREEN}→ A2Aシステム: 正常稼働${NC}"
    else
        echo -e "  ${YELLOW}→ A2Aシステム: 部分稼働または停止${NC}"
    fi

    echo ""

    # PRESIDENTセッション
    echo -e "${BLUE}👥 エージェント:${NC}"
    if tmux has-session -t "$SESSION_PRESIDENT" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} PRESIDENT: 稼働中"
    else
        echo -e "  ${RED}✗${NC} PRESIDENT: 停止中"
    fi

    # MULTIAGENTセッション
    if tmux has-session -t "$SESSION_MULTIAGENT" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} MULTIAGENT: 稼働中"
        echo "    - O3 (multiagent:0.0)"
        echo "    - GROK4 (multiagent:0.1)"
        echo "    - WORKER2 (multiagent:0.2)"
        echo "    - WORKER3 (multiagent:0.3)"
    else
        echo -e "  ${RED}✗${NC} MULTIAGENT: 停止中"
    fi

    echo ""
    echo -e "${BLUE}📌 接続方法:${NC}"
    echo "  tmux attach -t $SESSION_PRESIDENT    # PRESIDENT"
    echo "  tmux attach -t $SESSION_MULTIAGENT   # O3 + GROK4 + WORKER×2"
    echo ""
    echo -e "${BLUE}📌 ログ確認:${NC}"
    echo "  tail -f /tmp/a2a-system.log          # A2Aシステム"
}

# システム停止
stop_system() {
    echo -e "${YELLOW}=== システム停止 ===${NC}"
    echo ""

    # tmuxセッション停止
    if tmux has-session -t "$SESSION_PRESIDENT" 2>/dev/null; then
        echo "PRESIDENTセッションを停止..."
        tmux kill-session -t "$SESSION_PRESIDENT"
        echo -e "${GREEN}✓ PRESIDENT停止完了${NC}"
    fi

    if tmux has-session -t "$SESSION_MULTIAGENT" 2>/dev/null; then
        echo "MULTIAGENTセッションを停止..."
        tmux kill-session -t "$SESSION_MULTIAGENT"
        echo -e "${GREEN}✓ MULTIAGENT停止完了${NC}"
    fi

    # A2Aシステム停止
    echo ""
    echo "A2Aシステムを停止..."
    pkill -f "broker.py" 2>/dev/null && echo "  ✓ Broker停止" || true
    pkill -f "gpt5_worker.py" 2>/dev/null && echo "  ✓ GPT-5 Worker停止" || true
    pkill -f "grok4_worker.py" 2>/dev/null && echo "  ✓ Grok4 Worker停止" || true
    pkill -f "orchestrator.py" 2>/dev/null && echo "  ✓ Orchestrator停止" || true
    pkill -f "claude_bridge.py" 2>/dev/null && echo "  ✓ Claude Bridge停止" || true
    echo -e "${GREEN}✓ A2Aシステム停止完了${NC}"

    echo ""
    echo -e "${GREEN}全システム停止完了${NC}"
}

# 5エージェント起動
start_5agents() {
    echo -e "${BLUE}=== 5エージェント構成で起動 ===${NC}"
    echo ""

    # A2Aシステム起動
    echo -e "${BLUE}[ステップ1/2]${NC} A2Aシステムを起動..."
    cd "$SCRIPT_DIR/a2a_system"

    # 既存A2Aプロセスをクリーンアップ
    pkill -f "broker.py" 2>/dev/null || true
    pkill -f "gpt5_worker.py" 2>/dev/null || true
    pkill -f "grok4_worker.py" 2>/dev/null || true
    pkill -f "orchestrator.py" 2>/dev/null || true
    pkill -f "claude_bridge.py" 2>/dev/null || true
    sleep 1

    # A2Aシステム起動
    ./start_a2a.sh all > /tmp/a2a-system.log 2>&1 &
    A2A_PID=$!
    sleep 3

    if ps -p $A2A_PID > /dev/null 2>&1; then
        echo -e "${GREEN}✓ A2Aシステム起動完了 (PID: $A2A_PID)${NC}"
        echo "  ログ: /tmp/a2a-system.log"
    else
        echo -e "${YELLOW}⚠ A2Aシステムの起動に問題がありますが続行します${NC}"
    fi

    cd "$SCRIPT_DIR"
    echo ""

    # エージェント起動
    echo -e "${BLUE}[ステップ2/2]${NC} 5エージェントを起動..."
    echo ""

    # 既存セッションチェック
    if tmux has-session -t "$SESSION_PRESIDENT" 2>/dev/null; then
        echo -e "${YELLOW}警告: PRESIDENTセッションが既に存在します${NC}"
        read -p "停止して再起動しますか？ (y/N): " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            tmux kill-session -t "$SESSION_PRESIDENT"
        else
            echo "起動をキャンセルしました"
            exit 1
        fi
    fi

    if tmux has-session -t "$SESSION_MULTIAGENT" 2>/dev/null; then
        echo -e "${YELLOW}警告: MULTIAGENTセッションが既に存在します${NC}"
        read -p "停止して再起動しますか？ (y/N): " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            tmux kill-session -t "$SESSION_MULTIAGENT"
        else
            echo "起動をキャンセルしました"
            exit 1
        fi
    fi

    # PRESIDENTセッション作成
    echo "PRESIDENTセッションを作成..."
    tmux new-session -d -s "$SESSION_PRESIDENT" -n "president"
    tmux send-keys -t "$SESSION_PRESIDENT:0.0" "cd $SCRIPT_DIR" C-m
    tmux send-keys -t "$SESSION_PRESIDENT:0.0" "echo '=== PRESIDENT統括責任者シェル ==='" C-m
    tmux send-keys -t "$SESSION_PRESIDENT:0.0" "echo '指示書: instructions/president.md'" C-m
    tmux send-keys -t "$SESSION_PRESIDENT:0.0" "echo 'メッセージ送信: ./agent-send.sh [相手] \"[メッセージ]\"'" C-m
    echo -e "${GREEN}✓ PRESIDENT起動完了${NC}"

    # MULTIAGENTセッション作成（4ペイン構成）
    echo "MULTIAGENTセッションを作成..."
    tmux new-session -d -s "$SESSION_MULTIAGENT" -n "agents"

    # ペイン分割（2x2グリッド）
    tmux split-window -h -t "$SESSION_MULTIAGENT:0.0"
    tmux split-window -v -t "$SESSION_MULTIAGENT:0.0"
    tmux split-window -v -t "$SESSION_MULTIAGENT:0.1"

    # O3シェル起動（ペイン0）
    echo "O3を起動..."
    tmux send-keys -t "$SESSION_MULTIAGENT:0.0" "cd $SCRIPT_DIR" C-m
    if [ -f "$SCRIPT_DIR/o3-shell.sh" ]; then
        tmux send-keys -t "$SESSION_MULTIAGENT:0.0" "./o3-shell.sh" C-m
    else
        tmux send-keys -t "$SESSION_MULTIAGENT:0.0" "echo '=== O3高度推論エンジン ==='" C-m
        tmux send-keys -t "$SESSION_MULTIAGENT:0.0" "echo '指示書: instructions/o3.md'" C-m
        tmux send-keys -t "$SESSION_MULTIAGENT:0.0" "echo 'o3-shell.shが見つかりません'" C-m
    fi

    # GROK4シェル起動（ペイン1）
    echo "GROK4を起動..."
    tmux send-keys -t "$SESSION_MULTIAGENT:0.1" "cd $SCRIPT_DIR" C-m
    if [ -f "$SCRIPT_DIR/grok4-shell.sh" ]; then
        tmux send-keys -t "$SESSION_MULTIAGENT:0.1" "./grok4-shell.sh" C-m
    else
        tmux send-keys -t "$SESSION_MULTIAGENT:0.1" "echo '=== GROK4品質保証AI ==='" C-m
        tmux send-keys -t "$SESSION_MULTIAGENT:0.1" "echo '指示書: instructions/grok4.md'" C-m
        tmux send-keys -t "$SESSION_MULTIAGENT:0.1" "echo 'grok4-shell.shが見つかりません'" C-m
    fi

    # WORKER2起動（ペイン2）
    echo "WORKER2を起動..."
    tmux send-keys -t "$SESSION_MULTIAGENT:0.2" "cd $SCRIPT_DIR" C-m
    tmux send-keys -t "$SESSION_MULTIAGENT:0.2" "echo '=== WORKER2サポートエンジニア ==='" C-m
    tmux send-keys -t "$SESSION_MULTIAGENT:0.2" "echo '指示書: instructions/worker.md'" C-m
    tmux send-keys -t "$SESSION_MULTIAGENT:0.2" "echo 'メッセージ送信: ./agent-send.sh [相手] \"[メッセージ]\"'" C-m

    # WORKER3起動（ペイン3）
    echo "WORKER3を起動..."
    tmux send-keys -t "$SESSION_MULTIAGENT:0.3" "cd $SCRIPT_DIR" C-m
    tmux send-keys -t "$SESSION_MULTIAGENT:0.3" "echo '=== WORKER3メインエンジニア（ultrathink搭載） ==='" C-m
    tmux send-keys -t "$SESSION_MULTIAGENT:0.3" "echo '指示書: instructions/worker.md'" C-m
    tmux send-keys -t "$SESSION_MULTIAGENT:0.3" "echo '環境変数: worker3-env/'" C-m
    tmux send-keys -t "$SESSION_MULTIAGENT:0.3" "echo 'メッセージ送信: ./agent-send.sh [相手] \"[メッセージ]\"'" C-m

    echo -e "${GREEN}✓ MULTIAGENT起動完了${NC}"

    echo ""
    echo -e "${GREEN}=== 全システム起動完了 ===${NC}"
    echo ""
    echo -e "${BLUE}📌 起動済みシステム:${NC}"
    echo "  ✓ A2Aシステム（相互通信基盤）"
    echo "  ✓ PRESIDENT（統括責任者）"
    echo "  ✓ O3（高度推論エンジン）"
    echo "  ✓ GROK4（品質保証AI）"
    echo "  ✓ WORKER2（サポートエンジニア）"
    echo "  ✓ WORKER3（メインエンジニア）"
    echo ""
    echo -e "${BLUE}📌 接続方法:${NC}"
    echo "  tmux attach -t $SESSION_PRESIDENT    # PRESIDENT"
    echo "  tmux attach -t $SESSION_MULTIAGENT   # O3 + GROK4 + WORKER×2"
    echo ""
    echo -e "${BLUE}📌 A2A通信:${NC}"
    echo "  ログ確認: tail -f /tmp/a2a-system.log"
    echo "  状態確認: $0 status"
    echo ""
    echo -e "${BLUE}📌 停止方法:${NC}"
    echo "  $0 stop"
}

# メイン処理
case "${1:-}" in
    5agents)
        start_5agents
        ;;
    status)
        check_status
        ;;
    stop)
        stop_system
        ;;
    help|--help|-h|"")
        show_help
        ;;
    *)
        echo -e "${RED}エラー: 不明なコマンド '$1'${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
