# LINE Bridge 運用ガイド

## 現状の問題

❌ **都度起動している**
- 手動でLINE Bridgeを起動
- プロセスが落ちても気づかない
- 不安定な運用

## 解決策の選択肢

### オプション1: 常時起動（推奨 - 即座に実装可能）

**起動方法**:
```bash
/home/planj/claudecode-wind/line-integration/start-line-bridge.sh
```

**特徴**:
- ✅ シンプル（追加実装不要）
- ✅ 即座に運用開始
- ✅ 自動再起動（nohup + disown）
- ⚠️ 手動起動が必要

**自動起動（systemd）**:
```bash
# サービスファイルをコピー
sudo cp /home/planj/claudecode-wind/line-integration/line-bridge.service /etc/systemd/system/

# サービス有効化
sudo systemctl enable line-bridge
sudo systemctl start line-bridge

# 状態確認
sudo systemctl status line-bridge
```

---

### オプション2: アーキテクチャ再設計

**変更内容**:

#### 現状のアーキテクチャ
```
LINE → LINE Bridge (Flask) → inbox/line_*.json
                              ↓
                        Claude Bridge → notification
                              ↓
                        LINE Handler → response
                              ↓
                        LINE Bridge (threading) → LINE
```

**問題点**:
1. LINE Bridgeが単一障害点
2. スレッド管理が複雑
3. 応答ファイルとLINEメッセージの紐付けが不安定

#### 改善案A: メッセージキュー導入
```
LINE → LINE Bridge → Redis Queue
                          ↓
                     Worker (Celery)
                          ↓
                     Claude Code
                          ↓
                     Redis Queue → LINE Bridge → LINE
```

**メリット**:
- 分散処理可能
- 耐障害性向上
- スケーラブル

**デメリット**:
- Redis, Celery のセットアップ必要
- 複雑度増加

#### 改善案B: Webhook → 直接処理
```
LINE → ngrok → LINE Bridge (軽量)
                    ↓
               Claude Code API (FastAPI)
                    ↓
               push_message → LINE
```

**メリット**:
- シンプル
- 応答が直接的
- デバッグしやすい

**デメリット**:
- Claude Code側にAPIサーバー必要

---

## 推奨アプローチ

### フェーズ1: 常時起動（即座）✅
```bash
/home/planj/claudecode-wind/line-integration/start-line-bridge.sh
```

### フェーズ2: 監視追加（1週間後）
```bash
# cron で定期チェック
*/5 * * * * /home/planj/claudecode-wind/line-integration/check-line-bridge.sh
```

### フェーズ3: アーキテクチャ再設計（必要に応じて）
- 利用状況を1ヶ月観察
- 問題が頻発する場合のみ再設計

---

## 運用コマンド

### 起動
```bash
/home/planj/claudecode-wind/line-integration/start-line-bridge.sh
```

### 状態確認
```bash
ps aux | grep line-to-claude-bridge
```

### ログ確認
```bash
tail -f /home/planj/claudecode-wind/line-integration/line_bridge.log
```

### 停止
```bash
pkill -f line-to-claude-bridge.py
```

### 再起動
```bash
pkill -f line-to-claude-bridge.py
sleep 2
/home/planj/claudecode-wind/line-integration/start-line-bridge.sh
```

---

## トラブルシューティング

### LINE Bridgeが起動しない
```bash
# ポート確認
lsof -i:5000

# 既存プロセス削除
pkill -f line-to-claude-bridge.py

# 再起動
./start-line-bridge.sh
```

### メッセージが届かない
```bash
# ログ確認
tail -50 line_bridge.log

# Claude Bridge確認
ps aux | grep claude_bridge

# LINE Handler確認
ps aux | grep line_message_handler
```

---

**最終更新**: 2025-10-12
**推奨**: まずフェーズ1で常時起動、様子を見て必要なら再設計
