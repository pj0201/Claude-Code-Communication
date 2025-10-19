# GPT-5 Worker 初期化ガイド

## 🚀 起動時の必須読み込みファイル

**GPT-5 Worker が起動するたびに、以下のファイルを読み込んでください：**

```
/home/planj/Claude-Code-Communication/ROBUST_A2A_SYSTEM.md
/home/planj/Claude-Code-Communication/IMPLEMENTATION_REVIEW.md
```

---

## ⚠️ GPT-5 Worker 起動時の初期化手順

### Step 1: 起動確認メッセージ
```
🤖 GPT-5 Worker [gpt5_001] initialized
✅ Connected to broker at tcp://localhost:5555
```

### Step 2: コンテキストファイル読み込み
起動後、必ず以下のシステムプロンプトを適用してください：

```
【Claude-Code通信システムの動作情報】

【実装フレームワーク】
- ファイルベースのA2A（Agent-to-Agent）通信システム
- コンテキストは YAML 形式で外部ファイルに永続化
- コンテキストファイル: /a2a_system/shared/context_storage/gpt5_working_context.yml
- 学習パターン: /a2a_system/shared/learned_patterns/

【あなたの役割】
1. 質問受信時に gpt5_working_context.yml を自動読み込み
2. 最新3ラウンドの壁打ち履歴を参考にする
3. 学習エンジンから関連パターンを参照する
4. 回答後、新ラウンドをコンテキストに追加

【重要な通信フロー】
Claude Code → Bridge → Broker → GPT-5 Worker
                              ↓
                       (外部コンテキストファイル)
                              ↓
                       GPT-5 API 呼び出し
                              ↓
                       Broker → Bridge → Claude Code

【システム特徴】
- コンテキストは外部ファイル管理（ログ肥大化なし）
- 学習パターンから過去経験を参考可能
- 各ラウンドは自動的にファイルに記録される
- メモリリスク無し（すべてYAMLファイル保存）
```

### Step 3: 実装詳細の確認

起動後、必ず以下を確認してください：

**実装の4フェーズ**:
1. **ファイルベースコンテキスト管理** (`context_manager.py`)
   - YAML形式で永続化
   - 無制限容量対応

2. **学習エンジン統合** (`learning_integration.py`)
   - 成功パターン自動記録
   - 信頼度スコアリング

3. **GPT-5 Worker 拡張** (`gpt5_worker.py`)
   - コンテキスト自動読み込み
   - システムプロンプトに統合

4. **監視・再起動システム** (`system_supervisor.py`)
   - プロセス落ち自動検出
   - 自動再起動機能

---

## 📖 必読ドキュメント

### 優先度1（必須）
```
/ROBUST_A2A_SYSTEM.md
    ↑
  起動時に必ず読む
  4フェーズの実装内容確認
```

### 優先度2（推奨）
```
/IMPLEMENTATION_REVIEW.md
    ↑
  テスト結果と検証内容
  システム動作確認
```

---

## 🔄 毎回の起動時チェックリスト

起動するたびに以下を確認してください：

- [ ] `gpt5_working_context.yml` ファイルが存在するか
- [ ] `/a2a_system/shared/learned_patterns/` にパターンファイルがあるか
- [ ] Bridge が `📤 Sent to ZMQ` ログを出力しているか
- [ ] Broker が `📤 Routed to gpt5_001` ログを出力しているか
- [ ] Worker が `📨 Received: QUESTION` ログを出力しているか

---

## 💾 記憶領域への保存について

現在、このドキュメント（`GPT5_INITIALIZATION.md`）内にシステム情報を記載しています。

**将来的には**：
- GPT-5 の記憶領域（ベクトルDB など）に保存可能
- 毎回の初期化手順を省略可能

**現在の運用**：
- 起動時にこのファイルを読み込み
- システムプロンプトに含める
- 実装の4フェーズを理解・対応

---

## 🎯 質問/レビュー受信時の対応方法

### QUESTION メッセージ受信時

1. `gpt5_working_context.yml` を読み込み
2. 最新3ラウンドの履歴を確認
3. 学習パターンから関連情報を検索
4. システムプロンプトにコンテキストを統合
5. ChatGPT API を呼び出し
6. 回答後、新ラウンドをコンテキストに追加

### REVIEW_REQUEST メッセージ受信時

1. 提示されたコードを分析
2. `learned_patterns/` から類似パターンを検索
3. 過去の成功例を参考に
4. 詳細で実行可能なレビューを提供

---

## 📝 ログレベルと確認方法

### 確認用コマンド
```bash
# Worker ログ確認
tail -50 a2a_system/gpt5_worker_fresh.log

# Bridge ログ確認
tail -50 a2a_system/claude_bridge.log

# コンテキストファイル確認
cat a2a_system/shared/context_storage/gpt5_working_context.yml

# 学習パターン確認
ls -la a2a_system/shared/learned_patterns/
```

---

## ✅ 正常な起動時の表示例

```
🤖 GPT-5 Worker [gpt5_001] initialized
🚀 Connecting to broker at tcp://localhost:5555
✅ Connected to broker at tcp://localhost:5555
📨 Received: QUESTION
📋 System prompt length: 1250 chars
📨 Using context from: /a2a_system/shared/context_storage/gpt5_working_context.yml
HTTP Request: POST https://api.openai.com/v1/chat/completions "HTTP/1.1 200 OK"
✅ Context updated: Round 1
📤 Sent response: ANSWER
```

---

## ❌ トラブルシューティング

### コンテキストファイルが見つからない
```bash
# ファイルを初期化
mkdir -p a2a_system/shared/context_storage
touch a2a_system/shared/context_storage/gpt5_working_context.yml
```

### 学習パターンが記録されない
```bash
# パターンディレクトリ確認
mkdir -p a2a_system/shared/learned_patterns
```

### システムプロンプトが反映されない
- `gpt5_worker.py` の `_answer_question` メソッドを確認
- システムプロンプト生成ロジックを再確認

---

## 🚀 実装完了日時
2025-10-18 16:58:00 UTC

## ✅ テスト状況
- 統合テスト: 成功 ✓
- 通信テスト: 成功 ✓
- YAML形式: 成功 ✓
- ファイル永続化: 成功 ✓

---

**最後に**: このドキュメントは GPT-5 がシステムを理解するための必須ガイドです。
毎回起動時に読み込み、実装の4フェーズを把握してください。
