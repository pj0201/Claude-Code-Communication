# 環境変数セットアップガイド

このドキュメントは、Claude-Code-Communication システムの環境変数セットアップ手順を説明します。

## 目次

1. [クイックスタート](#クイックスタート)
2. [必須変数の設定](#必須変数の設定)
3. [オプション変数の設定](#オプション変数の設定)
4. [検証](#検証)
5. [トラブルシューティング](#トラブルシューティング)

---

## クイックスタート

```bash
# 1. .env ファイルを作成
cp .env.example .env

# 2. .env を編集して API キーを設定
# テキストエディタで開く
nano .env  # または vim, VS Code等

# 3. 検証を実行
python3 validate_env.py

# 4. セットアップ手順を表示（初回のみ）
python3 validate_env.py --setup
```

---

## 必須変数の設定

### 1. GITHUB_TOKEN（GitHub API トークン）

**目的**: GitHub ISSUE を自動作成するために必要

**設定手順**:

1. GitHub にログイン: https://github.com/login

2. Personal Access Token ページへ移動:
   - 右上のプロフィールアイコン → **Settings**
   - 左サイドバー → **Developer settings**
   - **Personal access tokens** → **Fine-grained tokens**

3. 新規トークンを生成:
   - **Generate new token** をクリック
   - トークン名: `ACE Learning Engine` など自由に設定

4. リポジトリを選択:
   - **Repository access** → `Only select repositories` を選択
   - あなたのリポジトリを選択（例: `Claude-Code-Communication`）

5. パーミッションを設定:
   - **Permissions** セクションで以下を `Read & write` に設定:
     - **Issues** → `read & write`
     - **Contents** → `read` (オプション)

6. トークンをコピー:
   - **Generate token** をクリック
   - **新しいトークンが表示されます（このページを離れると二度と見られません）**
   - トークンをコピー

7. .env に設定:

```bash
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**セキュリティ注意**:
- ✅ トークンを安全に保管してください
- ✅ .env ファイルは .gitignore に含まれています
- ❌ GitHub にトークンをコミットしないでください
- ❌ 他人にトークンを見せないでください

### 2. GITHUB_REPO（GitHub リポジトリ）

**目的**: ISSUE を作成するリポジトリを指定

**形式**: `username/repository-name`

**例**:
```bash
GITHUB_REPO=pj0201/Claude-Code-Communication
```

**確認方法**:
1. リポジトリを GitHub で開く
2. 緑色の **Code** ボタンの下に `owner/repo` が表示されます

### 3. OPENAI_API_KEY（OpenAI API キー）

**目的**: GPT-4 や gpt-4-turbo を使用するために必要

**設定手順**:

1. OpenAI Platform にアクセス: https://platform.openai.com

2. API キー管理ページへ:
   - 右上のユーザーアイコン → **API keys**
   - または直接: https://platform.openai.com/api-keys

3. 新規キーを生成:
   - **Create new secret key** をクリック
   - キー名を入力（例: `ACE Learning Engine`）

4. キーをコピー:
   - 新しいキーが表示されます
   - **Copy** をクリック（このページを離れるとコピーできなくなります）

5. .env に設定:

```bash
OPENAI_API_KEY=sk-proj-xxxxxxxxxxxxxxxxxxxxxx
```

**セキュリティ注意**:
- ✅ キーを安全に保管してください
- ✅ .env ファイルは .gitignore に含まれています
- ❌ GitHub にキーをコミットしないでください
- ❌ 他人にキーを見せないでください
- ⚠️ 使用していないキーは定期的に削除してください

**料金**:
- OpenAI API は有料です（使用量に応じた従量課金）
- 無料トライアル期間（初回の $5 クレジット）がある場合があります
- 使用量の監視: https://platform.openai.com/account/billing/overview

---

## オプション変数の設定

### LOG_LEVEL（ログレベル）

**デフォルト**: `INFO`

**許可値**:
- `DEBUG`: 詳細ログ（開発時）
- `INFO`: 通常のログ
- `WARNING`: 警告以上のみ
- `ERROR`: エラーのみ
- `CRITICAL`: 致命的エラーのみ

**推奨設定**:
```bash
LOG_LEVEL=INFO           # 本番環境
LOG_LEVEL=DEBUG          # 開発環境
```

### QUALITY_SCORE_THRESHOLD（品質スコア閾値）

**デフォルト**: `0.7` (70%)

**範囲**: `0.0` - `1.0`

**説明**: スコアが下回るとログ警告を出力

```bash
QUALITY_SCORE_THRESHOLD=0.7    # 標準設定
QUALITY_SCORE_THRESHOLD=0.8    # 厳格
QUALITY_SCORE_THRESHOLD=0.5    # 寛容
```

### A2A_BROKER_HOST / A2A_BROKER_PORT

**デフォルト**: `localhost` / `5555`

**説明**: マルチエージェント通信用のメッセージブローカー

**ローカル開発**:
```bash
A2A_BROKER_HOST=localhost
A2A_BROKER_PORT=5555
```

**リモート接続**（高度な用途）:
```bash
A2A_BROKER_HOST=192.168.1.100
A2A_BROKER_PORT=5555
```

### WIKI_REPO_PATH（GitHub WIKI リポジトリ）

**デフォルト**: 設定なし（`docs/` フォルダを使用）

**説明**: GitHub WIKI を使用する場合のみ設定

**セットアップ手順**:

```bash
# 1. WIKI リポジトリをクローン
git clone https://github.com/{USER}/{REPO}.wiki.git ./wiki

# 2. .env に設定
WIKI_REPO_PATH=./wiki
```

**確認方法**:
```bash
# WIKI リポジトリが正しくクローンされているか確認
ls -la ./wiki/.git
```

### DRY_RUN（ドライランモード）

**デフォルト**: `false` (実行モード)

**説明**: テストモードでファイル作成のみ行い、Git操作は実行しない

**テスト環境**:
```bash
DRY_RUN=true   # ファイル作成のみ（Git操作なし）
```

**本番環境**:
```bash
DRY_RUN=false  # 実際にGitコミット・プッシュ
```

### LINE 通知（オプション）

**説明**: LINE Official Account との連携（オプション）

```bash
LINE_CHANNEL_ACCESS_TOKEN=your_line_token_here
LINE_USER_ID=your_line_user_id_here
```

### プロキシ設定（企業ネットワーク）

**説明**: 企業ネットワーク内でプロキシを使用する場合

```bash
HTTP_PROXY=http://proxy.example.com:8080
HTTPS_PROXY=https://proxy.example.com:8080
```

---

## 検証

### 環境変数を検証する

```bash
# 標準検証
python3 validate_env.py

# 詳細表示（修正提案付き）
python3 validate_env.py --fix

# セットアップ手順を表示
python3 validate_env.py --setup

# 別のファイルを検証
python3 validate_env.py --env /path/to/.env
```

### 期待される出力

✅ **成功時**:
```
✅ 検証成功: すべての設定が正しいです
```

❌ **失敗時**:
```
❌ 検証失敗: 上記のエラーを修正してください
```

### 検証項目

| 項目 | 種別 | チェック内容 |
|-----|------|-----------|
| GITHUB_TOKEN | 必須 | 存在確認、形式検証、ダミー値確認 |
| GITHUB_REPO | 必須 | 存在確認、形式検証（username/repo）、ダミー値確認 |
| OPENAI_API_KEY | 必須 | 存在確認、形式検証（sk-で始まる）、ダミー値確認 |
| LOG_LEVEL | オプション | 許可値確認（DEBUG\|INFO\|WARNING\|ERROR\|CRITICAL） |
| QUALITY_SCORE_THRESHOLD | オプション | 数値範囲確認（0.0-1.0） |
| A2A_BROKER_PORT | オプション | ポート番号範囲確認（1-65535） |
| WIKI_REPO_PATH | オプション | ファイル存在確認、Git リポジトリ確認 |
| DRY_RUN | オプション | 値確認（true\|false） |

---

## トラブルシューティング

### Q: "GITHUB_TOKEN が設定されていません" エラーが出る

**原因**: GITHUB_TOKEN が .env に設定されていない

**解決**:
```bash
# .env ファイルを確認
cat .env | grep GITHUB_TOKEN

# 設定されていなければ追加
echo "GITHUB_TOKEN=your_token_here" >> .env
```

### Q: GitHub API 認証エラーが出る

**原因**: トークンが無効、期限切れ、またはスコープが不足

**解決**:
1. 新しいトークンを生成してください
2. トークンのスコープを確認: **issues:read/write** が必要
3. トークンの有効期限を確認

### Q: "OpenAI API key is invalid" エラー

**原因**: OpenAI API キーが無効または形式が正しくない

**解決**:
1. 新しいキーを生成してください: https://platform.openai.com/api-keys
2. キーが `sk-` で始まることを確認
3. キーをコピーする際にスペースが含まれていないか確認

### Q: "GITHUB_REPO format is invalid" エラー

**原因**: GITHUB_REPO の形式が `username/repository` ではない

**解決**:
```bash
# 正しい形式
GITHUB_REPO=pj0201/Claude-Code-Communication

# 誤った形式（以下は不正）
GITHUB_REPO=https://github.com/pj0201/Claude-Code-Communication  # ❌
GITHUB_REPO=pj0201                                               # ❌
GITHUB_REPO=Claude-Code-Communication                            # ❌
```

### Q: ローカル開発では GITHUB_TOKEN を設定したくない

**解決**:
- GITHUB_TOKEN を設定しない場合、月次レポートの ISSUE 作成は スキップされます
- テストモード: `DRY_RUN=true` を設定してファイル生成のみ行う

```bash
DRY_RUN=true
LOG_LEVEL=DEBUG
# GITHUB_TOKEN は設定しない
```

### Q: 新しい環境変数を追加したい

**手順**:
1. `.env.example` に新しい変数を追加（コメント付き）
2. `validate_env.py` に検証ロジックを追加（必要に応じて）
3. ドキュメントを更新

---

## チェックリスト

セットアップ完了を確認してください:

- [ ] `.env` ファイルが作成されている
- [ ] `GITHUB_TOKEN` が設定されている
- [ ] `GITHUB_REPO` が設定されている（形式: `username/repo`）
- [ ] `OPENAI_API_KEY` が設定されている
- [ ] `python3 validate_env.py` で検証成功している
- [ ] 本番環境の場合、トークンが安全に保管されている
- [ ] `.env` が `.gitignore` に含まれていることを確認

---

## セキュリティベストプラクティス

### 🔐 トークン管理

| 項目 | 推奨事項 |
|------|--------|
| トークン保存 | `.env` ファイルのみ（.gitignore に含める） |
| トークン共有 | チーム内でも共有しない（個別トークン生成） |
| トークン有効期限 | 定期的に更新（90日ごと推奨） |
| トークン廃止 | 使用していないトークンは削除 |
| トークン監視 | ログで使用状況を確認 |

### 🔒 本番環境

| 項目 | 設定 |
|------|-----|
| LOG_LEVEL | `INFO` または `WARNING` |
| DRY_RUN | `false` |
| QUALITY_SCORE_THRESHOLD | `0.7` 以上 |
| GitHub トークン | Fine-grained token（スコープ限定） |

### 🧪 開発環境

| 項目 | 設定 |
|------|-----|
| LOG_LEVEL | `DEBUG` |
| DRY_RUN | `true` |
| QUALITY_SCORE_THRESHOLD | `0.5` 以上 |
| GitHub トークン | Fine-grained token（テストリポジトリ） |

---

## 参考資料

- [GitHub Personal Access Tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- [OpenAI API Documentation](https://platform.openai.com/docs)
- [GitHub Issues API](https://docs.github.com/en/rest/issues)

---

**最終更新**: 2025-10-22
