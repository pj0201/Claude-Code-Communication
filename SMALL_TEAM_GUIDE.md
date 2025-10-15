# 小規模チーム運用ガイド

## 📖 概要

**対象**: Claude Code（メイン開発） + GPT-5（壁打ち・レビュー）の小規模チーム

**特徴**:
- ✅ A2A強化機能をフル活用
- ✅ シンプルな構成（2エージェント）
- ✅ 実装した機能が即座に価値を発揮
- ✅ フルメンバーへの段階的移行が可能

---

## 🚀 クイックスタート

### 1. 環境設定

```bash
# .env ファイルを作成
cd /home/planj/Claude-Code-Communication
cp .env.example .env

# OPENAI_API_KEYを設定
nano .env
```

**.env の設定例**:
```bash
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 2. システム起動

```bash
# 小規模チーム起動
./start-gpt5-with-a2a.sh
```

### 3. tmuxセッションに接続

```bash
tmux attach -t small-team
```

**ペイン構成**:
```
┌─────────────────┬──────────────────┐
│                 │ GPT-5対話エリア   │
│  Claude Code    │ （壁打ち・レビュー）│
│  作業エリア      ├──────────────────┤
│                 │ システムモニター   │
└─────────────────┴──────────────────┘
```

**ペイン移動**: `Ctrl+b` → 矢印キー

---

## 💬 使い方

### パターン1: コードレビュー依頼

**Claude Code作業エリア（左ペイン）**:
```bash
# コード実装
vim src/main.py

# レビュー依頼メッセージを送信
python3 - <<EOF
import sys
sys.path.insert(0, "/home/planj/Claude-Code-Communication")

from a2a_system.shared.message_protocol import create_question_message, MessagePriority

msg = create_question_message(
    sender="claude_code_main",
    target="gpt5_reviewer",
    question="""
以下のコードをレビューしてください:

\`\`\`python
def calculate_total(items):
    total = 0
    for item in items:
        total += item['price'] * item['quantity']
    return total
\`\`\`

改善点を指摘してください。
""",
    priority=MessagePriority.HIGH
)

# メッセージをファイルに保存（GPT-5側で読み込み）
import json
with open('/tmp/review_request.json', 'w') as f:
    json.dump(msg.to_json_compatible(), f, ensure_ascii=False, indent=2)

print("✓ レビュー依頼を作成しました: /tmp/review_request.json")
EOF
```

**GPT-5対話エリア（右上ペイン）**:
```bash
# GPT-5シェル起動（必要に応じて）
# ※ start-gpt5-with-a2a.sh で自動起動されます

# レビューリクエストを読み込んで実行
You> /tmp/review_request.jsonの内容をレビューしてください
```

---

### パターン2: 壁打ち（アイデア検討）

**GPT-5対話エリア**:
```bash
# ※ start-gpt5-with-a2a.sh で自動起動されます

You> ユーザー認証機能を実装したいんだけど、JWT vs Session どっちがいいと思う？

GPT-5> [回答が返ってくる]

You> セキュリティ面ではどう？

GPT-5> [回答が返ってくる]
```

**特徴**:
- 応答時間が自動記録される
- エージェントステータスが自動更新される
- パフォーマンスメトリクスが蓄積される

---

### パターン3: 実装後の品質チェック

**Claude Code作業エリア**:
```bash
# 実装完了後、品質レポート作成
python3 - <<EOF
import sys
sys.path.insert(0, "/home/planj/Claude-Code-Communication")

from quality.quality_helper import QualityHelper, create_code_quality_issue, IssueSeverity

helper = QualityHelper()

# 品質レポート作成
report = helper.create_report(
    project_path="/home/planj/my-project",
    checked_by="claude_code_main"
)

# 自己チェックで見つけた問題を記録
report.add_issue(create_code_quality_issue(
    title="関数名が不明瞭",
    description="calc() という名前では何を計算するのか不明",
    file_path="src/utils.py",
    line_number=42,
    severity=IssueSeverity.LOW,
    suggestion="calculate_total_price() など明確な名前にする"
))

# レポート保存
helper.save_report(report)

