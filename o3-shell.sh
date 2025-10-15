#!/bin/bash
# O3高度推論エンジン専用シェル
# 多層的推論・矛盾検出・予測分析を担当

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# ヘッダー表示
clear
echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                                ║${NC}"
echo -e "${CYAN}║              ${MAGENTA}🧠 O3 高度推論エンジンシェル${CYAN}                    ║${NC}"
echo -e "${CYAN}║                                                                ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}役割${NC}: 高度な推論と分析を担当する戦略的アドバイザー"
echo ""
echo -e "${BLUE}専門領域${NC}:"
echo "  • 多層的推論（水平・垂直・抽象化）"
echo "  • 矛盾検出と論理的整合性チェック"
echo "  • 予測的分析とリスク評価"
echo "  • パターン認識とベストプラクティス提案"
echo ""
echo -e "${BLUE}使用ツール${NC}:"
echo "  • O3 Search MCP - 専用検索ツール"
echo "  • context7 - 最新ドキュメンテーション参照"
echo "  • serena - セマンティックコード理解・解析"
echo ""
echo -e "${BLUE}メッセージ送信${NC}:"
echo "  ./agent-send.sh president \"【O3より】推論結果: ...\""
echo "  ./agent-send.sh worker3 \"【O3より】代替案を提示します\""
echo ""
echo -e "${BLUE}指示書${NC}: ${GREEN}instructions/o3.md${NC}"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 指示書の自動表示（存在する場合）
if [ -f "$SCRIPT_DIR/instructions/o3.md" ]; then
    echo -e "${BLUE}📋 指示書を読み込んでいます...${NC}"
    echo ""
    # 最初の20行を表示
    head -20 "$SCRIPT_DIR/instructions/o3.md"
    echo ""
    echo -e "${YELLOW}（全文は instructions/o3.md を参照）${NC}"
    echo ""
fi

# インタラクティブシェル起動
echo -e "${GREEN}O3シェルを起動します...${NC}"
echo -e "${YELLOW}⚠️ 注意: japanese-chat-system.sh は使用禁止（定型応答問題のため）${NC}"
echo ""

# 作業ディレクトリに移動
cd "$SCRIPT_DIR"

# Bashシェルを起動（環境変数を設定）
export O3_MODE=true
export AGENT_NAME="O3"
export AGENT_ROLE="高度推論エンジン"
export INSTRUCTIONS_FILE="$SCRIPT_DIR/instructions/o3.md"

exec /bin/bash --rcfile <(cat ~/.bashrc 2>/dev/null || echo ""; cat <<'EOF'
# O3専用プロンプト
PS1='\[\033[0;36m\][O3🧠]\[\033[0m\] \[\033[0;34m\]\w\[\033[0m\] $ '

# エイリアス
alias send-president='./agent-send.sh president'
alias send-worker3='./agent-send.sh worker3'
alias send-grok4='./agent-send.sh grok4'
alias instructions='cat instructions/o3.md | less'

# ウェルカムメッセージ
echo ""
echo "O3シェル起動完了 - 高度推論モード有効"
echo "コマンド例:"
echo "  send-president \"推論結果: ...\"    # PRESIDENTにメッセージ送信"
echo "  instructions                      # 指示書を表示"
EOF
)
