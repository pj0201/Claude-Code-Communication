#!/bin/bash
# LINE Bridge 起動スクリプト（常時起動）

echo "🚀 LINE Bridge 起動中..."

# 既存プロセスを停止
pkill -f "line-to-claude-bridge.py" 2>/dev/null
sleep 2

# 環境変数読み込み
export LINE_CHANNEL_ACCESS_TOKEN="UckUbyqRYPfLGj4XwUer3s8SxNnbGad42z7ZsZK1NLWCBdntbRUir50pzkBGF3zT2gUcnnYJD4tYUdOii/IN/CMAh6ezTi4Yhz0UrNxH+hL1VVdQfcKSEIe6484aWKhmz9Xd9leV2NkS8Fecn6giyQdB04t89/1O/w1cDnyilFU="
export LINE_CHANNEL_SECRET="434a82d0fdbae98118211adf6d90a234"

# ディレクトリ移動
cd /home/planj/claudecode-wind/line-integration

# バックグラウンド起動（自動再起動）
nohup python3 line-to-claude-bridge.py > line_bridge.log 2>&1 &
PID=$!
disown

echo "✅ LINE Bridge 起動完了 (PID: $PID)"
echo "📝 ログ: /home/planj/claudecode-wind/line-integration/line_bridge.log"
echo ""
echo "📊 状態確認: ps aux | grep line-to-claude-bridge"
echo "🛑 停止: pkill -f line-to-claude-bridge.py"
