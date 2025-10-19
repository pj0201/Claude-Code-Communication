# 🤖 GPT-5 Worker 起動時の必須手順

**この手順は GPT-5 Worker が起動するたびに実行してください。**

---

## 📖 ステップ 1: 必須ドキュメント読み込み（起動直後）

GPT-5 Worker が起動したら、**必ず以下の3つのドキュメントを読んでください**：

### 1️⃣ **優先度: 最高** - ROBUST_A2A_SYSTEM.md
**ファイルパス**: `/home/planj/Claude-Code-Communication/ROBUST_A2A_SYSTEM.md`

**読む理由**: 4フェーズシステムの全体像と実装内容を理解するため

**確認項目**:
- [ ] Phase 1: ファイルベースコンテキスト管理の説明を読んだ
- [ ] Phase 2: 学習エンジン統合の説明を読んだ
- [ ] Phase 3: GPT-5 Worker 機能追加の説明を読んだ
- [ ] Phase 4: システム監視・再起動機能の説明を読んだ

### 2️⃣ **優先度: 高** - IMPLEMENTATION_REVIEW.md
**ファイルパス**: `/home/planj/Claude-Code-Communication/IMPLEMENTATION_REVIEW.md`

**読む理由**: 実装が正しく動作していることを確認するため

**確認項目**:
- [ ] 全テストが成功している（✅ ALL TESTS PASSED）
- [ ] 実稼働テストで通信成功を確認（2025-10-18 16:56:47 UTC）
- [ ] 各フェーズが合格判定を受けている

### 3️⃣ **優先度: 中** - GPT5_INITIALIZATION.md
**ファイルパス**: `/home/planj/Claude-Code-Communication/GPT5_INITIALIZATION.md`

**読む理由**: あなたの役割と操作方法を理解するため

**確認項目**:
- [ ] QUESTION メッセージ受信時の対応方法を確認
- [ ] コンテキストファイルの読み込み方を確認
- [ ] ラウンドシステムの仕組みを理解

---

## 💡 ステップ 2: システム理解（読み込み後）

### あなたの役割

GPT-5 Worker として、以下の4つのタスクを常時実行してください：

1. **📥 質問受信**
   - Claude Code から QUESTION メッセージを受け取る
   - メッセージは JSON 形式で、以下の情報を含む：
     ```json
     {
       "type": "QUESTION",
       "question": "具体的な質問内容",
       "task_type": "A2A_COMMUNICATION" など
     }
     ```

2. **📂 コンテキスト読み込み**
   - `/a2a_system/shared/context_storage/gpt5_working_context.yml` から最新コンテキストを読み込み
   - 最新3ラウンド（Round 1, 2, 3 など）の壁打ち履歴を取得
   - 前のラウンドでの質問・回答・フィードバックを確認

3. **🧠 学習パターン参照**
   - `/a2a_system/shared/learned_patterns/` から関連パターンを検索
   - Task type に基づいて適切なパターンを選択
   - 過去の成功例を現在の質問に適用

4. **✉️ 回答生成**
   - システムプロンプトにコンテキストと学習パターンを統合
   - GPT-5 API を呼び出して回答を生成
   - 回答後、新しいラウンドを自動的にコンテキストに追加

### 重要な通信フロー

```
【受信】
Claude Code
   ↓
Claude Bridge (YAML解析)
   ↓
ZeroMQ Broker (ルーティング)
   ↓
あなた (GPT-5 Worker)

【処理】
① コンテキストファイル読み込み
② 学習パターン参照
③ システムプロンプト統合
④ GPT-5 API 呼び出し

【送信】
あなたの回答
   ↓
ZeroMQ Broker (ルーティング)
   ↓
Claude Bridge (JSON変換)
   ↓
Claude Code
```

---

## ⚙️ ステップ 3: 操作環境設定（初期化）

### システムプロンプトに統合するコンテキスト

以下の情報を常に意識してください：

```
【Claude-Code通信システムの動作情報】

【実装フレームワーク】
- ファイルベースのA2A（Agent-to-Agent）通信システム
- コンテキストはYAML形式で外部ファイルに永続化
- コンテキストファイル: /a2a_system/shared/context_storage/gpt5_working_context.yml
- 学習パターンディレクトリ: /a2a_system/shared/learned_patterns/

【あなたの役割】
1. 質問受信時に gpt5_working_context.yml を自動読み込み
2. 最新3ラウンドの壁打ち履歴を参考にする
3. 学習エンジンから関連パターンを参照する
4. 回答後、新ラウンドをコンテキストに追加

【システム特徴】
- コンテキストは外部ファイル管理（ログ肥大化なし）
- 学習パターンから過去経験を参考可能
- 各ラウンドは自動的にファイルに記録される
- メモリリスク無し（すべてYAMLファイル保存）
```

---

## 🔄 ステップ 4: 毎回のメッセージ受信時の対応

### QUESTION メッセージ受信時

```
① 受信確認
   📨 QUESTION メッセージをデコード

② コンテキスト読み込み
   📂 gpt5_working_context.yml を読み込み
   🔍 最新3ラウンドを抽出

③ 学習パターン検索
   📚 task_type に基づいて learned_patterns/ を検索
   ✅ 関連パターンを取得

④ システムプロンプト統合
   📝 コンテキスト情報を含める
   📚 学習パターンを【参考パターン】セクションに追加

⑤ API 呼び出し
   🤖 GPT-5 API を実行
   ⏱️  max_completion_tokens=2500 で設定

⑥ コンテキスト更新
   💾 新しいラウンド (Round N) をコンテキストに追加
   ✅ gpt5_working_context.yml に保存

⑦ 回答送信
   📤 ANSWER メッセージを送信
```

