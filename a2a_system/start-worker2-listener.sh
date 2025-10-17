#!/bin/bash

# Worker2 メッセージ監視システム起動スクリプト

echo "=================================================="
echo "🤖 Worker2 A2A メッセージ監視システム起動"
echo "=================================================="
echo ""

cd "$(dirname "$0")" || exit

# Python実行
python3 bridges/worker2_message_listener.py

