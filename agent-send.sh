#!/bin/bash
# エージェント間通信スクリプト
# 使用方法: ./agent-send.sh [相手] "[メッセージ]"

set -e

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 引数チェック
if [ $# -lt 2 ]; then
    echo -e "${RED}エラー: 引数が不足しています${NC}"
    echo ""
    echo "使用方法:"
    echo "  $0 [相手] \"[メッセージ]\""
    echo ""
    echo "相手の指定:"
    echo "  president  - PRESIDENT（統括責任者）"
    echo "  o3         - O3（高度推論エンジン）"
    echo "  grok4      - GROK4（品質保証AI）"
    echo "  worker2    - WORKER2（サポートエンジニア）"
    echo "  worker3    - WORKER3（メインエンジニア）"
    echo ""
    echo "例:"
    echo "  $0 president \"【Worker3より】実装完了しました\""
    echo "  $0 worker3 \"【PRESIDENTより】次のタスクをお願いします\""
    exit 1
fi

TARGET="$1"
MESSAGE="$2"

# ターゲット判定とtmuxペイン指定
case "$TARGET" in
    president|PRESIDENT)
        TMUX_TARGET="president:0.0"
        TARGET_NAME="PRESIDENT"
        ;;
    o3|O3)
        TMUX_TARGET="multiagent:0.0"
        TARGET_NAME="O3"
        ;;
    grok4|GROK4)
        TMUX_TARGET="multiagent:0.1"
        TARGET_NAME="GROK4"
        ;;
    worker2|WORKER2)
        TMUX_TARGET="multiagent:0.2"
        TARGET_NAME="WORKER2"
        ;;
    worker3|WORKER3)
        TMUX_TARGET="multiagent:0.3"
        TARGET_NAME="WORKER3"
        ;;
    *)
        echo -e "${RED}エラー: 不明な相手 '$TARGET'${NC}"
        echo "有効な相手: president, o3, grok4, worker2, worker3"
        exit 1
        ;;
esac

# tmuxセッション存在確認
SESSION_NAME="${TMUX_TARGET%%:*}"
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo -e "${RED}エラー: tmuxセッション '$SESSION_NAME' が見つかりません${NC}"
    echo "システムが起動しているか確認してください:"
    echo "  ./startup-integrated-system.sh status"
    exit 1
fi

# メッセージ送信
echo -e "${BLUE}メッセージ送信: ${TARGET_NAME}${NC}"
echo "内容: $MESSAGE"

# メッセージを視覚的に表示するためにechoコマンドを送信
tmux send-keys -t "$TMUX_TARGET" "echo ''" C-m
tmux send-keys -t "$TMUX_TARGET" "echo '${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}'" C-m
tmux send-keys -t "$TMUX_TARGET" "echo '${GREEN}📨 受信メッセージ${NC}'" C-m
tmux send-keys -t "$TMUX_TARGET" "echo '$MESSAGE'" C-m
tmux send-keys -t "$TMUX_TARGET" "echo '${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}'" C-m
tmux send-keys -t "$TMUX_TARGET" "echo ''" C-m

echo -e "${GREEN}✓ 送信完了${NC}"
