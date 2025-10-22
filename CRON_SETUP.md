# Cron セットアップガイド

このドキュメントは、ACE Learning Engine をデーモン方式から Cron ベースのスケジューリングに移行する手順を説明します。

## 目次

1. [概要](#概要)
2. [メリット](#メリット)
3. [セットアップ手順](#セットアップ手順)
4. [Crontab エントリ](#crontab-エントリ)
5. [実行確認](#実行確認)
6. [トラブルシューティング](#トラブルシューティング)
7. [Daemon からの移行](#daemon-からの移行)

---

## 概要

### Daemon 方式 vs Cron 方式

| 項目 | Daemon 方式 | Cron 方式 |
|------|----------|---------|
| 常時実行 | ✅ 常に動作 | ❌ 指定時刻のみ実行 |
| メモリ効率 | ❌ 常駐メモリを消費 | ✅ 効率的 |
| 状態管理 | ⚠️ 複雑 | ✅ シンプル |
| エラー復旧 | ❌ 手動対応が必要 | ✅ Cron が自動管理 |
| ログ管理 | ⚠️ 複雑 | ✅ 単純 |
| デプロイ | ⚠️ 複雑 | ✅ スクリプト置換で OK |
| テスト | ❌ 難しい | ✅ 単一実行で簡単 |

---

## メリット

### 1. シンプルな管理

```bash
# Cron方式: スクリプトを実行するだけ
python3 a2a_system/scripts/monthly_summary.py

# Daemon方式: プロセス管理が必要
systemctl start ace-learning-daemon  # または systemd, supervisord等
```

### 2. 自動エラー復旧

Cron は失敗時に自動的にリトライできます：

```bash
# リトライ可能な Crontab エントリ
5 0 1 * * cd /path && python3 a2a_system/scripts/monthly_summary.py || (sleep 60 && python3 a2a_system/scripts/monthly_summary.py)
```

### 3. メモリ効率

常駐プロセスがないため、メモリ使用量が大幅に削減されます。

### 4. ログ管理が簡単

```bash
# スクリプト出力をログファイルにリダイレクト
5 0 1 * * cd /path && python3 a2a_system/scripts/monthly_summary.py >> logs/monthly_summary.log 2>&1
```

---

## セットアップ手順

### Step 1: ログディレクトリを作成

```bash
mkdir -p logs
chmod 755 logs
```

### Step 2: スクリプトを確認

```bash
# 月次レポート生成スクリプト
python3 a2a_system/scripts/monthly_summary.py --help

# バックアップスクリプト
python3 a2a_system/scripts/backup.py --help
```

### Step 3: ドライランテストを実行

```bash
# テストモード（実際にはGitコミットしない）
python3 a2a_system/scripts/monthly_summary.py --dry-run

# ログをファイルに出力
python3 a2a_system/scripts/monthly_summary.py --dry-run --log-file logs/test_monthly_summary.log

# ログを確認
cat logs/test_monthly_summary.log
```

### Step 4: バックアップスクリプトをテスト

```bash
# バックアップを実行
python3 a2a_system/scripts/backup.py

# バックアップを検証
python3 a2a_system/scripts/backup.py --verify

# ログを確認
tail -20 logs/backup.log
```

### Step 5: Crontab に登録

```bash
# Crontab エディタを開く
crontab -e

# 以下を追加（下記参照）
# 5 0 1 * * cd /home/planj/Claude-Code-Communication && python3 a2a_system/scripts/monthly_summary.py >> logs/monthly_summary.log 2>&1
# 10 0 * * * cd /home/planj/Claude-Code-Communication && python3 a2a_system/scripts/backup.py >> logs/backup.log 2>&1
```

### Step 6: Crontab が登録されたか確認

```bash
# 登録内容を確認
crontab -l
```

---

## Crontab エントリ

### 推奨設定

#### 1. 月次レポート生成（毎月1日 午前0時05分）

```bash
5 0 1 * * cd /home/planj/Claude-Code-Communication && python3 a2a_system/scripts/monthly_summary.py >> logs/monthly_summary.log 2>&1
```

**説明**:
- `5 0 1 * *`: 毎月 1日 午前0時05分
- `cd /home/planj/Claude-Code-Communication`: リポジトリディレクトリに移動
- `python3 a2a_system/scripts/monthly_summary.py`: スクリプト実行
- `>> logs/monthly_summary.log 2>&1`: ログファイルに出力（標準出力とエラー両方）

#### 2. 日次バックアップ（毎日 午前0時10分）

```bash
10 0 * * * cd /home/planj/Claude-Code-Communication && python3 a2a_system/scripts/backup.py >> logs/backup.log 2>&1
```

**説明**:
- `10 0 * * *`: 毎日 午前0時10分
- その他は月次レポートと同じ

#### 3. 週1回フルバックアップ + クリーンアップ（毎週月曜日 午前3時）

```bash
0 3 * * 1 cd /home/planj/Claude-Code-Communication && python3 a2a_system/scripts/backup.py --full --cleanup >> logs/backup.log 2>&1
```

**説明**:
- `0 3 * * 1`: 毎週月曜日 午前3時
- `--full`: フルバックアップを実行
- `--cleanup`: 30日以上前のバックアップを削除

### リトライ付き設定（推奨）

失敗時に1分後にリトライ：

```bash
# 月次レポート（失敗時リトライ）
5 0 1 * * cd /home/planj/Claude-Code-Communication && python3 a2a_system/scripts/monthly_summary.py >> logs/monthly_summary.log 2>&1 || (sleep 60 && python3 a2a_system/scripts/monthly_summary.py >> logs/monthly_summary.log 2>&1)

# 日次バックアップ（失敗時リトライ）
10 0 * * * cd /home/planj/Claude-Code-Communication && python3 a2a_system/scripts/backup.py >> logs/backup.log 2>&1 || (sleep 60 && python3 a2a_system/scripts/backup.py >> logs/backup.log 2>&1)
```

### Crontab 形式説明

```
分   時   日   月   曜日   コマンド
│    │    │    │    │     └── 実行するコマンド
│    │    │    │    └─────── 曜日 (0=日, 1=月, ..., 6=土)
│    │    │    └──────────── 月 (1-12)
│    │    └───────────────── 日 (1-31)
│    └────────────────────── 時 (0-23)
└─────────────────────────── 分 (0-59)

例:
0 0 * * *     → 毎日 午前0時0分
0 0 1 * *     → 毎月 1日 午前0時0分
0 0 * * 1     → 毎週月曜 午前0時0分
5 0 1 * *     → 毎月 1日 午前0時5分
*/5 * * * *   → 5分ごと
0 */4 * * *   → 4時間ごと
```

---

## 実行確認

### ログの監視

```bash
# リアルタイムでログを監視
tail -f logs/monthly_summary.log
tail -f logs/backup.log

# ログの最新10行を表示
tail -10 logs/monthly_summary.log

# 特定の日付のログを確認
grep "2025-10-22" logs/monthly_summary.log

# エラーのみを抽出
grep "ERROR\|❌" logs/monthly_summary.log
```

### Cron 実行履歴を確認

```bash
# Cron ジョブの実行履歴（Linux/macOS）
log show --predicate 'process == "cron"' --last 1h

# または
sudo tail -f /var/log/syslog | grep CRON

# macOS の場合
log stream --predicate 'process == "cron"' --level debug
```

### Cron 実行確認スクリプト

```bash
#!/bin/bash
# test_cron.sh - Cron 実行テスト

echo "📋 Cron 登録内容:"
crontab -l

echo ""
echo "📊 ログファイルサイズ:"
ls -lh logs/*.log 2>/dev/null || echo "ログファイルが見つかりません"

echo ""
echo "⏰ 最新実行時刻:"
stat logs/monthly_summary.log 2>/dev/null | grep Modify || echo "実行されていません"

echo ""
echo "✅ Cron セットアップ確認完了"
```

実行方法：
```bash
bash test_cron.sh
```

---

## トラブルシューティング

### Q: Cron が実行されない

**原因候補**:
1. Crontab が正しく登録されていない
2. スクリプトへのパスが間違っている
3. Python パスが異なる
4. 環境変数が設定されていない

**対応手順**:

```bash
# 1. Crontab を確認
crontab -l

# 2. スクリプトが実行可能か確認
ls -la a2a_system/scripts/monthly_summary.py

# 3. パスが正しいか確認
pwd  # 現在のディレクトリ確認

# 4. Python パスを確認
which python3

# 5. 手動で実行テスト
python3 a2a_system/scripts/monthly_summary.py --dry-run

# 6. Crontab で使用する Python を明示的に指定
/usr/bin/python3 a2a_system/scripts/monthly_summary.py
```

### Q: "環境変数が見つからない" エラーが出る

**原因**: Cron は .bashrc や .profile を読み込まない

**解決方法**:

```bash
# Crontab に環境変数を明示的に指定
# ファイルの先頭に追加:
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
PYTHONPATH=/home/planj/Claude-Code-Communication

# その後にジョブを追加
5 0 1 * * cd /home/planj/Claude-Code-Communication && python3 a2a_system/scripts/monthly_summary.py >> logs/monthly_summary.log 2>&1
```

### Q: ログファイルが見つからない

**原因**: ログディレクトリが存在しない

**解決**:

```bash
# ログディレクトリを作成
mkdir -p logs
chmod 755 logs

# パーミッションを確認
ls -la logs/
```

### Q: "Permission denied" エラー

**原因**: スクリプトに実行権限がない

**解決**:

```bash
# 実行権限を付与
chmod +x a2a_system/scripts/monthly_summary.py
chmod +x a2a_system/scripts/backup.py

# 確認
ls -la a2a_system/scripts/
```

### Q: Cron メールが大量に届く

**原因**: スクリプト実行時の出力がメール送信されている

**解決**:

```bash
# 出力をログファイルに リダイレクト
5 0 1 * * cd /path && python3 a2a_system/scripts/monthly_summary.py >> logs/monthly_summary.log 2>&1

# または出力を破棄
5 0 1 * * cd /path && python3 a2a_system/scripts/monthly_summary.py > /dev/null 2>&1

# Cron メール送信を無効化（全体）
MAILTO=""
5 0 1 * * cd /path && python3 a2a_system/scripts/monthly_summary.py >> logs/monthly_summary.log 2>&1
```

---

## Daemon からの移行

### Step 1: Daemon を停止

```bash
# learning_engine_daemon.py を停止
pkill -f "python3.*learning_engine_daemon.py"

# または
ps aux | grep learning_engine_daemon
kill <PID>
```

### Step 2: Daemon を無効化

```bash
# learning_engine_daemon.py をコメントアウト（削除しない）
# または systemd サービスを無効化

# systemd の場合
sudo systemctl disable ace-learning-daemon
sudo systemctl stop ace-learning-daemon
```

### Step 3: Cron を設定

```bash
# 上記の「Crontab エントリ」を参照して設定
crontab -e
```

### Step 4: 実行確認

```bash
# Daemon が停止したか確認
ps aux | grep -i daemon | grep -v grep

# Cron が登録されたか確認
crontab -l

# ログが生成されるか確認
ls -la logs/*.log
tail logs/monthly_summary.log
```

### Step 5: 古い設定をクリーンアップ

```bash
# learning_engine_daemon.py は削除せず、アーカイブ化
cp a2a_system/learning_engine_daemon.py a2a_system/learning_engine_daemon.py.bak

# または完全に削除
rm a2a_system/learning_engine_daemon.py
```

---

## チェックリスト

- [ ] ログディレクトリが作成されている
- [ ] スクリプトが実行可能（chmod +x）
- [ ] ドライランテストが成功している
- [ ] Crontab に登録されている（crontab -l で確認）
- [ ] Daemon が停止されている
- [ ] 環境変数が .env に設定されている
- [ ] ログファイルが生成されている
- [ ] 月初日の実行がスケジュールされている
- [ ] 日次バックアップが スケジュールされている
- [ ] クリーンアップが週1回 スケジュールされている

---

## 参考リソース

- [Cron - Wikipedia](https://ja.wikipedia.org/wiki/Cron)
- [Linux Crontab 完全ガイド](https://www.redhat.com/ja/topics/automation/what-is-cron)
- [Crontab Format](https://crontab.guru/)
- [crontab(5) Manual](https://linux.die.net/man/5/crontab)

---

**最終更新**: 2025-10-22
