#!/usr/bin/env python3
import json
import urllib.request
import urllib.error
import os

token = os.environ.get('GITHUB_TOKEN') or os.environ.get('GH_TOKEN')

if not token:
    print("⚠️  GitHub token が見つかりません")
    print("現在の状態を確認するには:")
    print("  export GITHUB_TOKEN='your_personal_access_token'")
    print("その後もう一度実行してください")
    exit(1)

url = "https://api.github.com/repos/pj0201/Claude-Code-Communication"

headers = {
    'Authorization': f'token {token}',
    'Accept': 'application/vnd.github.v3+json'
}

req = urllib.request.Request(url, headers=headers)

try:
    with urllib.request.urlopen(req) as response:
        repo = json.loads(response.read().decode('utf-8'))
        
        print("✅ GitHub リポジトリ情報取得成功\n")
        print(f"Repository: {repo.get('full_name')}")
        print(f"Has Pages: {repo.get('has_pages', False)}")
        print(f"Description: {repo.get('description', 'N/A')}")
        
        # Pages情報取得
        pages_url = f"https://api.github.com/repos/pj0201/Claude-Code-Communication/pages"
        pages_req = urllib.request.Request(pages_url, headers=headers)
        
        try:
            with urllib.request.urlopen(pages_req) as pages_response:
                pages = json.loads(pages_response.read().decode('utf-8'))
                print(f"\n📄 GitHub Pages 情報:")
                print(f"  Status: {pages.get('status', 'unknown')}")
                print(f"  Public: {pages.get('public', False)}")
                print(f"  HTML URL: {pages.get('html_url', 'N/A')}")
                print(f"  HTTPS Enforced: {pages.get('https_enforced', 'N/A')}")
                
        except urllib.error.HTTPError as e:
            if e.code == 404:
                print(f"\n⚠️  GitHub Pages がまだ設定されていません")
                print(f"以下のURLで設定してください:")
                print(f"https://github.com/pj0201/Claude-Code-Communication/settings/pages")
            else:
                print(f"❌ Pages API エラー: {e.status} {e.reason}")
        
except Exception as e:
    print(f"❌ エラー: {e}")

