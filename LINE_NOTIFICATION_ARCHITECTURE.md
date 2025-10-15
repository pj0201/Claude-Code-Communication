# LINE通知システム - Slack-GitHub統合パターン実装

## 概要
Slack-GitHub統合と同じアーキテクチャパターンを採用し、Claude Code CLIの制約（passive/reactive）を克服したリアルタイム通知システム。

## アーキテクチャ図

```
┌─────────────────────────────────────────────────────────────┐
│ LINE Webhook API                                             │
│ (ユーザーがLINEでメッセージ送信)                            │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────────────────────────┐
│ LINE Bridge                                                  │
│ - Webhookを受信                                             │
│ - JSON形式でファイル作成                                    │
│   /shared/claude_inbox/line_*.json                          │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────────────────────────┐
│ Claude Bridge                                                │
│ - watchdogでinbox監視                                       │
│ - notification_line_*.jsonをoutboxに作成                    │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────────────────────────┐
│ line_notification_daemon.py ← THIS IS THE KEY!              │
│ - watchdogでoutbox監視（Claude Code CLI外で独立動作）      │
│ - 新着ファイル検出時:                                       │
│   1. ZeroMQ PUSH通知（最優先 - Slack-GitHub pattern）      │
│   2. tmux status bar変更                                    │
│   3. アラートファイル書き込み                              │
│   4. デスクトップ通知                                       │
└────────────────┬────────────────────────────────────────────┘
                 │ ZeroMQ PUSH/PULL
                 │ (tcp://localhost:5556)
                 ↓
┌─────────────────────────────────────────────────────────────┐
│ tmux_notification_display.py                                 │
│ - tmux別ペインで常時動作                                   │
│ - ZeroMQ PULL socket待機                                    │
│ - 受信時に視覚的表示:                                       │
│   ✅ 画面全体に通知表示（赤背景）                          │
│   ✅ 通知音再生                                             │
│   ✅ tmuxステータスバー点滅                                │
│   ✅ 通知履歴表示（最新10件）                              │
└────────────────┬────────────────────────────────────────────┘
                 │ (視覚的通知 - ユーザーは何もしなくても見える)
                 ↓
┌─────────────────────────────────────────────────────────────┐
│ Claude Code CLI                                              │
│ - user-prompt-submit時にhook実行                            │
│ - line_notification_hook.sh:                                │
│   1. /tmp/line_alert_for_claude.txt チェック               │
│   2. notification_line_*.json チェック                      │
└─────────────────────────────────────────────────────────────┘
```

## Slack-GitHub統合との対比

| Slack-GitHub統合 | LINE通知システム |
|-----------------|-----------------|
| GitHub Webhook | LINE Webhook |
| Slack API push | ZeroMQ PUSH |
| Slackアプリで自動表示 | tmuxペインで自動表示 |
| ユーザーは何もしなくてよい | ユーザーは何もしなくてよい |
| リアルタイム通知 | リアルタイム通知 |

## 重要ポイント

### 1. Claude Code CLIの制約を克服
**問題**: Claude Code CLIはpassive/reactiveシステムで自己トリガー不可

**解決**:
- `line_notification_daemon.py`が**Claude Code CLI外で独立動作**
- watchdogで能動的にファイル監視
- ZeroMQ PUSHで`tmux_notification_display.py`にpush型通知
- tmux別ペインで視覚的に表示 → **ユーザーが何もしなくても通知に気づく**

### 2. ZeroMQ PUSH/PULLパターンの採用
**理由（GPT-5の推奨）**:
- 特定ターゲット（tmux通知ペイン）への直接送信
- メッセージ配信の保証
- PUB/SUBよりも適切（ブロードキャスト不要）
- 別ポート（5556）で既存broker.py（5555）と分離

### 3. 多層防御の通知システム
1. **ZeroMQ PUSH** - リアルタイム通知（Slack-GitHub pattern）
2. **tmuxステータスバー** - 視覚的フィードバック
3. **アラートファイル** - Claude Code hookで読み取り
4. **デスクトップ通知** - Linux notify-send

## ファイル構成

```
Claude-Code-Communication/
├── start-line-notification-system.sh    # システム起動スクリプト
├── test-line-notification.sh            # テストスクリプト
├── line_notification_hook.sh            # Claude Code hook
├── LINE_NOTIFICATION_ARCHITECTURE.md    # このファイル
└── a2a_system/
    ├── line_notification_daemon.py      # 監視デーモン（独立動作）
    ├── tmux_notification_display.py     # tmux通知ペイン
    ├── claude_bridge.py                 # Claude Bridge
    └── shared/
        ├── claude_inbox/                # 受信ディレクトリ
        └── claude_outbox/               # 送信ディレクトリ
            └── read/                    # 処理済み
```

