# CLAUDE.md - チーム運営専用ガイド

**Claude-Code-Communicationリポジトリの目的**：
開発タスクを効率よく進めるための**マルチエージェントチーム運営システム**。各エージェントの起動・役割・手法・外部ツール（MCP・拡張機能）を最大限に発揮させる。

---

## ⚠️ 重要：リポジトリ目的の厳守

**このリポジトリはチーム運営専用です。アプリ開発コードは絶対に含めないでください。**

### ❌ このリポジトリに含めてはいけないもの
- **アプリケーション開発コード**（React, Vue, Next.js等のWebアプリ）
- **データベースファイル**（.db, .sqlite, .sql等）
- **開発プロジェクトのテスト・検証スクリプト**
- **プロジェクト固有のビジネスロジック**

### ✅ このリポジトリに含めるべきもの
- チーム運営スクリプト（起動・停止・通信）
- エージェント指示書（instructions/）
- システム設定ファイル（.env.example, CLAUDE.md等）
- MCPツール設定・統合スクリプト

### 別リポジトリで管理すべき開発プロジェクト例
- `line-support-system`: LINE公式アカウント支援システム
- `financial-analysis-app`: 財務分析アプリケーション
- その他、具体的なアプリケーション開発プロジェクト

**詳細**: [リポジトリ分離境界の厳守](#-リポジトリ分離境界の厳守) を参照

## 📋 リポジトリ分離境界の厳守

### Claude-Code-Communication（このリポジトリ）
**目的**: エージェント管理・チーム通信・システム運営

**含むべきもの**：
- エージェント起動スクリプト（startup-integrated-system.sh等）
- 通信システム（agent-send.sh, tmux設定）
- エージェント指示書（instructions/）
- MCPツール設定・統合
- チーム運営ドキュメント

**絶対に含めてはいけないもの**：
- 開発プロジェクトの実装コード
- データベースファイル
- アプリケーション固有のテスト・検証スクリプト

### 他のリポジトリ
- **line-support-system**: LINE公式アカウント支援システム開発
- **financial-analysis-app**: 財務分析アプリケーション開発
- その他開発プロジェクト

---

## 👥 チーム構成の選択

このリポジトリは、プロジェクト規模に応じて2つのチーム構成をサポートします：

---

### 1. スモールチーム構成 ← **推奨開始構成**

**対象**: 小〜中規模プロジェクト、個人開発、学習

**構成**:
- **Claude Code** (メイン開発者 - あなた自身)
- **GPT-5** (壁打ち相手 - A2Aエージェント)
- **LINE連携** (遠隔操作システム)

**起動方法**:
```bash
# 統合起動（唯一の方法）
./start-small-team.sh
```

**tmux構成（2ペイン均等レイアウト）**:
- ペイン0: GPT-5チャット（gpt5-chat.py）- 対話可能
- ペイン1: LINE通知ログ監視
- セッション名: `gpt5-a2a-line`

**LINE→GitHub Issue自動化**:
- LINEメッセージ → GitHub Issue自動作成（@claudeメンション付き）
- GitHub Actions → Claude Code Action自動実行
- Issue経由でタスク処理

**特徴**:
- ✅ シンプルで始めやすい
- ✅ A2A強化機能をフル活用
- ✅ LINE遠隔操作対応
- ✅ フルメンバーへスムーズに移行可能
- ✅ コストを抑えつつ高品質を実現

**バックエンドプロセス**:
- Broker (ZeroMQメッセージング)
- GPT-5 Worker (A2Aエージェント)
- Claude Bridge (ファイル↔ZeroMQ変換)
- Claude Code Wrapper (自律的通知受信)
- LINE Notification Daemon (LINE通知監視)

**設定**:
```bash
# .env ファイルに API Key を設定
OPENAI_API_KEY=your_openai_api_key
LINE_CHANNEL_ACCESS_TOKEN=your_line_token  # LINE連携する場合
```

**停止方法**:
```bash
# 統合停止（tmux + バックエンド）
./start-small-team.sh stop
```

---

**注意**: フルチーム構成（5エージェント）は現在サポートされていません。スモールチーム構成のみが利用可能です。

---

## 🚀 A2Aシステム強化機能（2025/10/07追加）

### 概要
shunsuke-ultimate-ai-platformから有益な機能を統合し、既存システムに干渉せずA2A通信を強化。

### 新機能一覧

#### 1. 強化メッセージプロトコル
**場所**: `a2a_system/shared/message_protocol.py`

**特徴**:
- **優先度管理**: CRITICAL/HIGH/MEDIUM/LOW/BACKGROUND
- **配信モード**: FIRE_AND_FORGET（既存）/RELIABLE（配信保証）/ORDERED（順序保証）
- **チェックサム検証**: メッセージ整合性の自動検証
- **TTL（有効期限）**: タイムアウト管理
- **後方互換性**: 既存のJSON形式を完全サポート

**使用例**:
```python
from a2a_system.shared.message_protocol import create_question_message, MessagePriority

# 高優先度メッセージ作成
msg = create_question_message(
    sender="claude_code",
    target="gpt5_001",
    question="緊急タスクです",
    priority=MessagePriority.CRITICAL,
    ttl_seconds=60  # 1分以内に処理
)

# 既存システムと互換のJSON形式に変換
json_data = msg.to_json_compatible()
```

#### 2. エージェント管理システム
**場所**: `a2a_system/orchestration/agent_manager.py`

**特徴**:
- **A2Aエージェント専用**: GPT-5, Grok4外部エージェントのみ管理（tmuxエージェントには干渉しない）
- **パフォーマンス追跡**: 応答時間、処理数、エラー率
- **状態管理**: IDLE/BUSY/WAITING/ERROR/OFFLINE
- **永続化**: JSON形式で状態保存

**使用例**:
```python
from a2a_system.orchestration.agent_manager import get_agent_manager, AgentType, AgentStatus

manager = get_agent_manager()

# GPT-5エージェント登録
manager.register_agent("gpt5_001", AgentType.GPT5_WORKER)

# 状態更新
manager.update_status("gpt5_001", AgentStatus.BUSY)

# 処理記録（応答時間: 2.5秒）
manager.record_message_processed("gpt5_001", 2.5)

# サマリー取得
summary = manager.get_agent_summary()
```

#### 3. 品質ヘルパーシステム
**場所**: `quality/quality_helper.py`

**特徴**:
- **GROK4補完**: 品質チェック結果の構造化（GROK4の品質チェック機能には干渉しない）
- **問題分類**: CODE_QUALITY/SECURITY/PERFORMANCE/MAINTAINABILITY等
- **深刻度管理**: CRITICAL/HIGH/MEDIUM/LOW/INFO
- **スコアリング**: 自動品質スコア計算
- **トレンド分析**: 品質変化の追跡

**使用例**:
```python
from quality.quality_helper import QualityHelper, create_code_quality_issue, IssueSeverity

helper = QualityHelper()

# GROK4の品質チェック結果を記録
report = helper.create_report("/home/planj/project", checked_by="GROK4")

# 問題追加
issue = create_code_quality_issue(
    title="関数の複雑度が高い",
    description="calculate関数の複雑度が15です",
    file_path="main.py",
    line_number=42,
    severity=IssueSeverity.MEDIUM
)
report.add_issue(issue)

# レポート保存
helper.save_report(report)
```

### 統合例
**場所**: `a2a_system/examples/enhanced_integration_example.py`

全機能の統合例を含む実践的なサンプルコード。

**実行方法**:
```bash
python3 a2a_system/examples/enhanced_integration_example.py
```

### 重要な設計原則
1. **既存システムに干渉しない**: tmuxベースのPRESIDENT/Worker構造は変更なし
2. **A2A専用**: 外部エージェント（GPT-5, Grok4）の管理のみ
3. **後方互換性**: 既存のJSON通信形式を完全サポート
4. **段階的導入**: 必要な機能から順次採用可能

---

## 🚀 フルチーム詳細構成

### 各メンバーの役割
- **PRESIDENT**: 統括責任者、プロジェクト方針決定、最終判断
- **O3**: 高度な推論と分析、矛盾検出、予測的提案
- **GROK4**: 品質保証、テスト設計、代替実装提案
- **WORKER2**: サポート業務、UI/UX実装、テストコード作成
- **WORKER3**: メインコーディング、アーキテクチャ設計、ultrathink搭載

### エージェント指示書
- **PRESIDENT**: `instructions/president.md`
- **O3**: `instructions/o3.md`
- **GROK4**: `instructions/grok4.md`
- **WORKER2,3**: `instructions/worker.md`

### システム起動方法
```bash
# フルチーム起動
cd /home/planj/Claude-Code-Communication
./startup-integrated-system.sh 5agents
```

### 個別接続（表示確認用）
```bash
tmux attach -t president    # PRESIDENTシェル
tmux attach -t multiagent   # O3 + GROK4 + Worker×2
```

### システム状態確認
```bash
./startup-integrated-system.sh status
```

### システム停止
```bash
./startup-integrated-system.sh stop
```

### エージェント間通信（フルチームのみ）
```bash
./agent-send.sh [相手] "[メッセージ]"

# 例
./agent-send.sh president "【Worker3より】実装完了しました"
./agent-send.sh worker3 "【PRESIDENTより】次のタスクをお願いします"
```

### ⚠️ tmux send-keys使用時の注意
**コマンド送信後は必ずエンターキー（C-m）を送信！**
```bash
# 正しい例
tmux send-keys -t multiagent:0.2 "curl http://example.com" C-m

# 間違い例（エンターキーを忘れている）
tmux send-keys -t multiagent:0.2 "curl http://example.com"
```

### O3高度推論システム（フルチームのみ）
- **役割**: 戦略的アドバイス、矛盾検出、予測分析
- **起動**: `tmux send-keys -t multiagent:0.0 "clear && /home/planj/Claude-Code-Communication/o3-shell.sh" C-m`
- **⚠️ 重要**: japanese-chat-system.shは使用禁止（定型応答問題のため）

### Grok4恒久動作システム（フルチームのみ）
- **役割**: 品質保証、テスト設計、コードレビュー
- **起動**: `./startup-integrated-system.sh 5agents` で自動起動
- **手動起動**: `tmux send-keys -t multiagent:0.1 "clear && /home/planj/Claude-Code-Communication/grok4-shell.sh" C-m`

---

## 🎯 統合済みMCPツール・外部ツール（2025/10/06更新）

### 🔧 コア機能MCPサーバー（稼働中）

#### 1. Context7 MCP Server ✅
- **統合日**: 2025-10-06
- **公式リポジトリ**: https://github.com/upstash/context7
- **状態**: ✅ 接続済み
- **役割**: 最新コードドキュメンテーション自動注入
- **特徴**:
  - 600以上のライブラリドキュメント対応
  - バージョン特化型API仕様取得
  - 幻覚的API呼び出しの防止
- **用途**: Worker2/3の開発効率向上、最新API仕様参照
- **セットアップ**: `claude mcp add context7 -- npx -y @upstash/context7-mcp`
- **優先度**: ⭐⭐⭐⭐⭐

#### 2. Serena MCP Server ⏳
- **統合日**: 2025-10-06
- **公式リポジトリ**: https://github.com/oraios/serena (⭐9.8k)
- **状態**: ⏳ 初回起動時にインストール
- **役割**: セマンティックコード理解・解析・編集
- **技術**: Python + MCP + LSP
- **対応言語**: Python, JavaScript, TypeScript, Java, Go, Rust等
- **特徴**: シンボルレベル編集、IDE機能のLLM統合
- **用途**: コードベース理解、リファクタリング支援
- **セットアップ**: `claude mcp add serena -- uvx --from git+https://github.com/oraios/serena serena start-mcp-server`
- **優先度**: ⭐⭐⭐⭐⭐

#### 3. Playwright MCP Server ✅
- **統合日**: 2025-10-06
- **公式リポジトリ**: @executeautomation/playwright-mcp-server
- **状態**: ✅ 接続済み
- **特徴**: E2Eテスト自動化、マルチブラウザ対応
- **用途**: 複雑なE2Eテスト、ブラウザ自動化
- **セットアップ**: `claude mcp add playwright -- npx -y @executeautomation/playwright-mcp-server`
- **優先度**: ⭐⭐⭐⭐⭐

#### 4. Chrome DevTools MCP ⏳
- **統合日**: 2025-10-06
- **公式リポジトリ**: https://github.com/pj0201/chrome-devtools-mcp.git
- **場所**: `/tools/chrome-devtools-mcp/`（gitサブモジュール）
- **状態**: ⏳ 初回起動時にインストール
- **役割**: Puppeteer + DevTools API統合
- **特徴**:
  - パフォーマンストレース記録・分析
  - ネットワークリクエスト監視
  - DevTools完全アクセス
- **用途**:
  - Webアプリのパフォーマンステスト自動化
  - E2Eテストのデバッグ支援
  - ネットワークリクエスト分析
- **セットアップ**: `claude mcp add chrome-devtools -- npx -y chrome-devtools-mcp`
- **優先度**: ⭐⭐⭐⭐

### 🌐 ブラウザ拡張機能（独立動作）

#### Chrome MCP Server（拡張機能版）
- **場所**: `/tools/mcp-chrome/`（gitサブモジュール）
- **公式リポジトリ**: https://github.com/pj0201/mcp-chrome.git
- **特徴**:
  - 既存Chromeブラウザセッション活用
  - StreamableHTTP接続（http://127.0.0.1:12306/mcp）
  - 20以上のツール（スクリーンショット、ネットワーク監視等）
- **用途**: 既存ログイン状態の活用、日常的なブラウザ自動化
- **優先度**: ⭐⭐⭐⭐

### 🤖 専用CLIツール

#### Grok CLI
- **場所**: `/tools/grok-cli/`（gitサブモジュール）
- **公式リポジトリ**: https://github.com/superagent-ai/grok-cli
- **役割**: Grok4エージェント専用インターフェース
- **特徴**: xAI Grokモデル、MCP対応、高速コード生成
- **優先度**: ⭐⭐⭐⭐ (Grok4必須)

---

### 🧪 開発環境・設定

#### Worker3専用環境 ✅
- **場所**: `/worker3-env/`
- **役割**: Worker3専用環境設定
- **内容**: 環境変数管理（.env.example参照）
- **セキュリティ**: .gitignore登録済み
- **優先度**: ⭐⭐⭐⭐⭐

---

### 📊 MCP統合状況サマリー

**稼働中（2/4）**:
- ✅ Context7: ドキュメント参照
- ✅ Playwright: ブラウザ自動化

**初回起動後に稼働（2/4）**:
- ⏳ Serena: コード解析
- ⏳ Chrome DevTools: パフォーマンス分析

**拡張機能（独立動作）**:
- Chrome MCP Server: ブラウザ拡張経由

**CLIツール**:
- Grok CLI: Grok4専用インターフェース

**削除済み・不要ツール**:
- Browserbase MCP: 未使用のため削除
- O3 Search MCP: 標準検索で代替
- Grok AI Toolkit: grok-cliで代替
- GitHub MCP Test: テスト用のため削除

---

## 🔍 チーム運営との連携マップ

### PRESIDENTシェル
- **使用ツール**: grok-cli, GitHub MCP
- **役割**: プロジェクト方針決定、Issue/PR管理

### O3シェル
- **使用ツール**: O3 Search MCP, context7, serena
- **役割**: 戦略的分析、コード品質管理

### Grok4シェル
- **使用ツール**: grok-cli（専用）, context7, serena
- **役割**: 品質保証、コードレビュー

### Worker2シェル（サポートエンジニア）
- **使用ツール**: serena, context7
- **役割**: UI/UX実装、テストコード作成、サポート業務

### Worker3シェル（メインエンジニア）
- **使用ツール**: serena, context7, worker3-env, Playwright MCP
- **役割**: コア機能実装、アーキテクチャ設計、環境変数管理

---

## 🚀 開発効率化設定

### 自動承認設定（2025-01-05 適用）
Read/Bash/Writeコマンドの自動承認を有効化し、開発速度を向上

**設定スクリプト**: `/home/planj/Claude-Code-Communication/auto-approve-commands.sh`

**適用内容**:
- Read/Bash/Writeコマンドの自動承認
- 信頼されたワークスペースの設定

**信頼されたパス**:
- `/home/planj`
- `/home/planj/Claude-Code-Communication`
- `/home/planj/financial-analysis-app`
- `/home/planj/line-support-system`
- `/tmp`

**適用方法**:
```bash
bash /home/planj/Claude-Code-Communication/auto-approve-commands.sh
```

**注意**: VS Code再起動または拡張機能リロードが必要

---

## 📋 開発原則

### シンプルコード原則
- **YAGNI（You Aren't Gonna Need It）**: 今必要じゃない機能は作らない
- **DRY（Don't Repeat Yourself）**: 同じコードを繰り返さない
- **KISS（Keep It Simple Stupid）**: シンプルに保つ

### 品質管理義務
全メンバー（PRESIDENT・O3・GROK4・WORKER全員）は実装完了後、**必ず以下を実行してからタスク終了報告**：

1. **コードの徹底見直し**
   - 実装したコードの再確認・再検証
   - 構文エラー・論理エラー・パフォーマンス問題の確認

2. **アウトプット（成果物）の品質検証**
   - 実際の動作確認・機能テスト
   - 期待される結果との一致確認

3. **自律的修正の実行**
   - 問題発見時の即座修正・改善実施
   - 品質向上のための追加改善

4. **困難時の早期相談**
   - 技術的困難・実装リスクの早期発見
   - 適切なタイミングでの上位者への相談

**⚠️ 重要**: 品質チェック未実施での完了報告は受理しない

---

## 🛡️ リポジトリ混入防止システム（2025/10/6追加）

### 目的
開発プロジェクトのコードがこのリポジトリに混入することを**自動的に防ぐ**

### 3層防御システム

#### 第1層: 開発時チェック（手動）
```bash
./check-repository-boundary.sh
```
- 開発プロジェクトコードの混入検出
- データベースファイルの混入検出
- 機密情報ファイルの検出
- 必須ファイルの存在確認

#### 第2層: コミット前チェック（手動）
```bash
./pre-commit-check.sh
```
- リポジトリ境界チェックを実行
- エラー時にコミットを推奨しない

#### 第3層: CI/CD自動チェック（自動）
- GitHub Actions: `.github/workflows/boundary-check.yml`
- PR作成・プッシュ時に自動実行
- 失敗時にPRへ自動コメント通知

### 運用方法
詳細は `PREVENTION_GUIDE.md` を参照

### 重要ファイル
- `check-repository-boundary.sh` - 境界チェックスクリプト（メイン）
- `pre-commit-check.sh` - コミット前チェック
- `.gitignore` - 厳格な除外設定
- `PREVENTION_GUIDE.md` - 混入防止運用マニュアル

---

## 📚 主要ドキュメント

- `CLAUDE.md`: このファイル（チーム運営ガイド）
- `README.md`: クイックスタートガイド
- `instructions/`: エージェント別指示書
- `REPOSITORY_BOUNDARY.md`: リポジトリ分離境界の詳細
- `PREVENTION_GUIDE.md`: 混入防止運用マニュアル（全員必読）
- `PLAYWRIGHT_MCP_INTEGRATION.md`: Playwright MCP技術仕様
- `BROWSER_AUTOMATION_GUIDE.md`: ブラウザ自動化実践ガイド