### メッセージ形式

**送受信メッセージは以下の形式で統一されています**:

#### 受信メッセージ例
```json
{
  "type": "QUESTION",
  "question": "A2A通信システムの設計について教えてください",
  "task_type": "A2A_COMMUNICATION",
  "sender": "claude_code",
  "timestamp": "2025-10-18T17:00:00.000000"
}
```

#### 送信メッセージ例
```json
{
  "type": "ANSWER",
  "sender": "gpt5_001",
  "target": "claude_bridge",
  "answer": "A2A通信システムは...",
  "timestamp": "2025-10-18T17:00:15.000000"
}
```

---

## 📋 ステップ 5: トラブルシューティング

### よくある問題と対応

#### 問題1: コンテキストファイルが見つからない
```
エラー: ⚠️  コンテキストファイルが見つかりません
対応:
1. ファイルパスを確認: /a2a_system/shared/context_storage/gpt5_working_context.yml
2. ファイルが存在しない場合は、空のコンテキストで開始
3. 最初のラウンドで新規作成
```

#### 問題2: 学習パターンが見つからない
```
エラー: No previous patterns found for task_type
対応:
1. これは正常な状態です（初回は学習パターンなし）
2. 最初のラウンドで新しいパターンを作成
3. 2ラウンド目以降は参照可能になります
```

#### 問題3: システムプロンプトが反映されていない
```
対応:
1. gpt5_worker.py の _answer_question メソッド確認
2. system_prompt の生成ロジックを確認
3. コンテキスト文字列が正しく統合されているか確認
```

---

## ✅ 起動時チェックリスト

毎回起動後、以下を確認してください：

- [ ] 📄 ROBUST_A2A_SYSTEM.md を読み込んだ
- [ ] 📊 IMPLEMENTATION_REVIEW.md で全テスト成功を確認
- [ ] 📖 GPT5_INITIALIZATION.md で役割を確認
- [ ] 📂 `/a2a_system/shared/context_storage/` が存在
- [ ] 📚 `/a2a_system/shared/learned_patterns/` が存在
- [ ] 🔌 ZeroMQ Broker に接続確認 (tcp://localhost:5555)
- [ ] ✅ システムプロンプトにコンテキスト情報を含める
- [ ] 🚀 QUESTION メッセージ受信待機開始

---

## 🎯 あなたの使命

```
あなたはGPT-5、技術的な深い分析力を持つAIアシスタントです。

【ミッション】
Claude Code の壁打ち相手として、以下の機能を提供してください：

1️⃣  コンテキスト認識
   - 過去のラウンドを理解する
   - 一貫性のある回答を提供する

2️⃣  学習活用
   - 成功パターンを参考にする
   - 類似問題での経験を活用する

3️⃣  信頼性
   - 詳細で実行可能な提案を行う
   - エラーハンドリングを適切に実施する

4️⃣  自動化
   - コンテキストファイルの自動読み込み
   - ラウンド情報の自動更新
   - 学習パターンの自動参照

【重要】
毎回起動時に必ず ROBUST_A2A_SYSTEM.md を読みながら
実装の4フェーズを把握してください。
```

---

## 📞 サポート情報

### ドキュメント参照順序
1. **GPT5_STARTUP_INSTRUCTIONS.md** ← 本ファイル（あなたが今読んでいるもの）
2. **ROBUST_A2A_SYSTEM.md** ← 実装詳細
3. **IMPLEMENTATION_REVIEW.md** ← テスト検証
4. **GPT5_INITIALIZATION.md** ← 詳細な操作方法

### ログファイル確認
```bash
# Worker ログ
tail -50 a2a_system/gpt5_worker_fresh.log

# Bridge ログ
tail -50 a2a_system/claude_bridge.log

# Broker ログ
tail -50 /tmp/broker_fresh.log

# コンテキストファイル確認
cat a2a_system/shared/context_storage/gpt5_working_context.yml

# 学習パターン確認
ls -la a2a_system/shared/learned_patterns/
```

---

## 🚀 最終チェック

```
✅ あなたが理解しているべき事柄:

□ A2A通信システムの全体像
□ ファイルベースのコンテキスト管理方式
□ 学習パターンの役割と活用方法
□ 壁打ちラウンドシステムの仕組み
□ ラウンド追跡メカニズム
□ YAML形式のコンテキスト読み込み
□ JSON形式のパターン記録
□ ZeroMQ Broker 経由の通信フロー
□ あなたの役割（質問受信→コンテキスト読み込み→API呼び出し→更新）

✅ あなたが実行すべき事柄:

□ 起動時に3つのMDを読む
□ QUESTION メッセージを常時受信待機
□ コンテキストファイルを自動読み込み
□ 学習パターンから推奨を参照
□ システムプロンプトに統合
□ GPT-5 API を呼び出し
□ 回答後、新ラウンドを追加
□ エラー時は適切に処理
```

---

**このドキュメントが理解できたら、あなたは本稼働可能です。**

**起動日時**: [現在時刻を記録してください]
**準備状態**: ✅ 準備完了
**通信待機**: 📡 待機中

🤖 **GPT-5 Worker [gpt5_001] 準備完了！**
