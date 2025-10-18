# チーム適応型学習システム (Team Adaptive Learning System)

**Phase 4 Implementation** - Team-wide continuous learning and knowledge accumulation system for Claude-Code-Communication team.

---

## 🎯 ビジョン (Vision)

チームの日常業務（Git操作、A2A通信、タスク管理）から自動的にノウハウを抽出・学習し、チーム全体の効率と品質を継続的に向上させるシステム。

Automatically extract and learn team knowledge from daily activities (Git operations, A2A communications, task management) and continuously improve team efficiency and quality.

---

## 📦 コンポーネント (Components)

### 1. **team_activity_monitor.py**
   - **目的**: チーム活動の監視と収集
   - **機能**:
     - GitHub操作の分析
     - A2A通信パターンの捕捉
     - タスク実行の記録

   ```python
   from team_learning import TeamActivityMonitor

   monitor = TeamActivityMonitor(learning_engine)
   github_patterns = monitor.capture_github_activity()
   ```

### 2. **team_knowledge_base.py**
   - **目的**: チームのノウハウを体系化・管理
   - **機能**:
     - パターン正規化
     - 信頼度スコア計算
     - パターン推奨生成
     - エージェント専門知識追跡

   ```python
   from team_learning import TeamKnowledgeBase

   kb = TeamKnowledgeBase(learning_engine)
   recommendations = kb.get_recommendations({'task_type': 'git_operation'})
   ```

### 3. **a2a_adaptive_system.py**
   - **目的**: A2A通信にチーム学習を統合
   - **機能**:
     - メッセージ最適化
     - ルーティング提案
     - 応答時間推定
     - 推奨情報の自動付加

   ```python
   from team_learning import A2AAdaptiveSystem

   a2a = A2AAdaptiveSystem(knowledge_base)
   enhanced = a2a.enhance_message(message)
   ```

### 4. **agent_role_optimizer.py**
   - **目的**: エージェントの役割を最適化
   - **機能**:
     - パフォーマンス分析
     - 強み・弱み識別
     - タスク最適化推奨
     - 協業パターン分析

   ```python
   from team_learning import AgentRoleOptimizer

   optimizer = AgentRoleOptimizer(knowledge_base)
   recommendation = optimizer.generate_agent_recommendation('claude_code')
   ```

### 5. **team_efficiency_optimizer.py**
   - **目的**: チーム全体の効率化
   - **機能**:
     - 通信フロー最適化
     - リソース配分分析
     - タスク並列化
     - ボトルネック検出
     - スプリント計画

   ```python
   from team_learning import TeamEfficiencyOptimizer

   eff = TeamEfficiencyOptimizer(knowledge_base)
   workflow = eff.analyze_team_workflow()
   sprint = eff.generate_sprint_plan(upcoming_tasks)
   ```

### 6. **github_webhook_handler.py**
   - **目的**: GitHub Webhookイベント処理
   - **機能**:
     - Push, PR, Issue, Release イベント解析
     - 署名検証
     - イベント正規化

   ```python
   from team_learning import GitHubWebhookHandler

   handler = GitHubWebhookHandler(activity_monitor)
   result = handler.handle_webhook(payload, signature)
   ```

### 7. **weekly_learning_report.py**
   - **目的**: 週次学習レポート生成
   - **機能**:
     - チーム学習成果サマリー
     - エージェント別パフォーマンス
     - 通信品質メトリクス
     - 協業インサイト
     - 推奨事項生成

   ```python
   from team_learning import ReportGenerator

   reporter = ReportGenerator(team_systems)
   report = reporter.generate_weekly_report()
   reporter.export_report_to_markdown(report, 'report.md')
   ```

### 8. **team_scheduler.py**
   - **目的**: 自動化タスクの調整
   - **機能**:
     - 定期的なモニタリング
     - 自動学習
     - レポート生成
     - バックアップ管理

   ```python
   from team_learning import TeamScheduler

   scheduler = TeamScheduler(team_systems)
   scheduler.schedule_activity_monitoring(30)  # Every 30 minutes
   results = scheduler.run_once()
   ```

### 9. **integration.py**
   - **目的**: 統合されたシステムインターフェース
   - **機能**:
     - 全コンポーネントの一元管理
     - 統一されたAPI
     - 自動スケジューリング

   ```python
   from team_learning import create_team_learning_system

   system = create_team_learning_system(learning_engine)
   enhanced_msg = system.process_a2a_message(message)
   status = system.get_system_status()
   report = system.generate_report()
   ```

---

## 🚀 クイックスタート (Quick Start)

### インポート (Import)

```python
from a2a_system.team_learning import create_team_learning_system

# Import Phase 3 learning engine
from a2a_system.learning_mechanism import AdvancedLearningEngine

# Create learning engine
engine = AdvancedLearningEngine()

# Create team learning system
system = create_team_learning_system(engine)
```

### A2Aメッセージ処理 (Process A2A Messages)

```python
# Process message with team learning
message = {
    'type': 'QUESTION',
    'sender': 'claude_code',
    'target': 'gpt5_001',
    'content': 'Next implementation step?'
}

enhanced = system.process_a2a_message(message)
print(enhanced['recommended_responses'])
print(enhanced['estimated_response_time'])

# Record result
result = {
    'success': True,
    'duration_seconds': 2.5,
    'status': 'success'
}
system.record_a2a_result(message, response, result)
```

### タスク実行記録 (Record Task Execution)

