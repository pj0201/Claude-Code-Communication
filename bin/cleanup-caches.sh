#!/bin/bash

# キャッシュ定期クリーンアップスクリプト
# 用途: Puppeteer, pip, Playwright等の蓄積キャッシュを定期削除
# 実行: manual または crontab で毎日実行推奨

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "================================"
echo "🧹 キャッシュ定期クリーンアップ"
echo "================================"
echo ""

# ログファイル
LOG_FILE="/tmp/cache-cleanup.log"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] クリーンアップ開始" >> "${LOG_FILE}"

# 前の実行前のサイズを記録
echo "📊 クリーンアップ前のサイズ:"
CACHE_BEFORE=$(du -sh ~/.cache 2>/dev/null | awk '{print $1}')
TMP_BEFORE=$(du -sh /tmp 2>/dev/null | awk '{print $1}')
echo "  ~/.cache: ${CACHE_BEFORE}"
echo "  /tmp: ${TMP_BEFORE}"

# 1. Puppeteer キャッシュ（容量上限チェック）
echo ""
echo "1️⃣  Puppeteerキャッシュ確認..."
if [ -d ~/.cache/puppeteer ]; then
    PUPPETEER_SIZE=$(du -sh ~/.cache/puppeteer 2>/dev/null | awk '{print $1}')
    PUPPETEER_MB=$(du -sb ~/.cache/puppeteer 2>/dev/null | awk '{printf "%.0f", $1/1024/1024}')

    echo "   現在のサイズ: ${PUPPETEER_SIZE} (${PUPPETEER_MB}MB)"

    # 上限: 500MB
    if [ "${PUPPETEER_MB}" -gt 500 ]; then
        echo -e "   ${YELLOW}⚠️  500MB超過 → 削除実行${NC}"
        rm -rf ~/.cache/puppeteer
        echo -e "   ${GREEN}✅ Puppeteerキャッシュ削除完了${NC}"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Puppeteer削除: ${PUPPETEER_MB}MB" >> "${LOG_FILE}"
    else
        echo -e "   ${GREEN}✅ OK (${PUPPETEER_MB}MB以下)${NC}"
    fi
else
    echo "   ℹ️  Puppeteerキャッシュなし"
fi

# 2. pip一時ファイル（7日以上前）
echo ""
echo "2️⃣  pip一時ファイル確認..."
PIP_COUNT=$(find /tmp -maxdepth 1 -name "pip-unpack-*" -type d 2>/dev/null | wc -l)
if [ "${PIP_COUNT}" -gt 0 ]; then
    echo "   見つかったディレクトリ: ${PIP_COUNT}個"
    PIP_SIZE=$(find /tmp -maxdepth 1 -name "pip-unpack-*" -type d -exec du -sh {} \; 2>/dev/null | awk '{s+=$1} END {print s}')
    echo "   合計サイズ: ${PIP_SIZE}"
    find /tmp -maxdepth 1 -name "pip-unpack-*" -mtime +7 -type d -exec rm -rf {} \; 2>/dev/null
    echo -e "   ${GREEN}✅ 7日以上前のpip一時ファイル削除完了${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] pip削除: ${PIP_COUNT}個" >> "${LOG_FILE}"
else
    echo -e "   ${GREEN}✅ pip一時ファイルなし${NC}"
fi

# 3. Playwright環境（定期削除）
echo ""
echo "3️⃣  Playwright環境確認..."
if [ -d /tmp/playwright-env ]; then
    PW_SIZE=$(du -sh /tmp/playwright-env 2>/dev/null | awk '{print $1}')
    echo "   現在のサイズ: ${PW_SIZE}"
    rm -rf /tmp/playwright-env
    echo -e "   ${GREEN}✅ Playwright環境削除完了${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Playwright環境削除: ${PW_SIZE}" >> "${LOG_FILE}"
else
    echo -e "   ${GREEN}✅ Playwright環境なし${NC}"
fi

