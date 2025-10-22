#!/bin/bash
# LINE Bridge システム安定性モニター
# クラッシュ時の自動再起動機能付き

set -e

BRIDGE_DIR="/home/planj/Claude-Code-Communication/line_integration"
MONITOR_LOG="/home/planj/Claude-Code-Communication/system_monitor.log"
MAX_RESTART_ATTEMPTS=5
RESTART_DELAY=5

# ロギング関数
log_message() {
    local msg="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $msg" | tee -a "$MONITOR_LOG"
}

# ヘルスチェック
check_health() {
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:5000/health 2>/dev/null || echo "000")
    if [ "$http_code" = "200" ]; then
        return 0
    else
        return 1
    fi
}

# プロセス起動
start_bridge() {
    log_message "🚀 LINE Bridge を起動中..."
    cd "$BRIDGE_DIR"
    nohup python3 line-to-claude-bridge.py >> line_bridge.log 2>&1 &
    sleep 3
    
    if check_health; then
        log_message "✅ LINE Bridge 起動成功"
        return 0
    else
        log_message "❌ LINE Bridge 起動失敗"
        return 1
    fi
}

# クラッシュ時の自動復旧
recover_from_crash() {
    local attempts=0
    
    log_message "⚠️ LINE Bridge クラッシュ検出"
    log_message "🔧 自動復旧を開始"
    
    while [ $attempts -lt $MAX_RESTART_ATTEMPTS ]; do
        attempts=$((attempts + 1))
        log_message "🔄 再起動試行 ($attempts/$MAX_RESTART_ATTEMPTS)"
        
        # ゾンビプロセス強制終了
        pkill -9 -f "line-to-claude-bridge" 2>/dev/null || true
        sleep 2
        
        # ポート強制解放
        lsof -i :5000 2>/dev/null | grep -v COMMAND | awk '{print $2}' | xargs kill -9 2>/dev/null || true
        sleep 2
        
        # 再起動
        if start_bridge; then
            log_message "✅ 復旧成功 (試行 $attempts)"
            return 0
        fi
        
        sleep $RESTART_DELAY
    done
    
    log_message "❌ 復旧失敗 - 管理者に通知が必要"
    return 1
}

# メイン監視ループ
main() {
    log_message "════════════════════════════════════════════════════"
    log_message "📱 LINE Bridge システム安定性モニター 起動"
    log_message "════════════════════════════════════════════════════"
    
    # 初期起動確認
    if ! check_health; then
        if ! start_bridge; then
            log_message "❌ 初期起動失敗"
            exit 1
        fi
    fi
    
    log_message "✅ 初期チェック完了 - 監視開始"
    
    # 無限監視ループ
    while true; do
        sleep 30  # 30秒ごとにチェック
        
        if ! check_health; then
            recover_from_crash
        else
            # 5分ごとにログ出力
            if [ $(($(date +%s) % 300)) -lt 30 ]; then
                log_message "✅ LINE Bridge 正常稼働中"
            fi
        fi
    done
}

# 実行
main
