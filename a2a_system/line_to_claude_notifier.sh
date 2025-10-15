#!/usr/bin/env bash
#
# LINE to Claude Notifier
# LINEメッセージをClaude Codeペインに通知
#

set -euo pipefail

# ディレクトリ設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINE_INBOX="${SCRIPT_DIR}/shared/claude_outbox"
NOTIFICATION_DIR="${SCRIPT_DIR}/shared/claude_inbox"
LOG_FILE="${SCRIPT_DIR}/line_to_claude_notifier.log"

# Claude Codeが動作しているtmuxペインを検索
CLAUDE_PANE=$(tmux list-panes -a -F "#{pane_id} #{pane_current_command}" | grep "claude" | head -1 | awk '{print $1}')

# ログ関数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "========================================="
log "LINE to Claude Notifier Starting..."
log "LINE INBOX: $LINE_INBOX"
log "NOTIFICATION DIR: $NOTIFICATION_DIR"
log "Claude Pane: ${CLAUDE_PANE:-NOT FOUND}"
log "========================================="

if [ -z "$CLAUDE_PANE" ]; then
    log "❌ Claude Code pane not found!"
    exit 1
fi

# inotifywaitでLINE INBOXを監視
inotifywait -m -e create --format '%f' "$LINE_INBOX" | while read filename; do
    # notification_line_*.jsonファイルのみ処理
    if [[ $filename == notification_line_*.json ]]; then
        log "📬 LINE message detected: $filename"

        # ファイルの内容を読み込み
        line_file="$LINE_INBOX/$filename"

        # ファイルが完全に書き込まれるまで少し待機
        sleep 0.5

        if [ -f "$line_file" ]; then
            # メッセージ内容を抽出
            message_text=$(jq -r '.original_message.text // "No text"' "$line_file")
            user_id=$(jq -r '.original_message.user_id // "unknown"' "$line_file")
            timestamp=$(date '+%Y%m%d_%H%M%S')

            log "💬 Message from $user_id: $message_text"

            # 通知ファイルを作成
            notification_file="$NOTIFICATION_DIR/URGENT_LINE_${timestamp}.json"
            cp "$line_file" "$notification_file"
            log "📁 Notification file created: $notification_file"

            # Claude Codeペインに視覚的通知を送信
            tmux display-message -t "$CLAUDE_PANE" "📬 新着LINEメッセージ from ${user_id}: ${message_text:0:50}..."
            log "✅ Notification sent to Claude Code pane"

            # tmux status-lineに通知カウントを追加（オプション）
            # 既存のstatus-rightに追加
            current_status=$(tmux show-option -gqv status-right)
            tmux set-option -g status-right "📬LINE:1 | $current_status"

            log "🔔 Status line updated"

            # 元のLINE通知ファイルを処理済みディレクトリに移動
            processed_dir="$LINE_INBOX/processed"
            mkdir -p "$processed_dir"
            mv "$line_file" "$processed_dir/"
            log "🗂️ LINE notification moved to processed/"
        else
            log "⚠️ File disappeared: $line_file"
        fi
    fi
done
