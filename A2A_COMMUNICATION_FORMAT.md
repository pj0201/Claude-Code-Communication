# A2A通信メッセージフォーマット（正式版）

**作成日**: 2025-10-16
**状態**: ✅ 検証済み・確定

---

## 📋 正式メッセージフォーマット

### Claude Code → GPT-5 への QUESTION メッセージ

**正しいフォーマット:**
```json
{
  "type": "QUESTION",
  "sender": "claude_code_worker2",
  "target": "gpt5_intelligent",
  "timestamp": "2025-10-16T13:17:09.000000",
  "question": "【質問タイトル】\n\n詳細な質問内容\n\n複数行対応\n\n【質問1】\n内容\n\n【質問2】\n内容"
}
```

**ポイント:**
- ✅ フィールド名は **"question"** （"content" ではない）
- ✅ トップレベルに質問を配置
- ✅ "type": "QUESTION" は必須
- ✅ 改行（\n）は問題なく処理される

---

## ❌ 間違ったフォーマット（これまで使用していたもの）

```json
{
  "type": "QUESTION",
  "content": {
    "question": "質問内容"
  }
}
```

**問題点:**
- ❌ GPT-5ワーカーが "question" フィールドを見つけられない
- ❌ message.get("question", "") で空文字列が返される
- ❌ 結果として一般的なあいさつしか返らない

---

## 📤 送信メッセージ作成テンプレート

```python
import json
from datetime import datetime
from pathlib import Path

# メッセージを構築（正しいフォーマット）
message = {
    "type": "QUESTION",                    # 必須
    "sender": "claude_code_worker2",       # 必須
    "target": "gpt5_intelligent",          # 必須
    "timestamp": datetime.now().isoformat(),
    "question": """【レビュー対象】Phase 1 学習エンジン

【実装内容】
- モジュール数: 4個
- 実装行数: 1,173行

【質問】
1. 設計は妥当か？
2. パフォーマンスは許容範囲か？"""
}

# 保存先：正しいディレクトリ
inbox_path = Path("/home/planj/Claude-Code-Communication/a2a_system/shared/claude_inbox")
inbox_path.mkdir(parents=True, exist_ok=True)

# JSONファイルに保存
msg_file = f"gpt5_question_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
with open(inbox_path / msg_file, 'w', encoding='utf-8') as f:
    json.dump(message, f, ensure_ascii=False, indent=2)

print(f"✅ メッセージを送信: {msg_file}")
```

---

## 🔄 通信フロー

```
1. Claude Code
   ↓
   JSONファイルを作成
   （/a2a_system/shared/claude_inbox/）
   ↓
2. Claude Bridge
   ↓
   ファイルを監視して ZeroMQ に送信
   ↓
3. ZeroMQ Broker
   ↓
   メッセージを GPT-5 ワーカーにルート
   ↓
4. GPT-5 ワーカー
   ↓
   message.get("question", "") で質問を取得
   ↓
   OpenAI API 呼び出し
   ↓
   ANSWER を返信
   ↓
5. Claude Bridge
   ↓
   応答ファイルを作成
   （/a2a_system/shared/claude_outbox/）
```

---

## ✅ 検証済み通信例

### Phase 1 レビュー依頼（成功例）

**送信ファイル**: `gpt5_review_phase1_request_20251016_131709.json`

```json
{
  "type": "QUESTION",
  "sender": "claude_code_worker2",
  "target": "gpt5_intelligent",
  "timestamp": "2025-10-16T13:17:09.000000",
  "question": "【Phase 1: 基本学習エンジン】の技術レビューをお願いします..."
}
```

**GPT-5応答**: ✅ 正常に処理（ただし詳細なレビューにはプロンプト工夫が必要）

**応答ファイル**: `response_gpt5_001_ANSWER_20251016_131710_433660.json`

---

## 📌 重要な注意事項

1. **ディレクトリは正確に**
   - ✅ 送信先: `/a2a_system/shared/claude_inbox/`
   - ✅ 応答先: `/a2a_system/shared/claude_outbox/`
   - ❌ 間違い: `/claude_inbox/` または `/claude_outbox/`

2. **ファイル形式**
   - ✅ JSON形式（必ず UTF-8 で保存）
   - ✅ ファイル拡張子: `.json`
   - ❌ テキスト形式や他の形式は非対応

3. **メッセージ型**
   - ✅ QUESTION: 質問・依頼用（最も一般的）
   - SEND_LINE: LINE送信用
   - GITHUB_ISSUE: GitHub Issue処理用
   - （その他のカスタム型は未実装）

---

## 🧪 テスト方法

```bash
# 1. メッセージファイルを作成
cat > /home/planj/Claude-Code-Communication/a2a_system/shared/claude_inbox/test_message.json << 'EOF'
{
  "type": "QUESTION",
  "sender": "claude_code_worker2",
  "target": "gpt5_intelligent",
  "question": "テストメッセージです。返信をお願いします。"
}
EOF

# 2. 応答ファイルが生成されるのを待つ（通常3-5秒）
sleep 5
ls -ltr /home/planj/Claude-Code-Communication/a2a_system/shared/claude_outbox/ | tail -3

# 3. 応答内容を確認
cat /home/planj/Claude-Code-Communication/a2a_system/shared/claude_outbox/response_gpt5_001_ANSWER_*.json | tail -20
```

---

## 📋 ファイル管理ポリシー

**削除対象（不正なフォーマット）:**
- ❌ `/home/planj/Claude-Code-Communication/claude_inbox/` 配下のファイル
- ❌ `message_type` フィールドを使用したファイル
- ❌ 実験的なメッセージタイプファイル

**保持対象（正式版）:**
- ✅ `/a2a_system/shared/claude_inbox/processed/` 配下のファイル
- ✅ 正式なメッセージフォーマットを使用したファイル
- ✅ テスト成功・検証済みのファイル

---

**このドキュメントは今後のA2A通信の標準仕様です。**
