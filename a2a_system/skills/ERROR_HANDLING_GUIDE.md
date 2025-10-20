# Pattern 1.5 エラーハンドリングガイド

**目的**: 開発者がPattern 1.5の各モジュールにおけるエラー処理を理解し、適切に対応できるようにする

---

## 📋 概要

Pattern 1.5は以下のエラーハンドリング戦略を採用しています：

1. **防御的プログラミング**: 入力値の事前検証
2. **グレースフルデグラデーション**: エラー時の機能縮退
3. **自動復旧**: 可能な限りの自動復旧
4. **ロギング**: 詳細なログ記録
5. **例外処理**: try-exceptによる例外キャッチ

---

## 🔧 モジュール別エラーハンドリング

### 1. LearningPersistenceManager

#### 主要なエラーシナリオ

| シナリオ | 予期される動作 | 対策 |
|---------|--------------|------|
| **ファイルアクセス権限なし** | JSONロード失敗 → 新規初期化 | `mkdir parents=True` で自動作成 |
| **破損したJSONファイル** | JSONパース失敗 → 新規初期化 | try-except で json.JSONDecodeError キャッチ |
| **ディスク容量不足** | 書き込み失敗 | ログ出力、失敗を呼び出し元に返す |
| **バックアップファイル喪失** | 復旧失敗 | `get_latest_backup()` で最新を確認してから復旧 |
| **メモリ不足** | 統計計算失敗 | EMA計算は軽量（前回値のみ保持） |

#### エラーハンドリングコード例

```python
def load_learning_data(self) -> Dict[str, Any]:
    """エラーハンドリング付きデータロード"""
    if os.path.exists(self.tmp_path):
        try:
            with open(self.tmp_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            logger.info(f"📂 Loaded existing learning data")
            return data
        except (json.JSONDecodeError, ValueError) as e:
            logger.warning(f"⚠️ Failed to load existing data: {e}")
            # 新規初期化にフォールバック
            return self._create_empty_data()
        except IOError as e:
            logger.error(f"❌ IO error: {e}")
            return self._create_empty_data()
```

#### 最も重要な例外ハンドリング

**`append_record()` - 学習レコード追加時**:
```python
def append_record(self, record: Dict[str, Any]) -> bool:
    """
    返却値:
        True: 成功
        False: 失敗（ディスク容量不足等）
    """
    try:
        # レコード追加 + 統計更新
        return self.save_learning_data(self.current_data)
    except Exception as e:
        logger.error(f"❌ Failed to append record: {e}")
        return False
```

**呼び出し元での処理**:
```python
success = persistence_manager.append_record(record)
if not success:
    logger.warning("Record not persisted - may retry later")
    # 呼び出し元でリトライ戦略を実装
```

---

### 2. BackupScheduler

#### 主要なエラーシナリオ

| シナリオ | 予期される動作 | 対策 |
|---------|--------------|------|
| **スレッド開始失敗** | デーモン開始失敗 | `threading.Thread` で例外キャッチ |
| **ジョブ実行失敗** | 1つのジョブ失敗 → 次ジョブ継続 | 個別try-exceptで隔離 |
| **ディレクトリ削除権限なし** | クリーンアップスキップ | ログに記録、次回の実行に委ねる |
| **バックアップ作成失敗** | ログ出力、スケジューラ継続 | メイン処理には影響しない |

#### エラーハンドリングコード例

```python
def _run_scheduler(self):
    """ジョブ実行ループのエラーハンドリング"""
    while self.running:
        try:
            self.scheduler.run_pending()  # 各ジョブ実行
            time.sleep(60)
        except Exception as e:
            # スケジューラ全体を止めない
            logger.error(f"❌ Scheduler error: {e}")
            time.sleep(60)  # リトライ前に待機
```

**各ジョブのエラーハンドリング**:
```python
def _hourly_backup(self):
    """個別ジョブのエラーハンドリング"""
    try:
        backup_path = self.manager.create_backup()
        logger.info(f"✅ Hourly backup created: {backup_path}")
        return True
    except Exception as e:
        logger.error(f"❌ Hourly backup failed: {e}")
        # 失敗してもスケジューラは継続
        return False
```

---

### 3. MonthlySummaryGenerator

#### 主要なエラーシナリオ

| シナリオ | 予期される動作 | 対策 |
|---------|--------------|------|
| **月内レコード0件** | 空のサマリー返却 | ガード条件で `len(records) == 0` チェック |
| **無効なタイムスタンプ** | レコードスキップ | `datetime.fromisoformat()` で ValueError キャッチ |
| **Markdown生成時エラー** | 部分的出力 | 各セクション個別try-except |
| **推奨事項生成失敗** | デフォルト提案返却 | 最終的には何かしら返す |

#### エラーハンドリングコード例

```python
def _filter_records_by_month(self, records: List[Dict],
                             start_date: datetime,
                             end_date: datetime) -> List[Dict]:
    """タイムスタンプフィルタのエラーハンドリング"""
    month_records = []
    for record in records:
        try:
            record_date = datetime.fromisoformat(record.get("timestamp", ""))
            if start_date <= record_date <= end_date:
                month_records.append(record)
        except (ValueError, TypeError):
            # タイムスタンプが無効 → スキップ
            logger.debug(f"Invalid timestamp, skipping record")
            pass
    return month_records
```

