# A2Aシステム強化機能 - クイックスタートガイド

## 📖 はじめに

このガイドでは、新しく追加されたA2A強化機能の基本的な使い方を説明します。

**重要**: これらの機能は**A2A（外部エージェント）専用**です。tmuxベースのPRESIDENT/Worker システムには影響しません。

---

## 🚀 5分で始める

### 1. 統合例を実行してみる

```bash
cd /home/planj/Claude-Code-Communication
python3 a2a_system/examples/enhanced_integration_example.py
```

このコマンドで、全ての新機能のデモが実行されます。

---

## 💬 シナリオ別使用例

### シナリオ1: 緊急タスクを優先的に処理したい

```python
from a2a_system.shared.message_protocol import create_task_message, MessagePriority

# 通常のタスク
normal_task = create_task_message(
    sender="claude_code",
    target="gpt5_001",
    task_description="コードレビューをお願いします",
    priority=MessagePriority.MEDIUM  # デフォルト
)

# 緊急タスク（優先処理される）
urgent_task = create_task_message(
    sender="claude_code",
    target="gpt5_001",
    task_description="本番環境でエラー発生！調査急務",
    priority=MessagePriority.CRITICAL  # 最高優先度
)

# 既存のZeroMQ送信に統合
import json
json_data = urgent_task.to_json_compatible()
# zmq_send(json.dumps(json_data))
```

---

### シナリオ2: エージェントのパフォーマンスを監視したい

```python
from a2a_system.orchestration.agent_manager import get_agent_manager, AgentType, AgentStatus
import time

manager = get_agent_manager()

# エージェント登録（初回のみ）
manager.register_agent(
    "gpt5_worker_01",
    AgentType.GPT5_WORKER,
    config={"endpoint": "http://localhost:5001"}
)

# タスク実行を記録
manager.update_status("gpt5_worker_01", AgentStatus.BUSY)

start_time = time.time()
# ... タスク実行 ...
response_time = time.time() - start_time

manager.record_message_processed("gpt5_worker_01", response_time)
manager.update_status("gpt5_worker_01", AgentStatus.IDLE)

# パフォーマンス確認
summary = manager.get_agent_summary()
print(f"総メッセージ数: {summary['performance']['total_messages']}")
print(f"平均応答時間: {summary['performance']['avg_response_time']:.2f}秒")
print(f"エラー数: {summary['performance']['total_errors']}")
```

---

### シナリオ3: GROK4の品質チェック結果を記録したい

```python
from quality.quality_helper import QualityHelper, create_code_quality_issue, IssueSeverity

helper = QualityHelper()

# GROK4による品質チェック後...
report = helper.create_report(
    project_path="/home/planj/my-project",
    checked_by="GROK4"
)

# GROK4が見つけた問題を追加
report.add_issue(create_code_quality_issue(
    title="関数が長すぎる",
    description="process_data関数が200行あります",
    file_path="src/processor.py",
    line_number=150,
    severity=IssueSeverity.HIGH,
    suggestion="複数の小さな関数に分割してください"
))

report.add_issue(create_code_quality_issue(
    title="未使用のimport",
    description="mathモジュールがimportされていますが使用されていません",
    file_path="src/utils.py",
    line_number=1,
    severity=IssueSeverity.LOW,
    suggestion="未使用のimportを削除してください"
))

# レポート保存
helper.save_report(report)

print(f"品質スコア: {report.overall_score:.2f}")
print(f"クリティカルな問題: {len(report.get_critical_issues())}件")
```

---

### シナリオ4: メッセージに有効期限を設定したい

```python
from a2a_system.shared.message_protocol import create_question_message, MessagePriority

# 1分以内に回答が必要な質問
time_sensitive_question = create_question_message(
    sender="claude_code",
    target="gpt5_001",
    question="本番デプロイ前の最終チェックをお願いします",
    priority=MessagePriority.HIGH,
    ttl_seconds=60  # 60秒後に無効化
)

# メッセージ送信
json_data = time_sensitive_question.to_json_compatible()

# 受信側では期限切れチェック
from a2a_system.shared.message_protocol import EnhancedMessage

received_msg = EnhancedMessage.from_json(json_data)
if received_msg.is_expired():
    print("⚠️ このメッセージは期限切れです")
else:
    print("✓ メッセージは有効です")
```

---

### シナリオ5: メッセージの整合性を検証したい

```python
from a2a_system.shared.message_protocol import EnhancedMessage, MessageValidator

# メッセージ受信後...
received_data = {
    "type": "ANSWER",
    "sender": "gpt5_001",
    "target": "claude_code",
    "timestamp": "2025-10-07T10:00:00",
    "answer": "実装が完了しました",
    "_metadata": {
        "checksum": "abc123...",
        "priority": 2
    }
}

msg = EnhancedMessage.from_json(received_data)

# 自動検証
is_valid, error_message = MessageValidator.validate_message(msg)

if is_valid:
    print("✓ メッセージは正常です")
    # 処理を続行...
else:
    print(f"✗ メッセージエラー: {error_message}")
    # エラー処理...
```

---

