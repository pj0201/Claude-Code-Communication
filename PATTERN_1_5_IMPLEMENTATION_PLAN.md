# Pattern 1.5 実装計画書
**実用的ハイブリッド - 段階的アプローチ**

**決定日**: 2025-10-20
**判断根拠**: 初期段階での過度な実装は危険 + AI進化速度を考慮した柔軟性確保
**目標期間**: 5-8日
**ステータス**: 実装準備完了

---

## 📊 Pattern 1.5 概要

### アーキテクチャ
```
3層構成（段階的に強化可能）:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
層1: 実行時（リアルタイム処理）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ├ /tmp/skill_learning.json
  └ メモリキャッシュ（高速アクセス）

↓ 自動バックアップ（毎時間 or 重要イベント後）

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
層2: 永続化保護（バックアップ）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ├ /a2a_system/shared/learned_patterns/
  │  └ backup_YYYYMMDD_HHMMSS.json
  └ 日次世代管理（最新10世代保持）

↓ 月次集計処理

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
層3: ドキュメント永続化（WIKI）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  └ GitHub WIKI
     └ SkillLearningMonthly/2025-10.md
        ├ スキル別統計
        ├ 上位学習パターン
        └ 改善提案
```

### 評価指標
| 項目 | 目標 | 実装難度 |
|------|------|--------|
| 堅牢性 | 8/10（十分実用的） | ✅ |
| 保守性 | 7/10（将来の拡張容易） | ✅ |
| パフォーマンス | 7/10（リアルタイム処理） | ✅ |
| 実装期間 | 5-8日 | ✅ |
| リスク | 最小限 | ✅ |

---

## 🎯 実装フェーズ

### Phase 1: 基礎実装（2-3日）

#### Task 1.1: JSONベース永続化モジュール設計
**ファイル**: `a2a_system/skills/learning_persistence.py`

```python
# 主要クラス構成
class LearningPersistenceManager:
    """学習データの永続化を管理"""

    def __init__(self, tmp_path="/tmp/skill_learning.json",
                 backup_path="/a2a_system/shared/learned_patterns/"):
        self.tmp_path = tmp_path
        self.backup_path = backup_path

    def load_learning_data(self) -> dict:
        """現在の学習データをロード（メモリ）"""
        pass

    def save_learning_data(self, data: dict) -> bool:
        """学習データを保存（両層に）"""
        # 層1: /tmp に即座に保存
        # 層2: バックアップディレクトリにも保存
        pass

    def create_backup(self) -> str:
        """現在の学習データをバックアップ作成"""
        # タイムスタンプ付きバックアップ
        pass

    def cleanup_old_backups(self, keep_count=10) -> int:
        """古いバックアップを削除（世代管理）"""
        pass

    def get_backup_summary(self) -> dict:
        """バックアップの統計情報"""
        pass
```

**実装チェックリスト**:
- [ ] クラス定義と基本メソッド
- [ ] JSONシリアライズ/デシリアライズ
- [ ] エラーハンドリング（ディスク容量、パーミッション等）
- [ ] ユニットテスト（各メソッド）

---

#### Task 1.2: SkillSelector への統合
**ファイル**: `a2a_system/skills/skill_selector.py` (修正)

```python
# 既存の _score_skills() メソッドの後に追加

def _persist_learning_outcome(self, selected_skill: SkillType,
                              task_classification, execution_result):
    """スキル選択と実行結果を永続化"""

    learning_record = {
        "timestamp": datetime.now().isoformat(),
        "skill_type": selected_skill.value,
        "task_type": task_classification.task_type,
        "file_type": task_classification.file_type,
        "confidence": task_classification.confidence,
        "execution_result": execution_result,
        "success": execution_result.get("success", False),
        "processing_time": execution_result.get("processing_time", 0)
    }

    # LearningPersistenceManager を使用
    self.persistence_manager.append_record(learning_record)

    # 定期的なバックアップトリガー
    if self._should_trigger_backup():
        self.persistence_manager.create_backup()
```

