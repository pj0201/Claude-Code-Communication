#!/bin/bash
# Claude Code Health Monitor
# Detects and reports frozen Claude Code processes
# Author: Claude Code Team
# Created: 2025-10-13

set -euo pipefail

# Configuration
readonly CPU_THRESHOLD=30        # CPU使用率閾値（%）
readonly CONN_THRESHOLD=50       # TCP接続数閾値
readonly UPTIME_THRESHOLD=10800  # 稼働時間閾値（3時間=10800秒）
readonly MEMORY_THRESHOLD=500000 # メモリ使用量閾値（KB）

# Color codes
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly GREEN='\033[0;32m'
readonly NC='\033[0m' # No Color

# Logging
log_warning() {
    echo -e "${YELLOW}⚠️  WARNING: $1${NC}"
}

log_error() {
    echo -e "${RED}❌ ERROR: $1${NC}"
}

log_info() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Check if process is frozen
check_claude_process() {
    local pid=$1
    local cmd=$2

    # スモールチームプロセスはスキップ
    if echo "$cmd" | grep -qE "line.*bridge|a2a|team-support"; then
        return 0
    fi

    # CPU使用率取得
    local cpu=$(ps -p "$pid" -o %cpu= 2>/dev/null | awk '{print int($1)}')

    # メモリ使用量取得（KB）
    local mem=$(ps -p "$pid" -o rss= 2>/dev/null | awk '{print int($1)}')

    # 稼働時間取得（秒）
    local uptime=$(ps -p "$pid" -o etimes= 2>/dev/null | awk '{print int($1)}')

    # TCP接続数取得
    local conn_count=$(ss -anp 2>/dev/null | grep -c "pid=$pid" || echo 0)

    # 送信バッファが詰まっている接続数
    local blocked_conns=$(ss -anp 2>/dev/null | grep "pid=$pid" | awk '$2 > 0 {count++} END {print count+0}')

    local warnings=0
    local is_frozen=false

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Process: $pid ($(readlink -f /proc/$pid/cwd 2>/dev/null || echo 'unknown'))"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # CPU使用率チェック
    if [ "$cpu" -gt "$CPU_THRESHOLD" ]; then
        log_warning "High CPU usage: ${cpu}% (threshold: ${CPU_THRESHOLD}%)"
        ((warnings++))
        if [ "$uptime" -gt "$UPTIME_THRESHOLD" ]; then
            is_frozen=true
        fi
    else
        log_info "CPU usage: ${cpu}%"
    fi

    # メモリ使用量チェック
    local mem_mb=$((mem / 1024))
    if [ "$mem" -gt "$MEMORY_THRESHOLD" ]; then
        log_warning "High memory usage: ${mem_mb}MB"
        ((warnings++))
    else
        log_info "Memory usage: ${mem_mb}MB"
    fi

    # 稼働時間チェック
    local uptime_min=$((uptime / 60))
    if [ "$uptime" -gt "$UPTIME_THRESHOLD" ] && [ "$cpu" -gt 10 ]; then
        log_warning "Long running with CPU activity: ${uptime_min} minutes"
        ((warnings++))
    else
        log_info "Uptime: ${uptime_min} minutes"
    fi

    # TCP接続数チェック
    if [ "$conn_count" -gt "$CONN_THRESHOLD" ]; then
        log_error "Excessive TCP connections: ${conn_count} (threshold: ${CONN_THRESHOLD})"
        ((warnings++))
        is_frozen=true
    else
        log_info "TCP connections: ${conn_count}"
    fi

    # 詰まっている接続チェック
    if [ "$blocked_conns" -gt 5 ]; then
        log_error "Blocked connections with pending data: ${blocked_conns}"
        ((warnings++))
        is_frozen=true
    elif [ "$blocked_conns" -gt 0 ]; then
        log_info "Blocked connections: ${blocked_conns}"
    fi

    # フリーズ判定
    if [ "$is_frozen" = true ]; then
        echo ""
        log_error "Process $pid appears to be FROZEN!"
        echo "  Recommendation: kill $pid"
        echo ""
        return 1
    elif [ "$warnings" -gt 2 ]; then
        echo ""
        log_warning "Process $pid shows $warnings warning signs (monitoring recommended)"
        echo ""
        return 0
    else
        echo ""
        log_info "Process $pid is healthy"
        echo ""
        return 0
    fi
}

# Main
main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Claude Code Health Monitor"
    echo "Started at: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Claude Codeプロセスを取得
    local claude_pids=$(pgrep -f "^claude$" || true)

    if [ -z "$claude_pids" ]; then
        log_info "No Claude Code processes found"
        return 0
    fi

    local total=0
    local frozen=0

    for pid in $claude_pids; do
        ((total++))
        if ! check_claude_process "$pid" "$(ps -p $pid -o cmd= 2>/dev/null)"; then
            ((frozen++))
        fi
    done

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Summary: Checked $total processes, Found $frozen frozen"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [ "$frozen" -gt 0 ]; then
        return 1
    fi

    return 0
}

# Run
main "$@"
