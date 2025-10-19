# Worker3 再開チェックリスト

**最終更新**: 2025-10-19 10:25
**前回落ちた時刻**: Oct 18 20:59:35
**復帰時刻**: Oct 19 10:12:37

---

## 🚀 即座に実行するコマンド

```bash
# 1. プロジェクト状態確認
cd /home/planj/Claude-Code-Communication
git status
git log --oneline -5

# 2. tmux セッション確認
tmux list-panes -t gpt5-a2a-line -a

# 3. プロセス確認
ps aux | grep -E "line|webhook" | grep -v grep

# 4. ポート確認
lsof -i :5000 || echo "lsof not available"

# 5. LINE メッセージ確認
ls -lah a2a_system/shared/claude_inbox/line_message_*.json | tail -3

# 6. Hook フラグ確認
ls -la /tmp/claude_code_line_notification.flag
```

---

## 📊 現在の状態（Oct 19 10:25 現在）

| 項目 | 状態 | 備考 |
|------|------|------|
| Git コミット | ✅ `WORKER3_4PANE_MIGRATION.md` 追加 | このドキュメントで進捗管理 |
| tmux セッション | ✅ 4ペイン稼働中 | 0.0:GPT-5, 0.1:Worker3✓, 0.2:LINE Bridge, 0.3:Tail |
| line-to-claude-bridge.py | ✅ ポート5000稼働 | PID 19169 (Oct 19 10:12起動) |
| line_notifier.py | ✅ 稼働中 | PID 9025 |
| **line_webhook_handler.py** | ❌ **起動していない** | 👈 **最初の問題** |
| LINE メッセージ受け取り | ❌ **Oct 18 20:58 以降なし** | 👈 **確認必要** |
| Hook 通知フラグ | 🟡 古い (Oct 18 20:56) | 更新されていない |

---

## 🔧 Phase 1: ポート5000競合を解決する（最優先）

### 問題
- `line-to-claude-bridge.py` がポート5000で稼働中
- `line_webhook_handler.py` も5000で起動しようとして失敗
- ❌ `ERROR: [Errno 98] error while attempting to bind on address ('0.0.0.0', 5000): address already in use`

### 解決策

**Option A: line_webhook_handler を別ポート (5001) に変更（推奨・簡単）**

```bash
# 1. line_webhook_handler.py を編集
vim bridges/line_webhook_handler.py

# 2. 以下の行を修正
# Line 406: port=5000 → port=5001
#     uvicorn.run(
#         app,
#         host="0.0.0.0",
#         port=5001,  # ← ここを変更
#         log_level="info"
#     )

# 3. LINE Webhook URL を更新（GitHub Webhook設定）
# GitHub → Settings → Webhooks
# Payload URL: https://your-domain.com/webhook
# Port: 5001 に変更する（または ngrok 等でフォワード設定）
```

**Option B: line-to-claude-bridge を停止して line_webhook_handler のみ使用（より大きな変更）**

```bash
# start-small-team.sh を編集してbridge起動を削除
# ただし 2ペイン → 4ペイン 構成のため非推奨
```

### テスト
```bash
# 1. プロセス再起動
pkill -f line_webhook_handler
pkill -f line-to-claude-bridge

./start-small-team.sh

# 2. ポート確認
lsof -i :5000
lsof -i :5001

# 3. LINE からテスト送信
# LINE で「テスト1」と送信

# 4. 受け取り確認
tail -20 line_webhook_handler.log

# Expected: ✅ 署名検証成功 / ✅ HOOK 通知フラグ作成
```

---

## 📋 Phase 1 完了条件

✅ LINE からメッセージ送信 → 即座に「✅ 受付完了」が返ってくる

この状態になったら、`WORKER3_4PANE_MIGRATION.md` の **Phase 2** に進んでください。

---

## 💾 参考資料

- 詳細な進捗: `WORKER3_4PANE_MIGRATION.md` 参照
- GitHub Actions ワークフロー: `.github/workflows/` 参照
- 4ペイン構成: `.tmux.conf` 参照

---

## ❓ トラブルシューティング

### Q: line_webhook_handler.py が起動時に署名検証エラーで落ちる
A: `.env` に正しい `LINE_CHANNEL_SECRET` が設定されているか確認

```bash
cat line_integration/.env | grep LINE_CHANNEL_SECRET
```

### Q: LINE から送信しても何も返ってこない
A: 以下を確認

```bash
# 1. Webhook ハンドラログ確認
tail -50 line_webhook_handler.log | grep ERROR

# 2. ポート確認
lsof -i :5001

# 3. LINE Webhook URL の設定確認
# GitHub Webhook → Payload URL が正しいか
```

### Q: GitHub Issue が作成されない
A: Phase 1 が完了していることを確認してから Phase 2 に進んでください

---

**次のステップ**: Option A を実装してテストしてください
