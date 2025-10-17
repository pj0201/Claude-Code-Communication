# チーム起動コマンド（保存版）

## ✅ 正しい起動コマンド（1つのみ）

### スモールチーム起動（GPT-5 + A2A + LINE連携）

```bash
cd "/home/planj/Claude-Code-Communication"
./start-small-team.sh
```

**用途**: 小〜中規模プロジェクト、個人開発

**起動されるもの**:
- GPT-5チャット用ターミナル（2ペインtmux）
- A2Aバックエンドシステム（Broker, GPT-5 Worker, Bridge, Wrapper）
- LINE→GitHub Issue自動化システム

---

---

## ⚠️ 重要事項

**起動スクリプトは1つだけです！**

- ✅ `start-small-team.sh` - **唯一の起動方法**
- ❌ その他の起動スクリプト - **すべて削除済み**

---

## システム停止

```bash
# 統合停止（tmux + バックエンド）
./start-small-team.sh stop
```
