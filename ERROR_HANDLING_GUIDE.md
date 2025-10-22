# エラーハンドリング・リトライロジック ガイド

このドキュメントは、ACE Learning Engine のエラーハンドリングと自動リトライ機構について説明します。

## 目次

1. [概要](#概要)
2. [エラーハンドリングの3層構造](#エラーハンドリングの3層構造)
3. [リトライロジック](#リトライロジック)
4. [カスタム例外](#カスタム例外)
5. [エラー通知](#エラー通知)
6. [ベストプラクティス](#ベストプラクティス)
7. [トラブルシューティング](#トラブルシューティング)

---

## 概要

ACE Learning Engine は、外部 API（GitHub等）との通信時に発生するエラーに対して自動的にリトライを行います。

**主な特徴**:

- ✅ **指数バックオフ**: リトライの間隔を指数関数的に増加
- ✅ **トランザクション安全性**: 冪等性のある操作のみリトライ
- ✅ **構造化ログ**: すべてのエラーを JSON 形式で記録
- ✅ **通知システム**: Email・Slack・カスタム通知に対応
- ✅ **カスタム例外**: ドメイン固有の例外で詳細情報を保持

---

## エラーハンドリングの3層構造

```
層3: エラー通知
     ↓
     Email / Slack / カスタム通知

層2: エラーログ記録
     ↓
     構造化ログ（JSON形式）

層1: リトライロジック
     ↓
     指数バックオフ付き自動リトライ
```

### 層1: リトライロジック

**役割**: トランジェントエラー（一時的なエラー）を自動的に解決

**対象エラー**:
- ネットワークタイムアウト
- HTTP 5xx エラー（サーバーエラー）
- 一時的な接続障害

**非対象エラー**:
- 認証エラー（400, 401, 403）
- 無効なデータ（400, 422）
- リソース不在（404）

### 層2: エラーログ記録

**役割**: エラー内容を詳細に記録

**記録項目**:
- タイムスタンプ
- エラータイプ
- エラーメッセージ
- コンテキスト情報
- スタックトレース（DEBUG モード）

### 層3: エラー通知

**役割**: 重要なエラーを管理者に通知

**通知方法**:
- Email（設定時）
- Slack（設定時）
- ログファイル（常時）

---

## リトライロジック

### 基本的な使用方法

```python
from a2a_system.skills.error_handler import retry_with_exponential_backoff

@retry_with_exponential_backoff(
    max_retries=3,
    base_delay=2,
    max_delay=30,
    exceptions=(urllib.error.HTTPError, urllib.error.URLError),
)
def call_github_api(url, payload):
    # GitHub API を呼び出し
    response = urllib.request.urlopen(request)
    return response
```

### パラメータ説明

| パラメータ | デフォルト | 説明 |
|-----------|---------|-----|
| `max_retries` | 3 | 最大リトライ回数 |
| `base_delay` | 1 | 初期遅延（秒） |
| `max_delay` | 60 | 最大遅延（秒） |
| `exceptions` | (Exception,) | リトライ対象の例外タプル |
| `on_retry` | None | リトライ時のコールバック |

### 指数バックオフの計算

```
リトライ回数: 1      → 遅延: 1秒 (base_delay × 2^0)
リトライ回数: 2      → 遅延: 2秒 (base_delay × 2^1)
リトライ回数: 3      → 遅延: 4秒 (base_delay × 2^2)
リトライ回数: 4      → 遅延: 8秒 (base_delay × 2^3)
            :
max_delay に達したら そこで頭打ち
```

**例**: base_delay=2, max_delay=30 の場合

```
試行1: 即座に実行 (遅延なし)
試行2: 2秒待機 (2^0 × 2 = 2秒)
試行3: 4秒待機 (2^1 × 2 = 4秒)
試行4: 8秒待機 (2^2 × 2 = 8秒)
試行5: 16秒待機 (2^3 × 2 = 16秒)
試行6: 30秒待機 (2^4 × 2 = 32秒 → max_delay に制限)
```

### リトライ時のコールバック

```python
def on_retry_callback(attempt, max_attempts, exception):
    """
    リトライ時に呼ばれるコールバック

    Args:
        attempt: 現在の試行番号
        max_attempts: 最大試行回数
        exception: 発生した例外
    """
    logger.info(f"リトライ {attempt}/{max_attempts}: {exception}")

@retry_with_exponential_backoff(
    max_retries=3,
    on_retry=on_retry_callback,
    exceptions=(urllib.error.HTTPError,),
)
def call_api():
    pass
```

---

## カスタム例外

### ACEException（基本例外）

```python
from a2a_system.skills.error_handler import ACEException

exc = ACEException(
    message="Something went wrong",
    error_code="CUSTOM_ERROR",
    details={"key": "value"}
)

# 詳細情報を辞書として取得
error_dict = exc.to_dict()
# {
#     "message": "Something went wrong",
#     "error_code": "CUSTOM_ERROR",
#     "details": {"key": "value"},
#     "timestamp": "2025-10-22T10:00:00"
# }
```

### GitHubAPIError（GitHub API エラー）

```python
from a2a_system.skills.error_handler import GitHubAPIError

try:
    # GitHub API 呼び出し
    response = urllib.request.urlopen(request)
except urllib.error.HTTPError as e:
    raise GitHubAPIError(
        message="Failed to create ISSUE",
        status_code=e.code,
        response_body=e.read().decode('utf-8')
    )
```

**自動アクション提案機能**:
GitHubAPIError は HTTP ステータスコードに応じて、自動的にユーザー向けのアクション提案を生成します：

| ステータスコード | アクション提案 |
|------|---|
| 401 | GitHub トークンが無効または有効期限切れです。トークンを再生成してください。 |
| 403 | トークンの権限不足です。リポジトリへの書き込み権限を確認してください。 |
| 404 | 指定されたリポジトリが見つかりません。GITHUB_REPO の値を確認してください。 |
| 422 | リクエストデータが不正です。ISSUE タイトル・本文が正しく生成されているか確認してください。 |
| 429 | API レート制限に達しました。しばらく待機してから再試行してください。 |
| 5xx | GitHub サーバーエラーです。数分待ってから再試行してください。 |

エラー情報の取得例：
```python
try:
    create_github_issue(title, body)
except GitHubAPIError as e:
    error_dict = e.to_dict()
    print(f"Error: {error_dict['message']}")
    print(f"Action: {error_dict['actionable_advice']}")  # ← ユーザー向けアクション
```

### WikiUploadError（WIKI アップロードエラー）

```python
from a2a_system.skills.error_handler import WikiUploadError

try:
    # WIKI ファイルをアップロード
    with open(filepath, 'w') as f:
        f.write(content)
except IOError as e:
    raise WikiUploadError(
        message="Failed to write WIKI file",
        path=filepath
    )
```

### BackupError（バックアップエラー）

```python
from a2a_system.skills.error_handler import BackupError

try:
    # バックアップを作成
    shutil.copy(source, backup_path)
except OSError as e:
    raise BackupError(
        message="Backup creation failed",
        backup_path=backup_path
    )
```

---

## エラー通知

### safe_operation デコレータ

```python
from a2a_system.skills.error_handler import safe_operation

@safe_operation(
    operation_name="GitHub ISSUE 作成",
    default_return=False,
    should_raise=False,
)
def create_issue(title, body):
    # 実装
    pass

# 失敗時は False を返し、ログには ERROR レベルで記録
result = create_issue(title, body)
```

### エラーログ記録

```python
from a2a_system.skills.error_handler import log_error, get_notifier

try:
    # 何か処理
    pass
except Exception as e:
    # エラー情報を構造化ログとして記録
    error_info = log_error(
        e,
        context={"operation": "test", "user_id": 123},
        level="ERROR"
    )

    # 通知システムに送信
    notifier = get_notifier()
    notifier.notify(error_info, severity="ERROR")
```

### Email 通知の設定

```python
from a2a_system.skills.error_handler import EmailNotifier, get_notifier

# Email 通知ハンドラーを作成
email_notifier = EmailNotifier(
    smtp_server="mail.example.com",
    smtp_port=587,
    from_addr="noreply@example.com",
    to_addrs=["admin@example.com", "ops@example.com"],
)

# グローバル通知システムに登録
notifier = get_notifier()
notifier.register_handler(email_notifier.send)

# 以後のエラーは自動的に Email で通知されます
```

### Slack 通知の設定

```python
from a2a_system.skills.error_handler import SlackNotifier, get_notifier

# Slack 通知ハンドラーを作成
slack_notifier = SlackNotifier(
    webhook_url="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
)

# グローバル通知システムに登録
notifier = get_notifier()
notifier.register_handler(slack_notifier.send)

# 以後のエラーは自動的に Slack で通知されます
```

### 重大度別通知（アラート疲れ対策）

通知システムは重大度に応じて、送信先を自動的に選別します：

| 重大度 | 通知先 | 説明 |
|--------|--------|------|
| WARNING | ログのみ | 警告だが処理は続行。Email/Slack 通知は送らない |
| ERROR | Email | エラー発生。管理者への Email 通知のみ |
| CRITICAL | Email + Slack | 致命的エラー。Email と Slack の両方に緊急通知 |

**使用例**:
```python
notifier = get_notifier()

# 処理の遅延：ログのみ
notifier.notify(error_info, severity="WARNING")

# GitHub API エラー：Email 通知
notifier.notify(error_info, severity="ERROR")

# システムダウン：Email + Slack 通知
notifier.notify(error_info, severity="CRITICAL")
```

この設計により、**アラート疲れを防ぎながら重大な問題には素早く対応**できます。

---

## ベストプラクティス

### 1. リトライ対象かどうかを判断

**リトライすべき（トランジェント）エラー**:
```python
@retry_with_exponential_backoff(
    exceptions=(
        urllib.error.URLError,  # ネットワークエラー
        urllib.error.HTTPError,  # HTTP エラー（5xxなど）
        TimeoutError,             # タイムアウト
        ConnectionError,          # 接続エラー
    )
)
def call_external_api():
    pass
```

**リトライしてはいけないエラー**:
```python
# 認証エラー、無効なデータなどは
# リトライ対象から除外
@retry_with_exponential_backoff(
    exceptions=(urllib.error.URLError,),  # URLError のみ
)
def call_api():
    pass
```

### 2. 適切なリトライ回数とタイムアウトを設定

```python
# GitHub API: 中程度のリトライ（3回）
@retry_with_exponential_backoff(
    max_retries=3,
    base_delay=2,
    max_delay=30,
)
def create_github_issue():
    pass

# バックアップ: 積極的なリトライ（5回）
@retry_with_exponential_backoff(
    max_retries=5,
    base_delay=1,
    max_delay=60,
)
def backup_learning_data():
    pass
```

### 3. リトライ不可の操作は safe_operation で保護

```python
from a2a_system.skills.error_handler import safe_operation

@safe_operation("月次レポート生成", default_return=False)
def generate_monthly_report():
    # リトライではなく、エラーをログしてデフォルト値を返す
    pass
```

### 4. エラーコンテキストを記録

```python
from a2a_system.skills.error_handler import log_error

try:
    create_github_issue(title, body)
except Exception as e:
    error_info = log_error(
        e,
        context={
            "operation": "GitHub ISSUE 作成",
            "title": title,
            "repo": os.getenv("GITHUB_REPO"),
            "attempt": current_attempt,
        },
        level="ERROR"
    )
```

### 5. カスタム例外を使用

```python
from a2a_system.skills.error_handler import GitHubAPIError

try:
    response = urllib.request.urlopen(request)
except urllib.error.HTTPError as e:
    # 汎用の Exception ではなく、GitHubAPIError を使用
    raise GitHubAPIError(
        message=f"Failed to create ISSUE: {e.reason}",
        status_code=e.code,
        response_body=e.read().decode('utf-8')
    )
```

---

## トラブルシューティング

### Q: リトライが実行されていない

**原因候補**:
1. 例外が `exceptions` パラメータに含まれていない
2. リトライ対象外の例外が発生している

**確認方法**:
```python
# ログレベルを DEBUG に設定
import logging
logging.basicConfig(level=logging.DEBUG)

# リトライデコレータの状態をログで確認
# "🔄 実行試行" というログが出力されているか確認
```

**解決**:
```python
import urllib.error

@retry_with_exponential_backoff(
    exceptions=(urllib.error.HTTPError, urllib.error.URLError),
)
def call_api():
    pass
```

### Q: 何度もリトライされる（実行が遅い）

**原因**: リトライ回数が多すぎる、または初期遅延が大きい

**解決**:
```python
@retry_with_exponential_backoff(
    max_retries=2,        # 3回から2回に削減
    base_delay=1,         # 2秒から1秒に削減
    max_delay=10,         # 最大遅延を制限
)
def call_api():
    pass
```

### Q: Email 通知が送信されない

**原因候補**:
1. SMTP 設定が正しくない
2. Email アドレスが無効
3. ファイアウォールが SMTP ポートをブロック

**確認方法**:
```python
import smtplib

# SMTP 接続をテスト
try:
    with smtplib.SMTP("mail.example.com", 587) as server:
        server.starttls()
        print("✅ SMTP 接続成功")
except Exception as e:
    print(f"❌ SMTP 接続失敗: {e}")
```

### Q: Slack 通知が表示されない

**原因候補**:
1. Webhook URL が無効
2. 通知ハンドラーが登録されていない

**確認方法**:
```python
from a2a_system.skills.error_handler import get_notifier

# ハンドラーが登録されているか確認
notifier = get_notifier()
print(f"登録されたハンドラー: {len(notifier.handlers)}")

# 手動で通知をテスト
error_info = {"error_type": "Test", "error_message": "Test error"}
notifier.notify(error_info, severity="ERROR")
```

---

## ログレベルの使い分け

| レベル | 用途 | 例 |
|--------|------|-----|
| DEBUG | 詳細なデバッグ情報 | リトライ試行、ネットワーク詳細 |
| INFO | 通常のログ | 処理開始、処理完了 |
| WARNING | 警告（システムは動作） | API エラーからの復旧、スキップした処理 |
| ERROR | エラー（処理失敗） | 最大リトライ後の失敗、必須リソース不在 |
| CRITICAL | 致命的エラー | システム停止レベルの障害 |

**設定方法**:
```bash
# 環境変数で設定
export LOG_LEVEL=DEBUG
python3 a2a_system/scripts/monthly_summary.py

# または .env ファイルで設定
echo "LOG_LEVEL=DEBUG" >> .env
```

---

## パフォーマンス考慮事項

### リトライの総実行時間

```
base_delay=2, max_retries=3 の場合:
試行1: 0秒
試行2: +2秒 = 2秒
試行3: +4秒 = 6秒
試行4: +8秒 = 14秒

最大実行時間: 約14秒（API処理時間を除く）
```

### 推奨設定

**クリティカルな処理**:
```python
# 何としても成功させたい場合
max_retries=5, base_delay=1, max_delay=60
```

**通常の処理**:
```python
# バランスの取れた設定（推奨）
max_retries=3, base_delay=2, max_delay=30
```

**高速レスポンス必須**:
```python
# 素早く失敗したい場合
max_retries=1, base_delay=0.5, max_delay=5
```

---

## 参考リソース

- [Exponential Backoff - AWS Documentation](https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/)
- [Retry Pattern - Microsoft](https://docs.microsoft.com/en-us/azure/architecture/patterns/retry)
- [Python logging - Official Documentation](https://docs.python.org/3/library/logging.html)

---

**最終更新**: 2025-10-22
