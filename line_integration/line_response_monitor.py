#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
LINE Response Monitor
Claude Code の応答ファイルを監視して LINE に自動送信
"""

import os
import json
import time
import logging
import glob
import threading
from pathlib import Path
from dotenv import load_dotenv
from linebot import LineBotApi
from linebot.models import TextSendMessage

load_dotenv()

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - LINE_RESPONSE_MONITOR - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

LINE_CHANNEL_ACCESS_TOKEN = os.environ.get('LINE_CHANNEL_ACCESS_TOKEN')
OUTBOX_DIR = Path('/home/planj/Claude-Code-Communication/a2a_system/shared/claude_outbox')

line_bot_api = LineBotApi(LINE_CHANNEL_ACCESS_TOKEN)

def monitor_responses():
    """レスポンスファイルを監視して LINE に送信"""
    logger.info("📱 LINE Response Monitor 起動 - 重複防止機構有効")

    PROCESSED_MARKER = '.processed'

    while True:
        try:
            # レスポンスファイルを検索
            response_files = glob.glob(str(OUTBOX_DIR / 'response_line_*.json'))

            for response_file in response_files:
                # 既に処理済みか確認（.processed ファイルの有無）
                processed_marker = response_file + PROCESSED_MARKER
                if os.path.exists(processed_marker):
                    # 古い .processed ファイルを削除
                    try:
                        os.remove(response_file)
                        os.remove(processed_marker)
                        logger.info(f"🗑️ 古いファイル削除（マーカー有）: {response_file}")
                    except:
                        pass
                    continue

                try:
                    with open(response_file, 'r', encoding='utf-8') as f:
                        response_data = json.load(f)

                    to_user_id = response_data.get('to_user_id')
                    # 複数のキー名に対応: 'text' または 'message'
                    message_text = response_data.get('text') or response_data.get('message')

                    if to_user_id and message_text:
                        # LINE に送信
                        line_bot_api.push_message(
                            to_user_id,
                            TextSendMessage(text=message_text)
                        )
                        logger.info(f"✅ LINE 送信完了: {to_user_id}")

                        # 処理済みマーカーを作成（ファイルはすぐ削除）
                        with open(processed_marker, 'w') as f:
                            f.write(f"Processed at {time.time()}")

                        # 元のファイルを削除
                        try:
                            os.remove(response_file)
                            logger.info(f"🗑️ ファイル削除: {response_file}")
                        except Exception as e:
                            logger.warning(f"⚠️ ファイル削除失敗: {e}")

                except json.JSONDecodeError as e:
                    logger.error(f"❌ JSON パースエラー: {response_file} - {e}")
                except Exception as e:
                    logger.error(f"❌ ファイル処理エラー: {e}")

            time.sleep(2)  # 2秒ごとにチェック

        except Exception as e:
            logger.error(f"❌ モニター エラー: {e}")
            time.sleep(5)

if __name__ == '__main__':
    monitor_responses()

