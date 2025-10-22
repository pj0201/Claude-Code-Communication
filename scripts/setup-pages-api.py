#!/usr/bin/env python3
import json
import urllib.request
import urllib.error
import os

token = os.environ.get('GITHUB_TOKEN') or os.environ.get('GH_TOKEN')

if not token:
    print("❌ GitHub token が見つかりません")
    print("")
    print("セットアップ方法:")
    print("  1. Personal Access Token を生成:")
    print("     https://github.com/settings/tokens/new")
    print("     スコープ: repo, admin:repo_hook")
    print("")
    print("  2. トークンを環境変数に設定:")
    print("     export GITHUB_TOKEN='ghp_xxxxxxxxxx...'")
    print("")
    print("  3. このスクリプトを再実行")
    exit(1)

url = "https://api.github.com/repos/pj0201/Claude-Code-Communication/pages"

headers = {
    'Authorization': f'token {token}',
    'Accept': 'application/vnd.github.v3+json',
    'Content-Type': 'application/json'
}

# PUT リクエストで設定
data = {
    'source': {
        'branch': 'master',
        'path': '/docs'
    }
}

req = urllib.request.Request(
    url,
    data=json.dumps(data).encode('utf-8'),
    headers=headers,
    method='PUT'
)

try:
    with urllib.request.urlopen(req) as response:
        result = json.loads(response.read().decode('utf-8'))
        print("✅ GitHub Pages 設定が更新されました！")
        print(f"\n詳細:")
        print(f"  Status: {response.status}")
        print(f"  Build Type: {result.get('build_type', 'default')}")
        print(f"  Public: {result.get('public', False)}")
        print(f"  HTML URL: {result.get('html_url', 'N/A')}")
        
except urllib.error.HTTPError as e:
    print(f"❌ エラー: HTTP {e.code}")
    try:
        error_data = json.loads(e.read().decode('utf-8'))
        print(f"詳細: {error_data.get('message', 'Unknown error')}")
        
        # スコープエラーの場合
        if e.code == 403 and 'resource' in error_data.get('message', '').lower():
            print("\n💡 解決策:")
            print("  トークンの scope を確認してください:")
            print("  https://github.com/settings/tokens")
            print("  必要な scope: admin:repo_hook")
    except:
        pass

except Exception as e:
    print(f"❌ エラー: {e}")