**推奨事項生成のエラーハンドリング**:
```python
def _generate_recommendations(self, records: List[Dict]) -> List[str]:
    """推奨事項生成（常に何かしら返す）"""
    recommendations = []

    try:
        # 複数の推奨ロジック...
    except Exception as e:
        logger.error(f"Recommendation failed: {e}")
        # フォールバック
        recommendations.append("特に改善提案がありません。良好に動作しています。")

    # 常に何かしら返す
    return recommendations if recommendations else ["デフォルト推奨"]
```

---

### 4. WikiUploader

#### 主要なエラーシナリオ

| シナリオ | 予期される動作 | 対策 |
|---------|--------------|------|
| **Git認証失敗** | プッシュ失敗、ドライランで続行 | `subprocess` returncode チェック |
| **ディレクトリ作成失敗** | アップロード中止 | `Path.mkdir(parents=True)` で再帰作成 |
| **ファイル書き込み失敗** | ログ出力 → リターン False | try-except で IOError キャッチ |
| **WIKI構造が破損** | インデックス再生成 | `create_index_page()` を再実行 |

#### エラーハンドリングコード例

```python
def _commit_to_repo(self, files: list) -> bool:
    """Git操作のエラーハンドリング"""
    try:
        # Git add
        result = subprocess.run(["git", "add"] + files,
                                cwd=self.repo_path,
                                capture_output=True)
        if result.returncode != 0:
            logger.warning(f"⚠️ Git add warning: {result.stderr}")

        # Git commit
        result = subprocess.run(["git", "commit", "-m", message],
                                cwd=self.repo_path,
                                capture_output=True)

        if result.returncode == 0:
            logger.info(f"✅ Committed successfully")
        elif "nothing to commit" in result.stdout:
            logger.info("ℹ️ No changes to commit")
            return True  # 正常系
        else:
            logger.warning(f"⚠️ Commit warning: {result.stderr}")

        return result.returncode == 0

    except Exception as e:
        logger.error(f"❌ Git operation failed: {e}")
        return False
```

---

## 🎯 エラー対応のベストプラクティス

### 1. ログレベルの使い分け

```python
# 通常の動作
logger.debug("詳細情報")      # 開発時のみ有用
logger.info("正常系")         # ✅ リソース作成成功等

# 異常系
logger.warning("警告")        # ⚠️ リトライ可能な失敗
logger.error("エラー")        # ❌ 重大な失敗だが処理継続
logger.critical("致命的")    # 🔴 システム停止レベル
```

### 2. 返却値設計

```python
# ❌ 悪い例: 常に例外を発生させる
def dangerous_operation():
    result = risky_operation()  # 失敗時に例外
    return result

# ✅ 良い例: 返却値で成功/失敗を表現
def safe_operation() -> bool:
    try:
        result = risky_operation()
        return True
    except Exception:
        return False
```

### 3. リトライ戦略

```python
def persist_with_retry(record, max_retries=3):
    """リトライロジック"""
    for attempt in range(max_retries):
        try:
            success = manager.append_record(record)
            if success:
                return True
            time.sleep(1)  # バックオフ
        except Exception as e:
            logger.warning(f"Attempt {attempt+1} failed: {e}")
    return False
```

### 4. フェイルセーフ

```python
def load_data():
    """多層のフェイルセーフ"""
    # レベル1: メイン
    try:
        return load_from_main()
    except:
        pass

    # レベル2: バックアップ
    try:
        return load_from_backup()
    except:
        pass

    # レベル3: 初期化
    return initialize_new()
```

---

## 📊 エラー統計とモニタリング

### 監視すべき指標

| 指標 | 目標値 | 警告値 |
|------|--------|--------|
| バックアップ成功率 | 99.9% | < 95% |
| JSON ロード成功率 | 99.9% | < 95% |
| Markdowngeneration成功率 | 99% | < 90% |
| スケジューラ稼働率 | 99.9% | < 99% |

### ログファイルの確認

```bash
# ERROR レベルのログ確認
grep ERROR /var/log/pattern1.5.log

# 警告ログの確認
grep WARNING /var/log/pattern1.5.log

# 24時間内のエラー数
grep ERROR /var/log/pattern1.5.log | wc -l
```

---

## 🚨 一般的な問題と対応

### 問題1: `/tmp/skill_learning.json` が消失

**症状**: データが全て失われた

**原因**: システム再起動で /tmp がクリア

**対応**:
```python
# 最新バックアップから復旧
latest = manager.get_latest_backup()
if latest:
    manager.restore_from_backup(latest)
    logger.info("✅ Recovered from backup")
```

### 問題2: バックアップディレクトリがいっぱい

**症状**: バックアップ作成失敗「ディスク容量不足」

**対応**:
```bash
# 古いバックアップを手動削除
ls -t /a2a_system/shared/learned_patterns/ | tail -5 | xargs rm

# または自動クリーンアップを実行
manager.cleanup_old_backups(keep_count=5)
```

### 問題3: Git プッシュが失敗

**症状**: WIKI アップロード失敗

**対応**:
```bash
# ドライランモードでテスト
uploader = WikiUploader(repo_path, dry_run=True)

# Git 認証確認
git status

# 手動プッシュ
git push
```

---

## ✅ チェックリスト

本番投入前の確認：

- [ ] エラーログが適切に出力されている
- [ ] バックアップが定期的に作成されている
- [ ] `/tmp` が消失しても復旧できる
- [ ] WIKI アップロードがドライラン成功している
- [ ] 障害シナリオが複数テストされている
- [ ] アラート設定がされている（オプション）

---

**このガイドを参照して、安全で堅牢なPattern 1.5の運用を行ってください。**
