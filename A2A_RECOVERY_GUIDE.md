# A2A通信システム 障害復旧ガイド

## 🔍 問題の原因（2025-10-12判明）

### **真の根本原因**
**`start-gpt5-with-a2a.sh` がA2Aシステムを自動起動していなかった**

### 詳細
1. **10月7日11:09以降、5日間通信が途絶えていた**
2. `start-gpt5-with-a2a.sh` は下ペインで **メッセージ表示のみ** で実行していなかった
   ```bash
   echo '  ./start_a2a.sh all'  # 表示だけ！実行してない！
   ```
3. **ユーザーが手動で `./start_a2a.sh all` を実行する必要があった**
4. 誰も実行しなかったため、A2Aシステムが起動していなかった

### 副次的問題（当初の誤診）
- `start_a2a.sh` の `wait` による親プロセス依存
- ターミナルを閉じると全プロセスが停止する設計
- しかし今回はそもそも起動していなかったため、この問題は顕在化していなかった

---

## ✅ 実装した再発防止策

### 1. **A2Aシステム自動起動（最重要）**

**変更内容**: `/home/planj/Claude-Code-Communication/start-gpt5-with-a2a.sh`

```bash
# 修正前（表示のみ）
echo '  ./start_a2a.sh all'

# 修正後（自動実行）
./start_a2a.sh all
```

**効果**:
- **`start-gpt5-with-a2a.sh` 実行時にA2Aシステムも自動起動**
- 手動実行忘れによる通信停止を防止
- 起動後すぐに通信可能な状態になる

### 2. 軽量プロセス監視・自動復旧（NEW）

**新規作成**: `/home/planj/Claude-Code-Communication/a2a_system/monitor_a2a.sh`

**機能**:
- プロセス状態の確認（`check`）
- 停止プロセスの自動再起動（`auto-restart`）
- 継続監視モード（`watch`）

**特徴**:
- **外部依存なし**: 純粋なBashスクリプト
- **軽量**: Monit/Supervisorより遥かに軽い
- **柔軟**: 必要な時だけ実行

### 3. 設定ファイル化（NEW）

**新規作成**: `/home/planj/Claude-Code-Communication/a2a_system/config.sh`

**効果**:
- ポート番号、ログファイル名などを一元管理
- ハードコーディング排除
- 拡張時の変更が容易

### 4. プロセス永続化（nohup + disown）

**変更内容**: `/home/planj/Claude-Code-Communication/a2a_system/start_a2a.sh`

```bash
# 修正前
python3 zmq_broker/broker.py > broker.log 2>&1 &
BROKER_PID=$!

# 修正後
nohup python3 zmq_broker/broker.py > broker.log 2>&1 &
BROKER_PID=$!
disown
```

**効果**:
- `nohup`: HUPシグナル（ターミナル終了時の信号）を無視
- `disown`: シェルのジョブテーブルから削除し、完全に独立
- **ターミナルを閉じてもプロセスが継続動作**

### 2. stop コマンド追加

```bash
./start_a2a.sh stop
```

**機能**:
- 全A2Aプロセスを確実に停止
- 各プロセスの停止確認メッセージ表示

---

## 🚀 正しい運用方法

### A2Aシステム起動

```bash
cd /home/planj/Claude-Code-Communication/a2a_system
./start_a2a.sh all
```

**起動後の確認**:
```bash
✅ プロセスは永続化されました（ターミナルを閉じても動作継続）
```

**このメッセージが表示されたら、ターミナルを閉じてOK**

### A2Aシステム状態確認

#### 方法1: 軽量監視スクリプト（推奨）
```bash
cd /home/planj/Claude-Code-Communication/a2a_system
./monitor_a2a.sh check
```

**正常時の出力**:
```
✓ Broker: 稼働中
✓ GPT-5 Worker: 稼働中
✓ Claude Bridge: 稼働中
✅ 全プロセス正常稼働中
```

#### 方法2: 手動確認
```bash
ps aux | grep -E "(broker|gpt5_worker|claude_bridge)" | grep python
```

**正常時の出力例**:
```
planj    1323  broker.py
planj    1340  gpt5_worker.py
planj    1372  claude_bridge.py
```

### A2Aシステム停止

