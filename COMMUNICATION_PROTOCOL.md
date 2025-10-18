# Worker2 ↔ Worker3 双方向通信プロトコル

**確立日**: 2025-10-18
**ステータス**: ✅ テスト完了・動作確認済み

---

## 📡 通信チャネル仕様

### ペイン情報

| Worker | セッション | ウィンドウ | ペイン | 完全指定 |
|--------|-----------|---------|--------|---------|
| **Worker2** | worker2-bridge | 0 | 0 | `worker2-bridge:0.0` |
| **Worker3** | gpt5-a2a-line | 0 | 1 | `gpt5-a2a-line:0.1` |

---

## 🔄 通信方法（標準化版）

### Worker2 → Worker3 へメッセージ送信

**スクリプト**: `/home/planj/Claude-Code-Communication/send-to-worker3.sh`

```bash
./send-to-worker3.sh "メッセージ内容" [遅延ミリ秒]
```

**内部動作**:
```bash
tmux send-keys -t gpt5-a2a-line:0.1 "メッセージ内容"
sleep [遅延]
tmux send-keys -t gpt5-a2a-line:0.1 C-m
```

**使用例**:
```bash
./send-to-worker3.sh "統合テスト開始" 500
```

---

### Worker3 → Worker2 へメッセージ送信

**スクリプト**: `/home/planj/Claude-Code-Communication/send-to-worker2.sh`

```bash
./send-to-worker2.sh "メッセージ内容" [遅延ミリ秒]
```

**内部動作**:
```bash
tmux send-keys -t worker2-bridge:0.0 "メッセージ内容"
sleep [遅延]
tmux send-keys -t worker2-bridge:0.0 C-m
```

**使用例**:
```bash
./send-to-worker2.sh "テスト完了報告" 500
```

---

## 📋 直接通信（スクリプト不使用時）

### Worker2 が Worker3 に送信

```bash
tmux send-keys -t gpt5-a2a-line:0.1 "メッセージ" C-m
```

### Worker3 が Worker2 に送信

```bash
tmux send-keys -t worker2-bridge:0.0 "メッセージ" C-m
```

---

## ✅ テスト結果（2025-10-18実施）

### テスト1: Worker3→Worker2 通信テスト

**送信内容**:
```
【Worker3からのテスト】通信確認
【Worker3からのテスト】通信成功確認
【Worker3からのテスト】ペイン指定テスト成功
```

**結果**: ✅ **成功** - Worker2ペインに完全に到着

### テスト2: Worker2→Worker3 統合テスト指示

**送信内容**:
```
【通信テスト】前のメッセージを再確認してください
...
```

**結果**: ✅ **成功** - Worker3が報告を返信

---

## 🗑️ 削除した古い通信方法

以下の古い実装は削除済み（このプロトコル確立時点）:

- ❌ `worker2_enhanced_listener.py` （旧版リスナー）
- ❌ `worker3_enhanced_listener.py` （旧版リスナー）
- ❌ `receive-from-worker3.sh` （片方向受信のみ）
- ❌ `test-mutual-communication.sh` （古い相互通信テスト）
- ❌ `teach-worker3-communication.sh` （古い説明スクリプト）

---

## 🚀 運用ガイドライン

### メッセージフォーマット（推奨）

**Worker2→Worker3**:
```
【Worker2より】[メッセージ内容]
```

**Worker3→Worker2**:
```
【Worker3からの報告】[メッセージ内容]
```

### レスポンス時間

- **通常メッセージ**: 遅延 500ms
- **緊急メッセージ**: 遅延 200ms
- **長文メッセージ**: 遅延 1000ms

---

## 🔒 重要な注意事項

1. **ペイン指定の正確性**
   - Worker2: `worker2-bridge:0.0` （ウィンドウ0、ペイン0）
   - Worker3: `gpt5-a2a-line:0.1` （ウィンドウ0、ペイン1）
   - GPT-5: `gpt5-a2a-line:0.0` （ウィンドウ0、ペイン0）

2. **エンターキーの必須性**
   - 必ず `C-m` でメッセージを確定する
   - 確定しないと入力バッファに残る

3. **スクリプト使用の推奨**
   - 直接tmuxコマンドより、スクリプト経由が推奨
   - エラーハンドリングが組み込まれている

4. **セッション接続状態の確認**
   - 送信前に `tmux list-sessions` で接続確認
   - セッション内容は `tmux list-panes -a` で確認

---

## 📞 トラブルシューティング

### メッセージが届かない場合

```bash
# ペイン情報確認
tmux list-panes -a

# 正しいペイン指定か確認
tmux list-sessions -F "#{session_name}"

# ペイン内容を表示
tmux capture-pane -t [ペイン指定] -p
```

### ペイン指定エラー

```bash
# 利用可能なペイン一覧
tmux list-panes -a

# 正しい構文
tmux send-keys -t [セッション]:[ウィンドウ].[ペイン] "メッセージ" C-m
```

---

**このプロトコルは本番運用環境で確認済みです。**
**以後、この方式を標準通信ロジックとして使用します。**