print(f"✓ 品質レポート作成: {report.id}")
print(f"  スコア: {report.overall_score:.2f}")
print(f"  問題数: {len(report.issues)}")
EOF
```

---

### パターン4: GPT-5にレビューを依頼 → 品質レポート記録

**ワークフロー全体**:

```python
#!/usr/bin/env python3
"""
完全なレビューワークフロー例
"""
import sys
import time
from pathlib import Path

sys.path.insert(0, "/home/planj/Claude-Code-Communication")

from a2a_system.orchestration.agent_manager import get_agent_manager, AgentStatus
from a2a_system.shared.message_protocol import create_question_message, MessagePriority
from quality.quality_helper import QualityHelper, create_code_quality_issue, IssueSeverity

# 1. エージェント管理準備
manager = get_agent_manager()
manager.update_status("gpt5_reviewer", AgentStatus.BUSY)

# 2. レビュー依頼メッセージ作成
review_msg = create_question_message(
    sender="claude_code_main",
    target="gpt5_reviewer",
    question="""
以下のコードの品質をチェックしてください:
- セキュリティ問題
- パフォーマンス問題
- コードスタイル

[コードを貼り付け]
""",
    priority=MessagePriority.HIGH
)

print("レビュー依頼送信...")
print(f"優先度: {review_msg.priority.name}")

# 3. GPT-5のレビュー実行（実際のAPI呼び出し）
start_time = time.time()

# OpenAI API呼び出し
import os
import openai

openai.api_key = os.getenv("OPENAI_API_KEY")

response = openai.chat.completions.create(
    model="gpt-4",
    messages=[
        {"role": "system", "content": "あなたは厳格なコードレビュアーです。"},
        {"role": "user", "content": review_msg.payload['question']}
    ]
)

review_result = response.choices[0].message.content
response_time = time.time() - start_time

# 4. パフォーマンス記録
manager.record_message_processed("gpt5_reviewer", response_time)
manager.update_status("gpt5_reviewer", AgentStatus.IDLE)

print(f"✓ レビュー完了（{response_time:.2f}秒）")
print(f"\nレビュー結果:\n{review_result}\n")

# 5. 品質レポート作成
helper = QualityHelper()
report = helper.create_report(
    project_path="/home/planj/my-project",
    checked_by="gpt5_reviewer"
)

# GPT-5が指摘した問題を追加（手動または自動パース）
report.add_issue(create_code_quality_issue(
    title="GPT-5指摘: セキュリティ問題",
    description="SQLインジェクションのリスクあり",
    file_path="src/db.py",
    line_number=100,
    severity=IssueSeverity.CRITICAL,
    suggestion="パラメータ化クエリを使用"
))

# 6. レポート保存
helper.save_report(report)

print(f"✓ 品質レポート保存: {report.id}")
print(f"  スコア: {report.overall_score:.2f}")

# 7. エージェントサマリー表示
summary = manager.get_agent_summary()
print(f"\nエージェント状況:")
print(f"  総メッセージ数: {summary['performance']['total_messages']}")
print(f"  平均応答時間: {summary['performance']['avg_response_time']:.2f}秒")
```

---

## 📊 システム状態確認

### システムモニター（右下ペイン）

```bash
# リアルタイム状態確認
# ※ A2Aプロセス確認
ps aux | grep -E "(broker|gpt5_worker|claude_bridge)" | grep -v grep
```

**表示内容**:
- セッション状態
- 登録エージェント数
- 処理メッセージ数
- 平均応答時間
- 品質レポート数

### 詳細メトリクス確認

```python
from a2a_system.orchestration.agent_manager import get_agent_manager

manager = get_agent_manager()

# Claude Codeの状況
claude_info = manager.get_agent_info("claude_code_main")
print(f"Claude Code:")
print(f"  状態: {claude_info.status.value}")
print(f"  処理数: {claude_info.metrics.total_messages_processed}")

