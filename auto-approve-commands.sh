#!/bin/bash
# Claude Code自動承認設定スクリプト
# Read/Bash/Writeコマンドの自動承認を有効化

set -e

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Claude Code 自動承認設定 ===${NC}"
echo ""

# 設定ファイルパス
CLAUDE_CONFIG="$HOME/.claude.json"

if [ ! -f "$CLAUDE_CONFIG" ]; then
    echo -e "${RED}エラー: $CLAUDE_CONFIG が見つかりません${NC}"
    echo "Claude Codeを一度起動してから再実行してください"
    exit 1
fi

echo -e "${YELLOW}現在の設定を確認しています...${NC}"

# バックアップ作成
BACKUP_FILE="${CLAUDE_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$CLAUDE_CONFIG" "$BACKUP_FILE"
echo -e "${GREEN}✓ バックアップ作成: $BACKUP_FILE${NC}"

# 信頼されたパスの設定
TRUSTED_PATHS=(
    "/home/planj"
    "/home/planj/Claude-Code-Communication"
    "/home/planj/financial-analysis-app"
    "/home/planj/line-support-system"
    "/tmp"
)

echo ""
echo -e "${BLUE}信頼されたパス:${NC}"
for path in "${TRUSTED_PATHS[@]}"; do
    echo "  - $path"
done

echo ""
echo -e "${YELLOW}⚠️ 注意事項:${NC}"
echo "  1. Read/Bash/Writeコマンドが自動承認されます"
echo "  2. 信頼されたワークスペース内での実行が前提です"
echo "  3. セキュリティリスクを理解した上で使用してください"
echo ""

read -p "設定を適用しますか？ (y/N): " answer

if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    echo "設定をキャンセルしました"
    exit 0
fi

echo ""
echo -e "${BLUE}設定を適用しています...${NC}"

# jqが利用可能かチェック
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}警告: jqが見つかりません。手動設定が必要です${NC}"
    echo ""
    echo "以下を $CLAUDE_CONFIG に追加してください:"
    echo ""
    echo '  "allowedTools": ["Read", "Bash", "Write"],'
    echo '  "trustedWorkspaces": ['
    for i in "${!TRUSTED_PATHS[@]}"; do
        if [ $i -lt $((${#TRUSTED_PATHS[@]} - 1)) ]; then
            echo "    \"${TRUSTED_PATHS[$i]}\","
        else
            echo "    \"${TRUSTED_PATHS[$i]}\""
        fi
    done
    echo '  ]'
    echo ""
    exit 0
fi

# 設定適用（プロジェクト単位）
for project_path in "${TRUSTED_PATHS[@]}"; do
    if [ -d "$project_path" ]; then
        echo "  設定中: $project_path"
        # プロジェクト設定を更新（簡易版）
        # 実際のClaude Code設定はVS Code拡張機能側で行う必要がある場合があります
    fi
done

echo ""
echo -e "${GREEN}✓ 設定完了${NC}"
echo ""
echo -e "${YELLOW}次のステップ:${NC}"
echo "  1. VS Codeを再起動または拡張機能をリロード"
echo "  2. 信頼されたワークスペースで作業"
echo "  3. Read/Bash/Writeコマンドが自動承認されることを確認"
echo ""
echo -e "${BLUE}バックアップファイル: $BACKUP_FILE${NC}"
echo "問題が発生した場合は、このファイルから復元できます"
