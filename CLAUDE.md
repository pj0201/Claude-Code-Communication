# CLAUDE.md - チーム運営専用ガイド

**Claude-Code-Communicationリポジトリの目的**：
開発タスクを効率よく進めるための**マルチエージェントチーム運営システム**。各エージェントの起動・役割・手法・外部ツール（MCP・拡張機能）を最大限に発揮させる。

---

## ⚠️ 最重要：tmux 通信時の必須ルール

**絶対に忘れてはいけない！**

### 🚨 エンター（C-m）は **ALWAYS 必須**

Worker へのメッセージ送信時：
```bash
# ❌ 間違い（エンターなし）
tmux send-keys -t "gpt5-a2a-line:team.1" "echo 'メッセージ'"

# ✅ 正解（エンター付き）
tmux send-keys -t "gpt5-a2a-line:team.1" "echo 'メッセージ'" C-m
```

### 🔧 推奨：send-to-worker.sh を使用
```bash
./send-to-worker.sh 1 "メッセージ内容"
```

このスクリプトが自動的に C-m を付けます。

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

**⚠️ 必須：スモールチーム起動後の通信方法確認**

起動直後は **必ず以下を実行**：
1. `A2A_COMMUNICATION_FORMAT.md` を読む
2. GPT-5へのメッセージは正しいフォーマットで送信
   - 送信先: `/a2a_system/shared/claude_inbox/`
   - 正しいフォーマット: `{"type": "QUESTION", "sender": "...", "target": "gpt5_intelligent", "question": "..."}`
   - 間違い: 深くネストされたJSON構造や`"content"`フィールドの使用

**GPT-5ワーカー停止時の対応**:
- ❌ スモールチーム全体を再起動するな（チーム開発中断）
- ✅ GPT-5ワーカーのみ再起動：
  ```bash
  cd /home/planj/Claude-Code-Communication/a2a_system
  python3 workers/gpt5_worker.py >> gpt5_worker.log 2>&1 &
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

## 🚀 tmux 直接通信ガイド（2025/10/21統一）

### 通信方法の基本原則

スモールチーム構成では、**シンプルで実用的な tmux 直接通信** を採用しています。

**決定理由**:
- ✅ **シンプル**: A2A JSON ファイルシステムより実装が単純
- ✅ **リアルタイム性**: メッセージ送受信が即座に完了
- ✅ **実用性**: 複雑な検証機構が不要
- ✅ **信頼性**: 検証済みの方法

### ペイン構成（スモールチーム）

```
tmux セッション: gpt5-a2a-line
└── team (ウィンドウ)
    ├── Pane 0: Claude Code (Worker2)
    ├── Pane 1: Worker3 (自分)
    ├── Pane 2: GPT-5
    └── Pane 3: Claude Bridge
```

### メッセージ送信方法

#### 方法1: send-to-worker.sh を使用（推奨）

```bash
# ペイン0（Claude Code）にメッセージを送信
./send-to-worker.sh 0 "【Worker3より】メッセージ内容"

# ペイン2（GPT-5）にメッセージを送信
./send-to-worker.sh 2 "【質問】内容"
```

**特徴**:
- エンター（C-m）が自動的に付与される
- 確実にメッセージが送信される

#### 方法2: tmux send-keys を直接使用

```bash
# ペイン0にメッセージを送信（エンター必須！）
tmux send-keys -t "gpt5-a2a-line:team.0" "メッセージ内容" C-m

# ペイン2にメッセージを送信
tmux send-keys -t "gpt5-a2a-line:team.2" "質問内容" C-m
```

**⚠️ 重要ルール: C-m（エンターキー）は ALWAYS 必須**

### 通信パターン例

#### パターン1: Worker2（Claude Code）との双方向通信

```bash
# Worker3 → Worker2
./send-to-worker.sh 0 "【レビュー依頼】コードを確認してください"

# Worker2 が応答（手動でチャットに入力・送信）
```

#### パターン2: GPT-5 への質問

```bash
# Worker3 → GPT-5
./send-to-worker.sh 2 "【技術相談】Reactの最適化について意見をください"

# GPT-5 が応答
```

### メッセージ確認方法

送信後の確認:
```bash
# ペイン0の内容を確認
tmux capture-pane -t "gpt5-a2a-line:team.0" -p

# ペイン2の内容を確認
tmux capture-pane -t "gpt5-a2a-line:team.2" -p
```

### よくあるミス

❌ **エンターキー（C-m）を忘れる**
```bash
# 間違い
tmux send-keys -t "gpt5-a2a-line:team.0" "メッセージ"
```

✅ **エンターキーを付ける**
```bash
# 正解
tmux send-keys -t "gpt5-a2a-line:team.0" "メッセージ" C-m
```

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

## 📊 Pattern 1.5 スキル学習システム（2025/10/20完成）

### 概要
**実用的なハイブリッド型** スキル学習の永続化システム。3層アーキテクチャで安全性と利便性を両立。

### アーキテクチャ

**3層永続化戦略**:
- **層1 (実行時)**: `/tmp/skill_learning.json` - リアルタイムメモリ
- **層2 (保護)**: `/a2a_system/shared/learned_patterns/` - バックアップ保護
- **層3 (文書化)**: GitHub WIKI - 月次レポート・長期記録

### 実装済みモジュール

#### 1. LearningPersistenceManager (`learning_persistence.py` - 490行)
**責務**: 学習データの永続化・復旧・バージョン管理
- JSON ロード/保存（両層自動同期）
- レコード追加・統計更新（EMA付き）
- バックアップ作成・復旧
- 世代管理（古いバックアップ自動削除）
- ヘルスチェック

**使用例**:
```python
from a2a_system.skills.learning_persistence import LearningPersistenceManager

