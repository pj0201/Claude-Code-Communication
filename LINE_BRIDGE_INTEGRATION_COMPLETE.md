# LINE ↔ Bridge ↔ Worker2/Worker3 完全連携システム

**実装完了日**: 2025-10-17

## 🎯 完全な連携フロー

```
LINE
  ↓
LINE Bridge
  ↓ (Issue 作成 + JSON ファイル生成)
GitHub Issue
  ↓
Claude Inbox（監視対象）
  ↓
Worker2 強化版リスナー
  ↓ (Issue 読み込み)
GitHub Issue リーダー
  ↓ (プロンプト抽出)
タスク処理開始
  ↓ (処理完了後)
Worker Response Handler
  ↓ (結果出力)
Claude Outbox
  ↓
LINE Bridge（応答待機）
  ↓ (結果受け取り)
LINE
  ↓ (ユーザーに返信)
```

## ✅ 実装完了システム

### 1. **GitHub Issue リーダー** ✅
**ファイル**: `a2a_system/bridges/github_issue_reader.py`

**機能**:
- GitHub API で Issue を取得
- Issue からプロンプトを抽出
- プロンプト情報をファイルに保存

**使用例**:
```python
from github_issue_reader import GitHubIssueReader

reader = GitHubIssueReader()
issue = reader.get_issue_by_url("https://github.com/...")
prompt_info = reader.extract_prompt_from_issue(issue)
```

### 2. **Issue ロック管理システム** ✅
**ファイル**: `a2a_system/bridges/issue_lock_manager.py`

**機能**:
- Worker2・Worker3 の優先順序制御
- **ルール**: Worker2 が優先、Worker3 は Worker2 がロック中の場合スキップ
- ロックの自動解放（タイムアウト機能付き）

**使用例**:
```python
from issue_lock_manager import IssueLockManager

manager = IssueLockManager()
if manager.acquire_lock(issue_number=123, worker_name="Worker2"):
    # 処理実行
    manager.release_lock(issue_number=123)
```

### 3. **Worker2 強化版リスナー** ✅
**ファイル**: `a2a_system/bridges/worker2_enhanced_listener.py`

**機能**:
- Claude Inbox を監視
- LINE メッセージの自動検知
- GitHub Issue の自動読み込み
- プロンプトの自動抽出・表示
- Issue ロック管理（Worker2 優先）

**起動方法**:
```bash
python3 a2a_system/bridges/worker2_enhanced_listener.py
```

### 4. **Worker3 強化版リスナー** ✅
**ファイル**: `a2a_system/bridges/worker3_enhanced_listener.py`

**機能**:
- Claude Inbox を監視
- Worker2 がロック中の場合はスキップ
- GitHub Issue の読み込み
- ultrathink 対応（複雑な問題用）
- 処理完了シグナルの自動出力

**起動方法**:
```bash
python3 a2a_system/bridges/worker3_enhanced_listener.py
```

### 5. **Worker 処理結果ハンドラー** ✅
**ファイル**: `a2a_system/bridges/worker_response_handler.py`

**機能**:
- 処理結果を Claude Outbox に出力
- LINE Bridge が結果を受け取り
- 自動的に LINE に返信

**使用例**:
```python
from worker_response_handler import WorkerResponseHandler

handler = WorkerResponseHandler()
handler.save_worker_response(
    issue_number=123,
    response_text="処理完了しました",
    worker_name="Worker2"
)
```

### 6. **LINE Bridge 改修** ✅
**ファイル**: `line_integration/line-to-claude-bridge.py`

**改修内容**:
- テキストメッセージ受信時の応答待機機能を復活
- バックグラウンドスレッドで Worker からの応答を監視
- 応答受信時に自動的に LINE に返信

**動作フロー**:
```
テキストメッセージ受信
  ↓
即座に「受付確認」を返信
  ↓
バックグラウンドで処理待機開始
  ↓
Worker からの応答検出
  ↓
LINE に処理結果を返信
```