# GPT-5の状況
gpt5_info = manager.get_agent_info("gpt5_reviewer")
print(f"GPT-5:")
print(f"  状態: {gpt5_info.status.value}")
print(f"  平均応答時間: {gpt5_info.metrics.avg_response_time_sec:.2f}秒")
print(f"  エラー数: {gpt5_info.metrics.total_errors}")
```

---

## 🎯 実装機能の活用状況

### ✅ 強化メッセージプロトコル

**活用シーン**:
- レビュー依頼の優先度設定（CRITICAL/HIGH/MEDIUM）
- 緊急バグ修正の相談（TTL設定）
- メッセージ整合性検証

**効果**:
- 重要な質問を優先処理
- 期限付きタスクの管理
- 通信エラーの検出

### ✅ エージェント管理システム

**活用シーン**:
- GPT-5の応答時間追跡
- Claude Codeの作業状態管理
- パフォーマンスボトルネック特定

**効果**:
- エージェント稼働状況の可視化
- 処理時間の最適化
- エラー傾向の把握

### ✅ 品質ヘルパーシステム

**活用シーン**:
- Claude Codeの自己チェック記録
- GPT-5のレビュー結果記録
- 品質トレンド分析

**効果**:
- 品質の定量化
- 改善効果の測定
- 継続的な品質向上

---

## 🔄 フルメンバーへの移行

小規模チームで慣れたら、フルメンバー構成へスムーズに移行可能：

```bash
# 小規模チーム停止（ターミナルを閉じるだけでOK）
# または手動でプロセス停止:
pkill -f "python3.*a2a_system"

# フルメンバー起動
./startup-integrated-system.sh 5agents
```

**既存データの継承**:
- ✅ エージェント状態（`a2a_system/shared/agent_state.json`）
- ✅ 品質レポート（`quality/reports/`）
- ✅ パフォーマンスメトリクス

---

## 📝 ベストプラクティス

### 1. 日常的な使い方

**朝**:
```bash
./start-gpt5-with-a2a.sh
```

**開発中**:
- 左ペイン: コーディング
- 右上ペイン: 適宜GPT-5に相談
- 右下ペイン: 状態監視

**夕方**:
```bash
# 品質レポート確認
python3 -c "
from quality.quality_helper import QualityHelper
helper = QualityHelper()
reports = helper.get_recent_reports(limit=1)
if reports:
    r = reports[0]
    print(f'今日の品質スコア: {r.overall_score:.2f}')
"

# システム停止（ターミナルを閉じる）
```

### 2. GPT-5の効果的な使い方

**良い質問**:
```
You> このエラー処理は適切？
[コードを貼り付け]

You> パフォーマンスの観点でこのクエリを改善できる？

You> セキュリティ的に問題ない？
```

**避けるべき質問**:
```
You> コード書いて  # ← 自分で書くべき

You> 全部レビューして  # ← 具体的な観点を指定すべき
```

### 3. 品質レポートの活用

```python
# 週次レビュー
from quality.quality_helper import QualityHelper

helper = QualityHelper()

# 過去7日間のトレンド
trend = helper.get_quality_trend(days=7)

for date, score in zip(trend['dates'], trend['scores']):
    print(f"{date}: {score:.2f}")

# スコア低下の検出
if trend['scores'][-1] < 0.7:
    print("⚠️ 品質低下を検出。レビューを強化してください。")
```

---

## 🆘 トラブルシューティング

### GPT-5シェルが起動しない

```bash
# API Key確認
cat .env | grep OPENAI_API_KEY

# 権限確認
ls -l gpt5-shell.sh
chmod +x gpt5-shell.sh
```

### エージェント状態が更新されない

```python
from a2a_system.orchestration.agent_manager import get_agent_manager

manager = get_agent_manager()
manager._save_state()  # 手動保存
```

### tmuxセッションに接続できない

```bash
# セッション確認
tmux ls

# 強制再起動
pkill -f "python3.*a2a_system"
./start-gpt5-with-a2a.sh
```

---

## 📚 関連ドキュメント

- **クイックスタート**: `A2A_QUICK_START.md`
- **詳細仕様**: `A2A_ENHANCEMENT_SUMMARY.md`
- **フルチーム運用**: `CLAUDE.md`
- **統合例**: `a2a_system/examples/enhanced_integration_example.py`

---

**最終更新**: 2025年10月7日
**対象構成**: Claude Code + GPT-5（小規模チーム）
