#!/bin/bash
# A2A通信システム包括テストスイート

TEST_DIR="/home/planj/Claude-Code-Communication/a2a_system"
INBOX_DIR="$TEST_DIR/shared/claude_inbox"
OUTBOX_DIR="$TEST_DIR/shared/claude_outbox"
LOG_FILE="$TEST_DIR/test_results_$(date +%Y%m%d_%H%M%S).log"

# カラー出力
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ログ関数
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# テスト結果カウンター
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# テスト開始
log "${GREEN}========================================${NC}"
log "${GREEN}A2A Communication System Test Suite${NC}"
log "${GREEN}========================================${NC}"
log "開始時刻: $(date)"
log ""

# Test 1: 標準パターン（cat + touch）
test_standard_pattern() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log "${YELLOW}[Test 1/8] 標準パターン (cat + touch)${NC}"

    TIMESTAMP=$(date +%Y%m%d_%H%M%S_%N)
    TEST_FILE="$INBOX_DIR/test1_${TIMESTAMP}.json"

    # メッセージ作成
    cat > "$TEST_FILE" << EOF
{
  "type": "QUESTION",
  "sender": "claude_code",
  "target": "gpt5_001",
  "question": "Test 1: 標準パターンテスト - 簡単な応答をください",
  "timestamp": "$(date -Iseconds)"
}
EOF

    # touch でイベント発生
    touch "$TEST_FILE"

    # 検知待機
    sleep 3

    # 検証: Bridge ログで検知確認
    if grep -q "test1_${TIMESTAMP}" "$TEST_DIR/claude_bridge.log"; then
        log "${GREEN}✅ Bridge検知成功${NC}"

        # 応答待機
        sleep 10

        # 応答確認
        RESPONSE_COUNT=$(find "$OUTBOX_DIR" -name "response_gpt5_001_*" -newer "$TEST_FILE" | wc -l)
        if [ "$RESPONSE_COUNT" -gt 0 ]; then
            log "${GREEN}✅ GPT-5応答受信成功${NC}"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            log "${GREEN}[PASS] Test 1${NC}\n"
            return 0
        else
            log "${RED}❌ GPT-5応答なし${NC}"
            FAILED_TESTS=$((FAILED_TESTS + 1))
            log "${RED}[FAIL] Test 1${NC}\n"
            return 1
        fi
    else
        log "${RED}❌ Bridge検知失敗${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        log "${RED}[FAIL] Test 1${NC}\n"
        return 1
    fi
}

# Test 2: 高頻度送信（1秒間に5メッセージ）
test_high_frequency() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log "${YELLOW}[Test 2/8] 高頻度送信 (1秒5メッセージ)${NC}"

    SENT_COUNT=0
    for i in {1..5}; do
        TIMESTAMP=$(date +%Y%m%d_%H%M%S_%N)
        TEST_FILE="$INBOX_DIR/test2_${i}_${TIMESTAMP}.json"

        cat > "$TEST_FILE" << EOF
{
  "type": "QUESTION",
  "sender": "claude_code",
  "target": "gpt5_001",
  "question": "Test 2-${i}: 高頻度送信テスト",
  "timestamp": "$(date -Iseconds)"
}
EOF
        touch "$TEST_FILE"
        SENT_COUNT=$((SENT_COUNT + 1))
        sleep 0.2  # 1秒間に5メッセージ
    done

    log "送信完了: ${SENT_COUNT}件"
    sleep 5

    # 検知数確認
    DETECTED_COUNT=$(grep -c "test2_" "$TEST_DIR/claude_bridge.log" | tail -1)
    log "検知数: ${DETECTED_COUNT}件"

    if [ "$DETECTED_COUNT" -eq "$SENT_COUNT" ]; then
        log "${GREEN}✅ 全メッセージ検知成功 (${DETECTED_COUNT}/${SENT_COUNT})${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        log "${GREEN}[PASS] Test 2${NC}\n"
        return 0
    else
        log "${RED}❌ 検知漏れ発生 (${DETECTED_COUNT}/${SENT_COUNT})${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        log "${RED}[FAIL] Test 2${NC}\n"
        return 1
    fi
}

