# Phase 2: 自動転送通信方式ガイド

**作成日**: 2025-10-21
**状態**: ✅ 実装完了・テスト 31/31 PASS
**対象**: スモールチーム（Claude Code, Worker2, GPT-5）

---

## 📋 概要

Phase 2 では、**Sandbox Filter による自動セキュリティフィルタリング** と **自動転送方式** を実装しました。

**主な利点**:
- ✅ 相手エージェント（Worker2/GPT-5）が **自動的にメッセージを受け取って処理**
- ✅ エンター押し忘れ問題の根本解決
- ✅ セキュリティレベルを段階的に選択可能
- ✅ メッセージが確実に相手に届く

---

## 🔐 セキュリティモード（4段階）

### 1. **DISABLED** （開発用）
```
使用場面: テスト・開発時のみ
フィルタリング: なし（通過しない）
自動転送: ❌ いいえ
ペイロード制限: なし
署名検証: 不要
特徴: 高速だが、本番環境では推奨されない
```

### 2. **PERMISSIVE** （基本検証）
```
使用場面: 内部通信（Worker2 ↔ GPT-5 等）
フィルタリング: あり（基本検証）
自動転送: ✅ はい
ペイロード制限: 100KB
署名検証: 不要
特徴: バランス型。通常の内部通信に推奨
```

### 3. **RESTRICTIVE** （中程度制限）
```
使用場面: エージェント間の重要な通信
フィルタリング: あり（厳密）
自動転送: ✅ はい
ペイロード制限: 50KB
署名検証: 必須 ✓
特徴: 署名必須で改ざん検出。Worker2/GPT-5への送信に推奨
```

### 4. **STRICT** （最高レベル）
```
使用場面: 外部入力（LINE等）・セキュリティ重視
フィルタリング: あり（最厳密）
自動転送: ✅ はい
ペイロード制限: 10KB
署名検証: 必須 ✓
暗号化: サポート対象
特徴: 最高レベルセキュリティ。外部入力処理に必須
```

---

## 📤 メッセージ送信方法

### ステップ1: A2A JSON メッセージを作成

**形式**:
```json
{
  "type": "QUESTION",
  "sender": "worker3",
  "target": "worker2",
  "timestamp": "2025-10-21T13:00:00Z",
  "question": "【リファクタリング依頼】...",
  "_metadata": {
    "sandbox_mode": "restrictive",
    "priority": 2,
    "is_external_input": false,
    "requires_validation": true
  }
}
```

**必須フィールド**:
- `type`: メッセージタイプ（"QUESTION", "ANSWER", "EXTERNAL_INPUT"等）
- `sender`: 送信元エージェント（"worker3", "worker2", "gpt5_001"等）
- `target`: 送信先エージェント
- `timestamp`: ISO 8601形式のタイムスタンプ
- `question` または `answer`: メッセージ内容

**_metadata フィールド**:
- `sandbox_mode`: セキュリティモード（"disabled", "permissive", "restrictive", "strict"）
- `priority`: 優先度（1-5）
- `is_external_input`: 外部入力フラグ（true/false）
- `requires_validation`: 検証必須フラグ（true/false）

### ステップ2: Claude Bridge で自動処理

**処理フロー**:
```
JSON ファイル（claude_inbox）
    ↓
Claude Bridge が監視
    ↓
SandboxFilterIntegration で処理
    ↓
1. EnhancedMessage に変換
2. 外部入力フラグ検査
3. Sandbox Filter 検証
4. チェックサム検証
5. 自動転送判定
    ↓
✅ 自動転送対象 → ZeroMQ で送信
❌ 転送対象外 → claude_outbox に出力
```

### ステップ3: 相手エージェントが自動受け取り

**Worker2/GPT-5 の処理**:
```
ZeroMQ メッセージ受信
    ↓
メッセージ検証
    ↓
自動処理実行
    ↓
応答メッセージ生成
    ↓
claude_outbox に出力
```

**→ 相手が自動的に処理・応答します！**

---

## 💡 送信先別の推奨設定

### Claude Code → Worker2
```python
msg = {
    "type": "QUESTION",
    "sender": "worker3",
    "target": "worker2",
    "timestamp": "2025-10-21T...",
    "question": "リファクタリング依頼...",
    "_metadata": {
        "sandbox_mode": "restrictive",  # ← 推奨
        "priority": 2,
        "requires_validation": true
    }
}
```

