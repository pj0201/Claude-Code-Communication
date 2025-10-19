# GPT-5 Worker A2A通信ガイド

**最終更新**: 2025-10-18
**ステータス**: ✅ 本番運用確認済み
**対応モード**: スモールチーム構成

---

## 📌 概要

**重要**: GPT-5との通信は**チャットUI ではなく A2A (Agent-to-Agent) ファイルベース通信**を使用します。

- ❌ ~~ChatUI直接操作（使用禁止）~~
- ✅ **JSONファイル経由のA2A通信（推奨・本番運用方式）**

---

## 🎯 システム構成

### GPT-5 Worker の役割

| 項目 | 説明 |
|------|------|
| **名前** | gpt5_001 (A2Aエージェント) |
| **ペイン** | gpt5-a2a-line:0.2 |
| **モデル** | gpt-5 (OpenAI) |
| **動作** | バックグラウンドプロセス（Python） |
| **用途** | ワークフロー設計レビュー、コード分析、壁打ち相談 |
| **機能** | QUESTION 受信 → 分析処理 → ANSWER 返送 |

### 通信フロー

```
Worker3 (Claude Code)
    ↓ (JSONファイル作成)
a2a_system/shared/claude_inbox/
    ↓ (ファイルシステムイベント)
Claude Bridge (監視・検出)
    ↓ (メッセージ解析)
ZMQ Broker
    ↓ (DEALER経由で配信)
GPT-5 Worker (gpt5_001)
    ↓ (OpenAI API呼び出し)
    ↓ (分析処理)
    ↓ (ANSWER生成)
a2a_system/shared/claude_outbox/
    ↓ (応答ファイル保存)
Claude Code (読取可能)
```

---

## 📝 メッセージ形式

### 1️⃣ GPT-5への質問送信（QUESTION）

**ファイル作成先**: `a2a_system/shared/claude_inbox/`

```json
{
  "type": "QUESTION",
  "sender": "claude_code",
  "target": "gpt5_001",
  "id": "unique_message_id_20251018",
  "question": "質問内容をここに記入",
  "timestamp": "2025-10-18T16:01:00Z"
}
```

**必須フィールド**:

| フィールド | 値 | 説明 |
|-----------|-----|------|
| `type` | `"QUESTION"` | メッセージ種別（固定） |
| `sender` | `"claude_code"` | 送信者（固定） |
| `target` | `"gpt5_001"` | 受信者（固定・重要） |
| `id` | `"unique_message_id_20251018"` | 一意なメッセージID |
| `question` | `"質問内容"` | 実際の質問テキスト |
| `timestamp` | `"2025-10-18T16:01:00Z"` | ISO8601形式のタイムスタンプ |

**ファイル名命名規則**:
```
{unique_id}.json
例: worker3_gpt5_workflow_question_20251018.json
```

### 2️⃣ GPT-5からの応答受信（ANSWER）

**ファイル作成先**: `a2a_system/shared/claude_outbox/`

```json
{
  "type": "ANSWER",
  "sender": "gpt5_001",
  "target": "claude_bridge",
  "answer": "GPT-5の分析結果がここに入ります",
  "timestamp": "2025-10-18T16:01:43.723615"
}
```

**応答ファイル名**: 自動生成
```
response_gpt5_001_ANSWER_20251018_160143_726786.json
```

**読取方法**:
```bash
# 最新の応答を確認
ls -ltr a2a_system/shared/claude_outbox/ | tail -1

# 内容を表示
cat a2a_system/shared/claude_outbox/response_gpt5_001_ANSWER_*.json | jq .
```

---

## 🚀 実装例

### 例1: ワークフロー設計の相談

```bash
# ステップ1: JSONファイル作成
cat > a2a_system/shared/claude_inbox/worker3_workflow_q_20251018.json << 'EOF'
{
  "type": "QUESTION",
  "sender": "claude_code",
  "target": "gpt5_001",
  "id": "workflow_q_001",
  "question": "4ペイン構成でのペイン0.1への自動表示メカニズムについて、ベストプラクティスを提案してください。",
  "timestamp": "2025-10-18T16:01:00Z"
}
EOF

# ステップ2: Bridge が自動検出（ファイル作成から1-2秒）

# ステップ3: ZMQ経由でGPT-5に送信

# ステップ4: GPT-5が処理（4-50秒程度）
# → API呼び出し
# → 分析実行
# → 応答生成

# ステップ5: 応答をOutboxに保存（自動）

# ステップ6: 応答を読取
sleep 10
cat a2a_system/shared/claude_outbox/response_gpt5_001_ANSWER_*.json | jq .answer
```