**実装チェックリスト**:
- [ ] LearningPersistenceManager のインスタンス化
- [ ] _persist_learning_outcome() メソッド追加
- [ ] execute() メソッド内での呼び出し
- [ ] インテグレーションテスト

---

#### Task 1.3: 永続化ストレージの初期化
**実装内容**: ディレクトリ構成とアクセス権管理

```bash
# 必要なディレクトリ作成
mkdir -p /a2a_system/shared/learned_patterns/

# アクセス権設定
chmod 755 /a2a_system/shared/learned_patterns/

# 初期化ファイル
echo '{"backups": [], "created_at": "'$(date -I)'"}' \
  > /a2a_system/shared/learned_patterns/.index
```

**チェックリスト**:
- [ ] ディレクトリ作成と権限設定
- [ ] 初期インデックスファイル生成
- [ ] ディスク容量確認（警告設定）

---

### Phase 2: バックアップ保護メカニズム（2-3日）

#### Task 2.1: 自動バックアップシステム
**ファイル**: `a2a_system/skills/backup_scheduler.py` (新規)

```python
import schedule
import threading
from learning_persistence import LearningPersistenceManager

class BackupScheduler:
    """自動バックアップスケジューリング"""

    def __init__(self, manager: LearningPersistenceManager):
        self.manager = manager
        self.scheduler = schedule.Scheduler()
        self._setup_schedules()

    def _setup_schedules(self):
        """バックアップスケジュール設定"""
        # 毎時0分にバックアップ
        self.scheduler.every().hour.at(":00").do(self._hourly_backup)

        # 毎日深夜2時にフル統計バックアップ
        self.scheduler.every().day.at("02:00").do(self._daily_full_backup)

        # 古いバックアップを毎週削除
        self.scheduler.every().monday.at("03:00").do(self._cleanup_old_backups)

    def _hourly_backup(self):
        """時間ごとのバックアップ"""
        backup_path = self.manager.create_backup()
        logging.info(f"✅ Hourly backup created: {backup_path}")

    def _daily_full_backup(self):
        """日次フルバックアップ"""
        backup_path = self.manager.create_backup()
        logging.info(f"✅ Daily full backup created: {backup_path}")

    def _cleanup_old_backups(self):
        """古いバックアップ削除"""
        removed = self.manager.cleanup_old_backups(keep_count=10)
        logging.info(f"🧹 Cleaned up {removed} old backups")

    def start(self):
        """バックアップスケジューラ開始"""
        def _run_scheduler():
            while True:
                self.scheduler.run_pending()
                time.sleep(60)

        thread = threading.Thread(target=_run_scheduler, daemon=True)
        thread.start()
        logging.info("🚀 Backup scheduler started")
```

**実装チェックリスト**:
- [ ] schedule ライブラリ統合
- [ ] スケジュール設定（毎時、毎日、毎週）
- [ ] ログ出力
- [ ] テスト（時間トリガー）

---

#### Task 2.2: バックアップから復旧するメカニズム
**ファイル**: `a2a_system/skills/learning_persistence.py` (拡張)

```python
def restore_from_backup(self, backup_file: str) -> bool:
    """指定されたバックアップから復旧"""
    try:
        with open(backup_file, 'r') as f:
            data = json.load(f)

        # /tmp に復旧
        self.save_learning_data(data)
        logging.info(f"✅ Restored from backup: {backup_file}")
        return True
    except Exception as e:
        logging.error(f"❌ Restore failed: {e}")
        return False

def list_available_backups(self) -> list:
    """利用可能なバックアップ一覧"""
    backups = sorted(glob.glob(f"{self.backup_path}/backup_*.json"))
    return [{"file": b, "timestamp": self._extract_timestamp(b)} for b in backups]

def get_latest_backup(self) -> str:
    """最新のバックアップファイルパスを取得"""
    backups = self.list_available_backups()
    return backups[-1]["file"] if backups else None
```

