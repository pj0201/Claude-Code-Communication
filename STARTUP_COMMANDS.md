# チーム起動コマンド（保存版）

## ✅ 正しい起動コマンド（2つのみ）

### 1. スモールチーム起動（GPT-5 + A2A）

```bash
cd "/home/planj/Claude-Code-Communication"
./start-gpt5-with-a2a.sh
```

**用途**: 小〜中規模プロジェクト、個人開発

**起動されるもの**:
- GPT-5チャット用ターミナル
- A2Aシステム用ターミナル

---

### 2. フルチーム起動（5agents）

```bash
cd "/home/planj/Claude-Code-Communication"
./startup-integrated-system.sh 5agents
```

**用途**: 大規模プロジェクト、複雑な開発タスク

**起動されるもの**:
- PRESIDENT（統括責任者）
- O3（高度推論エンジン）
- GROK4（品質保証AI）
- WORKER2（サポートエンジニア）
- WORKER3（メインエンジニア）
- GPT-5 Worker（A2A）
- Grok4 Worker（A2A）

---

## ⚠️ 重要事項

**この2つのコマンド以外は使用しないこと！**

- ❌ `startup-small-team.sh` - **存在しません**
- ❌ その他の起動スクリプト - **使用不可**

---

## システム停止

```bash
# スモールチーム停止
# → ターミナルを閉じる、またはCtrl+Cで停止

# フルチーム停止
./startup-integrated-system.sh stop
```