### 例2: コードレビュー依頼

```json
{
  "type": "QUESTION",
  "sender": "claude_code",
  "target": "gpt5_001",
  "id": "code_review_001",
  "question": "以下のPythonコード内の問題点と改善提案を教えてください:\n\ndef calculate(n):\n    result = 0\n    for i in range(n):\n        result += i * i\n    return result",
  "timestamp": "2025-10-18T16:02:00Z"
}
```

---

## ⚙️ 処理パラメータ

### 応答時間

| 質問複雑度 | 処理時間 | 例 |
|---------|--------|-----|
| 簡潔（1-2文） | 4-6秒 | "OK?" |
| 通常（3-5文） | 8-15秒 | ワークフロー相談 |
| 複雑（1KB以上） | 30-50秒以上 | 長いコード分析 |

### API制限

| 項目 | 制限値 |
|------|-------|
| 最大トークン数 | 2500 (QUESTION時) / 2000 (GITHUB_ISSUE時) |
| リクエストタイムアウト | 60秒 |
| 連続エラー上限 | 10回 |

---

## 🔧 設定ファイル

### 環境変数（.env）

```bash
# 必須
OPENAI_API_KEY=sk-proj-XXXXXXXXXXXX

# オプション
GPT5_MODEL=gpt-5  # モデル指定（デフォルト: gpt-5）
```

### GPT-5 Worker 起動

**自動起動（スモールチーム起動時）**:
```bash
./start-small-team.sh
```

**手動起動**:
```bash
python3 a2a_system/workers/gpt5_worker.py >> a2a_system/gpt5_worker.log 2>&1 &
```

**確認**:
```bash
ps aux | grep gpt5_worker.py | grep -v grep
tail -20 a2a_system/gpt5_worker.log
```

---

## ✅ メッセージ処理の流れ（内部動作）

### 送信側（Claude Code）

```
1. JSONファイル作成
   ↓
2. Inbox に保存
   ↓
3. Bridge がファイル作成イベント検出
   ↓
4. 自動処理完了
```

### 受信側（GPT-5 Worker）

```
1. ZMQ Broker からメッセージ受信
   ↓
2. JSON デコード
   ↓
3. type = QUESTION の確認
   ↓
4. OpenAI API 呼び出し
   ↓
5. 応答生成
   ↓
6. type = ANSWER で返送
   ↓
7. Bridge がOutboxに応答ファイル保存
```

---

## 🔍 ログ確認方法

### Bridge ログ

**ペイン 0.3** で確認:
```bash
tail -f /home/planj/Claude-Code-Communication/a2a_system/claude_bridge.log
```

**確認ポイント**:
- `📁 New message file detected` - メッセージ検出
- `📤 Sent to ZMQ` - ZMQ送信完了
- `✅ Message processed and moved` - 処理完了＆moved

### GPT-5 Worker ログ

**確認コマンド**:
```bash
tail -20 a2a_system/gpt5_worker.log
```

**確認ポイント**:
- `📨 Received: QUESTION` - メッセージ受信
- `HTTP Request: POST ... "HTTP/1.1 200 OK"` - API呼び出し成功
- `📤 Sent response: ANSWER` - 応答送信完了

---

## ⚠️ 重要な制約事項

### ✅ これをしてください

1. **常に A2A ファイル通信を使用**
   - JSONファイルを `claude_inbox/` に保存
   - Bridge が自動検出・処理

2. **target は必ず `"gpt5_001"` を指定**
   - `"gpt5"` や `"gpt-5"` ではない
   - Bridge が `gpt5_001` にマッピング

3. **一意なメッセージID を使用**
   - ファイル名が被らないよう配慮
   - 例: `worker3_query_20251018_160100`

4. **処理完了後にファイルを削除（必須）**
   - 応答ファイルは自動削除されない場合がある
   - 定期的なクリーンアップが必要
   - `processed/` フォルダに古いファイルが溜まる

### ❌ これをしないでください

