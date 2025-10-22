# 本番環境デプロイメント チェックリスト

このドキュメントは、ACE Learning Engine を本番環境に展開する際の確認事項をリストアップしています。

## 目次

1. [デプロイ前チェック](#デプロイ前チェック)
2. [セキュリティチェック](#セキュリティチェック)
3. [環境設定チェック](#環境設定チェック)
4. [テストチェック](#テストチェック)
5. [ドキュメント確認](#ドキュメント確認)
6. [デプロイ後チェック](#デプロイ後チェック)
7. [本番環境設定](#本番環境設定)

---

## デプロイ前チェック

### コード品質

- [ ] すべてのテストが成功している
  ```bash
  pytest a2a_system/tests/ -v
  ```

- [ ] コード静的解析を実行（オプション）
  ```bash
  flake8 a2a_system/
  black --check a2a_system/
  ```

- [ ] 不要な debug コードがない
  ```bash
  grep -r "print(" a2a_system/scripts/ | grep -v "logger"
  grep -r "pdb" a2a_system/
  ```

- [ ] ログレベルが本番設定（INFO以上）
  ```bash
  grep -r "DEBUG" .env.example
  ```

### ファイルシステム

- [ ] logs/ ディレクトリが作成できる
  ```bash
  mkdir -p logs
  ls -la logs/
  ```

- [ ] docs/ ディレクトリが .gitignore に含まれていない
  ```bash
  cat .gitignore | grep -v "docs"
  ```

- [ ] .env ファイルが .gitignore に含まれている
  ```bash
  cat .gitignore | grep ".env"
  ```

- [ ] バックアップディレクトリへの書き込み権限がある
  ```bash
  touch ~/.local/share/ace_learning/backups/test.tmp
  rm ~/.local/share/ace_learning/backups/test.tmp
  ```

### 依存関係

- [ ] すべてのライブラリがインストールされている
  ```bash
  pip list | grep pytest
  pip list | grep python-dotenv
  pip list | grep requests
  ```

- [ ] requirements.txt が最新である
  ```bash
  pip install -r requirements.txt
  ```

- [ ] Python バージョンが 3.8 以上である
  ```bash
  python3 --version
  ```

---

## セキュリティチェック

### 認証情報

- [ ] .env ファイルが安全に保管されている
  ```bash
  ls -la .env
  # -rw-r--r-- (読み取り専用) または -rw------- (オーナーのみ)
  ```

- [ ] GitHub トークンが有効で正しい権限を持つ
  ```bash
  curl -H "Authorization: token YOUR_TOKEN" https://api.github.com/user
  ```

- [ ] OpenAI API キーが有効である
  ```bash
  python3 validate_env.py
  ```

- [ ] 認証情報が git リポジトリにコミットされていない
  ```bash
  git log -p | grep "GITHUB_TOKEN\|OPENAI_API_KEY"
  ```

### ネットワークセキュリティ

- [ ] GitHub API への接続が HTTPS である
  ```bash
  grep "https://api.github.com" a2a_system/scripts/monthly_summary.py
  ```

- [ ] Email 送信が TLS/STARTTLS を使用している（Email通知の場合）
  ```bash
  grep "starttls\|465\|587" a2a_system/skills/error_handler.py
  ```

- [ ] プロキシが必要な場合は設定されている
  ```bash
  echo $HTTP_PROXY
  echo $HTTPS_PROXY
  ```

### ファイル権限

- [ ] スクリプトが実行可能である
  ```bash
  ls -la a2a_system/scripts/
  # -rwxr-xr-x
  ```

- [ ] ログファイルの権限が適切である
  ```bash
  ls -la logs/
  ```

- [ ] バックアップファイルの権限が適切である
  ```bash
  ls -la ~/.local/share/ace_learning/backups/
  ```

---

## 環境設定チェック

### 環境変数

- [ ] すべての必須環境変数が設定されている
  ```bash
  python3 validate_env.py
  ```

- [ ] 環境変数が正しい値である
  ```bash
  echo $GITHUB_TOKEN | head -c 10  # 最初の10文字を確認
  echo $OPENAI_API_KEY | head -c 10
  ```

- [ ] 本番環境の設定が有効である
  ```bash
  cat .env | grep "LOG_LEVEL"
  # 期待値: INFO または WARNING
  ```

### 時刻設定

- [ ] システム時刻が正確である
  ```bash
  date
  timedatectl status  # Linux/WSL2
  ```

- [ ] タイムゾーンが正しく設定されている
  ```bash
  echo $TZ
  # 期待値: Asia/Tokyo
  ```

### Cron スケジュール

- [ ] Crontab エントリが登録されている
  ```bash
  crontab -l
  ```

- [ ] Crontab エントリが正しい時刻である
  ```bash
  # 期待値:
  # 5 0 1 * * ... (毎月1日 午前0時05分)
  # 10 0 * * * ... (毎日 午前0時10分)
  ```

---

## テストチェック

### 単体テスト

- [ ] すべてのテストが成功している
  ```bash
  python3 -m pytest a2a_system/tests/ -v
  # 結果: XX passed
  ```

- [ ] テストカバレッジが70%以上
  ```bash
  python3 -m pytest a2a_system/tests/ --cov=a2a_system --cov-report=term
  # 期待値: >= 70%
  ```

### 統合テスト

- [ ] ドライランモードでの実行が成功する
  ```bash
  python3 a2a_system/scripts/monthly_summary.py --dry-run --year 2025 --month 10
  # 結果: ✅ 月次サマリープロセス完了
  ```

- [ ] バックアップスクリプトが成功する
  ```bash
  python3 a2a_system/scripts/backup.py --verify
  # 結果: backup_count >= 0
  ```

### 環境検証

- [ ] 環境変数検証が成功する
  ```bash
  python3 validate_env.py
  # 結果: ✅ 検証成功
  ```

- [ ] 環境セットアップが再現可能である
  ```bash
  # 別のディレクトリで実行
  cp .env .env.bak
  rm .env
  python3 validate_env.py  # 失敗するはず
  cp .env.bak .env
  python3 validate_env.py  # 成功するはず
  ```

---

## ドキュメント確認

### 必須ドキュメント

- [ ] README.md が存在し、セットアップ手順が記載されている
  ```bash
  ls README.md
  grep "セットアップ" README.md
  ```

- [ ] ENVIRONMENT_SETUP.md が完成している
  ```bash
  ls ENVIRONMENT_SETUP.md
  grep "【Step 5】" ENVIRONMENT_SETUP.md
  ```

- [ ] CRON_SETUP.md が完成している
  ```bash
  ls CRON_SETUP.md
  grep "Crontab エントリ" CRON_SETUP.md
  ```

- [ ] ERROR_HANDLING_GUIDE.md が存在している
  ```bash
  ls ERROR_HANDLING_GUIDE.md
  grep "リトライロジック" ERROR_HANDLING_GUIDE.md
  ```

### デプロイメント計画

- [ ] デプロイ前後のロールバック計画がある
- [ ] 既知の制限事項が文書化されている
- [ ] トラブルシューティングガイドが完備されている

---

## デプロイ後チェック

### 機能動作確認

- [ ] 月次レポート生成が正常に動作する
  ```bash
  python3 a2a_system/scripts/monthly_summary.py
  # ログ確認: ✅ 月次サマリープロセス完了
  ```

- [ ] WIKI ファイルが正しく生成されている
  ```bash
  ls -la docs/skill_learning_wiki/current/latest.md
  # -rw-r--r-- ... latest.md
  ```

- [ ] GitHub ISSUE が正常に作成されている
  ```bash
  # GitHub リポジトリを確認
  # Issues タブで新しい Issue が表示されているか
  ```

- [ ] バックアップが正常に実行されている
  ```bash
  ls -la ~/.local/share/ace_learning/backups/ | head -5
  ```

### ログ確認

- [ ] ログファイルが生成されている
  ```bash
  ls -la logs/
  cat logs/monthly_summary.log | tail -20
  ```

- [ ] エラーが記録されていない（またはエラーが予期されたものである）
  ```bash
  grep "ERROR\|❌" logs/monthly_summary.log
  ```

### パフォーマンス確認

- [ ] スクリプト実行時間が許容範囲内（10秒以内）
  ```bash
  time python3 a2a_system/scripts/monthly_summary.py --dry-run
  ```

- [ ] メモリ使用量が正常
  ```bash
  ps aux | grep "python3.*monthly_summary"
  # メモリ: 100MB 以下
  ```

- [ ] CPU 負荷が正常
  ```bash
  top -b -n 1 | grep "python3"
  ```

---

## 本番環境設定

### 推奨設定

```bash
# .env ファイルの本番設定例

# ログレベル: DEBUG ではなく INFO
LOG_LEVEL=INFO

# ドライランモード: false
DRY_RUN=false

# GitHub 設定
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxx
GITHUB_REPO=pj0201/Claude-Code-Communication

# OpenAI API キー
OPENAI_API_KEY=sk-proj-xxxxxxxxxxxxxxxxxxxxx

# Crontab スケジュール（毎月1日 午前0時05分）
# 5 0 1 * * cd /home/planj/Claude-Code-Communication && python3 a2a_system/scripts/monthly_summary.py >> logs/monthly_summary.log 2>&1

# 日次バックアップ（毎日 午前0時10分）
# 10 0 * * * cd /home/planj/Claude-Code-Communication && python3 a2a_system/scripts/backup.py >> logs/backup.log 2>&1
```

### セキュリティ設定

```bash
# ファイル権限設定

# .env ファイル: オーナーのみ読み取り
chmod 600 .env

# スクリプト: 実行可能
chmod +x a2a_system/scripts/*.py

# ログディレクトリ: オーナーのみアクセス
chmod 700 logs/

# バックアップディレクトリ: オーナーのみアクセス
chmod 700 ~/.local/share/ace_learning/backups/
```

### モニタリング設定

```bash
# ログローテーション設定（logrotate）

# /etc/logrotate.d/ace-learning-engine

/home/planj/Claude-Code-Communication/logs/*.log {
    daily
    rotate 30
    compress
    delaycompress
    notifempty
    create 600 planj planj
    sharedscripts
    postrotate
        systemctl reload rsyslog > /dev/null 2>&1 || true
    endscript
}
```

---

## 本番環境監視

### ログ監視

```bash
# ログをリアルタイム監視
tail -f logs/monthly_summary.log

# エラーのみを監視
grep "ERROR\|❌" logs/monthly_summary.log | tail -20

# 特定の日付のログを検索
grep "2025-10-22" logs/monthly_summary.log
```

### Cron 実行確認

```bash
# Cron 実行履歴を確認
grep CRON /var/log/syslog | tail -20

# または
journalctl -u cron | tail -20
```

### ディスク容量監視

```bash
# ディスク使用量を確認
df -h /home/

# バックアップサイズを確認
du -sh ~/.local/share/ace_learning/backups/
```

---

## トラブルシューティング

### デプロイ後にエラーが発生した場合

```bash
# 1. ログを確認
tail -100 logs/monthly_summary.log

# 2. 環境変数を確認
python3 validate_env.py

# 3. スクリプトを手動実行
python3 a2a_system/scripts/monthly_summary.py

# 4. ドライランで確認
python3 a2a_system/scripts/monthly_summary.py --dry-run
```

### ロールバック手順

```bash
# 1. 最新の git コミットを確認
git log --oneline | head -5

# 2. 前のバージョンに戻す
git revert HEAD
# または
git reset --hard HEAD~1

# 3. スクリプトを再実行
python3 a2a_system/scripts/monthly_summary.py --dry-run
```

---

## チェックリスト（印刷用）

### デプロイ前（5-10分）

```
☐ すべてのテストが成功
☐ コードに debug コードがない
☐ .env ファイルが正しく設定されている
☐ 環境検証が成功（python3 validate_env.py）
☐ ドライランテストが成功
```

### デプロイ中（5分）

```
☐ Crontab が登録されている（crontab -l）
☐ ログディレクトリが作成されている
☐ ファイル権限が正しく設定されている
```

### デプロイ後（5分）

```
☐ ログファイルが生成されている
☐ エラーが記録されていない
☐ GitHub ISSUE が作成されている（初回のみ）
☐ 実行時間が許容範囲内
```

---

**最終更新**: 2025-10-22
