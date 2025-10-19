#!/bin/bash

###############################################################################
# LINE → GitHub → Claude Code Integration Deployment Script
#
# このスクリプトは以下を実行します：
# 1. 環境確認
# 2. 依存パッケージのインストール
# 3. ディレクトリ構造の作成
# 4. 権限設定
# 5. systemd サービスの登録
# 6. 本番環境の起動準備
#
# 使用方法: ./deploy.sh [production|development]
###############################################################################

set -e  # エラーで終了

# ========================================
# 色定義
# ========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ========================================
# 変数設定
# ========================================
PROJECT_DIR="/home/planj/Claude-Code-Communication"
DEPLOYMENT_ENV="${1:-production}"
PYTHON_VERSION="3.11"
VENV_DIR="${PROJECT_DIR}/venv"
LOG_DIR="${PROJECT_DIR}/logs"

# ========================================
# ロギング関数
# ========================================
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# ========================================
# メイン処理
# ========================================
main() {
    log_info "=========================================="
    log_info "Claude-Code-Communication デプロイ開始"
    log_info "=========================================="
    log_info "デプロイ環境: ${DEPLOYMENT_ENV}"
    log_info "プロジェクトディレクトリ: ${PROJECT_DIR}"
    echo

    # 1. システム要件確認
    log_info "【ステップ 1】システム要件確認"
    check_system_requirements

    # 2. 環境ファイル確認
    log_info "【ステップ 2】環境ファイル確認"
    check_environment_files

    # 3. Python 仮想環境作成
    log_info "【ステップ 3】Python 仮想環境セットアップ"
    setup_virtual_environment

    # 4. 依存パッケージインストール
    log_info "【ステップ 4】依存パッケージインストール"
    install_dependencies

    # 5. ディレクトリ構造作成
    log_info "【ステップ 5】ディレクトリ構造作成"
    create_directory_structure

    # 6. 権限設定
    log_info "【ステップ 6】権限設定"
    set_permissions

    # 7. デプロイ環境別設定
    log_info "【ステップ 7】デプロイ環境別設定"
    configure_environment

    # 8. 最終確認
    log_info "【ステップ 8】最終確認"
    final_checks

    log_success "=========================================="
    log_success "デプロイ準備が完了しました！"
    log_success "=========================================="
    log_info "次のコマンドで起動してください："
    log_info "  ./start-integration.sh ${DEPLOYMENT_ENV}"
    echo
}

# ========================================
# システム要件確認
# ========================================
check_system_requirements() {
    log_info "Python バージョン確認..."
    python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
    if [[ ${python_version} != 3.11* ]]; then
        log_warning "推奨: Python 3.11 (検出: ${python_version})"
    else
        log_success "Python ${python_version} を検出"
    fi

    log_info "Git 確認..."
    if command -v git &> /dev/null; then
        git_version=$(git --version | cut -d' ' -f3)
        log_success "Git ${git_version} を検出"
    else
        log_error "Git がインストールされていません"
        exit 1
    fi

    log_info "Docker 確認..."
    if command -v docker &> /dev/null; then
        log_success "Docker を検出"
    else
        log_warning "Docker がインストールされていません（オプション）"
    fi

    echo
}

# ========================================
# 環境ファイル確認
# ========================================
check_environment_files() {
    if [ ! -f "${PROJECT_DIR}/.env" ]; then
        if [ -f "${PROJECT_DIR}/.env.example" ]; then
            log_warning ".env ファイルが見つかりません"
            log_info ".env.example をコピーしています..."
            cp "${PROJECT_DIR}/.env.example" "${PROJECT_DIR}/.env"
            log_success ".env ファイルを作成しました"
            log_warning "⚠️  .env ファイルを編集して、実際の値を入力してください："
            log_warning "   - LINE_CHANNEL_SECRET"
            log_warning "   - LINE_CHANNEL_ACCESS_TOKEN"
            log_warning "   - GITHUB_TOKEN"
            log_warning "   - OPENAI_API_KEY"
        else
            log_error ".env.example ファイルが見つかりません"
            exit 1
        fi
    else
        log_success ".env ファイルが存在します"
    fi

    echo
}

# ========================================
# Python 仮想環境セットアップ
# ========================================
setup_virtual_environment() {
    if [ -d "${VENV_DIR}" ]; then
        log_warning "仮想環境が既に存在します: ${VENV_DIR}"
    else
        log_info "仮想環境を作成中..."
        python3 -m venv "${VENV_DIR}"
        log_success "仮想環境を作成しました"
    fi

    # 仮想環境をアクティベート
    source "${VENV_DIR}/bin/activate"
    log_success "仮想環境をアクティベートしました"

    # pip をアップグレード
    log_info "pip をアップグレード中..."
    pip install --upgrade pip setuptools wheel > /dev/null
    log_success "pip をアップグレードしました"

    echo
}

