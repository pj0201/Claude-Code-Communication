# Claude-Code-Communication

**マルチエージェントチーム運営システム**

開発タスクを効率よく進めるための統合システム。5つの専門エージェントが協調して高品質な開発を実現します。

## 🎯 システム概要

このリポジトリは、開発プロジェクトを効率的に進めるための**エージェント管理・チーム通信・システム運営**を担当します。

## 👥 エージェント構成

```
PRESIDENT（統括責任者）[president:0.0]
    ├─ O3（高度推論エンジン）[multiagent:0.0]
    ├─ GROK4（品質保証AI）[multiagent:0.1]
    ├─ WORKER2（サポートエンジニア）[multiagent:0.2]
    └─ WORKER3（メインエンジニア）[multiagent:0.3]
```

### 各エージェントの役割

- **PRESIDENT**: 統括責任者、プロジェクト方針決定、最終判断
- **O3**: 高度な推論と分析、矛盾検出、予測的提案
- **GROK4**: 品質保証、テスト設計、代替実装提案
- **WORKER2**: サポート業務、UI/UX実装、テストコード作成
- **WORKER3**: メインコーディング、アーキテクチャ設計、ultrathink搭載

## 🚀 クイックスタート

### 1. システム起動
```bash
cd /home/planj/Claude-Code-Communication
./startup-integrated-system.sh 5agents
```

### 2. エージェントに接続
```bash
# PRESIDENTに接続
tmux attach -t president

# O3, GROK4, WORKER2, WORKER3に接続
tmux attach -t multiagent
```

### 3. メッセージ送信
```bash
./agent-send.sh worker3 "【PRESIDENTより】次のタスクをお願いします"
```

## 📂 ディレクトリ構造

```
Claude-Code-Communication/
├── CLAUDE.md                          # チーム運営ガイド（詳細版）
├── README.md                          # このファイル
├── REPOSITORY_BOUNDARY.md             # リポジトリ分離境界
├── startup-integrated-system.sh       # システム起動スクリプト
├── agent-send.sh                      # エージェント間通信
├── o3-shell.sh                        # O3専用シェル
├── grok4-shell.sh                     # GROK4専用シェル
├── auto-approve-commands.sh           # 自動承認設定
├── instructions/                      # エージェント指示書
│   ├── president.md
│   ├── o3.md
│   ├── grok4.md
│   └── worker.md
└── tools/                             # MCPツール・外部ツール
    ├── README.md
    └── (MCPサーバー・サブモジュール)
```

## 🔧 主要コマンド

### システム管理
```bash
# 5エージェント起動
./startup-integrated-system.sh 5agents

# システム状態確認
./startup-integrated-system.sh status

# システム停止
./startup-integrated-system.sh stop
```

### エージェント間通信
```bash
# メッセージ送信
./agent-send.sh [相手] "[メッセージ]"

# 例
./agent-send.sh president "【Worker3より】実装完了しました"
./agent-send.sh worker3 "【PRESIDENTより】次のタスクをお願いします"
```

## 🧠 MCPツール統合

このシステムは以下のMCPツールと統合されています：

### コア機能
- **Context7 MCP**: 最新コードドキュメンテーション自動注入（全エージェント必須）
- **Serena MCP**: セマンティックコード理解・解析（全Worker必須）
- **Grok CLI**: xAI Grokモデル統合（GROK4専用）

### ブラウザ自動化
- **Chrome MCP Server**: Chromeブラウザ直接制御
- **Playwright MCP Server**: E2Eテスト自動化
- **Browserbase MCP Server**: LLMによる自然言語ブラウザ制御

詳細は `tools/README.md` を参照してください。

## 📋 開発原則

### シンプルコード原則
- **YAGNI**: 今必要じゃない機能は作らない
- **DRY**: 同じコードを繰り返さない
- **KISS**: シンプルに保つ

### 品質管理義務
全メンバーは実装完了後、**必ず以下を実行してからタスク終了報告**：

1. コードの徹底見直し
2. アウトプット品質検証
3. 自律的修正の実行
4. 困難時の早期相談

## 🎯 リポジトリ境界

### このリポジトリに含むべきもの
✅ エージェント起動スクリプト
✅ 通信システム
✅ エージェント指示書
✅ MCPツール設定
✅ チーム運営ドキュメント

### このリポジトリに含めてはいけないもの
❌ 開発プロジェクトの実装コード
❌ データベースファイル
❌ アプリケーション固有のテスト・検証スクリプト

詳細は `REPOSITORY_BOUNDARY.md` を参照してください。

## 📚 ドキュメント

- **CLAUDE.md**: チーム運営ガイド（最も重要）
- **README.md**: このファイル（概要・クイックスタート）
- **REPOSITORY_BOUNDARY.md**: リポジトリ分離境界の詳細
- **instructions/**: エージェント別指示書
- **tools/README.md**: MCPツール・外部ツール詳細

## 🔍 トラブルシューティング

### システムが起動しない
```bash
# tmuxが存在するか確認
which tmux

# 既存セッションの確認
tmux ls

# 既存セッションを停止
./startup-integrated-system.sh stop
```

### メッセージが送信できない
```bash
# システムが起動しているか確認
./startup-integrated-system.sh status

# tmuxセッションが存在するか確認
tmux ls
```

## 🚀 次のステップ

1. **システム起動**: `./startup-integrated-system.sh 5agents`
2. **CLAUDE.md読み込み**: チーム運営ガイドを詳細に確認
3. **エージェント指示書確認**: `instructions/` 内のファイルを各エージェントが読む
4. **開発開始**: 各エージェントが役割に応じてタスクを実行

## 📞 サポート

不明点や問題が発生した場合：
1. CLAUDE.mdを参照
2. 各エージェントの指示書を確認
3. PRESIDENTに相談

---

**重要**: このシステムは開発プロジェクトとは独立しています。開発プロジェクトのコードはこのリポジトリに含めないでください。
