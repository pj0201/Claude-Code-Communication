#!/bin/bash
# リポジトリ境界チェックスクリプト
# Claude-Code-Communicationに不適切なファイルが混入していないか自動チェック

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
echo -e "${BLUE}║        🔍 リポジトリ境界チェック - 混入検出システム         ║${NC}"
echo -e "${BLUE}║                                                               ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# チェック結果カウンター
ERRORS=0
WARNINGS=0

# エラー報告関数
report_error() {
    echo -e "${RED}❌ エラー: $1${NC}"
    ERRORS=$((ERRORS + 1))
}

# 警告報告関数
report_warning() {
    echo -e "${YELLOW}⚠️  警告: $1${NC}"
    WARNINGS=$((WARNINGS + 1))
}

# 成功報告関数
report_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

echo -e "${BLUE}=== チェック1: 開発プロジェクトコードの混入検出 ===${NC}"

# Pythonファイル（toolsディレクトリ以外）
PYTHON_FILES=$(find "$SCRIPT_DIR" -name "*.py" \
    ! -path "*/tools/*" \
    ! -path "*/node_modules/*" \
    ! -path "*/.git/*" \
    2>/dev/null || true)

if [ -n "$PYTHON_FILES" ]; then
    report_error "Pythonファイルが混入しています:"
    echo "$PYTHON_FILES" | while read -r file; do
        echo "  - $file"
    done
else
    report_success "Pythonファイルの混入なし"
fi