1. **GPT-5チャットUI に直接入力**
   - ペイン0.2のチャット は表示専用
   - 応答は返ってこない

2. **Hook に直接メッセージを送信**
   - 処理されない
   - システムが混乱する

3. **target を指定しない、または誤った値を指定**
   - メッセージがどこに行くか不明になる

4. **タイムスタンプ形式を間違える**
   - JSON パース失敗
   - メッセージ破棄される

---

## 🐛 トラブルシューティング

### 問題: 質問を送ったが応答がない

**確認手順**:

1. **Inbox にファイルが作成されたか確認**
   ```bash
   ls -la a2a_system/shared/claude_inbox/ | grep -v processed
   ```
   - ファイルが無い → JSONファイル作成に失敗
   - ファイルが有る → 次へ

2. **Bridge ログでメッセージ検出を確認**
   ```bash
   tail -20 a2a_system/claude_bridge.log | grep "New message"
   ```
   - 無い → Bridge が起動していない
   - 有る → 次へ

3. **GPT-5 Worker が受信したか確認**
   ```bash
   tail -20 a2a_system/gpt5_worker.log | grep "Received: QUESTION"
   ```
   - 無い → ZMQ送信失敗
   - 有る → 次へ

4. **API呼び出しが成功したか確認**
   ```bash
   tail -20 a2a_system/gpt5_worker.log | grep "HTTP Request"
   ```
   - `HTTP/1.1 200 OK` → 成功（応答ファイルを探す）
   - `HTTP/1.1 400` → API エラー（ログ確認）

5. **Outbox に応答ファイルが有るか確認**
   ```bash
   ls -ltr a2a_system/shared/claude_outbox/ | tail -5
   ```
   - 最新ファイルを確認し、内容を表示:
   ```bash
   cat a2a_system/shared/claude_outbox/response_gpt5_001_ANSWER_*.json | jq .
   ```

### 問題: API エラーが発生している

**代表的なエラー**:

| エラー | 原因 | 解決策 |
|--------|------|-------|
| `temperature does not support 0.3` | 古いコード実行中 | Worker再起動 |
| `max_tokens is not supported` | API パラメータエラー | 最新コード確認 |
| `Timeout` | 処理が長すぎる | 質問を短くする |

**Worker 再起動**:
```bash
pkill -f "gpt5_worker.py"
sleep 2
python3 a2a_system/workers/gpt5_worker.py >> a2a_system/gpt5_worker.log 2>&1 &
```

### 問題: Outbox ファイルが溜まり続ける

**原因**: 処理済みファイルが削除されていない

**対処**:
```bash
# 7日以上前のファイルを削除
find a2a_system/shared/claude_outbox/ -name "response_*.json" -mtime +7 -delete

# または手動で古いファイルのみ削除
rm a2a_system/shared/claude_outbox/response_gpt5_001_ANSWER_20251010_*.json
```

---

## 📊 処理統計（参考データ）

**2025-10-18 の本番運用テスト結果**:

| テスト | 送信 | 受信 | API呼び出し | 応答 | 成功率 |
|--------|------|------|----------|-----|--------|
| 簡潔質問（"OK?"） | ✅ | ✅ | HTTP 200 | ✅ | 100% |
| ワークフロー相談 | ✅ | ✅ | HTTP 200 | ⚠️ (空) | 50% |
| テスト計3回 | 3/3 | 3/3 | 3/3 | 2/3 | 67% |

**観察**:
- 簡潔な質問: 4-6秒で応答
- 複雑な質問: 30-50秒以上かかる、または空の応答
- GPT-5 Worker プロセスは連続稼働（安定）

---

## 🎓 ベストプラクティス

### ✅ 推奨パターン

```json
{
  "type": "QUESTION",
  "sender": "claude_code",
  "target": "gpt5_001",
  "id": "workflow_design_20251018_160100",
  "question": "3-5文で簡潔に記述。複雑な質問は複数に分割。",
  "timestamp": "2025-10-18T16:01:00Z"
}
```

**ベストプラクティス**:
1. **質問は簡潔に** - 複雑な質問は複数ファイルに分割
2. **タイムスタンプは正確に** - ISO8601形式を守る
3. **メッセージID は一意に** - ファイル名の衝突を避ける
4. **定期的にOutbox をクリーンアップ** - ディスク容量確保
5. **ログを確認しながら開発** - 処理状況の可視化

