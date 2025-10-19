#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
LINE to Claude Code Bridge
LINEからのメッセージをClaude Code（スモールチーム）に転送し、応答を返す
"""
import os
import json
import time
import logging
import requests
import base64
from flask import Flask, request, abort
from linebot import LineBotApi, WebhookHandler
from linebot.exceptions import InvalidSignatureError
from linebot.models import MessageEvent, TextMessage, ImageMessage, TextSendMessage
from dotenv import load_dotenv

# .envファイル読み込み
load_dotenv()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# LINE Bot認証情報
LINE_CHANNEL_ACCESS_TOKEN = os.environ.get('LINE_CHANNEL_ACCESS_TOKEN')
LINE_CHANNEL_SECRET = os.environ.get('LINE_CHANNEL_SECRET')

# GitHub認証情報（Issue作成用）
GITHUB_TOKEN = os.environ.get('GITHUB_TOKEN')
GITHUB_REPO = os.environ.get('GITHUB_REPO', 'planj/Claude-Code-Communication')

if not LINE_CHANNEL_ACCESS_TOKEN or not LINE_CHANNEL_SECRET:
    logger.error("❌ LINE認証情報が設定されていません")
    exit(1)

line_bot_api = LineBotApi(LINE_CHANNEL_ACCESS_TOKEN)
handler = WebhookHandler(LINE_CHANNEL_SECRET)

# Claude Code通信用ディレクトリ（スモールチーム用A2Aシステム）
CLAUDE_INBOX = '/home/planj/Claude-Code-Communication/a2a_system/shared/claude_inbox'
CLAUDE_OUTBOX = '/home/planj/Claude-Code-Communication/a2a_system/shared/claude_outbox'
IMAGE_STORAGE = '/home/planj/claudecode-wind/line-integration/images'

def create_github_issue(user_message, user_id, timestamp):
    """
    GitHub Issueを作成し、Claude Code ペイン(0.1)に/process-issueコマンドを送信

    Args:
        user_message: LINEメッセージテキスト
        user_id: LINEユーザーID
        timestamp: タイムスタンプ

    Returns:
        tuple: (issue_url, issue_number)（成功時）、(None, None)（失敗時）
    """
    if not GITHUB_TOKEN:
        logger.warning("⚠️ GITHUB_TOKEN未設定 - Issue作成スキップ")
        return None, None

    try:
        # ユーザーIDを短縮（プライバシー保護）
        user_short = user_id[-8:] if len(user_id) > 8 else user_id

        # Issue作成
        issue_title = f"📱 LINE通知 ({timestamp})"
        issue_body = f"""@claude

## LINE通知

**受信時刻**: {timestamp}
**ユーザー**: `...{user_short}`

### メッセージ内容

{user_message}

