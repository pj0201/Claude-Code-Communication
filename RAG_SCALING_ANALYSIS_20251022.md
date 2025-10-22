# RAG + Advanced Generator スケーリング分析

## 📊 RAG ソース規模の分析

### ソースサイズ
- OCR補正テキスト: 877KB (1321行)
- 風営法MD: 22KB (614行)
- **合計: 899KB**

### チャンク数の計算

#### TextChunker パラメータ
```
- チャンクサイズ: 800文字
- オーバーラップ: 100文字
- 実効チャンク長: 700文字
```

#### 推定チャンク数
```
OCR: 877,000 bytes ÷ 700 effective chars = ~1,253 chunks
Wind Eikyo: 22,000 bytes ÷ 700 effective chars = ~31 chunks
合計: ~1,284 チャンク
```

---

## 🎯 1491問スケーリング要件

### 現在の RAG Bulk Generator（250-300問）
```javascript
// 各カテゴリ設定
{
  targetCount: 30-40,     // 30-40問/カテゴリ
  contexts_per_category: ceil(40/3) = 14,
  problems_per_context: 3-4
}
```

### スケール後の要件（1491問）
```
1491問 ÷ 7カテゴリ = 213問/カテゴリ
```

#### カテゴリごと問題数
- 営業許可・申請手続き: 213問
- 営業時間・営業場所: 213問
- 遊技機規制: 213問
- 従業者の要件・禁止事項: 213問
- 顧客保護・規制遵守: 213問
- 法令違反と行政処分: 160問（約213問）
- 実務的対応: 160問（約213問）
- **合計: 1491問**

#### 必要なコンテキスト数
```
213問/カテゴリ ÷ 3問/コンテキスト = 71コンテキスト/カテゴリ
71 × 7カテゴリ = 497コンテキスト必要
```

---

## ✅ 結論: RAG は十分です

### チャンク数 vs 必要コンテキスト数
```
利用可能: ~1,284チャンク
必要: 497コンテキスト
余裕: 2.6倍以上
```

**つまり、「法律が足りない」わけではありません。**

利用可能なRAGソースで1491問スケーリングは技術的に可能です。

---

## ⚠️ 実際のボトルネック

RAGコンテンツではなく、以下が懸念事項です：

### 1. **LLM API レート制限**
```
現在: 1コンテキストあたり 4問 × 497コンテキスト = 1,988 LLM呼び出し
- 問題生成: 1呼び出し/問
- 各呼び出し遅延: 800ms
- 合計時間: 1,988 × 0.8s = 26分
```

### 2. **システム安定性**
```
26分間の連続LLM呼び出し中に:
- メモリリーク防止
- エラーリカバリー
- 進捗保存
が必要
```

### 3. **処理タイムアウト**
```
各ステップのタイムアウト:
- 問題生成: 10-15秒/問
- 法律分析: 5秒/問
- バリデーション: 3秒/問
合計: 18-23秒/問
```

---

## 📈 スケーリング実装案

### 案A: RAG Bulk Generator を拡張（推奨）
```javascript
// 既存コードで targetCount を変更するだけ
categories.forEach(cat => {
  cat.targetCount = 213;  // 30-40 → 213
});
```

**メリット:**
- 最小限の変更
- Advanced Generator の 6段階パイプライン活用
- 法律ロジック分析を活用

**懸念:**
- 26分間の連続実行での安定性
- LLM API の費用増加

### 案B: 分割生成（バッチ処理）
```javascript
// カテゴリ別・または日別に分割生成
const batchSize = 10;  // 10問ごと
for (let i = 0; i < totalProblems; i += batchSize) {
  await generateBatch(i, i + batchSize);
  await saveCheckpoint();
  await delay(2000);  // バッチ間の遅延
}
```

**メリット:**
- システム安定性が高い
- エラーリカバリーが容易
- リソース使用量が平準化

**懸念:**
- 実行時間が伸びる (3-4時間)

### 案C: 並列生成（高リスク）
```javascript
// 複数カテゴリを同時実行
const categoryPromises = categories.map(cat =>
  generateCategoryProblems(cat)
);
await Promise.all(categoryPromises);
```

**メリット:**
- 最短時間で完了

**懸念:**
- 「システムが落ちるようなことはあってはならない」に違反
- LLM API の同時呼び出し数制限

---

## 🔧 推奨実装手順

### ステップ1: 拡張版 RAG Bulk Generator 作成
```javascript
class ScaledRAGBulkGenerator extends RAGBulkProblemGenerator {
  constructor(rag, llmProvider, targetTotal = 1491) {
    super(rag, llmProvider);

    // targetCount を自動計算
    const perCategory = Math.ceil(targetTotal / this.categories.length);
    this.categories.forEach(cat => {
      cat.targetCount = perCategory;
    });
  }
}
```

### ステップ2: チェックポイント・リカバリー実装
```javascript
async generateWithCheckpoint() {
  const checkpoint = this.loadCheckpoint();

  for (const category of this.categories) {
    if (checkpoint.completed.includes(category.id)) continue;

    const problems = await this.generateCategoryProblems(category);
    this.allProblems.push(...problems);
    this.saveCheckpoint({ completed: [...checkpoint.completed, category.id] });
  }
}
```

### ステップ3: レート制限・遅延の実装
```javascript
async executeWithRateLimit(fn, delayMs = 800) {
  const result = await fn();
  await this.delay(delayMs);
  return result;
}
```

---

## ❓ ユーザーへの確認質問

【質問1】 スケーリングアプローチについて
- **案A（単純拡張）**: 26分連続実行、シンプル
- **案B（バッチ分割）**: 3-4時間、安定性重視
- **案C（並列実行）**: リスク高い

どのアプローチを採用しますか？

【質問2】 品質レビュー体制について
- 1491問すべてのレビューは現実的ですか？
- サンプル（カテゴリごと5-10問）レビューで十分ですか？

【質問3】 システム動作環境について
- 26分以上の連続実行でシステムは安定していますか？
- メモリ制限や API 制限はありますか？

---

## 📋 技術的結論

| 項目 | 評価 |
|------|------|
| **RAG コンテンツ量** | ✅ 十分 (1284 chunks > 497 contexts) |
| **Advanced Generator** | ✅ 適用可能 |
| **スケーリング技術的可能性** | ✅ 実現可能 |
| **システム安定性懸念** | ⚠️ 要確認（26分連続実行） |
| **推奨度** | ✅ 案B（バッチ分割） |