## 使用方法

### 1. システム起動
```bash
cd /home/planj/Claude-Code-Communication
./start-line-notification-system.sh
```

これにより:
- tmux新ウィンドウ `line-notifications` 作成
- `tmux_notification_display.py` 起動（ZeroMQ PULL待機）
- `line_notification_daemon.py` バックグラウンド起動（watchdog監視）

### 2. 動作確認
```bash
# プロセス確認
ps aux | grep -E '(line_notification|tmux_notification)'

# tmux通知ペインに切り替え
tmux select-window -t line-notifications

# ログ確認
tail -f /tmp/line_daemon.log
```

### 3. テスト実行
```bash
./test-line-notification.sh
```

シミュレーションファイルを作成し、通知システム全体をテスト。
tmux通知ペインに視覚的通知が表示されることを確認。

### 4. システム停止
```bash
# デーモン停止
pkill -f line_notification_daemon

# 通知ディスプレイ停止
pkill -f tmux_notification_display

# または tmuxウィンドウを閉じる
tmux kill-window -t line-notifications
```

## GPT-5との壁打ち結果

### 第1ラウンド
**質問**: Slack-GitHub統合パターンをLINE通知に適用する方法

**GPT-5の回答**:
- ✅ ZeroMQのブローカー/ワーカーモデル
- ✅ 非同期通信の導入
- ✅ tmux環境の活用
- ✅ A2AシステムでのPUSH型通知

### 第2ラウンド
**質問**: 具体的な実装設計のレビュー

**GPT-5の評価**:
1. ✅ Slack-GitHub統合パターンと同等
2. ✅ Claude Code CLIの制約を克服
3. ✅ **PUSH/PULLパターンが適切**（PUB/SUBより）
4. ✅ tmux通知ペイン実装可能
5. ✅ **別ポート推奨**（既存brokerと分離）
6. ✅ 「ユーザーが何もしなくても検知している状態」実現可能

**改善点の指摘**:
- 通知音実装の具体化 → 実装済み（paplay/beep/afplay）
- ZeroMQ接続安定性の監視 → エラーハンドリング実装済み
- 再接続ロジックの強化 → ソケットリセット実装済み

### 合意結果
**完全合意（GPT-5）** - Slack-GitHub統合パターンの正確な実装

## トラブルシューティング

### 通知が表示されない
1. プロセス確認: `ps aux | grep line_notification`
2. ログ確認: `tail -f /tmp/line_daemon.log`
3. ZeroMQ接続確認: `netstat -an | grep 5556`
4. tmuxペイン確認: `tmux list-windows`

### ZeroMQ接続エラー
```bash
# ポート使用状況確認
lsof -i :5556

# tmux_notification_display.pyを先に起動
python3 /home/planj/Claude-Code-Communication/a2a_system/tmux_notification_display.py

# その後デーモン起動
python3 /home/planj/Claude-Code-Communication/a2a_system/line_notification_daemon.py
```

### tmuxウィンドウが作成されない
```bash
# 手動で作成
tmux new-window -n "line-notifications"
python3 /home/planj/Claude-Code-Communication/a2a_system/tmux_notification_display.py
```

## 技術スタック

- **Python 3.8+**
- **ZeroMQ (pyzmq)** - PUSH/PULL通信
- **watchdog** - ファイルシステム監視
- **tmux** - 多重ウィンドウ管理
- **JSON** - メッセージフォーマット
- **Bash** - システム統合スクリプト

## 今後の拡張

1. **LINE自動返信機能** - gpt5_worker.pyの`_send_line_message()`統合
2. **通知履歴の永続化** - SQLiteデータベース導入
3. **複数LINEアカウント対応** - user_id別の通知管理
4. **Web UI** - ブラウザでの通知確認インターフェース
5. **メトリクス監視** - 通知送信成功率・遅延時間の可視化

## まとめ

このシステムは、Slack-GitHub統合と同じアーキテクチャパターンを採用し:
- ✅ Claude Code CLIの制約（passive）を完全に克服
- ✅ リアルタイム通知の実現
- ✅ ユーザーが何もしなくても通知に気づく
- ✅ GPT-5との壁打ちで完全合意

**「完璧ちゃうわ！」と言われない確実な実装**を目指しました。