---
*この通知はLINE Bridgeから自動作成されました*
"""

        headers = {
            "Authorization": f"token {GITHUB_TOKEN}",
            "Accept": "application/vnd.github.v3+json"
        }

        data = {
            "title": issue_title,
            "body": issue_body,
            "labels": ["LINE-notification"]
        }

        response = requests.post(
            f"https://api.github.com/repos/{GITHUB_REPO}/issues",
            headers=headers,
            json=data,
            timeout=10
        )

        if response.status_code == 201:
            issue_url = response.json().get('html_url')
            issue_number = response.json().get('number')
            logger.info(f"✅ GitHub Issue作成成功: {issue_url}")

            # ★新規★ Issue作成後、Claude Code ペイン(0.1)に/process-issueコマンドを送信
            # エラーが発生しても Issue は作成されているので、返す
            try:
                send_to_claude_pane(issue_number)
            except Exception as e:
                logger.warning(f"⚠️ Claude Code ペイン通知失敗（Issue は作成済み）: {e}")

            return issue_url, issue_number
        else:
            logger.error(f"❌ GitHub Issue作成失敗: {response.status_code} - {response.text}")
            return None, None

    except Exception as e:
        logger.error(f"❌ GitHub Issue作成エラー: {e}")
        return None, None

def send_to_claude_pane(issue_number):
    """
    ★新規★ Claude Code ペイン(0.1)に/process-issueコマンドを送信

    Args:
        issue_number: GitHub Issue番号
    """
    try:
        import subprocess
        import shutil

        # /process-issue スクリプトのパスを確認
        process_issue_path = shutil.which('process-issue') or '/home/planj/bin/process-issue'

        # tmux send-keys でペイン0.1に/process-issue コマンドを送信
        cmd1_result = subprocess.run([
            'tmux', 'send-keys',
            '-t', 'gpt5-a2a-line:0.1',
            '-l', f'{process_issue_path} #{issue_number}'
        ], check=False, timeout=5, capture_output=True, text=True)

        if cmd1_result.returncode != 0:
            logger.warning(f"⚠️ tmux send-keys コマンド実行エラー: {cmd1_result.stderr}")

        cmd2_result = subprocess.run([
            'tmux', 'send-keys',
            '-t', 'gpt5-a2a-line:0.1',
            'C-m'
        ], check=False, timeout=5, capture_output=True, text=True)

        if cmd2_result.returncode != 0:
            logger.warning(f"⚠️ tmux send-keys (Enter) 実行エラー: {cmd2_result.stderr}")

        logger.info(f"✅ Claude Code ペイン(0.1)に {process_issue_path} #{issue_number} を送信しました")
    except Exception as e:
        logger.error(f"❌ tmux send-keys エラー（ペイン0.1へのコマンド送信失敗）: {e}", exc_info=True)

def send_to_claude(user_message, user_id, image_path=None):
    """
    Claude Code（スモールチーム）にメッセージを送信

    a2a_systemの通信プロトコルを使用

    Args:
        user_message: テキストメッセージ
        user_id: LINEユーザーID
        image_path: 画像ファイルパス（オプション）
    """
    timestamp = time.strftime('%Y%m%d_%H%M%S')
    message_id = f"line_{user_id}_{timestamp}"

    # GitHub Issueを作成（ダイレクト通知）
    # ★修正★: タプル(issue_url, issue_number)を受け取る
    issue_url, issue_number = create_github_issue(user_message, user_id, timestamp)

    # Claude Code（Worker3）へのメッセージフォーマット
    # Claude Codeが直接受け取り、必要に応じてGPT-5にレビュー依頼
    message = {
        "type": "LINE_MESSAGE",
        "sender": "line_user",
        "target": "claude_code",
        "message_id": message_id,
        "text": user_message,
        "user_id": user_id,
        "source": "LINE",
        "timestamp": timestamp
    }

    # GitHub Issue URLと番号を追加
    if issue_url:
        message["github_issue"] = issue_url
    if issue_number:
        message["issue_number"] = issue_number

    # 画像がある場合は追加
    if image_path:
        message["image_path"] = image_path
        message["has_image"] = True

    # Claude Codeのinboxに保存
    inbox_file = os.path.join(CLAUDE_INBOX, f"{message_id}.json")
    with open(inbox_file, 'w', encoding='utf-8') as f:
        json.dump(message, f, ensure_ascii=False, indent=2)

    logger.info(f"✅ Claude Codeにメッセージ送信: {inbox_file}")
    return message_id

def wait_for_claude_response(message_id, timeout=60):
    """
    Claude Codeからの応答を待機

    Args:
        message_id: メッセージID
        timeout: タイムアウト秒数

    Returns:
        str: Claude Codeの応答テキスト
    """
    start_time = time.time()

    while time.time() - start_time < timeout:
        # Outboxをチェック（message_idに関連する応答を探す）
        import glob
        # Claude Codeからの応答ファイルを探す
        pattern = os.path.join(CLAUDE_OUTBOX, f"response_*{message_id}*.json")
        response_files = glob.glob(pattern)

        # パターンマッチしない場合は、最新の応答ファイルをチェック
        if not response_files:
            all_responses = glob.glob(os.path.join(CLAUDE_OUTBOX, "response_*.json"))
            # 最近1秒以内に作成されたファイルのみ
            recent_responses = [f for f in all_responses if os.path.getmtime(f) > start_time]
            if recent_responses:
                response_files = [max(recent_responses, key=os.path.getmtime)]

        if response_files:
            # 最新のファイルを取得
            response_file = max(response_files, key=os.path.getmtime)

            with open(response_file, 'r', encoding='utf-8') as f:
                response = json.load(f)

            # ファイル削除（処理済み）
            os.remove(response_file)

            logger.info(f"✅ Claude Codeから応答受信: {response_file}")

            # 応答テキストを抽出（複数の形式に対応）
            if 'text' in response:
                return response['text']
            elif 'answer' in response:
                return response['answer']
            elif 'response' in response:
                return response['response']
            elif 'content' in response and isinstance(response['content'], dict) and 'text' in response['content']:
                return response['content']['text']
            elif 'content' in response:
                return str(response['content'])
            else:
                return str(response)

        time.sleep(1)

    # タイムアウト
    logger.warning(f"⏰ タイムアウト: {message_id}")
    return "⏰ タイムアウト\n\n応答時間を超過しました。"

@app.route('/webhook', methods=['POST'])
def webhook():
    """LINE Webhook エンドポイント"""
    signature = request.headers['X-Line-Signature']
    body = request.get_data(as_text=True)

    logger.info(f"📥 Webhook受信")

    try:
        handler.handle(body, signature)
    except InvalidSignatureError:
        logger.error("❌ 不正な署名")
        abort(400)

    return 'OK'

def download_image(message_id):
    """
    LINEから画像をダウンロード

    Args:
        message_id: LINEメッセージID

    Returns:
        str: 保存した画像のファイルパス
    """
    try:
        # LINE APIから画像コンテンツを取得
        message_content = line_bot_api.get_message_content(message_id)

        # 画像を保存
        timestamp = time.strftime('%Y%m%d_%H%M%S')
        image_filename = f"line_image_{timestamp}_{message_id}.jpg"
        image_path = os.path.join(IMAGE_STORAGE, image_filename)

        with open(image_path, 'wb') as f:
            for chunk in message_content.iter_content():
                f.write(chunk)

        logger.info(f"📷 画像保存: {image_path}")
        return image_path

    except Exception as e:
        logger.error(f"❌ 画像ダウンロードエラー: {e}")
        return None

@handler.add(MessageEvent, message=TextMessage)
def handle_text_message(event):
    """テキストメッセージ受信時の処理"""
    user_id = event.source.user_id
    text = event.message.text

    logger.info(f"💬 メッセージ受信: {text} (from {user_id})")

    # 「受付確認」のみ即座に返信
    line_bot_api.reply_message(
        event.reply_token,
        TextSendMessage(text=f"✅ 受付完了\n\n【依頼内容】\n{text}\n\n処理を開始します。")
    )

    # Claude Code に転送
    message_id = send_to_claude(text, user_id)

    # ★変更★: バックグラウンド処理での応答ファイル検出・LINE送信
    # Claude Code がタスク完了 or エラー or 進行中停止時に応答ファイルを作成
    import threading
    def detect_and_send_response():
        """
        Claude Code からの応答ファイル検出・LINE送信

        Claude Code が以下の場合に Outbox に応答ファイルを作成:
        1. ✅ タスク完了時: response_line_*.json (status: success)
        2. ⏳ 進行中で停止: response_line_*.json (status: in_progress)
        3. ❌ エラー発生: response_line_*.json (status: error)
        """
        start_time = time.time()
        timeout = 600  # 10分（長時間処理対応）

        while time.time() - start_time < timeout:
            # Outbox から応答ファイルを探す
            import glob
            pattern = os.path.join(CLAUDE_OUTBOX, f"response_*{message_id}*.json")
            response_files = glob.glob(pattern)

            if response_files:
                # 応答ファイルが見つかった
                response_file = max(response_files, key=os.path.getmtime)

                try:
                    with open(response_file, 'r', encoding='utf-8') as f:
                        response = json.load(f)

                    # LINE に送信
                    response_text = response.get('text', str(response))
                    line_bot_api.push_message(
                        user_id,
                        TextSendMessage(text=response_text)
                    )
                    logger.info(f"✅ LINE返信完了: {message_id}")

                    # ファイル削除（処理済み）
                    os.remove(response_file)
                    return

                except Exception as e:
                    logger.error(f"❌ 応答ファイル処理エラー: {e}")
                    return

            time.sleep(2)  # 2秒ごとにチェック

        # タイムアウト時もログのみ（LINE には返信しない）
        logger.warning(f"⏰ 応答タイムアウト（600秒）: {message_id}")

    # 別スレッドで実行
    thread = threading.Thread(target=detect_and_send_response)
    thread.daemon = True
    thread.start()

    logger.info(f"📤 GitHub Issue経由でタスク処理開始: {message_id}")

@handler.add(MessageEvent, message=ImageMessage)
def handle_image_message(event):
    """画像メッセージ受信時の処理"""
    user_id = event.source.user_id
    message_id = event.message.id

    logger.info(f"📷 画像受信 (from {user_id})")

    # 「受付確認」のみ即座に返信
    line_bot_api.reply_message(
        event.reply_token,
        TextSendMessage(text="✅ 画像受付完了\n\n処理を開始します。")
    )

    # バックグラウンドスレッドで処理
    import threading
    def process_image():
        # 画像をダウンロード
        image_path = download_image(message_id)

        if not image_path:
            # エラーを LINE に送信
            line_bot_api.push_message(
                user_id,
                TextSendMessage(text="❌ 画像のダウンロードに失敗しました。")
            )
            logger.error(f"❌ 画像ダウンロード失敗: {message_id}")
            return

        # Claude Codeに転送（画像パスを含む）
        task_message_id = send_to_claude("", user_id, image_path=image_path)

        # ★変更★: 応答ファイル検出・LINE送信
        # Claude Code がタスク完了 or エラー or 進行中停止時に応答ファイルを作成
        start_time = time.time()
        timeout = 600  # 10分（長時間処理対応）

        while time.time() - start_time < timeout:
            # Outbox から応答ファイルを探す
            import glob
            pattern = os.path.join(CLAUDE_OUTBOX, f"response_*{task_message_id}*.json")
            response_files = glob.glob(pattern)

            if response_files:
                # 応答ファイルが見つかった
                response_file = max(response_files, key=os.path.getmtime)

                try:
                    with open(response_file, 'r', encoding='utf-8') as f:
                        response = json.load(f)

                    # LINE に送信
                    response_text = response.get('text', str(response))
                    line_bot_api.push_message(
                        user_id,
                        TextSendMessage(text=response_text)
                    )
                    logger.info(f"✅ 画像処理完了・LINE返信: {task_message_id}")

                    # ファイル削除（処理済み）
                    os.remove(response_file)
                    return

                except Exception as e:
                    logger.error(f"❌ 応答ファイル処理エラー: {e}")
                    return

            time.sleep(2)  # 2秒ごとにチェック

        # タイムアウト時もログのみ（LINE には返信しない）
        logger.warning(f"⏰ 画像処理タイムアウト（600秒）: {task_message_id}")

    # 別スレッドで実行
    thread = threading.Thread(target=process_image)
    thread.daemon = True
    thread.start()

    logger.info(f"📤 画像処理バックグラウンド開始")

@app.route('/health', methods=['GET'])
def health():
    """ヘルスチェック"""
    return {'status': 'ok', 'service': 'LINE to Claude Code Bridge'}

if __name__ == '__main__':
    logger.info("🚀 LINE to Claude Code Bridge起動")
    logger.info(f"📍 Webhook URL: http://localhost:5000/webhook")
    logger.info(f"📁 Claude Inbox: {CLAUDE_INBOX}")
    logger.info(f"📁 Claude Outbox: {CLAUDE_OUTBOX}")
    logger.info(f"📁 Image Storage: {IMAGE_STORAGE}")

    # ディレクトリ確認
    os.makedirs(CLAUDE_INBOX, exist_ok=True)
    os.makedirs(CLAUDE_OUTBOX, exist_ok=True)
    os.makedirs(IMAGE_STORAGE, exist_ok=True)

    # サーバー起動
    app.run(host='0.0.0.0', port=5000, debug=False)
