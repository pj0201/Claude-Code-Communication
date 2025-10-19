#!/bin/bash

# ディスク容量監視スクリプト
# 用途: キャッシュが閾値を超えたら警告・自動クリーンアップ
# 実行: crontab で定期実行 (例：毎日午前8時チェック)

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

LOG_FILE="/tmp/disk-monitor.log"

# 閾値設定（単位: MB）
CACHE_WARNING=500      # 警告値
CACHE_CRITICAL=600     # 危機値 → 自動クリーンアップ
TMP_WARNING=3000       # 警告値
TMP_CRITICAL=5000      # 危機値 → 自動クリーンアップ
ROOT_CRITICAL=80       # ディスク使用率% → 自動クリーンアップ

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 容量監視開始" >> "${LOG_FILE}"

# 現在の容量確認
CACHE_MB=$(du -sb ~/.cache 2>/dev/null | awk '{printf "%.0f", $1/1024/1024}')
TMP_MB=$(du -sb /tmp 2>/dev/null | awk '{printf "%.0f", $1/1024/1024}')
ROOT_USAGE=$(df / | awk 'NR==2 {printf "%.0f", $5}' 2>/dev/null || echo "0")

echo "📊 現在の容量状況 ($(date '+%Y-%m-%d %H:%M:%S')):"
echo "  ~/.cache: ${CACHE_MB}MB (警告: ${CACHE_WARNING}MB, 危機: ${CACHE_CRITICAL}MB)"
echo "  /tmp:     ${TMP_MB}MB (警告: ${TMP_WARNING}MB, 危機: ${TMP_CRITICAL}MB)"
echo "  /: ${ROOT_USAGE}% (危機: ${ROOT_CRITICAL}%)"

# アラート状態
ALERT_FLAG=0

# 1. キャッシュチェック
if [ "${CACHE_MB}" -gt "${CACHE_CRITICAL}" ]; then
    echo ""
    echo -e "${RED}🚨 【危機】 ~/.cache が ${CACHE_MB}MB に達しました (上限: ${CACHE_CRITICAL}MB)${NC}"
    echo "自動クリーンアップを実行します..."
    bash /home/planj/Claude-Code-Communication/bin/cleanup-caches.sh
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 自動クリーンアップ実行: キャッシュ=${CACHE_MB}MB" >> "${LOG_FILE}"
    ALERT_FLAG=1
elif [ "${CACHE_MB}" -gt "${CACHE_WARNING}" ]; then
    echo ""
    echo -e "${YELLOW}⚠️  【警告】 ~/.cache が ${CACHE_MB}MB です (警告値: ${CACHE_WARNING}MB)${NC}"
    echo "   推奨: bin/cleanup-caches.sh を手動実行してください"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 警告: キャッシュ=${CACHE_MB}MB" >> "${LOG_FILE}"
fi

# 2. /tmp チェック
if [ "${TMP_MB}" -gt "${TMP_CRITICAL}" ]; then
    echo ""
    echo -e "${RED}🚨 【危機】 /tmp が ${TMP_MB}MB に達しました (上限: ${TMP_CRITICAL}MB)${NC}"
    echo "自動クリーンアップを実行します..."
    bash /home/planj/Claude-Code-Communication/bin/cleanup-caches.sh
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 自動クリーンアップ実行: tmp=${TMP_MB}MB" >> "${LOG_FILE}"
    ALERT_FLAG=1
elif [ "${TMP_MB}" -gt "${TMP_WARNING}" ]; then
    echo ""
    echo -e "${YELLOW}⚠️  【警告】 /tmp が ${TMP_MB}MB です (警告値: ${TMP_WARNING}MB)${NC}"
    echo "   推奨: bin/cleanup-caches.sh を手動実行してください"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 警告: tmp=${TMP_MB}MB" >> "${LOG_FILE}"
fi

# 3. ルートディスクチェック
if [ "${ROOT_USAGE}" -gt "${ROOT_CRITICAL}" ]; then
    echo ""
    echo -e "${RED}🚨 【危機】 ルートディスク使用率が ${ROOT_USAGE}% に達しました (上限: ${ROOT_CRITICAL}%)${NC}"
    echo "緊急: 広いディスク容量確保が必要です"
    bash /home/planj/Claude-Code-Communication/bin/cleanup-caches.sh
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 自動クリーンアップ実行: ルート=${ROOT_USAGE}%" >> "${LOG_FILE}"
    ALERT_FLAG=1
fi

# 最終状態
echo ""
if [ "${ALERT_FLAG}" -eq 1 ]; then
    echo -e "${RED}⚠️  【重要】 容量問題が発生しました${NC}"
    echo "ログを確認してください: ${LOG_FILE}"
    echo ""
    echo "詳細情報:"
    df -h / ~/.cache /tmp 2>/dev/null

    # 詳細なトラブルシューティング情報
    echo ""
    echo "📋 容量が大きいディレクトリ (Top 5):"
    du -sh ~/.cache/* ~/.npm /tmp/* 2>/dev/null | sort -rh | head -5

    exit 1
else
    echo -e "${GREEN}✅ 容量は正常な範囲内です${NC}"
    echo ""
    echo "詳細情報:"
    df -h / ~/.cache /tmp 2>/dev/null
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 容量監視完了" >> "${LOG_FILE}"