**実装チェックリスト**:
- [ ] restore_from_backup() 実装
- [ ] list_available_backups() 実装
- [ ] 復旧テスト

---

### Phase 3: ドキュメント永続化＆WIKI連携（2-3日）

#### Task 3.1: 月次サマリー生成スクリプト
**ファイル**: `a2a_system/skills/monthly_summary_generator.py` (新規)

```python
class MonthlySummaryGenerator:
    """学習データの月次サマリー生成"""

    def __init__(self, learning_data_dir: str):
        self.learning_data_dir = learning_data_dir

    def generate_summary(self, year: int, month: int) -> dict:
        """月次のサマリーデータを生成"""
        summary = {
            "period": f"{year}-{month:02d}",
            "skill_statistics": self._calculate_skill_stats(),
            "top_patterns": self._extract_top_patterns(),
            "accuracy_trends": self._analyze_accuracy_trends(),
            "recommendations": self._generate_recommendations()
        }
        return summary

    def _calculate_skill_stats(self) -> dict:
        """スキル別の統計情報"""
        # 各スキルごとの実行回数、成功率、平均処理時間
        pass

    def _extract_top_patterns(self) -> list:
        """最頻出パターン（上位5）"""
        # タスク/ファイルタイプの組み合わせ
        pass

    def _analyze_accuracy_trends(self) -> dict:
        """分類精度のトレンド"""
        # 月初 vs 月末の精度比較
        pass

    def _generate_recommendations(self) -> list:
        """改善提案"""
        # 弱い領域、改善すべき領域
        pass

    def generate_markdown(self, summary: dict) -> str:
        """Markdown形式で出力"""
        md = f"""# スキル学習サマリー {summary['period']}

## 📊 スキル別統計
{self._format_skill_stats(summary['skill_statistics'])}

## 🔝 上位学習パターン
{self._format_patterns(summary['top_patterns'])}

## 📈 精度トレンド
{self._format_trends(summary['accuracy_trends'])}

## 💡 改善提案
{self._format_recommendations(summary['recommendations'])}
"""
        return md
```

**実装チェックリスト**:
- [ ] generate_summary() 実装
- [ ] 統計計算ロジック
- [ ] Markdown生成
- [ ] テスト（サンプルデータ）

---

#### Task 3.2: GitHub WIKI への自動アップロード
**ファイル**: `a2a_system/skills/wiki_uploader.py` (新規)

```python
class WikiUploader:
    """GitHub WIKI への自動アップロード"""

    def __init__(self, repo_path: str, github_token: str = None):
        self.repo_path = repo_path
        self.wiki_path = f"{repo_path}.wiki"
        self.github_token = github_token or os.getenv("GITHUB_TOKEN")

    def upload_monthly_summary(self, year: int, month: int,
                               markdown_content: str) -> bool:
        """月次サマリーをWIKIにアップロード"""

        filename = f"SkillLearning-{year}-{month:02d}.md"
        wiki_file = f"{self.wiki_path}/{filename}"

        try:
            # ファイルに書き込み
            with open(wiki_file, 'w', encoding='utf-8') as f:
                f.write(markdown_content)

            # Git コミット
            self._commit_to_wiki(filename, f"Monthly summary for {year}-{month:02d}")

            logging.info(f"✅ Uploaded to WIKI: {filename}")
            return True
        except Exception as e:
            logging.error(f"❌ WIKI upload failed: {e}")
            return False

    def _commit_to_wiki(self, filename: str, commit_message: str):
        """WIKIリポジトリへのコミット"""
        import subprocess

        cwd = self.wiki_path
        subprocess.run(["git", "add", filename], cwd=cwd)
        subprocess.run(["git", "commit", "-m", commit_message], cwd=cwd)
        subprocess.run(["git", "push"], cwd=cwd)
```

