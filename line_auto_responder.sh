#!/bin/bash
# LINE自動応答スクリプト
# notification_line_*.jsonを監視して自動的にLINEに返信する

set -euo pipefail

OUTBOX_DIR="/home/planj/Claude-Code-Communication/a2a_system/shared/claude_outbox"
READ_DIR="$OUTBOX_DIR/read"
LOG_FILE="/tmp/line_auto_responder.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "========================================="
log "🤖 LINE自動応答システム起動"
log "📂 監視ディレクトリ: $OUTBOX_DIR"
log "========================================="

# readディレクトリ作成
mkdir -p "$READ_DIR"

# inotifywaitでnotification_line_*.jsonを監視
inotifywait -m -e create --format '%f' "$OUTBOX_DIR" | while read filename; do
    # notification_line_*.jsonのみ処理
    if [[ $filename == notification_line_*.json ]]; then
        notif_file="$OUTBOX_DIR/$filename"

        log "📬 新着LINE通知検知: $filename"

        # ファイルが完全に書き込まれるまで待機
        sleep 0.5

        if [ ! -f "$notif_file" ]; then
            log "⚠️ ファイルが見つかりません: $notif_file"
            continue
        fi

        # JSON解析
        if ! command -v jq &> /dev/null; then
            log "❌ jqがインストールされていません"
            continue
        fi

        TEXT=$(jq -r '.original_message.text // ""' "$notif_file" 2>/dev/null)
        USER_ID=$(jq -r '.original_message.user_id // ""' "$notif_file" 2>/dev/null)

        if [ -z "$TEXT" ] || [ -z "$USER_ID" ]; then
            log "⚠️ メッセージまたはユーザーIDが取得できません"
            mv "$notif_file" "$READ_DIR/" 2>/dev/null || true
            continue
        fi

        log "💬 メッセージ: $TEXT"
        log "👤 ユーザーID: $USER_ID"

        # 自動応答メッセージ生成
        RESPONSE="Worker3（Claude Code）より：

メッセージを受信しました：
「$TEXT」

現在、自動応答システムが稼働中です。
必要に応じて対応いたします。

受信時刻: $(date '+%Y-%m-%d %H:%M:%S')"

        log "📤 LINEに自動返信を送信中..."

        # LINEに返信
        if python3 /home/planj/Claude-Code-Communication/send_line_push.py "$USER_ID" "$RESPONSE" >> "$LOG_FILE" 2>&1; then
            log "✅ 自動返信成功"
        else
            log "❌ 自動返信失敗"
        fi

        # 処理済みに移動
        mv "$notif_file" "$READ_DIR/" 2>/dev/null || true
        log "🗂️ 通知ファイルをread/に移動"

    fi
done