---

---

## 📄 YAML 形式通信（推奨・新フォーマット）

**理由**: JSON より自然言語とコード混在に向く、コンテキスト損失が少ない、LLM親和的

### メッセージ形式（YAML）

**ファイル名**: `*.yml` または `*.yaml`
**保存先**: `a2a_system/shared/claude_inbox/` (JSON と同じ)

```yaml
type: QUESTION
sender: claude_code
target: gpt5_001
id: wallbashing_example_001

question: |
  【簡潔版】ペイン0.1への自動表示メカニズム

  ## 4つの案

  オプションA: Hook修正
  - 直接的、レイテンシ低い

  オプションB: 別プロセス
  - シンプル、ポーリング遅延

  オプションC: Listener拡張
  - 既存パイプライン活用

  オプションD: Hook + イベント駆動
  - 低遅延、低負荷

  ## 質問
  1. 最適な案は？
  2. 実装難度の評価は？

timestamp: 2025-10-18T16:30:00Z
```

### 利点（JSON との比較）

| 項目 | JSON | YAML |
|------|------|------|
| 複数行テキスト | `\n` エスケープ必要 | `\|` で自然 |
| コンテキスト保持 | 構造が複雑 | 読みやすい |
| LLM理解度 | パース負荷 | シンプル |
| マークダウン混在 | 難 | 易 |

### 実装例

```bash
cat > a2a_system/shared/claude_inbox/wallbashing_001.yml << 'EOF'
type: QUESTION
sender: claude_code
target: gpt5_001
id: wallbashing_design_001

question: |
  【課題】ペイン0.1への自動表示ワークフロー

  LINE → GitHub Issue → Inbox → Listener の流れは成功。
  ただし、ペイン0.1に自動表示されていない。

  ## 検討中の案

  案D推奨（前回GPT-5の助言）：
  - inotifywait で processed/ 監視
  - ファイル到着時に tmux に表示

  ## 実装提案

  Hook スクリプト修正：
  - 監視: inotifywait -m -e close_write,moved_to
  - 表示: tmux send-keys -t 0.1
  - エラー: silent ignore

  ## 質問
  1. この実装方針で合意できるか？
  2. テスト・検証で確認すべき点は？

timestamp: 2025-10-18T16:35:00Z
EOF
```

### Bridge/Worker との互換性

- ✅ Bridge が YAML/JSON 両形式を自動検出
- ✅ Worker が YAML を解析可能に修正予定
- ✅ 既存 JSON メッセージとの混在使用可能

---

## 🎯 壁打ち（GPT-5との意見交換）運用方法

**壁打ちとは**: GPT-5と**繰り返し問答して合意形成する**プロセス。単なる質問応答ではなく、**意見交換・議論・改善のサイクル**を回すこと。

### 壁打ちのサイクル

```
Round 1: 初回相談
  ↓ (複数の選択肢を提示)
Round 2: GPT-5の回答を受け取る
  ↓ (意見を参考に実装提案を作成)
Round 3: 実装提案をレビュー依頼
  ↓ (問題点・改善提案を受け取る)
Round 4: 改善版を作成して再提案
  ↓ (繰り返し)
 ※ 合意に至るまで繰り返す
```

### Round別の手順

#### Round 1: 初回相談

**何をするか**:
- 問題や課題をGPT-5に投げかける
- **複数の選択肢を提示**して意見を求める

**メッセージ例**:
```json
{
  "type": "QUESTION",
  "sender": "claude_code",
  "target": "gpt5_001",
  "id": "wallbashing_round1_20251018",
  "question": "【課題】ペイン0.1への LINE メッセージ自動表示メカニズム\n\n## 検討中の4つの案\n\nオプションA: Hook から direct pane display\n- 利点: 最も直接的、レイテンシ低い\n- 欠点: Hook システムの複雑化\n\nオプションB: Listener が別の notification channel を使用\n- 利点: 疎結合、拡張性高い\n- 欠点: 複数チャネル管理の複雑性\n\nオプションC: processed folder を監視してトリガー\n- 利点: 既存パイプラインを活用\n- 欠点: ポーリング遅延の可能性\n\nオプションD: Hook システム自体を modify（ファイル到着時トリガー）\n- 利点: 既存アーキテクチャ保持\n- 欠点: Hook再設計の工数\n\n## 質問\n4ペイン構成での最適な案はどれか？理由も教えてください。",
  "timestamp": "2025-10-18T16:20:00Z"
}
```