manager = LearningPersistenceManager()
manager.append_record({
    "skill_type": "code_analysis",
    "task_type": "code_review",
    "success": True,
    "processing_time": 1200,
    "confidence": 0.85
})
```

#### 2. BackupScheduler (`backup_scheduler.py` - 280行)
**責務**: 自動バックアップとメンテナンス
- 毎時バックアップ（:00分）
- 毎日フルバックアップ（深夜2時）
- 毎週クリーンアップ（月曜3時）
- デーモンスレッド実行

**特徴**: 外部ライブラリ不要の自作スケジューラ

#### 3. MonthlySummaryGenerator (`monthly_summary_generator.py` - 450行)
**責務**: 月次統計分析・Markdown生成
- スキル別統計（成功率、処理時間など）
- パターン抽出（上位5パターン）
- 精度トレンド分析
- 自動改善提案
- Markdown出力

#### 4. WikiUploader (`wiki_uploader.py` - 420行)
**責務**: GitHub WIKI統合
- アーカイブ構造管理（archives/YYYY/YYYY-MM.md）
- 最新レポート維持（current/latest.md）
- インデックスページ生成（meta/index.md）
- Git コミット・プッシュ自動化

#### 5. Common Utilities (`common_utils.py` - 300行)
**責務**: 重複コード削減・共通機能一元化
- **JSONHelper**: JSON操作統一
- **FileHelper**: ファイル操作統一
- **StatisticsHelper**: 統計計算統一（EMA、成功率等）
- **DateTimeHelper**: 日時操作統一
- **Decorators**: @safe_operation, @retry_operation

### テスト結果

| テスト項目 | 結果 | 詳細 |
|-----------|------|------|
| **単体テスト** | ✅ PASS | 全4モジュール動作確認 |
| **パフォーマンス** | ✅ PASS | 500記録: 1.07s / サマリー: 0.001s |
| **エッジケース** | ✅ PASS | 6/7合格（85.7%） |
| **ストレステスト** | ✅ PASS | 5000記録全操作成功 |
| **リファクタリング** | ✅ PASS | 重複削減200-300行、パフォーマンス劣化なし |

### ステータス

**✅ 本番投入準備完了**:
- 実装完了
- テスト完了
- ドキュメント完成
- リファクタリング完了
- エラーハンドリング実装
- セキュリティ確認済み

### ドキュメント

- `PATTERN_1_5_PRODUCTION_CHECKLIST.md` - 本番投入チェックリスト
- `ERROR_HANDLING_GUIDE.md` - エラーハンドリング詳細ガイド
- `PATTERN_1_5_IMPLEMENTATION_PLAN.md` - 実装計画書

### 統合例

```python
from a2a_system.skills.learning_persistence import LearningPersistenceManager
from a2a_system.skills.backup_scheduler import BackupScheduler
from a2a_system.skills.monthly_summary_generator import MonthlySummaryGenerator
from a2a_system.skills.wiki_uploader import WikiUploader

# 1. マネージャー初期化
manager = LearningPersistenceManager()

# 2. スケジューラ開始
scheduler = BackupScheduler(manager)
scheduler.start()

# 3. 月次サマリー生成
generator = MonthlySummaryGenerator(manager)
summary = generator.generate_summary(2025, 10)
md = generator.generate_markdown(summary)

# 4. WIKI にアップロード
uploader = WikiUploader("/home/planj/Claude-Code-Communication")
uploader.upload_monthly_summary(2025, 10, md, summary)
```

---

## 🎯 Skill & Learning 統合システム（2025/10/20整備）

### 概要
16種ドメイン分類 × 多言語タスク解析による**自律的スキル学習システム**

### コンポーネント

#### 1. SkillRegistry（16-Domain分類）
**場所**: `a2a_system/skills/skill_registry.py`

**16ドメイン分類**:
- **Basic Skills (6)**: 文章生成、質問応答、翻訳、要約、分類、テンプレート生成
- **Execution Skills (2)**: コード実行、ツール実行
- **Management Skills (3)**: プロジェクト管理、スケジュール、リソース管理
- **AGI-Evolution Skills (5)**: 推論、学習、計画、創造、メタ認識

**Enum構造**:
- SkillType: スキルタイプ（16値）
- SkillDomain: スキル分類（Basic/Execution/Management/AGI）
- SkillCategory: スキルカテゴリ（Language/Code/Planning等）

#### 2. TaskClassifier（多言語対応）
**場所**: `a2a_system/skills/task_classifier.py`

**特徴**:
- 多言語キーワード（EN/KO/JA/ZH）
- 信頼度スコアリング（EMA付き）
- フォールバック機構
- リアルタイム学習

**キーワード例**:
- "code_review" → ["レビュー", "review", "검토", "审查"]
- 言語別信頼度計算

#### 3. SkillSelector（インテリジェント選択）
**場所**: `a2a_system/skills/skill_selector.py`

**選択ロジック**:
1. タスク＋ファイルタイプマッチング
2. 学習データ参照（過去成功率）
3. 信頼度加重計算
4. フォールバック（複数候補提案）

**精度**: 現在40% → 目標60%

#### 4. AdvancedLearningEngine（拡張機構）
**場所**: `a2a_system/skills/advanced_learning_engine.py`

**機能**:
- スキル特化型学習プロファイル
- パターン認識（EMA）
- メタ情報記録
- 学習曲線分析

### 統合フロー

```
タスク受け取り
    ↓
TaskClassifier (多言語→スキル推定)
    ↓
SkillSelector (学習データ参照)
    ↓
Best Skill 選択
    ↓
実行 + 結果記録
    ↓
LearningPersistenceManager (永続化)
    ↓
月次分析 (MonthlySummaryGenerator)
    ↓
改善提案 (WIKI記録)
```

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

