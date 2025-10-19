# 統合学習・スキルシステム設計

**Design**: Unified Learning-Skill Integration Architecture
**Status**: Phase 2 Implementation Planning
**Related**: SKILL_AUTONOMY_PHILOSOPHY.md

---

## 🎯 目標

既存の `AdvancedLearningEngine` と新しいスキルシステムを統合し、スキルごとの自律的な専門化学習を実現。

---

## 📊 現在の構成

### 現状（統合前）

```
【独立システム】
AdvancedLearningEngine
  └─ /a2a_system/shared/learned_patterns/
     ├── pattern_code_review_001.json
     ├── pattern_api_search_002.json
     └── ... （スキルが混在）

LearningSkillIntegration（新規・未統合）
  └─ /tmp/skill_learning.json
     ├── task_history
     ├── skill_success_rates
     └── ... （独立）
```

### 目標状態（統合後）

```
【統合システム】
AdvancedLearningEngine（メインエンジン）
  └─ /a2a_system/shared/learned_patterns/
     ├── code_analysis/
     │   ├── pattern_python_review_001.json
     │   ├── pattern_js_refactoring_002.json
     │   ├── stats_code_analysis.json
     │   └── skill_confidence.json
     ├── query_processing/
     │   ├── pattern_api_search_001.json
     │   ├── pattern_doc_research_002.json
     │   ├── stats_query_processing.json
     │   └── skill_confidence.json
     ├── file_operations/
     ├── browser_automation/
     ├── performance_analysis/
     └── crossskill_patterns/  ← 転移学習
```

---

## 🔗 統合設計

### 1. AdvancedLearningEngine の拡張

```python
class AdvancedLearningEngine:
    """
    既存のPhase 1-3学習エンジン
    + スキル別カテゴライズ機能
    """

    def record_task_with_skill(
        self,
        task_name: str,
        task_type: str,
        skill_type: str,  # ← 新規：code_analysis等
        result: str,
        execution_time: float,
        quality_score: float,
        confidence_score: float,
    ) -> str:
        """
        タスクをスキル別に記録
        保存: /learned_patterns/{skill_type}/pattern_*.json
        """

    def get_skill_patterns(
        self,
        skill_type: str,
        task_type: str = None,
    ) -> List[SuccessPattern]:
        """
        スキル別の学習パターンを取得
        """

    def get_skill_confidence(
        self,
        skill_type: str,
    ) -> Dict[str, Any]:
        """
        スキルの信頼度・統計情報を取得
        """

    def update_skill_confidence(
        self,
        skill_type: str,
        new_confidence: float,
    ) -> None:
        """
        スキル信頼度を更新（自動計算）
        """
```

### 2. LearningSkillIntegration の新しい役割

**削除**: 独立した学習DBは不要

**新しい役割**: AdvancedLearningEngine のファサード + スキル特化機能

```python
class LearningSkillIntegration:
    """
    AdvancedLearningEngine をラップして、
    スキル別の学習・最適化を提供
    """

    def __init__(self):
        self.engine = AdvancedLearningEngine(
            storage_dir="/a2a_system/shared/learned_patterns"
        )

    def record_skill_task(
        self,
        skill_type: str,
        task_result: TaskResult,
    ) -> None:
        """
        スキル別にタスク結果を記録
        """
        self.engine.record_task_with_skill(
            task_name=task_result.task_type,
            skill_type=skill_type,
            ...
        )

    def get_skill_recommendations(
        self,
        task_type: str,
        skill_type: str,
    ) -> List[SuccessPattern]:
        """
        スキルの専門領域から推奨パターンを取得
        """
        patterns = self.engine.get_skill_patterns(skill_type, task_type)
        return self.engine.advanced_search(
            task_name=task_type,
            patterns=patterns,
            use_semantic=True,
            use_ml_scoring=True,
        )
```

### 3. Skill Registry との連携

```python
# Skill Selector で
selected_skills = skill_selector.select_skills(classification)

# → LearningSkillIntegration で
for skill_name in selected_skills:
    recommendations = learning_integration.get_skill_recommendations(
        task_type=classification.task_type,
        skill_type=skill_name,
    )
    # 推奨パターンをプロンプトに注入
```

### 4. 学習データの流れ

