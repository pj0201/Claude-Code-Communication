#!/bin/bash
# Pre-commit風チェックスクリプト
# コミット前に手動実行してリポジトリ境界をチェック

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                               ║${NC}"
echo -e "${BLUE}║            🔒 Pre-Commit Check - コミット前チェック          ║${NC}"
echo -e "${BLUE}║                                                               ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# リポジトリ境界チェックを実行
if [ -f "$SCRIPT_DIR/check-repository-boundary.sh" ]; then
    echo -e "${BLUE}リポジトリ境界チェックを実行中...${NC}"
    echo ""

    if "$SCRIPT_DIR/check-repository-boundary.sh"; then
        echo ""
        echo -e "${GREEN}✅ Pre-commitチェック成功${NC}"
        echo -e "${GREEN}   コミット可能です${NC}"
        exit 0
    else
        echo ""
        echo -e "${RED}❌ Pre-commitチェック失敗${NC}"
        echo -e "${RED}   リポジトリ境界違反があります${NC}"
        echo ""
        echo -e "${YELLOW}対処方法:${NC}"
        echo "  1. check-repository-boundary.sh の結果を確認"
        echo "  2. 不適切なファイルを削除または適切なリポジトリに移動"
        echo "  3. 再度このスクリプトを実行"
        echo ""
        exit 1
    fi
else
    echo -e "${RED}エラー: check-repository-boundary.sh が見つかりません${NC}"
    exit 1
fi
