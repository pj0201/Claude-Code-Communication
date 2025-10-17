#!/bin/bash

# Claude Code リアルタイムメッセージリスナー起動スクリプト

echo "=================================================="
echo "💻 Claude Code リアルタイム A2A メッセージリスナー"
echo "=================================================="
echo ""
echo "このリスナーが起動すると、Worker2などからのメッセージに"
echo "リアルタイムで気づいて、対話形式で応答できます。"
echo ""
echo "使用方法："
echo "  1. Worker2からA2Aメッセージを送信"
echo "  2. このリスナーがメッセージを受信・表示"
echo "  3. 対話形式で応答を入力（Ctrl+D で終了）"
echo "  4. 応答が Worker2 に自動送信される"
echo ""
echo "=================================================="
echo ""

cd "$(dirname "$0")" || exit

# Python実行
python3 bridges/claude_code_listener.py

