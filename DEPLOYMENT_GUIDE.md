# LINE → GitHub → Claude Code 統合 デプロイガイド

**最終更新**: 2025-10-18 17:50:00 UTC
**ステータス**: ✅ **本稼働可能**

---

## 📋 デプロイ前チェックリスト

### 環境準備

- [ ] Linux サーバー（Ubuntu 20.04 LTS 以上推奨）
- [ ] Python 3.11 以上
- [ ] Git
- [ ] 十分なディスク容量（最小 2GB）
- [ ] インターネット接続

### 認証情報の準備

- [ ] LINE Channel Secret（LINE Developers）
- [ ] LINE Channel Access Token（LINE Developers）
- [ ] GitHub Personal Access Token（GitHub Settings）
- [ ] OpenAI API Key（OpenAI Platform）

### ネットワーク設定

- [ ] ファイアウォールで ポート 8000 を開放（LINE Webhook）
- [ ] ポート 5555 が 127.0.0.1 でリッスン可能（ZeroMQ）
- [ ] GitHub API への接続確認

---

## 🚀 デプロイ手順

### ステップ 1: リポジトリクローン

```bash
cd /home/planj
git clone https://github.com/your-username/Claude-Code-Communication.git
cd Claude-Code-Communication
```

### ステップ 2: デプロイスクリプト実行

```bash
# 実行権限を付与
chmod +x deploy.sh

# デプロイスクリプト実行（本番環境）
./deploy.sh production

# または開発環境
./deploy.sh development
```

**実行内容**:
- ✅ Python 仮想環境作成
- ✅ 依存パッケージインストール
- ✅ ディレクトリ構造作成
- ✅ 権限設定
- ✅ 環境別設定適用

### ステップ 3: 環境変数設定

```bash
# .env ファイルをエディタで開く
nano .env

# または
vim .env
```

**必須項目**を設定：

```bash
# LINE 設定
LINE_CHANNEL_SECRET=<LINE Channel Secret>
LINE_CHANNEL_ACCESS_TOKEN=<LINE Channel Access Token>

# GitHub 設定
GITHUB_TOKEN=<GitHub Personal Access Token>
GITHUB_REPO=owner/repository

# OpenAI 設定
OPENAI_API_KEY=<OpenAI API Key>
```

### ステップ 4: 依存パッケージインストール確認

```bash
# 仮想環境をアクティベート
source venv/bin/activate

# パッケージ確認
pip list | grep -E "fastapi|github|zmq"
```

### ステップ 5: テスト実行

```bash
# ユニットテスト実行
python3 -m pytest tests/test_line_github_integration.py -v

# 期待される結果: 11/11 テスト成功
```

---

## 🎯 起動方法

### 方法 A: 手動起動（開発・テスト用）

```bash
# 実行権限を付与
chmod +x start-integration.sh

# 開発環境で起動（ログを表示）
./start-integration.sh development manual

# または本番環境
./start-integration.sh production manual
```

**表示されるログ**:
```
ℹ️  A2A システム起動中...
✅ ZeroMQ Message Broker Starting...
✅ GPT-5 Worker [gpt5_001] initialized
ℹ️  LINE Webhook Handler 起動中...
✅ Uvicorn running on http://0.0.0.0:8000
ℹ️  GitHub Issue Creator 起動中...
📡 /a2a_system/shared/claude_inbox を監視中...
ℹ️  LINE Notifier 起動中...
📡 /a2a_system/shared/claude_outbox を監視中...
```

### 方法 B: systemd で起動（本番環境推奨）

```bash
# 実行権限を付与
chmod +x start-integration.sh

# systemd で起動
sudo ./start-integration.sh production systemd

# ステータス確認
sudo systemctl status claude-a2a.service

# ログ確認
sudo journalctl -u claude-a2a.service -f

# 自動起動を有効化
sudo systemctl enable claude-a2a.service

# 停止
sudo systemctl stop claude-a2a.service
```

---

## 🧪 動作確認

### テスト 1: Webhook ヘルスチェック

```bash
curl -X GET http://localhost:8000/health

# 期待される応答:
# {"status":"healthy","timestamp":"2025-10-18T17:50:00.000000"}
```

### テスト 2: LINE から実際に送信

1. LINE で任意のメッセージを送信
2. GitHub の Issues タブで Issue が自動作成されたか確認
3. Issue にコメントが投稿されているか確認
4. LINE で完了通知を受け取ったか確認

### テスト 3: ログで確認

```bash
# Webhook ログ
tail -f line_webhook_handler.log

# Issue Creator ログ
tail -f github_issue_creator.log

# Line Notifier ログ
tail -f line_notifier.log

# すべてのログ
tail -f *.log
```

---

## 📊 サービス起動構成

### systemd サービスツリー

```
claude-a2a.service (メイン)
├─ claude-webhook.service (LINE Webhook)
├─ claude-github-creator.service (GitHub Issue Creator)
└─ claude-line-notifier.service (LINE Notifier)
```

