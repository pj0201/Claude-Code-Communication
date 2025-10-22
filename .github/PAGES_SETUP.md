# GitHub Pages セットアップ手順

GitHub Pages の自動設定スクリプトはトークンスコープの制限により実行できません。
以下の簡単な手動設定で完了します（2分以内）。

## ⚡ 即座に実施する設定（必須）

### ステップ1: GitHub リポジトリ Settings を開く
```
https://github.com/pj0201/Claude-Code-Communication/settings/pages
```

### ステップ2: Pages セクションで設定
以下を選択：
- **Source**: "Deploy from a branch"
- **Branch**: `master`
- **Folder**: `/docs`
- **Save** ボタンをクリック

## ✅ 完了確認

設定後、以下で確認可能：
- GitHub Pages URL: https://pj0201.github.io/Claude-Code-Communication/
- Settings → Pages に "✓ Your site is live at..." と表示されたら完了

## 🎯 この設定で自動化される内容

設定後は以下が自動的に行われます：
- ✅ `master` ブランチの `docs/` フォルダを監視
- ✅ 変更を検出時に自動ビルド・デプロイ
- ✅ Jekyll で `_config.yml` を自動処理
- ✅ スキル学習レポート（monthly_summary）が自動公開

## 📝 注記

- GitHub API は `admin:repo_hook` スコープが必要（セキュリティ上、制限されている）
- GitHub CLI インストール失敗（環境制限）
- そのため手動設定が必要になっています
