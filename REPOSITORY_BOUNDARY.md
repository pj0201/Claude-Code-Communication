# リポジトリ分離境界の厳守

## 📋 目的
開発プロジェクトとチーム運営システムを明確に分離し、責任範囲を明確化する

## 🎯 Claude-Code-Communication（このリポジトリ）

### 目的
エージェント管理・チーム通信・システム運営

### 含むべきもの
✅ **エージェント起動スクリプト**
- `startup-integrated-system.sh`
- `o3-shell.sh`
- `grok4-shell.sh`

✅ **通信システム**
- `agent-send.sh`
- tmux設定

✅ **エージェント指示書**
- `instructions/president.md`
- `instructions/o3.md`
- `instructions/grok4.md`
- `instructions/worker.md`

✅ **MCPツール設定・統合**
- `tools/` ディレクトリ
- MCP設定ファイル
- セットアップガイド

✅ **チーム運営ドキュメント**
- `CLAUDE.md`
- `REPOSITORY_BOUNDARY.md`（このファイル）
- その他運営関連ドキュメント

### 絶対に含めてはいけないもの
❌ **開発プロジェクトの実装コード**
- アプリケーションのソースコード
- プロジェクト固有のビジネスロジック

❌ **データベースファイル**
- SQLiteファイル
- データダンプ

❌ **アプリケーション固有のテスト・検証スクリプト**
- プロジェクト固有のテストコード
- プロジェクト固有の検証スクリプト

## 🗂️ 他のリポジトリ

### line-support-system
**目的**: LINE公式アカウント支援システム開発

**場所**: `/home/planj/line-support-system` (予定)

**含むべきもの**:
- LINE APIクライアント実装
- メッセージ処理ロジック
- データベーススキーマ
- テストコード
- デプロイ設定

### financial-analysis-app
**目的**: 財務分析アプリケーション開発

**場所**: `/home/planj/financial-analysis-app` (予定)

**含むべきもの**:
- 財務分析エンジン
- データ可視化コンポーネント
- API実装
- テストコード
- デプロイ設定

## 🔄 連携方法

### 開発プロジェクトでのClaude-Code-Communication利用

1. **CLAUDE.md参照**
   ```bash
   # 開発プロジェクト内から参照
   ln -s /home/planj/Claude-Code-Communication/CLAUDE.md ./CLAUDE.md
   ```

2. **エージェント起動**
   ```bash
   cd /home/planj/Claude-Code-Communication
   ./startup-integrated-system.sh 5agents
   ```

3. **作業ディレクトリ移動**
   ```bash
   # Workerエージェント内で開発プロジェクトに移動
   cd /home/planj/line-support-system
   ```

## ⚠️ 混入検出チェックリスト

### Claude-Code-Communicationでチェック
```bash
cd /home/planj/Claude-Code-Communication

# 開発プロジェクトコードの混入チェック
find . -name "*.py" -o -name "*.js" -o -name "*.ts" | grep -v "tools/" | grep -v "node_modules"

# データベースファイルの混入チェック
find . -name "*.db" -o -name "*.sqlite"

# プロジェクト固有のテストの混入チェック
find . -name "*test*.py" -o -name "*test*.js" | grep -v "tools/"
```

### 開発プロジェクトでチェック
```bash
cd /home/planj/line-support-system  # または他のプロジェクト

# チーム運営スクリプトの混入チェック
ls -la | grep -E "(agent-send|startup-integrated|o3-shell|grok4-shell)"

# エージェント指示書の混入チェック
find . -path "*/instructions/*.md"
```

## 🎯 ベストプラクティス

### 1. 作業前の確認
```bash
# 現在のディレクトリを確認
pwd

# 適切なリポジトリにいることを確認
```

### 2. ファイル作成時の判断基準
**質問**: このファイルは何のためのものか？

- **エージェント管理・チーム運営**: → Claude-Code-Communication
- **アプリケーション開発**: → 各開発プロジェクト

### 3. コミット前の確認
```bash
# 変更ファイル一覧を確認
git status

# 各ファイルが適切なリポジトリにあるか確認
```

## 📊 ディレクトリ構造比較

### Claude-Code-Communication
```
Claude-Code-Communication/
├── CLAUDE.md                          # チーム運営ガイド
├── REPOSITORY_BOUNDARY.md             # このファイル
├── startup-integrated-system.sh       # システム起動
├── agent-send.sh                      # エージェント間通信
├── o3-shell.sh                        # O3専用シェル
├── grok4-shell.sh                     # GROK4専用シェル
├── auto-approve-commands.sh           # 自動承認設定
├── instructions/                      # エージェント指示書
│   ├── president.md
│   ├── o3.md
│   ├── grok4.md
│   └── worker.md
└── tools/                             # MCPツール
    ├── README.md
    └── (MCPサーバー・サブモジュール)
```

### 開発プロジェクト例（line-support-system）
```
line-support-system/
├── README.md                          # プロジェクト概要
├── src/                               # ソースコード
│   ├── api/
│   ├── models/
│   └── services/
├── tests/                             # テストコード
├── db/                                # データベース
├── docs/                              # プロジェクトドキュメント
├── .env.example                       # 環境変数テンプレート
└── package.json / requirements.txt    # 依存関係
```

## 🔍 トラブルシューティング

### 問題: ファイルがどちらのリポジトリに属するか不明
**解決策**:
1. ファイルの目的を明確にする
2. 上記の「含むべきもの」リストを参照
3. 不明な場合はPRESIDENTに相談

### 問題: 既に混入してしまった
**解決策**:
1. 適切なリポジトリに移動
2. 元の場所から削除
3. 必要に応じてリンク作成

```bash
# 例: line-support-systemに属するファイルが混入していた場合
mv /home/planj/Claude-Code-Communication/incorrectfile.py \
   /home/planj/line-support-system/src/

cd /home/planj/Claude-Code-Communication
git rm incorrectfile.py
git commit -m "Remove misplaced file"
```

## ✅ 定期レビュー

月次でリポジトリ境界の整合性をチェック：

```bash
# Claude-Code-Communicationでの確認
./check-repository-boundary.sh  # 作成予定のチェックスクリプト
```

---

**重要**: この境界を厳守することで、プロジェクトの保守性と可読性が大幅に向上します。
