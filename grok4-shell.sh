#!/bin/bash
# GROK4品質保証AI専用シェル
# コードレビュー・テスト設計・品質保証を担当

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
echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║                                                                ║${NC}"
echo -e "${MAGENTA}║            ${CYAN}🔍 GROK4 品質保証AIシェル${MAGENTA}                       ║${NC}"
echo -e "${MAGENTA}║                                                                ║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}役割${NC}: 品質保証・テスト設計・コードレビュー・xAI独自視点"
echo ""
echo -e "${BLUE}専門領域${NC}:"
echo "  • コードレビューと品質評価"
echo "  • テストケース設計とカバレッジ分析"
echo "  • セキュリティ脆弱性検出"
echo "  • セカンドオピニオン提供"
echo ""
echo -e "${BLUE}使用ツール${NC}:"
echo "  • grok-cli - xAI Grokモデル専用インターフェース（必須）"
echo "  • context7 - 最新ドキュメンテーション参照"
echo "  • serena - セマンティックコード理解・解析"
echo ""
echo -e "${BLUE}メッセージ送信${NC}:"
echo "  ./agent-send.sh president \"【GROK4より】品質評価結果: ...\""
echo "  ./agent-send.sh worker3 \"【GROK4より】改善提案があります\""
echo ""
echo -e "${BLUE}指示書${NC}: ${GREEN}instructions/grok4.md${NC}"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 指示書の自動表示（存在する場合）
if [ -f "$SCRIPT_DIR/instructions/grok4.md" ]; then
    echo -e "${BLUE}📋 指示書を読み込んでいます...${NC}"
    echo ""
    # 最初の20行を表示
    head -20 "$SCRIPT_DIR/instructions/grok4.md"
    echo ""
    echo -e "${YELLOW}（全文は instructions/grok4.md を参照）${NC}"
    echo ""
fi

# grok-cliの存在確認
if [ -d "$SCRIPT_DIR/grok-cli" ]; then
    echo -e "${GREEN}✓ grok-cli検出: $SCRIPT_DIR/grok-cli${NC}"
else
    echo -e "${YELLOW}⚠️ grok-cliが見つかりません: $SCRIPT_DIR/grok-cli${NC}"
    echo -e "${YELLOW}   grok-cliのセットアップが必要な場合があります${NC}"
fi

# インタラクティブシェル起動
echo ""
echo -e "${GREEN}GROK4シェルを起動します...${NC}"
echo -e "${YELLOW}⚠️ 注意: grok-cliを活用した品質評価を実施してください${NC}"
echo ""

# 作業ディレクトリに移動
cd "$SCRIPT_DIR"

# Bashシェルを起動（環境変数を設定）
export GROK4_MODE=true
export AGENT_NAME="GROK4"
export AGENT_ROLE="品質保証AI"
export INSTRUCTIONS_FILE="$SCRIPT_DIR/instructions/grok4.md"

exec /bin/bash --rcfile <(cat ~/.bashrc 2>/dev/null || echo ""; cat <<'EOF'
# GROK4専用プロンプト
PS1='\[\033[0;35m\][GROK4🔍]\[\033[0m\] \[\033[0;34m\]\w\[\033[0m\] $ '

# エイリアス
alias send-president='./agent-send.sh president'
alias send-worker2='./agent-send.sh worker2'
alias send-worker3='./agent-send.sh worker3'
alias send-o3='./agent-send.sh o3'
alias instructions='cat instructions/grok4.md | less'

# grok-cli関連
if [ -d "grok-cli" ]; then
    alias grok='cd grok-cli && npm start'
fi

# ウェルカムメッセージ
echo ""
echo "GROK4シェル起動完了 - 品質保証モード有効"
echo "コマンド例:"
echo "  send-president \"品質評価結果: ...\"    # PRESIDENTにメッセージ送信"
echo "  instructions                          # 指示書を表示"
if [ -d "grok-cli" ]; then
    echo "  grok                                  # grok-cli起動"
fi
EOF
)