# TypeScript/JavaScriptファイル（toolsディレクトリ以外）
TS_JS_FILES=$(find "$SCRIPT_DIR" -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.jsx" \) \
    ! -path "*/tools/*" \
    ! -path "*/node_modules/*" \
    ! -path "*/.git/*" \
    2>/dev/null || true)

if [ -n "$TS_JS_FILES" ]; then
    report_error "TypeScript/JSXファイルが混入しています:"
    echo "$TS_JS_FILES" | while read -r file; do
        echo "  - $file"
    done
else
    report_success "TypeScript/JSXファイルの混入なし"
fi

# アプリケーション固有のディレクトリ
APP_DIRS=$(find "$SCRIPT_DIR" -type d \( \
    -name "src" -o \
    -name "app" -o \
    -name "models" -o \
    -name "controllers" -o \
    -name "views" -o \
    -name "services" -o \
    -name "components" \
    \) \
    ! -path "*/tools/*" \
    ! -path "*/node_modules/*" \
    ! -path "*/.git/*" \
    2>/dev/null || true)

if [ -n "$APP_DIRS" ]; then
    report_error "アプリケーション固有のディレクトリが混入しています:"
    echo "$APP_DIRS" | while read -r dir; do
        echo "  - $dir"
    done
else
    report_success "アプリケーション固有のディレクトリの混入なし"
fi

echo ""
echo -e "${BLUE}=== チェック2: データベースファイルの混入検出 ===${NC}"

# データベースファイル
DB_FILES=$(find "$SCRIPT_DIR" -type f \( \
    -name "*.db" -o \
    -name "*.sqlite" -o \
    -name "*.sqlite3" -o \
    -name "*.sql" \
    \) \
    ! -path "*/tools/*" \
    ! -path "*/node_modules/*" \
    ! -path "*/.git/*" \
    2>/dev/null || true)

if [ -n "$DB_FILES" ]; then
    report_error "データベースファイルが混入しています:"
    echo "$DB_FILES" | while read -r file; do
        echo "  - $file"
    done
else
    report_success "データベースファイルの混入なし"
fi

echo ""
echo -e "${BLUE}=== チェック3: プロジェクト固有のテストファイル検出 ===${NC}"

# テストファイル（toolsディレクトリ以外）
TEST_FILES=$(find "$SCRIPT_DIR" -type f \( \
    -name "*test*.py" -o \
    -name "*test*.js" -o \
    -name "*test*.ts" -o \
    -name "test_*.py" -o \
    -name "*_test.py" -o \
    -name "*.test.js" -o \
    -name "*.spec.js" -o \
    -name "*.test.ts" -o \
    -name "*.spec.ts" \
    \) \
    ! -path "*/tools/*" \
    ! -path "*/node_modules/*" \
    ! -path "*/.git/*" \
    2>/dev/null || true)

if [ -n "$TEST_FILES" ]; then
    report_warning "プロジェクト固有のテストファイルが検出されました:"
    echo "$TEST_FILES" | while read -r file; do
        echo "  - $file"
    done
else
    report_success "プロジェクト固有のテストファイルなし"
fi

echo ""
echo -e "${BLUE}=== チェック4: 環境変数・機密情報ファイルの検出 ===${NC}"

# .envファイル（worker3-env以外）
ENV_FILES=$(find "$SCRIPT_DIR" -name ".env" \
    ! -path "*/worker3-env/*" \
    ! -path "*/tools/*" \
    ! -path "*/node_modules/*" \
    ! -path "*/.git/*" \
    2>/dev/null || true)

if [ -n "$ENV_FILES" ]; then
    report_warning ".envファイルが検出されました（gitignore確認推奨）:"
    echo "$ENV_FILES" | while read -r file; do
        echo "  - $file"
    done
else
    report_success ".envファイルなし（または適切に配置）"
fi

# 機密情報ファイル
SECRET_FILES=$(find "$SCRIPT_DIR" -type f \( \
    -name "*.pem" -o \
    -name "*.key" -o \
    -name "*credentials*" -o \
    -name "*secret*" \
    \) \
    ! -path "*/tools/*" \
    ! -path "*/node_modules/*" \
    ! -path "*/.git/*" \
    2>/dev/null || true)

if [ -n "$SECRET_FILES" ]; then
    report_error "機密情報ファイルが検出されました:"
    echo "$SECRET_FILES" | while read -r file; do
        echo "  - $file"
    done
else
    report_success "機密情報ファイルなし"
fi

echo ""
echo -e "${BLUE}=== チェック5: 必須ファイルの存在確認 ===${NC}"

# 必須ファイルリスト
REQUIRED_FILES=(
    "CLAUDE.md"
    "README.md"
    "REPOSITORY_BOUNDARY.md"
    "startup-integrated-system.sh"
    "agent-send.sh"
    "o3-shell.sh"
    "grok4-shell.sh"
    "auto-approve-commands.sh"
    "instructions/president.md"
    "instructions/o3.md"
    "instructions/grok4.md"
    "instructions/worker.md"
    "tools/README.md"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$SCRIPT_DIR/$file" ]; then
        report_success "$file 存在"
    else
        report_error "$file が見つかりません"
    fi
done

echo ""
echo -e "${BLUE}=== チェック6: 不適切な命名パターン検出 ===${NC}"

# LINE関連のファイル（line-support-systemに属するべき）
LINE_FILES=$(find "$SCRIPT_DIR" -type f -iname "*line*" \
    ! -path "*/node_modules/*" \
    ! -path "*/.git/*" \
    2>/dev/null | grep -v "startup-integrated-system.sh" | grep -v "REPOSITORY_BOUNDARY.md" || true)

if [ -n "$LINE_FILES" ]; then
    report_warning "LINE関連のファイルが検出されました（line-support-systemに属するべき可能性）:"
    echo "$LINE_FILES" | while read -r file; do
        echo "  - $file"
    done
else
    report_success "LINE関連ファイルなし"
fi

# Financial関連のファイル
FINANCIAL_FILES=$(find "$SCRIPT_DIR" -type f -iname "*financial*" \
    ! -path "*/node_modules/*" \
    ! -path "*/.git/*" \
    2>/dev/null | grep -v "REPOSITORY_BOUNDARY.md" || true)

if [ -n "$FINANCIAL_FILES" ]; then
    report_warning "Financial関連のファイルが検出されました（financial-analysis-appに属するべき可能性）:"
    echo "$FINANCIAL_FILES" | while read -r file; do
        echo "  - $file"
    done
else
    report_success "Financial関連ファイルなし"
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                        チェック結果                           ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ 完璧です！リポジトリ境界は正しく保たれています。${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  警告: ${WARNINGS}件${NC}"
    echo -e "${YELLOW}   確認が必要な項目がありますが、致命的な問題はありません。${NC}"
    exit 0
else
    echo -e "${RED}❌ エラー: ${ERRORS}件, 警告: ${WARNINGS}件${NC}"
    echo -e "${RED}   リポジトリ境界違反が検出されました！${NC}"
    echo ""
    echo -e "${YELLOW}対処方法:${NC}"
    echo "  1. エラー項目のファイルを適切なリポジトリに移動"
    echo "  2. 不要なファイルは削除"
    echo "  3. 再度このスクリプトを実行して確認"
    echo ""
    exit 1
fi