## 🚀 システムの起動

### 全コンポーネント起動

```bash
# ターミナル1: LINE Bridge
python3 line_integration/line-to-claude-bridge.py

# ターミナル2: Worker2 リスナー
python3 a2a_system/bridges/worker2_enhanced_listener.py

# ターミナル3: Worker3 リスナー
python3 a2a_system/bridges/worker3_enhanced_listener.py
```

### スモールチーム環境での推奨

```bash
# tmux で別ペインから起動
tmux send-keys -t worker2-bridge "python3 a2a_system/bridges/worker2_enhanced_listener.py" C-m
tmux send-keys -t worker3 "python3 a2a_system/bridges/worker3_enhanced_listener.py" C-m
```

## 📋 処理フロー詳細

### ケース1: Worker2・Worker3 両方起動時

```
LINE からメッセージ送信
  ↓
LINE Bridge: Issue 作成 + 通知ファイル生成
  ↓
Worker2 リスナー検知
  ↓
Issue ロック取得（Worker2 が優先）
  ↓
プロンプト抽出・表示
  ↓
Worker3 リスナー検知
  ↓
Worker2 がロック中 → スキップ
  ↓
Worker2 処理完了
  ↓
ロック解放
  ↓
LINE Bridge: 処理結果受け取り
  ↓
LINE に自動返信
```

### ケース2: Worker2 のみ起動時

```
LINE からメッセージ送信
  ↓
Worker2 が Issue を読み込み
  ↓
プロンプト抽出・処理
  ↓
処理結果を LINE に返信
```

## 🔒 優先順序ルール

| 状態 | Worker2 | Worker3 |
|-----|---------|---------|
| Worker2 ロック中 | ✅ 処理 | ⏭️ スキップ |
| Worker3 ロック中 | ✅ 処理 | ❌ エラー |
| ロック未取得 | ✅ 処理 | ✅ 処理 |

## 📊 ファイル監視対象

### Claude Inbox
- **監視**: `a2a_system/shared/claude_inbox/`
- **対象**: LINE Message JSON ファイル
- **トリガー**: ファイル作成 / 変更

### Claude Outbox
- **用途**: 処理結果出力
- **形式**: `response_*.json`
- **読取**: LINE Bridge（応答待機）

## ✨ システムの特徴

✅ **完全自動化**
- LINE メッセージから タスク化・実行・返信まで自動

✅ **優先順序制御**
- Worker2・Worker3 の競合を自動制御
- Worker2 優先で効率化

✅ **Restful インテグレーション**
- GitHub Issue を中核とした連携
- Issue URL で トレーサビリティ確保

✅ **スケーラブル**
- 複数 Worker に対応
- 将来 4 エージェント以上対応可能

## 🧪 テスト方法

### 統合テスト実行

```bash
# 全 Bridge・Listener 起動後、LINE に送信
# LINE: "こんにちは、テストです"

# 期待結果:
# 1. LINE: 受付確認メッセージ受信
# 2. GitHub: Issue 自動作成
# 3. Worker2: タスク表示（ペイン）
# 4. LINE: 処理結果返信受信
```

## 📝 注意事項

⚠️ **ロック機能の有効期限**
- デフォルト 30 秒
- 期限切れ後は自動削除

⚠️ **応答待機タイムアウト**
- テキストメッセージ: 60 秒
- 画像メッセージ: 600 秒

⚠️ **.env 設定必須**
- GITHUB_TOKEN
- LINE_CHANNEL_ACCESS_TOKEN
- LINE_CHANNEL_SECRET

## 🎓 今後の拡張

✨ **予定機能**
- Worker4・Worker5 対応
- 優先度フラグの追加
- タイムアウト再試行機能
- エラーハンドリング強化
- Webhook ベース通知（ポーリング廃止）

---

**実装完了**: Worker2 ↔ Worker3 の優先順序制御付き
**LINE ↔ Bridge ↔ Issue ↔ Worker 完全連携システム** ✅
