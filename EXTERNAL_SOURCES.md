# 外部ソース追跡記録

このドキュメントは、外部から取り込んだMCP、リポジトリ、ソースコード、記事などを記録します。

---

## 📋 記録形式

各エントリには以下の情報を記録：
- **ソース名**: 外部ソースの名称
- **種別**: MCP / リポジトリ / コードスニペット / 記事・ドキュメント
- **取込日**: 取り込んだ日付
- **取込範囲**: 全体 / 一部（部分的な場合は詳細を記載）
- **使用箇所**: このリポジトリ内のどこで使用しているか
- **オリジナルURL**: 元のソース
- **ライセンス**: ライセンス情報
- **変更内容**: オリジナルから変更した点

---

## 🔧 MCP (Model Context Protocol)

### 1. Context7 MCP Server
- **種別**: MCP
- **取込日**: 2025-10-06
- **取込範囲**: 全体
- **使用箇所**: Claude Code全体（MCPとして統合）
- **オリジナルURL**: https://github.com/upstash/context7
- **ライセンス**: MIT License
- **変更内容**: なし（標準MCPとして使用）
- **用途**: 最新ライブラリドキュメント自動注入

### 2. Serena MCP Server
- **種別**: MCP
- **取込日**: 2025-10-06
- **取込範囲**: 全体
- **オリジナルURL**: https://github.com/oraios/serena
- **ライセンス**: MIT License (推定)
- **変更内容**: なし（標準MCPとして使用）
- **用途**: セマンティックコード解析・編集

### 3. Playwright MCP Server
- **種別**: MCP
- **取込日**: 2025-10-06
- **取込範囲**: 全体
- **使用箇所**: テスト自動化時に使用
- **オリジナルURL**: @executeautomation/playwright-mcp-server (npm)
- **ライセンス**: Apache 2.0
- **変更内容**: なし（標準MCPとして使用）
- **用途**: E2Eテスト自動化

### 4. Chrome DevTools MCP
- **種別**: MCP (Gitサブモジュール)
- **取込日**: 2025-10-06
- **取込範囲**: 全体
- **使用箇所**: `/tools/chrome-devtools-mcp/`
- **オリジナルURL**: https://github.com/pj0201/chrome-devtools-mcp.git
- **ライセンス**: MIT License
- **変更内容**: なし
- **用途**: Puppeteer + DevTools API統合、パフォーマンス分析

---

## 📦 リポジトリ・ツール

### 1. Grok CLI
- **種別**: Gitサブモジュール
- **取込日**: 2025-10-06
- **取込範囲**: 全体
- **使用箇所**: `/tools/grok-cli/`
- **オリジナルURL**: https://github.com/superagent-ai/grok-cli
- **ライセンス**: MIT License
- **変更内容**: なし
- **用途**: Grok4エージェント専用インターフェース

### 2. Chrome MCP Extension
- **種別**: Gitサブモジュール
- **取込日**: 2025-10-06
- **取込範囲**: 全体
- **使用箇所**: `/tools/mcp-chrome/`
- **オリジナルURL**: https://github.com/pj0201/mcp-chrome.git
- **ライセンス**: MIT License
- **変更内容**: なし
- **用途**: ブラウザ拡張経由でのChrome操作

---

## 💡 コードスニペット・アーキテクチャ

### 1. A2A強化機能（メッセージプロトコル）
- **種別**: コード部分流用
- **取込日**: 2025-10-07
- **取込範囲**: **一部流用** - メッセージプロトコル設計のみ
- **使用箇所**:
  - `/a2a_system/shared/message_protocol.py` - 優先度・配信モード・TTL機能
- **オリジナルURL**: shunsuke-ultimate-ai-platform（プライベートリポジトリ）
- **ライセンス**: N/A（個人プロジェクト）
- **流用範囲の詳細**:
  ```
  流用した概念・パターン:
  - MessagePriority Enum（CRITICAL/HIGH/MEDIUM/LOW/BACKGROUND）
  - DeliveryMode Enum（FIRE_AND_FORGET/RELIABLE/ORDERED）
  - TTL（Time To Live）機能
  - チェックサム検証パターン

  流用していない部分:
  - 実装コード（全て独自実装）
  - データベース連携
  - 認証・認可機能
  - WebSocketサーバー
  ```
- **変更内容**:
  - 既存A2AシステムのJSON形式に適応
  - 後方互換性の追加
  - ZeroMQ特化の最適化

### 2. A2A強化機能（エージェント管理）
- **種別**: コード部分流用
- **取込日**: 2025-10-07
- **取込範囲**: **一部流用** - エージェント管理の概念のみ
- **使用箇所**:
  - `/a2a_system/orchestration/agent_manager.py` - 状態管理とメトリクス
- **オリジナルURL**: shunsuke-ultimate-ai-platform（プライベートリポジトリ）
- **ライセンス**: N/A（個人プロジェクト）
- **流用範囲の詳細**:
  ```
  流用した概念・パターン:
  - AgentStatus Enum（IDLE/BUSY/WAITING/ERROR/OFFLINE）
  - AgentType Enum（GPT5_WORKER/GROK4_WORKER等）
  - パフォーマンスメトリクス構造
    - total_messages_processed
    - avg_response_time_sec
    - total_errors

  流用していない部分:
  - データベース永続化（→ JSON永続化に変更）
  - Redis連携
  - Kubernetes統合
  - 分散トレーシング
  ```
