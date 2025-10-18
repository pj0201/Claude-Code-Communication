# LINE メッセージ処理ガイド

## 問題

LINEからメッセージを送信しても、Claude Code Bridgeに表示されていない。

## 原因分析

### 1. Claude Code Listener が起動していない
**ファイル**: `/home/planj/Claude-Code-Communication/a2a_system/bridges/claude_code_listener.py`

Claude Code Listener は、A2Aシステムのメッセージをリアルタイムで監視・表示するためのプロセスです。ただし、起動スクリプトに統合されていません。

### 2. LINEメッセージフロー

```
LINEアプリ
  ↓ (ユーザーがメッセージ送信)
LINE Bot API
  ↓ (Webhook → Flask)
line-to-claude-bridge.py (/webhook エンドポイント)
  ↓ (JSON ファイル作成)
/a2a_system/shared/claude_inbox/{message_id}.json
  ↓ (監視・表示)
claude_code_listener.py
  ↓ (ターミナルに表示)
Claude Code セッション
```

### 3. 修正内容

#### (1) Claude Code Listener に `text` フィールド対応を追加
**修正**: `claude_code_listener.py:80-81行目`

LINE Bridge は `text` フィールドでメッセージを送信しますが、Claude Code Listener が処理していませんでした。

修正：
```python
if message.get('text'):
    print(f"テキスト:\n{message.get('text')}")
```

#### (2) ファイル移動エラー対応を改善
**修正**: `claude_code_listener.py:130-152行目`

処理済みファイルを `processed/` フォルダに移動する際のエラーハンドリングを改善：
- 移動前のファイル存在確認
- エラー時の詳細ログ出力
- リトライ機能の追加

## 使用方法

### 1. Claude Code Listener を起動

```bash
python3 /home/planj/Claude-Code-Communication/a2a_system/bridges/claude_code_listener.py
```

または、バックグラウンド実行：

```bash
python3 /home/planj/Claude-Code-Communication/a2a_system/bridges/claude_code_listener.py > /tmp/claude_listener.log 2>&1 &
```

### 2. LINEからメッセージ送信

LINE Official Account経由でメッセージを送信すると、以下のように表示されます：

```
======================================================================
💬 【A2Aメッセージ受信】
======================================================================
送信者: line_user
型式: LINE_MESSAGE
テキスト:
[LINEメッセージのテキストがここに表示]
======================================================================
💭 応答メッセージを作成してください（Ctrl+Dで終了）:
======================================================================

[ユーザーが応答メッセージを入力]
Ctrl+D を押して応答を送信
```

### 3. 応答メッセージの入力

複数行対応：

```
この分析の結果をまとめました。

以下が主なポイントです：
1. 最初のポイント
2. 次のポイント
3. 最後のポイント

何かご不明な点はあればお知らせください。
```

`Ctrl+D` を押すと応答メッセージが送信されます。

## トラブルシューティング

### メッセージが表示されない場合

1. **Claude Code Listener が起動しているか確認**
   ```bash
   ps aux | grep claude_code_listener
   ```

2. **LINE Inbox にファイルが作成されているか確認**
   ```bash
   ls -lah /home/planj/Claude-Code-Communication/a2a_system/shared/claude_inbox/
   ```

3. **Claude Code Listener のログを確認**
   ```bash
   tail -f claude_code_listener.log
   ```

4. **ファイルが `processed/` フォルダに移動しているか確認**
   ```bash
   ls -lah /home/planj/Claude-Code-Communication/a2a_system/shared/claude_inbox/processed/
   ```

### ファイル移動エラーが出る場合

1. **`processed/` フォルダの権限を確認**
   ```bash
   ls -ld /home/planj/Claude-Code-Communication/a2a_system/shared/claude_inbox/processed/
   ```

2. **ディスク容量を確認**
   ```bash
   df -h /home/planj/Claude-Code-Communication/
   ```

3. **ファイルシステムの状態を確認**
   ```bash
   fsck -n /
   ```

## 統合提案

Claude Code Listener をスモールチーム起動スクリプトに統合することを検討してください：

```bash
# start-small-team.sh に追加
# Claude Code Listener をバックグラウンド起動
python3 /home/planj/Claude-Code-Communication/a2a_system/bridges/claude_code_listener.py >> /tmp/claude_listener.log 2>&1 &
LISTENER_PID=$!
```

## 関連ファイル

- **LINE Bridge**: `/home/planj/Claude-Code-Communication/line_integration/line-to-claude-bridge.py`
- **Claude Code Listener**: `/home/planj/Claude-Code-Communication/a2a_system/bridges/claude_code_listener.py`
- **A2Aシステム**: `/home/planj/Claude-Code-Communication/a2a_system/`
- **メッセージプロトコル**: `/home/planj/Claude-Code-Communication/a2a_system/shared/message_protocol.py`