# 4. OCR環境（防止的削除）
echo ""
echo "4️⃣  OCR環境確認..."
if [ -d /tmp/ocr_env ]; then
    OCR_SIZE=$(du -sh /tmp/ocr_env 2>/dev/null | awk '{print $1}')
    echo "   現在のサイズ: ${OCR_SIZE}"
    rm -rf /tmp/ocr_env
    echo -e "   ${RED}🚨 OCR環境削除完了 (意図しない蓄積)${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] OCR環境削除: ${OCR_SIZE}" >> "${LOG_FILE}"
else
    echo -e "   ${GREEN}✅ OCR環境なし${NC}"
fi

# 5. 古いPuppeteerプロファイル（30日以上前）
echo ""
echo "5️⃣  古いPuppeteerプロファイル確認..."
OLD_PROFILES=$(find /tmp -maxdepth 1 -name "puppeteer_dev_chrome_profile-*" -mtime +30 2>/dev/null | wc -l)
if [ "${OLD_PROFILES}" -gt 0 ]; then
    echo "   見つかったプロファイル: ${OLD_PROFILES}個"
    find /tmp -maxdepth 1 -name "puppeteer_dev_chrome_profile-*" -mtime +30 -exec rm -rf {} \; 2>/dev/null
    echo -e "   ${GREEN}✅ 30日以上前のプロファイル削除完了${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 古いプロファイル削除: ${OLD_PROFILES}個" >> "${LOG_FILE}"
else
    echo -e "   ${GREEN}✅ 古いプロファイルなし${NC}"
fi

# 6. Node/npm 一時ファイル
echo ""
echo "6️⃣  Node/npm一時ファイル確認..."
if [ -d /tmp/.npm ]; then
    NPM_SIZE=$(du -sh /tmp/.npm 2>/dev/null | awk '{print $1}')
    echo "   現在のサイズ: ${NPM_SIZE}"
    rm -rf /tmp/.npm
    echo -e "   ${GREEN}✅ npm キャッシュ削除完了${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] npm削除: ${NPM_SIZE}" >> "${LOG_FILE}"
else
    echo -e "   ${GREEN}✅ npm キャッシュなし${NC}"
fi

# 7. 最後の確認と統計
echo ""
echo "================================"
echo "📊 クリーンアップ後のサイズ:"
CACHE_AFTER=$(du -sh ~/.cache 2>/dev/null | awk '{print $1}')
TMP_AFTER=$(du -sh /tmp 2>/dev/null | awk '{print $1}')
echo "  ~/.cache: ${CACHE_AFTER}"
echo "  /tmp: ${TMP_AFTER}"

# 容量警告
echo ""
echo "⚠️  容量警告チェック:"
CACHE_MB=$(du -sb ~/.cache 2>/dev/null | awk '{printf "%.0f", $1/1024/1024}')
TMP_MB=$(du -sb /tmp 2>/dev/null | awk '{printf "%.0f", $1/1024/1024}')

if [ "${CACHE_MB}" -gt 600 ]; then
    echo -e "  ${RED}🚨 ~/.cache が 600MB 超過: ${CACHE_MB}MB${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 警告: キャッシュ=${CACHE_MB}MB" >> "${LOG_FILE}"
elif [ "${CACHE_MB}" -gt 500 ]; then
    echo -e "  ${YELLOW}⚠️  ~/.cache が大きい: ${CACHE_MB}MB${NC}"
else
    echo -e "  ${GREEN}✅ ~/.cache OK: ${CACHE_MB}MB${NC}"
fi

if [ "${TMP_MB}" -gt 5000 ]; then
    echo -e "  ${RED}🚨 /tmp が 5GB 超過: ${TMP_MB}MB${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 警告: tmp=${TMP_MB}MB" >> "${LOG_FILE}"
elif [ "${TMP_MB}" -gt 3000 ]; then
    echo -e "  ${YELLOW}⚠️  /tmp が大きい: ${TMP_MB}MB${NC}"
else
    echo -e "  ${GREEN}✅ /tmp OK: ${TMP_MB}MB${NC}"
fi

echo ""
echo -e "${GREEN}✅ クリーンアップ完了${NC}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] クリーンアップ完了" >> "${LOG_FILE}"
echo ""

# ログ出力
echo "ℹ️  ログ: ${LOG_FILE}"