```bash
cd /home/planj/Claude-Code-Communication/a2a_system
./start_a2a.sh stop
```

---

## 🔧 トラブルシューティング

### 問題1: A2Aプロセスが起動しているのに通信できない

**確認手順**:
```bash
# 1. プロセス確認
ps aux | grep python | grep -E "(broker|worker|bridge)"

# 2. ログ確認
cd /home/planj/Claude-Code-Communication/a2a_system
tail -30 claude_bridge.log
tail -30 broker.log
tail -30 gpt5_worker.log
```

**復旧手順**:
```bash
# 1. 全プロセス停止
./start_a2a.sh stop

# 2. 再起動
./start_a2a.sh all
```

### 問題2: プロセスが見つからない

**原因**: ターミナルを閉じたか、システムが再起動された

**復旧手順**:
```bash
cd /home/planj/Claude-Code-Communication/a2a_system
./start_a2a.sh all
```

### 問題3: ログに「ERROR」が頻出

**確認**:
```bash
tail -100 gpt5_worker.log | grep ERROR
```

**よくあるエラー**:
- `Error processing message: Expecting value`: JSON解析エラー（一時的なもの、通常は無視してOK）
- `API Key error`: OpenAI API Key未設定 → `.env` ファイルを確認

---

## 📊 通信テスト方法

### 手動テスト

```bash
cd /home/planj/Claude-Code-Communication/a2a_system/shared

# テストメッセージ作成
python3 -c "
import json
import time

message = {
    'type': 'QUESTION',
    'sender': 'test_client',
    'target': 'gpt5',
    'question': '通信テスト：受信確認してください',
    'timestamp': time.strftime('%Y-%m-%dT%H:%M:%S')
}

with open(f\"claude_inbox/test_{int(time.time())}.json\", 'w') as f:
    json.dump(message, f, ensure_ascii=False, indent=2)

print('✓ テストメッセージ作成完了')
"

# 10秒待機
sleep 10

# 応答確認
ls -lht claude_outbox/ | head -3
cat claude_outbox/response_gpt5_001_ANSWER_*.json | head -20
```

---

## 🛡️ 予防保守

### 自動監視モード（オプション）

**継続的な監視が必要な場合**:
```bash
cd /home/planj/Claude-Code-Communication/a2a_system
./monitor_a2a.sh watch
```

- 30秒ごとにプロセス状態チェック
- 停止検出時に自動再起動
- Ctrl+Cで停止

### 定期確認（推奨：週1回）

```bash
# 1. プロセス稼働確認
cd /home/planj/Claude-Code-Communication/a2a_system
./monitor_a2a.sh check

# 2. ログサイズ確認（肥大化防止）
ls -lh /home/planj/Claude-Code-Communication/a2a_system/*.log

# 3. 通信テスト実施（上記の手動テスト参照）
```

### 自動復旧

**プロセスが停止している場合**:
```bash
cd /home/planj/Claude-Code-Communication/a2a_system
./monitor_a2a.sh auto-restart
```

- 停止プロセスを自動検出
- 必要最小限のプロセスのみ再起動
- Brokerが停止している場合は全体再起動

### ログローテーション（月1回推奨）

```bash
cd /home/planj/Claude-Code-Communication/a2a_system

# 古いログをバックアップ
mkdir -p logs_backup
mv *.log logs_backup/backup_$(date +%Y%m%d).log 2>/dev/null

# システム再起動（新しいログファイルが作成される）
./start_a2a.sh stop
./start_a2a.sh all
```

---

## 📝 障害履歴

### 2025-10-12: A2Aシステム自動起動の不備（真因）
- **期間**: 10月7日11:09 ～ 10月12日17:20（5日間通信途絶）
- **真因**: `start-gpt5-with-a2a.sh` がA2Aシステムを自動起動していなかった
- **対策**: スクリプト修正でA2A自動起動を実装
- **状態**: ✅ 解決済み

### 2025-10-12: プロセス永続化の不備（副次的問題）
- **原因**: `wait` による親プロセス依存
- **影響**: ターミナルを閉じると全プロセスが停止
- **対策**: `nohup` + `disown` による永続化実装
- **状態**: ✅ 解決済み（今回は顕在化せず）

---

**最終更新**: 2025-10-12
**担当**: Claude Code