- **変更内容**:
  - tmuxエージェントとの分離（A2Aエージェントのみ管理）
  - JSON形式での永続化
  - シンプルな状態管理

### 3. A2A強化機能（品質ヘルパー）
- **種別**: コード部分流用
- **取込日**: 2025-10-07
- **取込範囲**: **一部流用** - 品質レポート構造のみ
- **使用箇所**:
  - `/quality/quality_helper.py` - レポート構造とスコアリング
- **オリジナルURL**: shunsuke-ultimate-ai-platform（プライベートリポジトリ）
- **ライセンス**: N/A（個人プロジェクト）
- **流用範囲の詳細**:
  ```
  流用した概念・パターン:
  - IssueSeverity Enum（CRITICAL/HIGH/MEDIUM/LOW/INFO）
  - IssueCategory Enum（CODE_QUALITY/SECURITY/PERFORMANCE等）
  - QualityReport構造
    - overall_score（品質スコア）
    - issues リスト
    - checked_by（レビュアー）

  流用していない部分:
  - 静的解析ツール連携（Pylint/ESLint等）
  - CI/CD統合
  - 自動修正機能
  - AIによる品質予測
  ```
- **変更内容**:
  - GROK4との連携に特化
  - 軽量なJSON永続化
  - トレンド分析の追加

---

## 📚 記事・ドキュメント・論文

### 1. Agentic Context Engineering (ACE) 論文
- **種別**: 学術論文
- **取込日**: 2025-10-12
- **取込範囲**: 概念・アーキテクチャパターンのみ
- **使用箇所**: 今後実装予定（知識蓄積システム）
- **オリジナルURL**: https://www.arxiv.org/abs/2510.04618
- **ライセンス**: arXiv.org（学術利用）
- **論文タイトル**: Agentic Context Engineering
- **主要概念**:
  ```
  - 進化するプレイブック（Evolving Playbooks）
  - Brevity bias（要約による情報損失）の防止
  - Context collapse（反復書き換えによる詳細損失）の防止
  - 構造化された段階的コンテキスト更新
  - 実行フィードバックからの自動学習
  ```
- **適用計画**:
  - Phase 1: タスク実行履歴の蓄積システム
  - Phase 2: コンテキスト注入システム
  - Phase 3: 自己反省メカニズム（GPT-5連携）
- **性能指標**:
  - エージェントタスク: +10.6%
  - 金融特化タスク: +8.6%
- **実装ファイル（予定）**:
  - `/knowledge/task_history.jsonl` - タスク履歴
  - `/knowledge/playbooks/` - 蓄積された知見
  - `/a2a_system/knowledge_accumulator.py` - 知識蓄積エンジン
- **変更内容**: Small Team構成に最適化、ファイルベース通信との統合

### 2. ZeroMQブローカーパターン
- **種別**: 記事・公式ドキュメント
- **取込日**: 2025-08-20（推定）
- **取込範囲**: アーキテクチャパターンのみ
- **使用箇所**: `/a2a_system/zmq_broker/broker.py`
- **オリジナルURL**: https://zguide.zeromq.org/docs/chapter4/
- **ライセンス**: CC BY-SA 4.0
- **流用内容**: Router-Dealer パターン
- **変更内容**: 日本語対応、エラーハンドリング強化

### 2. LINE Messaging API ドキュメント
- **種別**: 公式ドキュメント
- **取込日**: 2025-10-12
- **取込範囲**: APIパターン参照のみ
- **使用箇所**: `/home/planj/claudecode-wind/line-integration/`（別リポジトリ）
- **オリジナルURL**: https://developers.line.biz/ja/docs/messaging-api/
- **ライセンス**: LINE公式ドキュメント
- **流用内容**: Webhook実装パターン
- **変更内容**: A2Aシステムとの統合

### 3. Watchdog ドキュメント
- **種別**: ライブラリドキュメント
- **取込日**: 2025-10-06（推定）
- **取込範囲**: ファイル監視パターン
- **使用箇所**: `/a2a_system/bridges/claude_bridge.py`
- **オリジナルURL**: https://pythonhosted.org/watchdog/
- **ライセンス**: Apache 2.0
- **流用内容**: FileSystemEventHandler パターン
- **変更内容**: 非同期処理との統合

---

## 🔄 更新履歴

### 2025-10-12
- 初版作成
- 既存の全外部ソースを記録
- MCP、リポジトリ、コードスニペット、記事を分類
- **追加**: Agentic Context Engineering (ACE) 論文 - AIエージェントの知識蓄積システム

---

## 📝 追記方法

新しい外部ソースを取り込む際は、このファイルに以下の形式で追記：

```markdown
### N. [ソース名]
- **種別**: MCP / リポジトリ / コードスニペット / 記事
- **取込日**: YYYY-MM-DD
- **取込範囲**: 全体 / 一部（詳細）
- **使用箇所**: パス
- **オリジナルURL**: URL
- **ライセンス**: ライセンス名
- **流用範囲の詳細**: （一部流用の場合のみ）
- **変更内容**: 変更点
```

---

**管理責任者**: Claude Code Team
**最終更新**: 2025-10-12