**実装チェックリスト**:
- [ ] WikiUploader クラス実装
- [ ] WIKI ファイル書き込み
- [ ] Git コミット
- [ ] テスト（ドライラン）

---

#### Task 3.3: 月次スケジューラの統合
**ファイル**: `backup_scheduler.py` (拡張)

```python
def _monthly_wiki_update(self):
    """月次WIKI更新"""
    from datetime import datetime, timedelta

    # 先月のデータを集計
    today = datetime.now()
    first_of_month = today.replace(day=1)
    last_month = first_of_month - timedelta(days=1)

    year = last_month.year
    month = last_month.month

    # サマリー生成
    summary_gen = MonthlySummaryGenerator(self.manager.backup_path)
    summary = summary_gen.generate_summary(year, month)
    markdown = summary_gen.generate_markdown(summary)

    # WIKI アップロード
    uploader = WikiUploader(repo_path="/home/planj/Claude-Code-Communication")
    success = uploader.upload_monthly_summary(year, month, markdown)

    if success:
        logging.info(f"✅ Monthly WIKI update completed for {year}-{month:02d}")
    else:
        logging.error(f"❌ Monthly WIKI update failed for {year}-{month:02d}")

# スケジューラに追加
self.scheduler.every().month.do(self._monthly_wiki_update)
```

**チェックリスト**:
- [ ] スケジューラに月次処理を追加
- [ ] 初回実行テスト

---

### Phase 4: 統合テストと本番投入（1-2日）

#### Task 4.1: エンドツーエンドテスト
**ファイル**: `tests/test_pattern_1_5_e2e.py` (新規)

```python
class TestPattern15E2E(unittest.TestCase):
    """Pattern 1.5 統合テスト"""

    def setUp(self):
        """テスト環境初期化"""
        self.tmp_dir = tempfile.mkdtemp()
        self.backup_dir = tempfile.mkdtemp()
        self.manager = LearningPersistenceManager(
            tmp_path=f"{self.tmp_dir}/skill_learning.json",
            backup_path=self.backup_dir
        )

    def test_normal_flow(self):
        """通常フロー: 実行 → 保存 → バックアップ → WIKI"""
        # 1. データ保存
        test_data = {"skill": "code_analysis", "success": True}
        self.manager.save_learning_data(test_data)

        # 2. バックアップ作成
        backup_file = self.manager.create_backup()
        self.assertTrue(os.path.exists(backup_file))

        # 3. 復旧テスト
        self.manager.cleanup_old_backups(keep_count=0)
        restored = self.manager.restore_from_backup(backup_file)
        self.assertTrue(restored)

    def test_recovery_from_tmp_loss(self):
        """/tmp 喪失時の復旧テスト"""
        # 1. データ保存
        test_data = {"skill": "code_analysis"}
        self.manager.save_learning_data(test_data)

        # 2. /tmp を削除（シミュレート）
        os.remove(f"{self.tmp_dir}/skill_learning.json")

        # 3. バックアップから復旧
        backups = self.manager.list_available_backups()
        self.assertGreater(len(backups), 0)
        restored = self.manager.restore_from_backup(backups[0]["file"])
        self.assertTrue(restored)

    def test_backup_cleanup(self):
        """世代管理テスト"""
        # 15個のバックアップ作成
        for i in range(15):
            self.manager.create_backup()

        # 10個まで削除
        removed = self.manager.cleanup_old_backups(keep_count=10)
        self.assertEqual(removed, 5)

        # 確認
        backups = self.manager.list_available_backups()
        self.assertEqual(len(backups), 10)

    def test_monthly_summary_generation(self):
        """月次サマリー生成テスト"""
        summary_gen = MonthlySummaryGenerator(self.backup_dir)
        summary = summary_gen.generate_summary(2025, 10)

        self.assertEqual(summary["period"], "2025-10")
        self.assertIn("skill_statistics", summary)
        self.assertIn("top_patterns", summary)
```