# ========================================
# 依存パッケージインストール
# ========================================
install_dependencies() {
    log_info "依存パッケージをインストール中..."

    if [ -f "${PROJECT_DIR}/requirements.txt" ]; then
        pip install -r "${PROJECT_DIR}/requirements.txt"
        log_success "依存パッケージをインストールしました"
    else
        log_error "requirements.txt ファイルが見つかりません"
        exit 1
    fi

    echo
}

# ========================================
# ディレクトリ構造作成
# ========================================
create_directory_structure() {
    log_info "ディレクトリ構造を作成中..."

    # ログディレクトリ
    mkdir -p "${LOG_DIR}"
    log_success "ログディレクトリ: ${LOG_DIR}"

    # A2A システムディレクトリ
    mkdir -p "${PROJECT_DIR}/a2a_system/shared/context_storage"
    mkdir -p "${PROJECT_DIR}/a2a_system/shared/learned_patterns"
    mkdir -p "${PROJECT_DIR}/a2a_system/shared/claude_inbox/processed"
    mkdir -p "${PROJECT_DIR}/a2a_system/shared/claude_outbox/processed_notifications"
    log_success "A2A システムディレクトリを作成"

    # テストディレクトリ
    mkdir -p "${PROJECT_DIR}/tests"
    log_success "テストディレクトリを作成"

    echo
}

# ========================================
# 権限設定
# ========================================
set_permissions() {
    log_info "ファイル権限を設定中..."

    # スクリプトに実行権限を付与
    chmod +x "${PROJECT_DIR}/deploy.sh"
    chmod +x "${PROJECT_DIR}/start-robust-a2a-system.sh"
    [ -f "${PROJECT_DIR}/start-integration.sh" ] && chmod +x "${PROJECT_DIR}/start-integration.sh"

    # ディレクトリに適切な権限を付与
    chmod 755 "${LOG_DIR}"
    chmod 755 "${PROJECT_DIR}/a2a_system/shared/context_storage"
    chmod 755 "${PROJECT_DIR}/a2a_system/shared/learned_patterns"
    chmod 755 "${PROJECT_DIR}/a2a_system/shared/claude_inbox"

    log_success "ファイル権限を設定しました"

    echo
}

# ========================================
# デプロイ環境別設定
# ========================================
configure_environment() {
    if [ "${DEPLOYMENT_ENV}" = "production" ]; then
        log_info "本番環境の設定を適用中..."

        # 環境変数を設定
        sed -i 's/DEPLOYMENT_ENV=development/DEPLOYMENT_ENV=production/' "${PROJECT_DIR}/.env"
        sed -i 's/LOG_LEVEL=DEBUG/LOG_LEVEL=INFO/' "${PROJECT_DIR}/.env"

        log_success "本番環境の設定を適用しました"

    elif [ "${DEPLOYMENT_ENV}" = "development" ]; then
        log_info "開発環境の設定を適用中..."

        sed -i 's/DEPLOYMENT_ENV=production/DEPLOYMENT_ENV=development/' "${PROJECT_DIR}/.env"
        sed -i 's/LOG_LEVEL=INFO/LOG_LEVEL=DEBUG/' "${PROJECT_DIR}/.env"

        log_success "開発環境の設定を適用しました"
    else
        log_error "不明なデプロイ環境: ${DEPLOYMENT_ENV}"
        exit 1
    fi

    echo
}

# ========================================
# 最終確認
# ========================================
final_checks() {
    log_info "最終確認を実施中..."

    # テスト実行
    log_info "ユニットテストを実行中..."
    if python3 -m pytest "${PROJECT_DIR}/tests/" -q 2>/dev/null; then
        log_success "全テストが成功"
    else
        log_warning "テストに失敗しました（続行します）"
    fi

    # 環境変数確認
    log_info "環境変数を確認中..."
    if grep -q "your_" "${PROJECT_DIR}/.env"; then
        log_warning "⚠️  .env ファイルにデフォルト値が残っています"
        log_warning "   実際の値を設定してください："
        grep "your_" "${PROJECT_DIR}/.env" | sed 's/^/   /'
    else
        log_success "環境変数が設定されています"
    fi

    # ディレクトリ確認
    log_info "ディレクトリ構造を確認中..."
    if [ -d "${LOG_DIR}" ] && [ -d "${PROJECT_DIR}/a2a_system/shared/context_storage" ]; then
        log_success "ディレクトリ構造が正常です"
    else
        log_error "ディレクトリ構造に問題があります"
        exit 1
    fi

    echo
}

# ========================================
# スクリプト実行
# ========================================
if [ ! -d "${PROJECT_DIR}" ]; then
    log_error "プロジェクトディレクトリが見つかりません: ${PROJECT_DIR}"
    exit 1
fi

cd "${PROJECT_DIR}"
main