```
タスク受信
    ↓
[TaskClassifier]
  ├─ task_type: "code_review"
  └─ file_type: ".py"
    ↓
[SkillSelector]
  ├─ primary: ["code_analysis"]
  └─ confidence: 0.92
    ↓
[LearningSkillIntegration]
  ├─ Get patterns for code_analysis/code_review
  └─ Inject into prompt
    ↓
[Execution]
  ├─ Python code review performed
  └─ Result: success, quality: 0.95
    ↓
[Learning Recording]
  └─ AdvancedLearningEngine.record_task_with_skill(
       skill_type="code_analysis",
       task_type="code_review",
       quality_score=0.95,
     )
    ↓
[Skill Confidence Update]
  └─ code_analysis skill confidence: 0.92 → 0.94
    ↓
[Next execution]
  └─ code_analysis パターンが増加 → より高精度
```

---

## 📁 ストレージ構造（最終形態）

```
/a2a_system/shared/learned_patterns/
├── code_analysis/
│   ├── patterns/
│   │   ├── pattern_python_code_review_20251020_001.json
│   │   ├── pattern_python_code_review_20251020_002.json
│   │   ├── pattern_js_refactoring_20251020_001.json
│   │   ├── pattern_go_debugging_20251020_001.json
│   │   └── ...
│   ├── meta/
│   │   ├── skill_confidence.json         # {"confidence": 0.94, "updated": "2025-10-20"}
│   │   ├── skill_statistics.json         # {"total_runs": 45, "success_rate": 0.94}
│   │   └── specializations.json          # {"python": 0.98, "js": 0.91, "go": 0.78}
│   └── index/
│       └── semantic_index.db             # パターンのセマンティックインデックス
├── query_processing/
│   ├── patterns/
│   ├── meta/
│   └── index/
├── file_operations/
├── browser_automation/
├── performance_analysis/
└── crossskill_patterns/                  # 転移学習用
    ├── python_to_go_refactoring.json
    └── ...
```

---

## 🧠 スキル信頼度の計算式

### 基本式（既存と同じ）
```
new_confidence = (success_factor × quality_score × time_factor) × 0.3
               + current_confidence × 0.7
```

### スキル特化ボーナス（新規）
```
specialization_bonus = 1.0 + (domain_match_count × 0.02)

domain_match_count = "同じタスク型で成功したパターン数"

例:
  - 5個のコード解析パターン = 1.10倍
  - 10個のコード解析パターン = 1.20倍
  - 25個のコード解析パターン = 1.50倍（上限）

最終式:
new_confidence = (base_calculation) × specialization_bonus
```

---

## ✅ 実装チェックリスト

### Phase 2-1: AdvancedLearningEngine 拡張
- [ ] `record_task_with_skill()` メソッド追加
- [ ] `get_skill_patterns()` メソッド追加
- [ ] `get_skill_confidence()` メソッド追加
- [ ] スキル別ディレクトリ構造の実装
- [ ] 既存パターンのマイグレーション

### Phase 2-2: LearningSkillIntegration 統合
- [ ] AdvancedLearningEngine をベースに変更
- [ ] `/tmp/skill_learning.json` から `/learned_patterns/` に移行
- [ ] TaskResult をスキル別に記録する機能
- [ ] Skill Selector との連携テスト

### Phase 2-3: Skill Registry 連携
- [ ] SkillSelector から LearningSkillIntegration へ呼び出し
- [ ] 推奨パターンのプロンプト注入
- [ ] エンドツーエンドテスト

### Phase 2-4: ドキュメント・テスト
- [ ] スキル別学習の効果測定
- [ ] 統合テストの実施
- [ ] ドキュメント更新

---

## 🎯 成功基準

- [ ] スキル別に学習パターンが蓄積
- [ ] スキル信頼度が継続的に向上（週±0.05以上）
- [ ] 同一タスク 3回実行時に 95% 以上の一貫性
- [ ] 未知タスクに対する初期成功率が 80% 以上
- [ ] スキル間の転移学習が機能

---

## 📝 実装方針

**重要**: 理念を先に理解してから実装開始

1. **理念の確認** ✅ SKILL_AUTONOMY_PHILOSOPHY.md
2. **ドキュメント化** ✅ このドキュメント
3. **AdvancedLearningEngine 拡張** → 次
4. **LearningSkillIntegration 統合** → その次
5. **エンドツーエンドテスト** → 最後

---

**Next Step**: AdvancedLearningEngine への `record_task_with_skill()` メソッド実装

🧠 **Philosophy Foundation**: Each skill becomes an autonomous expert through continuous learning
