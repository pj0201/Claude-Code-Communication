# LINE自動検知システム

## 概要
Claude Code CLIでLINEメッセージを自動的に検知・表示するハイブリッドシステム

## システム構成

### 必要ファイル（現行システム）
- `line_notification_monitor.sh` - tmux新ペインで実行、LINE通知をリアルタイム監視
- `watch_line_triggers.sh` - バックグラウンドでトリガーファイル監視
- `check_line_notifications.sh` - トリガーファイルからLINE通知を表示
- `line_notification_hook.sh` - Claude Code hookスクリプト
- `start-gpt5-with-a2a.sh` - システム起動スクリプト（自動起動設定済み）

### 設定ファイル
- `~/.claude/hooks/user-prompt-submit.sh` - Claude Code自動実行hook

## 動作フロー

1. **LINE受信** → LINE Message Handler処理
2. **A2Aシステム** → claude_outbox/notification_line_*.json作成
3. **tmux新ペイン** → line_notification_monitor.shが検知・表示
4. **トリガー作成** → /tmp/line_trigger_*.trigger
5. **監視スクリプト** → watch_line_triggers.shが検知
6. **ログ記録** → /tmp/line_notifications.log
7. **ユーザー入力時** → hookが自動実行
8. **通知表示** → Claude Code内に表示！

## 起動方法

```bash
# システム全体起動
./start-gpt5-with-a2a.sh

# 手動でLINE通知確認
./line_notification_hook.sh
```

## 特徴

- ✅ リアルタイム検知（inotifywait使用）
- ✅ Claude Code制約を回避（ハイブリッド方式）
- ✅ 自動起動設定済み
- ✅ ユーザー入力時に自動通知
- ✅ OS非依存
- ✅ GPT-5と合意済みのアーキテクチャ

## 削除した旧ファイル
- line_socket_client.py - Unix Socket実装（非実用的）
- line_socket_server.py - Unix Socket実装（非実用的）
- realtime_line_monitor.py - 初期実装（非効率）
- line_poll_monitor.sh - ポーリング方式（リアルタイム性欠如）
- line_realtime_processor.py - 中間実装
- line_notifier.sh - 旧通知スクリプト
- gpt5_direct_discussion*.py - 一時的な議論用スクリプト

## 2025-10-13 実装完了
- Ultra Think実施
- GPT-5との壁打ち完了
- 実際のLINEメッセージ受信テスト成功