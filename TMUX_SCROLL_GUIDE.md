# TMUXペイン スクロール&ログ閲覧ガイド

**Status**: ✅ 実装完了
**Date**: 2025-10-19
**Purpose**: Claude Code出力のロングコンテキスト履歴を遡って確認

---

## 🎯 概要

Claude CodeがTMUXペイン0.1で実行される際、以下の3つの方法でスクロール履歴を確認できます：

1. **TMUXペイン内スクロール（リアルタイム）** - ペイン内で直接スクロール
2. **自動ログ記録（バックグラウンド）** - 全セッション履歴を自動保存
3. **ログ閲覧ツール（事後確認）** - 保存済みログを検索・表示

---

## 1️⃣ TMUXペイン内スクロール（推奨：リアルタイム確認）

### コピーモード（スクロール対応）を有効化

ペイン0.1がアクティブな状態で：

```bash
# コピーモードに入る（TMUXプレフィックス + [）
Ctrl+b [

# または、設定済みのショートカット
Alt+b [
```

### コピーモード内での操作

```
上スクロール:     PageUp / Shift+PageUp / ↑矢印
下スクロール:     PageDown / Shift+PageDown / ↓矢印
上へ素早く移動:   Home キー
下へ素早く移動:   End キー
一行ずつ移動:     ↑ / ↓ 矢印キー

テキスト検索:     / (フォワード検索)
                ? (バックワード検索)
                n (次の結果)
                N (前の結果)

テキスト選択:     Space で開始
                Enter で確定・コピー
                Esc でキャンセル
```

### コピーモード終了

```bash
# q キーまたは Esc で終了
q
```

### 例：最新100行を見たい場合

```
1. Ctrl+b [ でコピーモード開始
2. PageUp を何度か押して履歴を遡る
3. / で検索（例：「エラー」「完了」など）
4. q で終了
```

---

## 2️⃣ 自動ログ記録（バックグラウンド）

### ログ記録の開始

```bash
# TMUXセッション内（例：ペイン0.0）で実行
/home/planj/Claude-Code-Communication/bin/capture-claude-logs &

# または
cd /home/planj/Claude-Code-Communication
./bin/capture-claude-logs &
```

### ログ記録の仕組み

- **ログディレクトリ**: `/home/planj/Claude-Code-Communication/logs/`
- **ログファイル名**: `claude_code_session_YYYYMMDD_HHMMSS.log`
- **記録間隔**: 5秒ごと（ペイン内容に変化がある場合のみ）
- **スクロール履歴**: 50,000行まで保存（`.tmux.conf`設定）

### ログ記録の自動化

`start-small-team.sh`で自動開始：

```bash
./start-small-team.sh  # 起動時に自動的にログ記録開始
```

---

## 3️⃣ ログ閲覧ツール（事後確認・検索）

### 最新セッションログを表示

```bash
# 最新ログをlessで表示（スクロール可能）
view-claude-logs

# または最後の50行のみ表示
view-claude-logs tail
```

### ログの一覧表示

```bash
# 全セッションログを一覧表示
view-claude-logs list

# 出力例:
# 📋 Claude Code Session Logs:
#
# /home/planj/.../logs/claude_code_session_20251019_121746.log (45K)
# /home/planj/.../logs/claude_code_session_20251019_122556.log (120K)
```

### ログ内で検索

```bash
# 特定の単語を検索
view-claude-logs grep "エラー"
view-claude-logs grep "完了"
view-claude-logs grep "Issue #"

# 出力例:
# 🔍 Searching for: Issue #
#
# 12:15:47 === Issue #18 作成完了 ===
# 12:16:02 === Issue #19 作成完了 ===
```

### ログ内でのインタラクティブ検索

```bash
# ログを開く
view-claude-logs

# less内でコマンド実行
/検索キーワード      # フォワード検索（例：/エラー）
?検索キーワード      # バックワード検索
n                   # 次の結果
N                   # 前の結果
```

---

## 📊 使い分けガイド

| 用途 | 方法 | 長所 | 短所 |
|------|------|------|------|
| **リアルタイム確認** | TMUXコピーモード | 即座に確認できる | ペイン内の見える範囲のみ |
| **セッション全体記録** | 自動ログ記録 | 永続保存・検索可能 | 5秒の遅延あり |
| **事後検索** | ログ閲覧ツール | 高速検索・grep対応 | リアルタイムではない |

**推奨フロー**：
1. 🚀 システム起動 → 自動ログ記録開始
2. 📝 リアルタイムで見たい → TMUXコピーモード
3. 🔍 後で検索 → ログ閲覧ツール

---

## 🔧 トラブルシューティング

### Q: コピーモードが開かない

```bash
# TMUXセッションが起動しているか確認
tmux list-sessions

# セッション内のペイン確認
tmux list-panes -t gpt5-a2a-line
```

### Q: ログが記録されていない

```bash
# キャプチャプロセスが起動しているか確認
ps aux | grep capture-claude-logs

# 手動で再起動
/home/planj/Claude-Code-Communication/bin/capture-claude-logs &
```

### Q: ログが大きくなりすぎた

```bash
# 古いログを削除（1週間以上前のみ保持）
find /home/planj/Claude-Code-Communication/logs -name "*.log" -mtime +7 -delete

# または全ログクリア
rm /home/planj/Claude-Code-Communication/logs/claude_code_session_*.log
```

### Q: スクロール履歴の行数を変更したい

```bash
# .tmux.conf を編集
vi /home/planj/Claude-Code-Communication/.tmux.conf

# history-limit の値を変更（デフォルト: 50000）
set -g history-limit 100000

# TMUXに反映
tmux source-file ~/.tmux.conf
# または
tmux send-keys -t gpt5-a2a-line 'r'  # Ctrl+b r で再ロード
```

---

## 📋 クイックリファレンス

```bash
# ============ TMUXペイン内操作 ============
Ctrl+b [              # コピーモード開始
PageUp / PageDown     # スクロール
/ テキスト           # 検索
q                     # 終了

# ============ ログ記録コマンド ============
capture-claude-logs &  # ログ記録開始
kill %1               # ログ記録停止

# ============ ログ閲覧コマンド ============
view-claude-logs                # 最新ログ表示
view-claude-logs list           # ログ一覧
view-claude-logs tail           # 最後の50行
view-claude-logs grep "キーワード"  # ログ検索
```

---

## ✅ システム影響

- ✅ 既存のLINE→GitHub→Claude Codeシステムに**影響なし**
- ✅ スクロール履歴は非侵襲的（ペイン内容に変更なし）
- ✅ ログ記録は別プロセス（メモリ使用量は最小限）
- ✅ 既存のTMUXバインキーと競合しない

---

**Last Updated**: 2025-10-19
**Status**: ✅ 本番運用対応