### サービス管理コマンド

```bash
# 全サービス起動
sudo systemctl start claude-a2a.service

# 全サービス停止
sudo systemctl stop claude-a2a.service

# 個別サービス起動
sudo systemctl start claude-webhook.service
sudo systemctl start claude-github-creator.service
sudo systemctl start claude-line-notifier.service

# ステータス確認
sudo systemctl status claude-a2a.service
sudo systemctl status claude-webhook.service

# ジャーナルログ確認
sudo journalctl -u claude-webhook.service -n 50 -f
```

---

## 🔍 トラブルシューティング

### 問題 1: LINE Webhook 接続拒否

**症状**: `Connection refused` エラー

**原因**: ファイアウォール設定、ポート占有

**対策**:
```bash
# ポート確認
lsof -i :8000

# ファイアウォール開放（Ubuntu）
sudo ufw allow 8000/tcp

# プロセス確認
ps aux | grep webhook
```

### 問題 2: GitHub Issue 作成失敗

**症状**: Issue が作成されない

**原因**: GitHub Token 期限切れ、権限不足

**対策**:
```bash
# Token を再生成
# GitHub Settings → Developer settings → Personal access tokens

# .env に新しい Token を設定
# GITHUB_REPO が正しいか確認
```

### 問題 3: LINE 通知が届かない

**症状**: Issue 完了しても通知が来ない

**原因**: ユーザーID 不一致、LINE Token 期限切れ

**対策**:
```bash
# Issue に記載されているユーザーID を確認
grep "ユーザーID" /a2a_system/shared/claude_inbox/line_message_*.json

# LINE Token を再取得
```

### 問題 4: A2A 通信エラー

**症状**: GPT-5 が応答しない

**原因**: Broker 未起動、ネットワークエラー

**対策**:
```bash
# Broker が起動しているか確認
ps aux | grep broker.py

# ポート確認
netstat -tuln | grep 5555

# Broker ログ確認
tail -f /tmp/broker_fresh.log
```

---

## 📈 本番環境設定

### ログローテーション

```bash
# /etc/logrotate.d/claude-code に以下を追加
/home/planj/Claude-Code-Communication/logs/*.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 0640 planj planj
}
```

### バックアップ設定

```bash
# 日次バックアップスクリプト
#!/bin/bash
BACKUP_DIR="/backup/claude-code"
mkdir -p "$BACKUP_DIR"
tar czf "$BACKUP_DIR/$(date +%Y%m%d).tar.gz" \
    /home/planj/Claude-Code-Communication/a2a_system/shared/
```

### モニタリング設定

```bash
# システムヘルスチェックスクリプト
#!/bin/bash
# サービスのヘルスチェック
curl -s http://localhost:8000/health | jq .

# ディスク容量確認
df -h /home/planj

# メモリ使用率確認
free -h
```

---

## 📝 パフォーマンスチューニング

### ZeroMQ 最適化

```bash
# /etc/security/limits.conf に追加
planj soft nofile 65536
planj hard nofile 65536

# システム設定
sysctl -w net.core.rmem_max=134217728
sysctl -w net.core.wmem_max=134217728
```

### Python ワーカー最適化

```bash
# uvicorn ワーカー数設定
# start-integration.sh を編集して以下を追加
--workers 4  # CPU コア数に合わせる
```

---

## 🆘 サポート

### ログ収集（トラブル報告時）

```bash
# 全ログをアーカイブ
tar czf claude-logs.tar.gz \
  line_webhook_handler.log \
  github_issue_creator.log \
  github_action_handler.log \
  line_notifier.log \
  /tmp/broker_fresh.log \
  a2a_system/gpt5_worker_fresh.log \
  a2a_system/claude_bridge.log
```

### 重要なファイル位置

```
プロジェクトディレクトリ: /home/planj/Claude-Code-Communication
設定ファイル: .env
ログディレクトリ: ./logs
A2A ディレクトリ: ./a2a_system/shared
コンテキスト: ./a2a_system/shared/context_storage
パターン: ./a2a_system/shared/learned_patterns
Inbox: ./a2a_system/shared/claude_inbox
Outbox: ./a2a_system/shared/claude_outbox
```

---

## ✅ デプロイ完了チェック

本番環境で以下を確認してください：

- [ ] 全サービスが起動している
- [ ] ログに エラーが出ていない
- [ ] LINE から メッセージ送信で Issue が作成される
- [ ] Issue のコメントが 投稿される
- [ ] LINE ユーザーに 通知が届く
- [ ] システムは 24時間 稼働している
- [ ] ディスク容量に 余裕がある

---

## 🎊 完成

**デプロイが正常に完了しました！**

LINE からのユーザー指示が、完全に自動化されたパイプラインで処理されます。

---

**ステータス**: ✅ **PRODUCTION DEPLOYED**
**開始日時**: 2025-10-18
**完了日時**: 2025-10-18 17:50:00 UTC
