#!/bin/bash

###############################################################################
# LINE → GitHub → Claude Code Integration Start Script
#
# 全統合パイプラインの起動スクリプト
#
# 使用方法:
#   ./start-integration.sh [production|development] [systemd|manual]
#
# 例:
#   ./start-integration.sh production systemd   # 本番環境（systemd）
#   ./start-integration.sh development manual   # 開発環境（手動）
###############################################################################

set -e

# ========================================
# 色定義
# ========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ========================================
# 変数
# ========================================
PROJECT_DIR="/home/planj/Claude-Code-Communication"
ENV="${1:-production}"
START_MODE="${2:-manual}"
VENV_DIR="${PROJECT_DIR}/venv"

# ========================================
# ロギング関数
# ========================================
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# ========================================
# systemd 起動モード
# ========================================
start_with_systemd() {
    log_info "systemd で起動中..."

    # サービスファイルをコピー
    log_info "systemd サービスを登録中..."
    sudo cp "${PROJECT_DIR}/systemd/"*.service /etc/systemd/system/
    sudo systemctl daemon-reload

    # メインサービスを起動
    log_info "claude-a2a.service を起動中..."
    sudo systemctl start claude-a2a.service
    sudo systemctl enable claude-a2a.service

    # ステータス確認
    sleep 2
    log_info "サービスステータスを確認中..."
    sudo systemctl status claude-a2a.service --no-pager

    log_success "systemd で起動しました"
}

# ========================================
# 手動起動モード
# ========================================
start_manually() {
    log_info "手動で起動中..."

    # 仮想環境をアクティベート
    if [ ! -d "${VENV_DIR}" ]; then
        log_error "仮想環境が見つかりません: ${VENV_DIR}"
        log_info "deploy.sh を実行してください"
        exit 1
    fi

    source "${VENV_DIR}/bin/activate"
    log_success "仮想環境をアクティベートしました"

    # A2A システム起動
    log_info "A2A システム起動中..."
    bash "${PROJECT_DIR}/start-robust-a2a-system.sh" &
    sleep 3

    # LINE Webhook Handler 起動
    log_info "LINE Webhook Handler 起動中..."
    python3 "${PROJECT_DIR}/bridges/line_webhook_handler.py" &
    WEBHOOK_PID=$!
    sleep 2

    # GitHub Issue Creator 起動
    log_info "GitHub Issue Creator 起動中..."
    python3 "${PROJECT_DIR}/integrations/github_issue_creator.py" &
    CREATOR_PID=$!
    sleep 2

    # LINE Notifier 起動
    log_info "LINE Notifier 起動中..."
    python3 "${PROJECT_DIR}/integrations/line_notifier.py" &
    NOTIFIER_PID=$!
    sleep 2

    log_success "手動で起動しました"
    log_info ""
    log_info "実行中のプロセス:"
    ps aux | grep -E "python3|broker|bridge" | grep -v grep

    log_info ""
    log_info "ログを監視中... (Ctrl+C で終了)"
    log_info ""

    # ログ監視
    tail -f "${PROJECT_DIR}"/logs/*.log \
            "${PROJECT_DIR}"/line_webhook_handler.log \
            "${PROJECT_DIR}"/github_issue_creator.log \
            "${PROJECT_DIR}"/line_notifier.log 2>/dev/null || true
}

# ========================================
# 環境確認
# ========================================
check_environment() {
    log_info "=========================================="
    log_info "統合パイプライン起動前確認"
    log_info "=========================================="
    log_info "環境: ${ENV}"
    log_info "起動モード: ${START_MODE}"
    echo

    # .env ファイル確認
    if [ ! -f "${PROJECT_DIR}/.env" ]; then
        log_error ".env ファイルが見つかりません"
        exit 1
    fi

    # 必須環境変数確認
    log_info "必須環境変数を確認中..."
    if grep -q "your_" "${PROJECT_DIR}/.env"; then
        log_error "❌ .env ファイルにデフォルト値が残っています"
        log_error "   実際の値を設定してください："
        grep "your_" "${PROJECT_DIR}/.env" | sed 's/^/   /'
        exit 1
    fi

    log_success ".env ファイルが正常に設定されています"

    # ディレクトリ確認
    log_info "ディレクトリ構造を確認中..."
    if [ ! -d "${PROJECT_DIR}/a2a_system/shared/context_storage" ]; then
        log_error "必要なディレクトリが見つかりません"
        exit 1
    fi

    log_success "ディレクトリ構造が正常です"
    echo
}

# ========================================
# メイン処理
# ========================================
main() {
    log_info "=========================================="
    log_info "LINE → GitHub → Claude Code 統合パイプライン"
    log_info "=========================================="
    echo

    # 環境確認
    check_environment

    # 起動モード別処理
    if [ "${START_MODE}" = "systemd" ]; then
        if [ "$EUID" -ne 0 ]; then
            log_error "systemd モードは root 権限が必要です"
            log_info "以下のコマンドで実行してください："
            log_info "  sudo ./start-integration.sh ${ENV} systemd"
            exit 1
        fi
        start_with_systemd

    elif [ "${START_MODE}" = "manual" ]; then
        start_manually

    else
        log_error "不明な起動モード: ${START_MODE}"
        log_info "有効な値: systemd, manual"
        exit 1
    fi

    log_success "=========================================="
    log_success "統合パイプラインの起動が完了しました！"
    log_success "=========================================="
}

# ========================================
# 実行
# ========================================
if [ ! -d "${PROJECT_DIR}" ]; then
    log_error "プロジェクトディレクトリが見つかりません: ${PROJECT_DIR}"
    exit 1
fi

cd "${PROJECT_DIR}"
main
