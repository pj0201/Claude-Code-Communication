#!/bin/bash
# LINEメッセージリアルタイム監視スクリプト
#
# バックグラウンドで動作し、新着LINEメッセージを検知したら
# ユーザーに通知する

OUTBOX_DIR="/home/planj/Claude-Code-Communication/a2a_system/shared/claude_outbox"
READ_DIR="$OUTBOX_DIR/read"
CHECK_INTERVAL=5

echo "🚀 LINEリアルタイム監視開始"
echo "チェック間隔: ${CHECK_INTERVAL}秒"
echo "監視ディレクトリ: $OUTBOX_DIR"
echo ""

mkdir -p "$READ_DIR"

while true; do
  # 新着メッセージファイルを検索（1分以内に作成されたもの）
  NEW_FILES=$(find "$OUTBOX_DIR" -maxdepth 1 \( -name "response_line_*.json" -o -name "notification_line_*.json" \) -type f -mmin -1 2>/dev/null)

  if [ -n "$NEW_FILES" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📱 新着LINEメッセージ検出！ $(date '+%Y-%m-%d %H:%M:%S')"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    echo "$NEW_FILES" | while read -r file; do
      if [ -f "$file" ]; then
        echo "📄 ファイル: $(basename "$file")"

        if command -v jq &> /dev/null; then
          # メッセージ内容を表示
          TEXT=$(jq -r '.text // .original_message.text // "（内容なし）"' "$file" 2>/dev/null)
          TIMESTAMP=$(jq -r '.timestamp // .original_message.timestamp // ""' "$file" 2>/dev/null)

          echo "⏰ $TIMESTAMP"
          echo "💬 メッセージ:"
          echo "$TEXT"
          echo ""
        fi

        # 読み取り済みに移動（重複検出防止）
        mv "$file" "$READ_DIR/" 2>/dev/null || true
        echo "✅ 処理済みに移動"
      fi
      echo "---"
    done

    echo ""
  fi

  sleep $CHECK_INTERVAL
done
