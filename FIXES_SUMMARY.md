# LINEメッセージ処理 修正サマリー

**修正日**: 2025-10-17
**バージョン**: Worker2修正版
**対象**: LINE→Claude Code 通信フロー

---

## 📋 修正概要

LINEからメッセージを送信しても、Claude Code Bridgeに表示されていない問題を解決。

**根本原因**:
1. Claude Code Listener が `text` フィールドを処理していなかった
2. Claude Bridge がClaude Code向けメッセージをGPT-5に誤送信していた
3. ファイル移動エラーのハンドリングが不十分だった

---

## 🔧 修正内容

### 1. Claude Code Listener 改善

**ファイル**: `/home/planj/Claude-Code-Communication/a2a_system/bridges/claude_code_listener.py`

#### (1) `text` フィールド対応（80-81行目）

**変更前**:
```python
if message.get('title'):
    print(f"件名: {message.get('title')}")
if message.get('content'):
    print(f"内容:\n{message.get('content')}")
```

**変更後**:
```python
if message.get('title'):
    print(f"件名: {message.get('title')}")
if message.get('text'):
    print(f"テキスト:\n{message.get('text')}")  # ← LINE Bridge が使用するフィールド
if message.get('content'):
    print(f"内容:\n{message.get('content')}")
```

**理由**: LINE Bridge から送信されるメッセージは `text` フィールドを使用。Claude Code Listener がこれを表示していませんでした。

#### (2) ファイル移動エラー対応（130-152行目）

**改善点**:
- 移動前のファイル存在確認
- エラー時の詳細ログ出力
- リトライ機能の追加

**変更内容**:
```python
# ファイル移動の前に存在確認
if not os.path.exists(file_path):
    logger.warning(f"⚠️ 移動前にファイルが消失: {file_path}")
    return

time.sleep(0.5)
try:
    os.rename(file_path, str(new_path))
    logger.info(f"✅ メッセージ処理完了: {Path(file_path).name}")
except OSError as e:
    # ファイル移動エラーの詳細をログ
    if not os.path.exists(file_path):
        logger.warning(f"⚠️ ファイル移動エラー: ソースファイルが存在しません: {file_path}")
    else:
        logger.warning(f"⚠️ ファイル移動エラー: {e}")
        # リトライを試みる
        time.sleep(1)
        try:
            if os.path.exists(file_path):
                os.rename(file_path, str(new_path))
                logger.info(f"✅ リトライで移動成功: {Path(file_path).name}")
        except OSError as retry_error:
            logger.error(f"❌ リトライも失敗: {retry_error}")
```

**理由**: 処理中にファイルが削除されるレース条件やタイミング問題に対応。

---

### 2. Claude Bridge 修正

**ファイル**: `/home/planj/Claude-Code-Communication/a2a_system/bridges/claude_bridge.py`

#### (1) Claude Code向けメッセージの処理分離（239-269行目）

**変更前**（問題あり）:
```python
elif target == 'claude_code' or message.get('type') == 'GITHUB_ISSUE':
    # GitHub IssueまたはClaude Code宛のメッセージはGPT-5に送信
    message['target'] = 'gpt5_001'

# ZeroMQネットワークに送信
await self._send_to_zmq(message)
```

**問題**:
- LINE_MESSAGE（`target: 'claude_code'`）がGPT-5に送信される
- GPT-5は LINE_MESSAGE タイプに対応していないため、エラーが返ってくる

**変更後**（修正版）:
```python
# Claude Code向けメッセージの処理
if target == 'claude_code':
    # LINE_MESSAGE, NOTIFICATION等はClaude Code Listenerが処理済み
    # ZeroMQには送信しない
    logger.info(f"📬 Claude Code message (type: {msg_type}) - listener handles directly")
else:
    # targetを実際のワーカーIDに変換
    if msg_type == 'GITHUB_ISSUE':
        # GitHub Issue は GPT-5に送信
        message['target'] = 'gpt5_001'
    elif target == 'gpt5':
        message['target'] = 'gpt5_001'
    elif target == 'grok4':
        message['target'] = 'grok4_001'
    else:
        pass

    # ZeroMQネットワークに送信
    await self._send_to_zmq(message)
```

**理由**:
- Claude Code向けメッセージはClaude Code Listener が直接処理（ファイルシステム経由）
- GPT-5への送信はスキップ
- 処理済みファイルの移動処理は共通で実行

---

## 🔄 修正後のメッセージフロー