**チェックリスト**:
- [ ] 通常フロー テスト成功
- [ ] 復旧テスト 成功
- [ ] 世代管理テスト 成功
- [ ] サマリー生成テスト 成功

---

#### Task 4.2: パフォーマンステスト
**テスト項目**:
- 保存レイテンシ: < 100ms
- 復旧レイテンシ: < 500ms
- バックアップ作成: < 200ms
- メモリ使用量: < 50MB

---

#### Task 4.3: 本番環境への投入
**手順**:
1. スケジューラ起動確認
2. ログ出力確認
3. 初回バックアップ成功確認
4. SkillSelector との統合テスト
5. 本番稼働開始

---

## 📝 ファイル構成（実装後）

```
a2a_system/skills/
├── learning_persistence.py        ✨ NEW
│   └── LearningPersistenceManager
├── backup_scheduler.py              ✨ NEW
│   └── BackupScheduler
├── monthly_summary_generator.py     ✨ NEW
│   └── MonthlySummaryGenerator
├── wiki_uploader.py                 ✨ NEW
│   └── WikiUploader
├── skill_selector.py                (修正)
│   └── _persist_learning_outcome() 追加
└── ...

a2a_system/shared/learned_patterns/
├── backup_20251020_120000.json
├── backup_20251020_130000.json
└── .index

tests/
└── test_pattern_1_5_e2e.py          ✨ NEW
```

---

## 🎯 マイルストーン

| マイルストーン | 期間 | 内容 | 成功基準 |
|---|---|---|---|
| **M1** | 2-3日 | JSONベース永続化 + 統合 | Unit test 100% pass |
| **M2** | 2-3日 | バックアップ保護 + スケジューラ | 自動バックアップ動作確認 |
| **M3** | 2-3日 | 月次サマリー + WIKI | Markdown生成 + WIKI アップロード成功 |
| **M4** | 1-2日 | E2E テスト + 本番投入 | 全テスト合格 + 本番稼働 |
| **完了** | **5-8日** | **Pattern 1.5 完成** | ✅ 本番環境で稼働中 |

---

## 🚀 次フェーズの判定基準（3-6ヶ月後）

### Pattern 2/3 への移行判定
```
以下の条件が満たされたら、learning-engine-prod 統合を検討:

✓ 条件1: 3ヶ月以上のデータが蓄積
✓ 条件2: 月次サマリーから明確な パターン需要が見える
✓ 条件3: セマンティック検索やML分析の実装根拠が確立
✓ 条件4: ユーザーからの具体的な要望がある

判定結果:
  - 全条件満たす → Pattern 2/3 実装開始
  - 一部条件のみ → さらに3ヶ月延長して再判定
  - 条件未満足 → Pattern 1.5 で継続
```

---

## ⚠️ リスク管理

| リスク | 確率 | 影響 | 対策 |
|--------|------|------|------|
| ディスク容量不足 | 低 | 中 | 月次クリーンアップ、容量監視 |
| バックアップ破損 | 極低 | 高 | 整合性チェック、複数世代保存 |
| WIKI アップロード失敗 | 低 | 低 | 自動リトライ、ログ記録 |
| スケジューラ停止 | 低 | 中 | プロセス監視、定期確認 |

---

## 💡 AI進化への適応

Pattern 1.5 の柔軟性:

```
2025年11月: 新しいセマンティック検索API公開
  → learning-engine-prod との統合仕様が更新される
  → Pattern 1.5 ベースなら、簡単に置き換え可能

2025年12月: マルチモーダルスキル分類が標準化
  → 新しい分類方式への移行が必要
  → Pattern 1.5 は JSON形式のため、スキーマ拡張が容易

2026年: AGI向けスキル学習システム標準化
  → 新しいベストプラクティスが確立
  → Pattern 1.5 ベースなら、最小限の改修で対応可能
```

---

**作成**: Claude Code
**判断**: ユーザー承認済み ✅
**ステータス**: 実装開始準備完了
