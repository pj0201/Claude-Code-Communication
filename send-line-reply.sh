#!/bin/bash
# Worker3からLINEに返信を送るスクリプト

USER_ID="$1"
MESSAGE="$2"

if [ -z "$USER_ID" ] || [ -z "$MESSAGE" ]; then
    echo "Usage: $0 <USER_ID> <MESSAGE>"
    exit 1
fi

# Python scriptでLINE push_messageを実行
python3 - << EOF
import os
from linebot import LineBotApi
from linebot.models import TextSendMessage

LINE_CHANNEL_ACCESS_TOKEN = os.environ.get('LINE_CHANNEL_ACCESS_TOKEN')
if not LINE_CHANNEL_ACCESS_TOKEN:
    print("❌ LINE_CHANNEL_ACCESS_TOKEN not set")
    exit(1)

line_bot_api = LineBotApi(LINE_CHANNEL_ACCESS_TOKEN)

try:
    line_bot_api.push_message(
        "$USER_ID",
        TextSendMessage(text="$MESSAGE")
    )
    print("✅ LINEに返信を送信しました")
except Exception as e:
    print(f"❌ エラー: {e}")
    exit(1)
EOF
