# GitHub Pages セットアップガイド

このドキュメントは、月次学習レポートを GitHub Pages で公開するセットアップ手順を説明します。

## 目次

1. [概要](#概要)
2. [WIKI vs GitHub Pages](#wiki-vs-github-pages)
3. [GitHub Pages セットアップ手順](#github-pages-セットアップ手順)
4. [ドキュメント構造](#ドキュメント構造)
5. [自動デプロイ設定](#自動デプロイ設定)
6. [カスタムドメイン設定](#カスタムドメイン設定)
7. [トラブルシューティング](#トラブルシューティング)

---

## 概要

**GitHub Pages** は、GitHub リポジトリから静的 HTML ページを自動的に公開するサービスです。

**用途**: 月次学習レポートの公開、プロジェクトドキュメンテーション

**メリット**:
- ✅ 無料ホスティング
- ✅ GitHub リポジトリとの統合
- ✅ 自動デプロイ（GitHub Actions）
- ✅ HTTPS 対応
- ✅ カスタムドメイン対応

**公開 URL**: `https://username.github.io/repository-name/`

例: `https://pj0201.github.io/Claude-Code-Communication/`

---

## WIKI vs GitHub Pages

| 項目 | GitHub WIKI | GitHub Pages |
|------|-----------|--------------|
| リポジトリ | 別リポジトリ（*.wiki.git） | メインリポジトリ内（docs/） |
| 形式 | Markdown → HTML（自動） | Markdown または HTML |
| URL 形式 | /wiki/Page-Name | /docs/page-name/ |
| ホスト | GitHub WIKI | GitHub Pages |
| カスタマイズ | 限定的 | 高い自由度 |
| 推奨用途 | プロジェクト Wiki | ドキュメント公開 |

### どちらを選ぶ？

**GitHub WIKI を選ぶ場合**:
- 社内向けドキュメント
- 共同編集が必要
- 公開が不要

**GitHub Pages を選ぶ場合**:
- 公開ドキュメント
- 学習成果の共有
- SEO 重視

---

## GitHub Pages セットアップ手順

### Step 1: リポジトリ設定を確認

```bash
# リポジトリが public か確認
# GitHub Settings → Visibility → Public

# または GitHub CLI で確認
gh repo view --json isPrivate
```

**GitHub Pages は public リポジトリでのみ無料で利用可能です**

### Step 2: docs/ ディレクトリを確認

```bash
# docs/ ディレクトリ構造を確認
tree docs/

# 期待される構造
docs/
├── index.html           （ホームページ）
├── style.css           （スタイルシート）
├── skill_learning_wiki/
│   ├── archives/       （月次レポートアーカイブ）
│   ├── current/        （最新レポート）
│   └── meta/           （インデックスページ）
```

### Step 3: GitHub Pages を有効化

**方法A: GitHub Web UI から設定**

1. リポジトリを GitHub で開く
2. **Settings** → **Pages** に移動
3. **Source** セクションで以下を選択:
   - Branch: `main` (または `master`)
   - Folder: `/ (root)` または `/docs`
4. **Save** をクリック

**方法B: GitHub CLI から設定**

```bash
# GitHub Pages を有効化（/docs フォルダから公開）
gh repo edit --enable-pages --pages-branch main --pages-source /docs

# または確認のみ
gh repo view --json hasPagesSite
```

### Step 4: ビルド設定を確認

GitHub Pages は自動的に Jekyll を実行します。

```bash
# _config.yml を確認（存在すれば）
cat docs/_config.yml
```

Jekyll 設定が不要な場合：

```bash
# .nojekyll ファイルを作成（Jekyll ビルドをスキップ）
touch docs/.nojekyll
git add docs/.nojekyll
git commit -m "Disable Jekyll processing"
git push
```

### Step 5: デプロイを確認

1. GitHub Web UI で **Settings** → **Pages** を確認
2. "Your site is published at: https://..." というメッセージが表示されるか確認
3. 数分待ってから URL にアクセス

**デプロイ時間**: 約 1-2 分

---

## ドキュメント構造

### 推奨フォルダ構造

```
docs/
├── .nojekyll                    （Jekyll ビルドをスキップ）
├── index.html                   （ホームページ）
├── README.md                    （リポジトリ説明）
├── skill_learning_wiki/
│   ├── README.md               （Wiki ホームページ）
│   ├── archives/               （月次レポートアーカイブ）
│   │   ├── 2025/
│   │   │   ├── 2025-10.md
│   │   │   ├── 2025-11.md
│   │   │   └── ...
│   │   └── ...
│   ├── current/                （最新レポート）
│   │   ├── latest.md
│   │   └── summary.json
│   └── meta/
│       └── index.md            （全レポート一覧）
└── style.css                    （オプション: カスタムスタイル）
```

### index.html（ホームページ）

```html
<!DOCTYPE html>
<html>
<head>
    <title>ACE Learning Engine - 月次学習レポート</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto; margin: 20px; }
        h1 { color: #333; }
        a { color: #0366d6; text-decoration: none; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <h1>📊 ACE Learning Engine - 月次学習レポート</h1>
    <p>自律学習システムの月次学習データと分析レポートです。</p>

    <h2>📖 レポート一覧</h2>
    <ul>
        <li><a href="skill_learning_wiki/meta/index.md">全レポート一覧</a></li>
        <li><a href="skill_learning_wiki/current/latest.md">最新レポート</a></li>
    </ul>

    <h2>ℹ️ 情報</h2>
    <ul>
        <li><a href="https://github.com/pj0201/Claude-Code-Communication">GitHub リポジトリ</a></li>
        <li><a href="https://github.com/pj0201/Claude-Code-Communication/wiki">WIKI</a></li>
    </ul>

    <hr>
    <p><small>最終更新: <span id="update-time"></span></small></p>
    <script>
        document.getElementById('update-time').textContent = new Date().toLocaleString('ja-JP');
    </script>
</body>
</html>
```

---

## 自動デプロイ設定

### GitHub Actions ワークフロー

```yaml
# .github/workflows/deploy-pages.yml

name: Deploy Pages

on:
  push:
    branches:
      - main
    paths:
      - 'docs/**'
      - '.github/workflows/deploy-pages.yml'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Upload artifacts
        uses: actions/upload-pages-artifact@v2
        with:
          path: docs/

      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v2
```

### Cron ジョブとの連携

月次レポート生成後に自動的にページをリロード：

```bash
# .github/workflows/monthly-report.yml

name: Monthly Report Generation

on:
  schedule:
    # 毎月1日 午前0時05分に実行
    - cron: '5 0 1 * *'

jobs:
  generate-report:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'

      - name: Install dependencies
        run: |
          pip install -r requirements.txt

      - name: Generate monthly report
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
        run: |
          python3 a2a_system/scripts/monthly_summary.py

      - name: Commit and push
        run: |
          git config --local user.email "action@github.com"
          git config --local user.name "GitHub Action"
          git add docs/
          git commit -m "📊 Monthly report $(date +%Y-%m-%d)" || true
          git push
```

---

## カスタムドメイン設定

### Step 1: DNS レコードを設定

GitHub Pages 用の DNS レコードをカスタムドメインに設定：

```
Type: A
Name: @
Value: 185.199.108.153
       185.199.109.153
       185.199.110.153
       185.199.111.153
```

または CNAME レコード：

```
Type: CNAME
Name: www
Value: username.github.io
```

### Step 2: GitHub で設定

1. リポジトリ **Settings** → **Pages** を開く
2. **Custom domain** に `example.com` を入力
3. **Save** をクリック

### Step 3: HTTPS を有効化

1. 「Enforce HTTPS」チェックボックスを確認
2. DNS 伝播の確認（数分～数時間）

---

## トラブルシューティング

### Q: "Your site is ready to be published..." の表示が出ない

**原因**: リポジトリが private である

**解決**:
```bash
# リポジトリを public に変更
# GitHub Settings → Visibility → Change visibility → Public
```

### Q: ページが見つからない（404エラー）

**原因**:
1. docs/ フォルダが存在しない
2. index.html がない
3. .gitignore で docs/ が除外されている

**確認・解決**:
```bash
# docs/ が存在し、GitHub にコミットされているか確認
git ls-files docs/

# .gitignore を確認
cat .gitignore | grep -i docs

# docs/ を強制的に追加
git add -f docs/
git commit -m "Add docs folder"
git push
```

### Q: ページの更新が反映されない

**原因**: キャッシュ

**解決**:
```bash
# ブラウザキャッシュをクリア
# Ctrl+Shift+Delete （Chromeの場合）

# または
# ブラウザの開発者ツール → Network → "Disable cache" をチェック
```

### Q: Markdown ファイルが HTML に変換されていない

**原因**: Jekyll が有効になっていない、または形式がおかしい

**解決**:
```bash
# .nojekyll ファイルを削除（Jekyll を有効化）
rm docs/.nojekyll
git add -A
git commit -m "Enable Jekyll"
git push

# または Markdown ファイルに front matter を追加
---
layout: default
---

# Page Title
...
```

### Q: デプロイに時間がかかる

**原因**: GitHub Actions の待機キュー

**対応**: 10分～数時間待つ（通常は数分で完了）

---

## WIKI と Pages の使い分け例

### シナリオ1: 社内向けドキュメント

→ GitHub WIKI を使用

```bash
# WIKI リポジトリをクローン
git clone https://github.com/pj0201/Claude-Code-Communication.wiki.git wiki

# WIKI に記事を追加
cd wiki
echo "# Internal Documentation" > Internals.md
git add Internals.md
git commit -m "Add internal docs"
git push
```

### シナリオ2: 公開ドキュメント

→ GitHub Pages を使用

```bash
# docs/ に Markdown ファイルを追加
mkdir -p docs/guides
echo "# Public Guide" > docs/guides/getting-started.md
git add docs/
git commit -m "Add public documentation"
git push
```

### シナリオ3: 月次レポートの公開

→ GitHub Pages + GitHub ISSUE

```bash
# 月次レポートを docs/ に生成
python3 a2a_system/scripts/monthly_summary.py

# GitHub ISSUE で通知
# Issue 本文に GitHub Pages URL へのリンクを含める
# https://pj0201.github.io/Claude-Code-Communication/docs/skill_learning_wiki/archives/2025/2025-10.md
```

---

## チェックリスト

- [ ] リポジトリが public 設定されている
- [ ] docs/ ディレクトリが作成されている
- [ ] docs/.nojekyll ファイルが存在する（または削除済み）
- [ ] docs/index.html が存在する
- [ ] GitHub Settings → Pages で source が設定されている
- [ ] "Your site is published at..." メッセージが表示されている
- [ ] 公開 URL にアクセスできる
- [ ] Markdown ファイルが HTML に変換されている

---

## 参考リソース

- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Jekyll Documentation](https://jekyllrb.com/docs/)
- [GitHub Pages Custom Domain Setup](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site)

---

**最終更新**: 2025-10-22
