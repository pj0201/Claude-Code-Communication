#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
LINE メッセージカウンター
無料プラン500通制限の追跡
"""
import json
import os
from datetime import datetime
from pathlib import Path

COUNTER_FILE = Path(__file__).parent / 'message_count.json'

def initialize_counter():
    """カウンターファイルを初期化"""
    if not COUNTER_FILE.exists():
        data = {
            "total_messages": 0,
            "month_messages": 0,
            "current_month": datetime.now().strftime("%Y-%m"),
            "last_reset": datetime.now().isoformat(),
            "history": []
        }
        save_counter(data)
        return data
    return load_counter()

def load_counter():
    """カウンターデータを読み込み"""
    with open(COUNTER_FILE, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_counter(data):
    """カウンターデータを保存"""
    with open(COUNTER_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

def increment_counter(message_type='push'):
    """
    メッセージカウントを増加

    Args:
        message_type: 'push' or 'reply' (replyは無料)

    Returns:
        dict: 更新後のカウンター情報
    """
    data = initialize_counter()
    current_month = datetime.now().strftime("%Y-%m")

    # 月が変わったらリセット
    if data['current_month'] != current_month:
        data['current_month'] = current_month
        data['month_messages'] = 0
        data['last_reset'] = datetime.now().isoformat()

    # push_messageのみカウント（reply_messageは無料）
    if message_type == 'push':
        data['total_messages'] += 1
        data['month_messages'] += 1

        # 履歴に記録
        data['history'].append({
            "timestamp": datetime.now().isoformat(),
            "type": message_type,
            "month": current_month
        })

        # 履歴は直近100件のみ保持
        if len(data['history']) > 100:
            data['history'] = data['history'][-100:]

    save_counter(data)
    return data

def get_counter_status():
    """
    カウンター状態を取得

    Returns:
        dict: カウンター情報と警告
    """
    data = initialize_counter()

    remaining = 500 - data['month_messages']
    percentage = (data['month_messages'] / 500) * 100

    status = {
        "month": data['current_month'],
        "used": data['month_messages'],
        "remaining": remaining,
        "limit": 500,
        "percentage": round(percentage, 1),
        "warning": None
    }

    # 警告レベル判定
    if remaining <= 0:
        status['warning'] = "⚠️ 制限到達！これ以上送信できません"
    elif remaining <= 50:
        status['warning'] = "🚨 残り50通以下です"
    elif remaining <= 100:
        status['warning'] = "⚡ 残り100通以下です"
    elif percentage >= 80:
        status['warning'] = "📊 使用率80%超過"

    return status

def format_status_message():
    """
    ステータスメッセージを整形

    Returns:
        str: LINEに送信するメッセージ
    """
    status = get_counter_status()

    msg = f"""📊 LINE送信カウンター

【{status['month']}】
使用: {status['used']} / {status['limit']}通
残り: {status['remaining']}通
使用率: {status['percentage']}%

"""

    if status['warning']:
        msg += f"{status['warning']}\n\n"

    # プログレスバー
    filled = int(status['percentage'] / 5)
    bar = '█' * filled + '░' * (20 - filled)
    msg += f"[{bar}] {status['percentage']}%"

    return msg

if __name__ == '__main__':
    # テスト実行
    print(format_status_message())