# Test 3: 大容量JSON (10KB)
test_large_json() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log "${YELLOW}[Test 3/8] 大容量JSON (10KB+)${NC}"

    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    TEST_FILE="$INBOX_DIR/test3_${TIMESTAMP}.json"

    # 10KBの大容量JSON作成
    LARGE_TEXT=$(python3 -c "print('A' * 10000)")

    cat > "$TEST_FILE" << EOF
{
  "type": "QUESTION",
  "sender": "claude_code",
  "target": "gpt5_001",
  "question": "Test 3: 大容量JSONテスト",
  "large_data": "$LARGE_TEXT",
  "timestamp": "$(date -Iseconds)"
}
EOF

    touch "$TEST_FILE"
    sleep 5

    # 重複処理チェック
    PROCESS_COUNT=$(grep -c "test3_${TIMESTAMP}" "$TEST_DIR/claude_bridge.log")

    if [ "$PROCESS_COUNT" -eq 1 ]; then
        log "${GREEN}✅ 重複処理なし (処理回数: ${PROCESS_COUNT})${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        log "${GREEN}[PASS] Test 3${NC}\n"
        return 0
    else
        log "${RED}❌ 重複処理発生 (処理回数: ${PROCESS_COUNT})${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        log "${RED}[FAIL] Test 3${NC}\n"
        return 1
    fi
}

# Test 4: 同時多重送信
test_concurrent_send() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log "${YELLOW}[Test 4/8] 同時多重送信 (並列3ファイル)${NC}"

    TIMESTAMP=$(date +%Y%m%d_%H%M%S)

    # 並列でファイル作成
    for i in {1..3}; do
        (
            TEST_FILE="$INBOX_DIR/test4_${i}_${TIMESTAMP}.json"
            cat > "$TEST_FILE" << EOF
{
  "type": "QUESTION",
  "sender": "claude_code",
  "target": "gpt5_001",
  "question": "Test 4-${i}: 並列送信テスト",
  "timestamp": "$(date -Iseconds)"
}
EOF
            touch "$TEST_FILE"
        ) &
    done

    wait  # 全プロセス完了待機
    sleep 5

    # 検知数確認
    DETECTED_COUNT=$(grep -c "test4_.*_${TIMESTAMP}" "$TEST_DIR/claude_bridge.log")

    if [ "$DETECTED_COUNT" -eq 3 ]; then
        log "${GREEN}✅ 全ファイル検知成功 (${DETECTED_COUNT}/3)${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        log "${GREEN}[PASS] Test 4${NC}\n"
        return 0
    else
        log "${RED}❌ 検知漏れまたは競合 (${DETECTED_COUNT}/3)${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        log "${RED}[FAIL] Test 4${NC}\n"
        return 1
    fi
}

# Test 5-8は簡易版（実装は後で拡張）
test_placeholder() {
    TEST_NUM=$1
    TEST_NAME=$2
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log "${YELLOW}[Test ${TEST_NUM}/8] ${TEST_NAME}${NC}"
    log "${YELLOW}⏭️  実装予定（スキップ）${NC}\n"
}

# テスト実行
test_standard_pattern
test_high_frequency
test_large_json
test_concurrent_send
test_placeholder 5 "システム再起動直後"
test_placeholder 6 "スリープ復帰後"
test_placeholder 7 "24時間稼働後"
test_placeholder 8 "GPT-5エラー時リトライ"

# サマリー
log "${GREEN}========================================${NC}"
log "${GREEN}テスト結果サマリー${NC}"
log "${GREEN}========================================${NC}"
log "総テスト数: ${TOTAL_TESTS}"
log "${GREEN}成功: ${PASSED_TESTS}${NC}"
log "${RED}失敗: ${FAILED_TESTS}${NC}"
log "成功率: $(awk "BEGIN {printf \"%.1f\", (${PASSED_TESTS}/${TOTAL_TESTS})*100}")%"
log ""
log "ログ保存先: $LOG_FILE"
log "完了時刻: $(date)"

if [ "$FAILED_TESTS" -eq 0 ]; then
    log "${GREEN}✅ 全テスト合格！${NC}"
    exit 0
else
    log "${RED}❌ 一部テスト失敗${NC}"
    exit 1
fi
