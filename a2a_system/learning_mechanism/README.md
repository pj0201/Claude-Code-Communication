# 学習メカニズム - Phase 1 実装ガイド

エージェント向けのパターンベース学習システムです。タスク実行パターンを記録し、類似タスクに対して推奨を提供します。

## 🎯 Phase 1 機能

### 1. パターン記録・永続化 (`pattern_storage.py`)

タスク実行結果を「成功パターン」として記録し、JSON形式で永続化します。

**SuccessPattern クラス**
```python
pattern = SuccessPattern(
    task_name="email_filter",
    task_type="data_processing",
    input_format={"email": "str", "keywords": "list"},
    output_format={"filtered": "list"},
    context={"agent": "worker2", "model": "gpt-5"},
    result="success",  # success/failure/partial_success
    confidence_score=0.95,
    execution_time=1.5,
    metadata={"version": "1.0"}
)
```

**PatternStorage クラス**
```python
storage = PatternStorage("pattern_storage/")
storage.add_pattern(pattern)
patterns = storage.get_all_patterns()
stats = storage.get_statistics()
```

### 2. 類似度計算 (`pattern_matcher.py`)

複数の指標を組み合わせた複合類似度を計算します。

**SimilarityCalculator クラス**
- 文字列類似度（30%）: SequenceMatcher
- 属性類似度（40%）: タスク属性マッチング
- コンテキスト類似度（30%）: 実行環境の一致度

```python
calc = SimilarityCalculator()
score = calc.composite_similarity(pattern_a, pattern_b)
```

**PatternSearcher クラス**
```python
searcher = PatternSearcher(patterns)
similar = searcher.find_similar_patterns(
    query_pattern,
    threshold=0.6,
    top_k=5
)
```

### 3. 統合エンジン (`learning_engine.py`)

パターン記録・検索・推奨を統合したメインインターフェース。

```python
engine = LearningEngine("pattern_storage/")

# タスク実行を記録
pattern = engine.record_task_execution(
    task_name="email_filter",
    task_type="data_processing",
    result="success",
    execution_time=1.5,
    confidence_score=0.95
)

# 類似パターンを検索
similar = engine.search_similar_patterns(
    task_name="email_filtering",
    task_type="data_processing"
)

# 推奨を取得
recommendations = engine.get_recommendations(
    task_name="email_filtering",
    num_recommendations=3
)

# 学習レポート
report = engine.get_learning_report()
```

## 📊 テスト結果

### 実行結果
```
✅ テスト1: パターン作成
✅ テスト2: パターン永続化
✅ テスト3: 類似度計算
✅ テスト4: 学習エンジン統合
✅ テスト5: パターン管理
```

### テスト実行方法
```bash
cd a2a_system/learning_mechanism
python3 test_learning_engine.py
```

## 🔧 使用例

### 基本的な使い方

```python
from learning_mechanism import LearningEngine

# エンジン初期化
engine = LearningEngine()

# 1. タスク実行を記録
engine.record_task_execution(
    task_name="データベースクエリ最適化",
    task_type="optimization",
    result="success",
    execution_time=2.3,
    input_format={"query": "str"},
    output_format={"optimized_query": "str"},
    confidence_score=0.92
)

# 2. 類似パターンを検索
patterns = engine.search_similar_patterns(
    task_name="SQLクエリ最適化",
    task_type="optimization",
    threshold=0.6
)

# 3. 推奨を表示
for pattern, score in patterns:
    print(f"{pattern.task_name}: {score:.2%}")

# 4. 学習状況をレポート
report = engine.get_learning_report()
print(f"成功率: {report['success_rate']}%")
print(f"パターン数: {report['total_patterns']}")
```

### 高度な使い方

```python
# A2Aシステムとの統合
from orchestration.agent_manager import get_agent_manager

manager = get_agent_manager()
agent_stats = manager.get_agent_summary()

# パフォーマンスデータを学習に反映
for agent in agent_stats:
    engine.record_task_execution(
        task_name=f"{agent['agent_id']}_task",
        task_type="agent_execution",
        execution_time=agent['avg_response_time'],
        confidence_score=1.0 - (agent['error_rate'] / 100)
    )
```

## 📈 データ構造

### パターンのJSON形式
```json
{
  "task_id": "email_filter_2025-10-16T12:30:00",
  "task_name": "email_filter",
  "task_type": "data_processing",
  "input_format": {
    "email": "str",
    "keywords": "list"
  },
  "output_format": {
    "filtered": "list"
  },
  "context": {
    "agent": "worker2"
  },
  "result": "success",
  "confidence_score": 0.95,
  "execution_time": 1.5,
  "metadata": {},
  "timestamp": "2025-10-16T12:30:00"
}
```

## 🚀 統計情報

```python
# ストレージの統計
stats = engine.get_learning_report()

# 出力例
{
  "timestamp": "2025-10-16T12:32:41.900752",
  "statistics": {
    "total_patterns": 15,
    "success_count": 13,
    "failure_count": 1,
    "partial_success_count": 1,
    "average_confidence": 0.917,
    "success_rate": 0.867
  },
  "success_rate": 86.7,
  "breakdown": {
    "successful": 13,
    "failed": 1,
    "partial": 1
  }
}
```

## 🔗 A2A統合（Phase 2予定）

- `agent_manager.py` との連携
- `conversation_memory.py` からのパターン抽出
- `claude_bridge.py` でのメッセージ共有

## 📝 API リファレンス

### LearningEngine

#### record_task_execution()
```python
pattern = engine.record_task_execution(
    task_name: str,
    task_type: str = "general",
    result: str = "success",
    execution_time: float = 0.0,
    input_format: Optional[Dict] = None,
    output_format: Optional[Dict] = None,
    context: Optional[Dict] = None,
    metadata: Optional[Dict] = None,
    confidence_score: float = 1.0
) -> SuccessPattern
```

#### search_similar_patterns()
```python
patterns = engine.search_similar_patterns(
    task_name: str,
    task_type: str = "general",
    threshold: float = 0.6,
    top_k: int = 5,
    input_format: Optional[Dict] = None,
    output_format: Optional[Dict] = None,
    context: Optional[Dict] = None
) -> List[Tuple[SuccessPattern, float]]
```

#### get_recommendations()
```python
recommendations = engine.get_recommendations(
    task_name: str,
    task_type: str = "general",
    num_recommendations: int = 3,
    input_format: Optional[Dict] = None,
    output_format: Optional[Dict] = None,
    context: Optional[Dict] = None
) -> List[Dict[str, Any]]
```

#### get_learning_report()
```python
report = engine.get_learning_report() -> Dict[str, Any]
```

## ✅ チェックリスト

- [x] SuccessPattern クラス実装
- [x] PatternStorage 永続化実装
- [x] SimilarityCalculator 複合スコア実装
- [x] PatternSearcher 検索実装
- [x] LearningEngine 統合実装
- [x] 全テスト成功
- [ ] A2Aシステム統合（Phase 2）
- [ ] パフォーマンス最適化（Phase 3）
- [ ] グラフDB対応（Phase 3）

## 📞 サポート

問題が発生した場合：
1. テストを実行: `python3 test_learning_engine.py`
2. ログを確認: `pattern_storage/patterns.json`
3. エラーメッセージを確認

---

**Version**: 0.1.0 (Phase 1)
**Last Updated**: 2025-10-16
