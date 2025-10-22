# GitHub Pages セットアップ最終ガイド

## 状況説明

GitHub Pages の自動設定は以下の理由で実装できません：
- GitHub API には `admin:repo_hook` scope が必要
- 現在のトークンにこのスコープがない
- セキュリティ上の制限により、トークンスコープはユーザーが手動で設定する必要

## ⚡ 2分で完了する手動セットアップ

### パターン A: GitHub Web UI （最も簡単 🎯）

1. **Settings → Pages を開く**
   ```
   https://github.com/pj0201/Claude-Code-Communication/settings/pages
   ```

2. **Source セクションで以下を選択:**
   - [ ] Source: "Deploy from a branch" を選択
   - [ ] Branch: `master` を選択
   - [ ] Folder: `/docs` を選択
   - [ ] **Save** ボタンをクリック

3. **完了確認**
   - ページを更新してメッセージを確認
   - "✓ Your site is live at https://pj0201.github.io/Claude-Code-Communication" が表示されたら完了

### パターン B: トークンスコープをアップグレードして自動化

トークンを再生成し、自動セットアップスクリプトを実行：

```bash
# 1. 新しいトークンを生成
# URL: https://github.com/settings/tokens/new
# 必要な scope チェック:
#  ✓ repo (full)
#  ✓ admin:repo_hook
# トークン名: "Pages Setup Token" 等

# 2. 環境変数に設定
export GITHUB_TOKEN='ghp_xxxxxxxxxxxxxxxxxxxx'

# 3. 自動セットアップスクリプトを実行
python3 /tmp/setup-pages-put.py
```

## 🎯 完了後の効果

設定後は以下が自動化されます：
- ✅ `master` ブランチの `docs/` フォルダを監視
- ✅ ファイル変更時に自動ビルド
- ✅ Jekyll で `_config.yml` を自動処理
- ✅ スキル学習レポート（Monthly Summary）が自動公開

## 📍 確認方法

```bash
# コマンドラインで確認
python3 /tmp/check_pages.py

# ブラウザで確認
# https://pj0201.github.io/Claude-Code-Communication/
```

## ⚠️ 注記

このドキュメント作成日: 2025-10-22
GitHub API scope 制限の詳細: https://docs.github.com/en/rest/overview/endpoints-available-for-github-apps