## 📊 品質レポートの確認

### レポートを読み込む

```python
from quality.quality_helper import QualityHelper

helper = QualityHelper()

# 最新のレポートを取得
recent_reports = helper.get_recent_reports(limit=5)

for report in recent_reports:
    print(f"レポートID: {report.id}")
    print(f"スコア: {report.overall_score:.2f}")
    print(f"問題数: {len(report.issues)}")
    print(f"チェック日時: {report.checked_at}")
    print("---")
```

### トレンド分析

```python
# 過去7日間の品質トレンドを取得
trend = helper.get_quality_trend(days=7)

print("日付別品質スコア:")
for date, score in zip(trend['dates'], trend['scores']):
    print(f"  {date}: {score:.2f}")
```

---

## 🔍 エージェント状態の確認

### 全エージェントのサマリー

```python
from a2a_system.orchestration.agent_manager import get_agent_manager

manager = get_agent_manager()

summary = manager.get_agent_summary()

print(f"登録エージェント数: {summary['total_agents']}")
print(f"\n状態別:")
for status, count in summary['by_status'].items():
    if count > 0:
        print(f"  {status}: {count}")

print(f"\nタイプ別:")
for agent_type, count in summary['by_type'].items():
    if count > 0:
        print(f"  {agent_type}: {count}")
```

### 特定エージェントの詳細

```python
agent_info = manager.get_agent_info("gpt5_001")

if agent_info:
    print(f"エージェントID: {agent_info.id}")
    print(f"タイプ: {agent_info.agent_type.value}")
    print(f"状態: {agent_info.status.value}")
    print(f"処理メッセージ数: {agent_info.metrics.total_messages_processed}")
    print(f"平均応答時間: {agent_info.metrics.avg_response_time_sec:.2f}秒")
    print(f"エラー数: {agent_info.metrics.total_errors}")
    print(f"最終アクティビティ: {agent_info.metrics.last_activity}")
```

---

## 🎯 ベストプラクティス

### 1. メッセージ優先度の使い分け

- **CRITICAL**: 本番障害、緊急バグ修正
- **HIGH**: 重要な機能実装、レビュー依頼
- **MEDIUM**: 通常のタスク（デフォルト）
- **LOW**: ドキュメント更新、リファクタリング
- **BACKGROUND**: ログ収集、統計処理

### 2. TTLの設定目安

- 即座の応答が必要: `ttl_seconds=30`（30秒）
- 数分以内: `ttl_seconds=300`（5分）
- 当日中: `ttl_seconds=86400`（24時間）
- 期限なし: `ttl_seconds=None`（デフォルト）

### 3. エージェント状態の更新タイミング

```python
# タスク開始時
manager.update_status(agent_id, AgentStatus.BUSY)

try:
    # タスク実行
    result = execute_task()

    # 成功時
    manager.record_message_processed(agent_id, response_time)
    manager.update_status(agent_id, AgentStatus.IDLE)

except Exception as e:
    # エラー時
    manager.record_error(agent_id)
    # 状態は自動的にERRORに設定される
```

### 4. 品質レポートの活用

```python
# 定期的に品質チェックを実行
report = helper.create_report(project_path, checked_by="GROK4")

# クリティカルな問題は即座に対処
critical_issues = report.get_critical_issues()
if critical_issues:
    for issue in critical_issues:
        print(f"🚨 {issue.title} ({issue.file_path}:{issue.line_number})")

# スコアが閾値を下回ったら警告
if report.overall_score < 0.7:
    print("⚠️ 品質スコアが低下しています。改善が必要です。")
```

---

## 📂 ファイルの場所

### ソースコード
- メッセージプロトコル: `a2a_system/shared/message_protocol.py`
- エージェント管理: `a2a_system/orchestration/agent_manager.py`
- 品質ヘルパー: `quality/quality_helper.py`

### 生成ファイル
- エージェント状態: `a2a_system/shared/agent_state.json`
- 品質レポート: `quality/reports/qr_*.json`

### ドキュメント
- 統合例: `a2a_system/examples/enhanced_integration_example.py`
- 詳細サマリー: `A2A_ENHANCEMENT_SUMMARY.md`
- このガイド: `A2A_QUICK_START.md`

---

## 🆘 トラブルシューティング

### ImportError: No module named 'a2a_system'

```python
# スクリプトの先頭に追加
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))
```

### エージェント状態が保存されない

```python
# 手動で保存を強制
manager._save_state()
```

### 品質レポートが見つからない

```python
# レポートディレクトリを確認
print(helper.report_dir)  # デフォルト: quality/reports/

# ディレクトリが存在しない場合は自動作成される
helper.report_dir.mkdir(parents=True, exist_ok=True)
```

---

## 📚 さらに詳しく

- **完全なドキュメント**: `A2A_ENHANCEMENT_SUMMARY.md`
- **チーム運営ガイド**: `CLAUDE.md`（A2Aシステム強化機能セクション）
- **統合例の全コード**: `a2a_system/examples/enhanced_integration_example.py`

---

**最終更新**: 2025年10月7日
**バージョン**: 1.0