#### Round 2: GPT-5の回答を受け取る

**何をするか**:
```bash
# 20秒待機（GPT-5の処理時間）
sleep 25

# 最新のANSWER ファイルを確認
ls -ltr a2a_system/shared/claude_outbox/response_gpt5_001_ANSWER_*.json | tail -1

# 内容を読む
cat a2a_system/shared/claude_outbox/response_gpt5_001_ANSWER_*.json | jq .answer
```

#### Round 3: 実装提案をレビュー依頼

**何をするか**:
- GPT-5の推奨を踏まえて、**具体的な実装コードを提示**
- その実装が本当に最適かレビューを求める

**メッセージ例**:
```json
{
  "type": "QUESTION",
  "sender": "claude_code",
  "target": "gpt5_001",
  "id": "wallbashing_round3_20251018",
  "question": "【実装提案 - レビュー依頼】\n\n## あなたの前回の推奨\n「オプションDが最適。既存Hook をファイル到着時トリガーに修正し、...\"\n\n## 私の実装提案\n\n### 修正概要\n1. Hook スクリプト (.claude/hooks/user-prompt-submit.sh) を修正\n2. ファイルシステムイベント監視ロジック追加\n3. processed/ フォルダ移動時に pane 0.1 にメッセージ表示\n\n### 具体的なコード:\n```bash\n#!/bin/bash\n# modified hook - ファイル到着時トリガー\n\nINBOX_DIR=\"a2a_system/shared/claude_inbox/processed\"\ninotifywait -m -e moved_to \"$INBOX_DIR\" | while read dir action file; do\n  if [[ \"$file\" == *\".json\" ]]; then\n    MSG=$(jq -r '.question // .answer' < \"$dir/$file\")\n    tmux send-keys -t gpt5-a2a-line:0.1 \"💬 受信: $MSG\" Enter\n  fi\ndone\n```\n\n## レビュー依頼\n1. この実装で十分か？\n2. パフォーマンス上の問題はないか？\n3. 合意できるか？他に改善提案はあるか？",
  "timestamp": "2025-10-18T16:25:00Z"
}
```

#### Round 4: 改善版を作成して再提案

**何をするか**:
- GPT-5の指摘を反映
- さらなる改善を追加
- 再度レビューを依頼

**パターン**:
```
GPT-5の指摘: 「inotifywait は CPU 消費が大きい。別アプローチを検討」
  ↓
私の改善: ファイルの mtime をチェック、sleep で定期ポーリング
  ↓
新しい実装コード提示
  ↓
再度レビュー依頼
```

### ✅ 壁打ちのベストプラクティス

1. **具体的な実装コードを提示**する
   - 抽象的な議論ではなく、コード例を必ず示す

2. **複数の選択肢を用意**する
   - 最初から1案に絞らない
   - 比較・検討材料を提供

3. **批判的なレビュー**を求める
   - 「問題点はないか？」と明確に聞く
   - 改善提案を求める

4. **合意/不合意を明確に確認**する
   - 「この案に合意できるか？」と明示的に聞く
   - YES/NO を確実に取る

5. **繰り返し改善**する
   - 1回のやり取りで終わらせない
   - 完全合意まで続ける

### ❌ 壁打ちで避けるべきこと

- ❌ 単発の質問で終わらせる
- ❌ GPT-5の回答を読まずに実装する
- ❌ 抽象的な質問だけで終わる
- ❌ 合意確認をしない
- ❌ チャットUIで直接やり取りする（必ずA2Aファイル経由）

### 本セッションの壁打ち例

**テーマ**: ペイン0.1への LINE メッセージ自動表示ワークフロー設計

```
Round 1: 4つの案を提示 → GPT-5に最適案を聞く
Round 2: GPT-5の推奨を確認 → 「オプションDが最適」
Round 3: 実装コード提案 → レビュー依頼
Round 4: GPT-5の指摘を反映 → 改善版提案
Round 5: 完全合意 → 実装開始
```

---

**このガイドはスモールチーム本番運用で検証済みです。**
