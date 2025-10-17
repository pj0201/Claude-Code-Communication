#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
GitHub Issue Monitor
新しいLINE-notificationラベルのIssueを検知し、claude_inboxに通知
"""
import os
import json
import time
import requests
from dotenv import load_dotenv

load_dotenv()

GITHUB_TOKEN = os.environ.get('GITHUB_TOKEN')
GITHUB_REPO = os.environ.get('GITHUB_REPO', 'pj0201/Claude-Code-Communication')
CLAUDE_INBOX = '/home/planj/Claude-Code-Communication/a2a_system/shared/claude_inbox'
CHECK_INTERVAL = 30  # 30秒ごとにチェック

# 最後に処理したIssue番号を記憶
LAST_PROCESSED_FILE = '/tmp/github_issue_last_processed.txt'

def get_last_processed_issue():
    """最後に処理したIssue番号を取得"""
    if os.path.exists(LAST_PROCESSED_FILE):
        with open(LAST_PROCESSED_FILE, 'r') as f:
            return int(f.read().strip())
    return 0

def save_last_processed_issue(issue_number):
    """最後に処理したIssue番号を保存"""
    with open(LAST_PROCESSED_FILE, 'w') as f:
        f.write(str(issue_number))

def check_new_issues():
    """新しいLINE-notificationラベルのIssueをチェック"""
    headers = {
        "Authorization": f"token {GITHUB_TOKEN}",
        "Accept": "application/vnd.github.v3+json"
    }

    # LINE-notificationラベルのopen Issueを取得
    url = f"https://api.github.com/repos/{GITHUB_REPO}/issues"
    params = {
        "state": "open",
        "labels": "LINE-notification",
        "sort": "created",
        "direction": "desc"
    }

    try:
        response = requests.get(url, headers=headers, params=params, timeout=10)
        if response.status_code != 200:
            print(f"❌ GitHub API Error: {response.status_code}")
            return

        issues = response.json()
        last_processed = get_last_processed_issue()

        for issue in issues:
            issue_number = issue['number']

            # 既に処理済みならスキップ
            if issue_number <= last_processed:
                continue

            # 新しいIssue発見
            print(f"🔔 新しいIssue検知: #{issue_number} - {issue['title']}")

            # claude_inboxに通知ファイルを作成
            timestamp = time.strftime('%Y%m%d_%H%M%S')
            notification = {
                "type": "GITHUB_ISSUE_NOTIFICATION",
                "sender": "github_issue_monitor",
                "target": "claude_code",
                "message_id": f"github_issue_{issue_number}_{timestamp}",
                "timestamp": timestamp,
                "issue_number": issue_number,
                "issue_title": issue['title'],
                "issue_body": issue['body'],
                "issue_url": issue['html_url'],
                "labels": [label['name'] for label in issue['labels']]
            }

            inbox_file = os.path.join(CLAUDE_INBOX, f"github_issue_{issue_number}_{timestamp}.json")
            with open(inbox_file, 'w', encoding='utf-8') as f:
                json.dump(notification, f, ensure_ascii=False, indent=2)

            print(f"✅ Claude Codeに通知: {inbox_file}")

            # 処理済みとして記録
            save_last_processed_issue(issue_number)

    except Exception as e:
        print(f"❌ エラー: {e}")

def main():
    """メインループ"""
    print("🚀 GitHub Issue Monitor起動")
    print(f"📍 監視対象: {GITHUB_REPO}")
    print(f"⏱️  チェック間隔: {CHECK_INTERVAL}秒")
    print(f"📁 通知先: {CLAUDE_INBOX}")

    while True:
        check_new_issues()
        time.sleep(CHECK_INTERVAL)

if __name__ == '__main__':
    main()