### Claude Code → GPT-5
```python
msg = {
    "type": "QUESTION",
    "sender": "worker3",
    "target": "gpt5_001",
    "timestamp": "2025-10-21T...",
    "question": "技術相談...",
    "_metadata": {
        "sandbox_mode": "restrictive",  # ← 推奨
        "priority": 1,
        "requires_validation": true
    }
}
```

### LINE/GitHub → 内部システム
```python
msg = {
    "type": "EXTERNAL_INPUT",
    "sender": "line",
    "target": "worker2",
    "timestamp": "2025-10-21T...",
    "content": "LINEメッセージ...",
    "_metadata": {
        "sandbox_mode": "strict",  # ← 必須
        "is_external_input": true,
        "requires_validation": true
    }
}
```

---

## ✅ 検証ルール

### Sandbox Filter が検証する項目

1. **ペイロードサイズ**
   - DISABLED: 制限なし
   - PERMISSIVE: 100KB以下
   - RESTRICTIVE: 50KB以下
   - STRICT: 10KB以下

2. **署名（チェックサム）**
   - DISABLED: 検証しない
   - PERMISSIVE: 検証しない
   - RESTRICTIVE: 必須 + 検証
   - STRICT: 必須 + 検証

3. **外部入力フラグ**
   - DISABLED/PERMISSIVE: 許可
   - RESTRICTIVE/STRICT: 外部入力フラグ=True は拒否（STRICTで別途処理）

4. **ペイロード形式**
   - 必須フィールド（type, sender, target, timestamp）
   - question/answer フィールド
   - JSON有効性

---

## 📊 処理結果の確認

### 成功時
```
✅ メッセージは自動転送対象です (sandbox_mode: restrictive)
```
→ メッセージは相手エージェントに自動転送されます

### 転送対象外時
```
⏸️  メッセージはフィルタを通過しましたが、自動転送対象外です (sandbox_mode: disabled)
```
→ メッセージは claude_outbox に出力されますが、自動転送されません

### フィルタ不合格時
```
❌ Sandbox Filter 検証失敗: Payload exceeds limit...
```
→ メッセージは拒否されます。サイズやモードを確認してください

---

## 🧪 通信テスト項目

| # | テスト項目 | 送信側 | 受信側 | モード | 期待結果 |
|----|----------|-------|-------|--------|--------|
| 1 | 通常メッセージ | Worker3 | Worker2 | RESTRICTIVE | ✅ 自動転送 |
| 2 | 高優先度 | Worker3 | GPT-5 | RESTRICTIVE | ✅ 自動転送 |
| 3 | DISABLED モード | Worker3 | Worker2 | DISABLED | ❌ 転送対象外 |
| 4 | 外部入力（LINE） | LINE | Worker2 | STRICT | ✅ 自動転送 |
| 5 | 外部入力（不正） | LINE | Worker2 | PERMISSIVE | ❌ 拒否 |
| 6 | 超大型ペイロード | Worker3 | Worker2 | RESTRICTIVE | ❌ 拒否 |
| 7 | 署名検証成功 | Worker3 | Worker2 | RESTRICTIVE | ✅ 自動転送 |
| 8 | 署名検証失敗 | Worker3 | Worker2 | RESTRICTIVE | ❌ 拒否 |

---

## 🔄 通信テスト実行手順

### 前提条件
```bash
# 1. スモールチーム起動
./start-small-team.sh

# 2. テストファイルを claude_inbox に配置
# a2a_system/shared/claude_inbox/

# 3. Claude Bridge が稼働中であることを確認
ps aux | grep claude_bridge
```

### 実行方法
```bash
# テスト用スクリプト実行
python3 tests/test_communication_flow.py

# または手動で JSON ファイルを claude_inbox に配置
cp test_messages/refactoring_request.json a2a_system/shared/claude_inbox/

# 応答ファイルが claude_outbox に生成されるのを待つ
ls -ltr a2a_system/shared/claude_outbox/ | tail -1
```

---

## 📝 ドキュメント参照

- `a2a_system/shared/message_protocol.py` - メッセージプロトコル実装
- `a2a_system/bridges/sandbox_filter_integration.py` - Sandbox Filter 統合
- `tests/test_sandbox_filter.py` - Sandbox Filter テスト
- `tests/test_sandbox_filter_integration.py` - 統合テスト

---

**Phase 2 通信方式は完全に完成しました。通信テストを開始してください！**