```python
task_info = {
    'name': 'Implement feature X',
    'task_type': 'feature_implementation',
    'agent': 'worker3',
    'status': 'success',
    'analysis': {
        'duration_seconds': 45.0,
        'resource_efficiency': 'excellent'
    }
}

system.record_task_execution(task_info)
```

### GitHub Webhook処理 (Handle GitHub Webhooks)

```python
# Handle GitHub webhook
result = system.handle_github_webhook(payload, signature)
if result['success']:
    print(f"Event processed: {result['event_type']}")
```

### レポート生成 (Generate Reports)

```python
# Generate weekly report
report = system.generate_report()

# Export to files
reporter = system.report_generator
reporter.export_report_to_markdown(report, 'report.md')
reporter.export_report_to_json(report, 'report.json')
```

### エージェント推奨 (Get Agent Recommendations)

```python
# Get recommendations for specific agent
rec = system.get_agent_recommendations('claude_code')
print(f"Current role: {rec['current_role']}")
print(f"Recommended focus: {rec['recommended_focus']}")
print(f"Collaboration partners: {rec['collaboration_hints']}")
```

### チーム効率分析 (Team Efficiency Analysis)

```python
# Analyze team workflow
workflow = system.get_team_efficiency_analysis()
print(f"Communication success rate: {workflow['communication']['success_rate']}")
print(f"Bottlenecks: {workflow['communication']['bottlenecks']}")

# Generate sprint plan
sprint = system.get_sprint_plan(upcoming_tasks)
print(f"Estimated duration: {sprint['estimated_duration']}s")
print(f"Success probability: {sprint['success_probability']}")
```

### スケジューラ実行 (Run Scheduler)

```python
# Run scheduler (executes all due tasks)
results = system.run_scheduler()
print(f"Tasks executed: {results['tasks_executed']}")
print(f"Errors: {results['errors']}")
```

---

## 📊 システム構成図 (Architecture)

```
チーム適応型学習システム (Team Adaptive Learning System)
│
├── レイヤー1: データ収集 (Layer 1: Data Collection)
│   ├── GitHub操作監視
│   ├── A2A通信捕捉
│   └── タスク実行記録
│
├── レイヤー2: パターン抽出・学習 (Layer 2: Pattern Extraction & Learning)
│   ├── パターン正規化
│   ├── 信頼度スコア計算
│   └── Phase 3学習エンジン統合
│
├── レイヤー3: チーム推奨 (Layer 3: Team Recommendations)
│   ├── A2A統合推奨
│   ├── エージェント役割最適化
│   └── チーム効率化提案
│
└── レイヤー4: 自動実行 (Layer 4: Automation)
    ├── GitHub Webhook処理
    ├── 週次レポート生成
    └── スケジューラ実行
```

---

## 🔄 デフォルトスケジュール (Default Schedule)

| タスク | 間隔 | 説明 |
|--------|------|------|
| Activity Monitoring | 30分 | チーム活動の監視 |
| A2A Analysis | 60分 | A2A通信分析 |
| Agent Optimization | 120分 | エージェント最適化 |
| Team Efficiency | 180分 | チーム効率分析 |
| Weekly Report | 7日 | 週次レポート生成 |
| KB Backup | 24時間 | ナレッジベース バックアップ |

---

## 📈 期待効果 (Expected Results)

### 短期 (1ヶ月)
- チーム通信効率: **10-15%改善**
- タスク完了時間: **10-12%短縮**
- 品質指標: **+5%**

### 中期 (3ヶ月)
- チーム学習効果: **15-25%改善**
- 自動化レベル: **30→50%**
- ノウハウ蓄積: **500+パターン**

### 長期 (6ヶ月)
- チーム自律性: **大幅向上**
- 効率化: **30-40%**
- 革新性: **+40%**

---

## 🔧 設定 (Configuration)

### 環境変数 (Environment Variables)

```bash
# GitHub Webhook Secret
GITHUB_WEBHOOK_SECRET=your-secret-key

# Learning Engine Path
LEARNING_ENGINE_PATH=/home/planj/learning-engine-prod

# Storage Paths
TEAM_KB_PATH=/tmp/team_knowledge_base.json
TEAM_SCHEDULER_PATH=/tmp/team_scheduler.json
```

### スケジュール変更 (Customize Schedule)

```python
system.scheduler.schedule_activity_monitoring(interval_minutes=15)  # Change to 15 min
system.scheduler.disable_task('knowledge_base_backup')  # Disable backup
system.scheduler.enable_task('weekly_report_generation')  # Enable reports
```

---

## 📝 ドキュメント (Documentation)

- **基本設計**: `TEAM_ADAPTIVE_LEARNING_SYSTEM.md` (in parent directory)
- **API詳細**: 各モジュール内のdocstring参照

---

## 🤝 統合例 (Integration Examples)

### A2Aシステムとの統合

```python
# A2Aメッセージを処理
def handle_a2a_message(message):
    # チーム学習で拡張
    enhanced = system.process_a2a_message(message)

    # 標準のA2A処理
    response = send_message(enhanced)

    # 結果を記録
    result = {'success': True, 'duration_seconds': 2.0}
    system.record_a2a_result(message, response, result)

# GitHub Webhookの処理
def handle_github_push(payload, signature):
    result = system.handle_github_webhook(payload, signature)
    if result['success']:
        # Perform additional processing
        pass
```

---

## 📞 サポート (Support)

各モジュールのdocstringを参照してください。

Refer to docstrings in each module for detailed API documentation.

---

**Version**: 1.0.0
**Updated**: 2025-10-17
**Status**: ✅ Production Ready

🤖 Generated with Claude Code