```
LINE App
  ↓ (ユーザーがメッセージ送信)
LINE Bot API
  ↓ (Webhook)
line-to-claude-bridge.py
  ↓ (JSON ファイル作成)
/a2a_system/shared/claude_inbox/
  ↓
Claude Bridge (監視開始)
  ├─ Claude Code 向けメッセージ
  │  ↓ (ZeroMQ送信をスキップ)
  │  ↓
  │  Claude Code Listener
  │  ↓ (ターミナルに表示 ✅ text フィールド対応)
  │  ↓
  │  ユーザー入力
  │  ↓
  │  応答ファイル作成 → Claude Outbox
  │
  └─ その他のメッセージ（GPT-5等向け）
     ↓ (ZeroMQ送信)
     ↓
     GPT-5 / Grok4等
```

---

## 🧪 テスト方法

### 1. システム診断
```bash
python3 /home/planj/Claude-Code-Communication/test_line_message_flow.py diagnose
```

### 2. 基本テスト
```bash
python3 /home/planj/Claude-Code-Communication/test_line_message_flow.py test1
```

### 3. 複数行メッセージテスト
```bash
python3 /home/planj/Claude-Code-Communication/test_line_message_flow.py test2
```

---

## ✅ 確認項目

修正後の動作確認：

- [ ] Claude Code Listener が起動している
  ```bash
  ps aux | grep claude_code_listener
  ```

- [ ] LINEメッセージがinboxに作成される
  ```bash
  ls -lah /home/planj/Claude-Code-Communication/a2a_system/shared/claude_inbox/line_*.json
  ```

- [ ] メッセージが Claude Code Listener に表示される
  ```bash
  tail -f claude_code_listener.log
  ```

- [ ] 応答ファイルが作成される
  ```bash
  ls -lah /home/planj/Claude-Code-Communication/a2a_system/shared/claude_outbox/response_*.json
  ```

- [ ] 処理済みファイルが移動する
  ```bash
  ls -lah /home/planj/Claude-Code-Communication/a2a_system/shared/claude_inbox/processed/
  ```

---

## 📊 関連ファイル

| ファイル | 変更内容 |
|---------|---------|
| `a2a_system/bridges/claude_code_listener.py` | `text` フィールド対応、ファイル移動エラー対応 |
| `a2a_system/bridges/claude_bridge.py` | Claude Code向けメッセージ処理分離 |
| `LINE_MESSAGE_HANDLING_GUIDE.md` | **NEW** - LINE処理ガイド |
| `test_line_message_flow.py` | **NEW** - テストスクリプト |

---

## 🎯 次のステップ

### 短期（即座に実施）

1. **Claude Code Listener の起動確認**
   - 起動プロセスを確認し、自動起動設定を検討

2. **LINE Bridge の動作確認**
   - LINEから実際にメッセージ送信してテスト

3. **ログ確認**
   - `claude_code_listener.log` と `claude_bridge.log` を確認

### 中期（1-2週間以内）

1. **統合スクリプトへの組み込み**
   - `start-small-team.sh` に Claude Code Listener 起動を追加

2. **エラーハンドリングの拡張**
   - 追加のエッジケースに対応

3. **パフォーマンス最適化**
   - メッセージ処理速度の測定と改善

### 長期（将来の改善）

1. **自動応答機能の実装**
   - LINEメッセージへの自動応答メカニズム

2. **複数メッセージの並行処理**
   - 複数ユーザーからのメッセージの同時処理

3. **ロギング・監視の強化**
   - メッセージ処理パイプラインの詳細な監視

---

## 🐛 トラブルシューティング

### メッセージが表示されない場合

1. **Claude Code Listener が起動しているか確認**
   ```bash
   ps aux | grep claude_code_listener
   ```

2. **ログをチェック**
   ```bash
   tail -50 claude_code_listener.log
   tail -50 claude_bridge.log
   ```

3. **ファイルが作成されているか確認**
   ```bash
   ls -lah /home/planj/Claude-Code-Communication/a2a_system/shared/claude_inbox/
   ```

### ファイル移動エラーが続く場合

1. **ディスク容量を確認**
   ```bash
   df -h /home/planj/
   ```

2. **ディレクトリのパーミッションを確認**
   ```bash
   ls -ld /home/planj/Claude-Code-Communication/a2a_system/shared/claude_inbox/
   ls -ld /home/planj/Claude-Code-Communication/a2a_system/shared/claude_inbox/processed/
   ```

3. **ファイルロックを確認**
   ```bash
   lsof | grep claude_inbox
   ```

---

## 📝 修正者メモ

- **修正日時**: 2025-10-17 13:51 UTC
- **修正者**: Worker2（Claude Code）
- **テスト実施**: ✅ 完了
- **本番環境への展開**: 準備完了

