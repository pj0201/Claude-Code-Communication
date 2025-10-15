# A2A (Agent-to-Agent) Communication System

エージェント間通信を実現するZeroMQベースの分散メッセージングシステム

## 🎯 概要

このシステムは、複数のAIエージェント（GPT-5、Grok4、Claude）が相互に通信し、協調して作業を行うための基盤を提供します。

### 主な特徴

- **永続的なワーカープロセス**: エージェントは常時稼働し、メッセージを待機
- **ZeroMQメッセージブローカー**: 高速で信頼性の高いメッセージ配信
- **ファイルベース通信**: Claude Code用のブリッジ機能
- **オーケストレーター**: ジョブの割り当てと管理
- **非同期処理**: 高いスループットとレスポンス性

## 📁 ディレクトリ構造

```
a2a_system/
├── zmq_broker/          # ZeroMQメッセージブローカー
│   └── broker.py
├── workers/             # 永続化ワーカー
│   ├── gpt5_worker.py
│   └── grok4_worker.py
├── bridges/             # 通信ブリッジ
│   └── claude_bridge.py
├── orchestrator/        # オーケストレーター
│   └── orchestrator.py
├── shared/              # 共有ファイル領域
│   ├── claude_inbox/    # Claudeからのメッセージ
│   ├── claude_outbox/   # Claudeへのメッセージ
│   └── samples/         # サンプルメッセージ
├── start_a2a.ps1        # システム起動スクリプト
├── test_client.py       # テストクライアント
└── README.md           # このファイル
```

## 🚀 クイックスタート

### 1. 環境準備

```powershell
# Python 3.13がインストールされていることを確認
python --version

# 必要なパッケージをインストール
pip install pyzmq watchdog aiofiles openai
```

### 2. APIキー設定

```powershell
# .envファイルにAPIキーを設定
cd C:\Users\planj\CascadeProjects\claudecode-wind
.\SET-REAL-API-KEYS.ps1
```

### 3. システム起動

```powershell
# A2Aシステムを起動
cd a2a_system
.\start_a2a.ps1 -Mode all
```

起動モード:
- `all`: 全コンポーネントを起動（推奨）
- `broker`: ブローカーのみ起動
- `workers`: ワーカーのみ起動
- `test`: テストメッセージを送信

### 4. テスト実行

```powershell
# 別のターミナルでテストクライアントを実行
python test_client.py
```

## 📨 メッセージフォーマット

### リクエストメッセージ

```json
{
  "type": "REVIEW",
  "sender": "claude_worker3",
  "target": "gpt5",
  "code": "def example(): pass",
  "context": "レビューをお願いします",
  "timestamp": "2025-08-16T12:00:00"
}
```

### メッセージタイプ

- `REVIEW`: コードレビュー依頼
- `ANALYZE`: コード分析依頼
- `SECURITY_AUDIT`: セキュリティ監査
- `CRITICAL_REVIEW`: 批判的レビュー
- `PERFORMANCE_ANALYSIS`: パフォーマンス分析
- `COLLABORATE`: コラボレーション要求
- `QUESTION`: 質問

### レスポンスメッセージ

```json
{
  "type": "REVIEW_RESULT",
  "sender": "gpt5_001",
  "analysis": "分析結果...",
  "timestamp": "2025-08-16T12:00:01"
}
```

## 🔧 アーキテクチャ

### コンポーネント

1. **ZeroMQ Broker** (Port 5555-5557)
   - Router-Dealerパターンで実装
   - メッセージルーティングとロードバランシング

2. **Persistent Workers**
   - GPT-5: OpenAI APIを使用
   - Grok4: X.AI APIを使用
   - 非同期処理でメッセージを待機

3. **Claude Bridge**
   - ファイルシステム監視
   - JSONファイル ↔ ZeroMQメッセージ変換

4. **Orchestrator** (Port 5558)
   - ジョブキュー管理
   - ワーカーへのタスク割り当て
   - 統計情報とモニタリング

## 📊 モニタリング

### ログファイル

- `broker.log`: ブローカーのログ
- `gpt5_worker.log`: GPT-5ワーカーのログ
- `grok4_worker.log`: Grok4ワーカーのログ
- `claude_bridge.log`: Claudeブリッジのログ
- `orchestrator.log`: オーケストレーターのログ

### 統計情報取得

```python
# オーケストレーターから統計を取得
import zmq
import json

context = zmq.Context()
socket = context.socket(zmq.REQ)
socket.connect("tcp://localhost:5558")

socket.send_json({"command": "get_stats"})
stats = socket.recv_json()
print(json.dumps(stats, indent=2))
```

## 🛠️ トラブルシューティング

### ポート競合

```powershell
# 使用中のポートを確認
netstat -ano | findstr :5555
netstat -ano | findstr :5556
netstat -ano | findstr :5557
netstat -ano | findstr :5558
```

### プロセス確認

```powershell
# Pythonプロセスを確認
Get-Process -Name python* | Format-Table Id, ProcessName, CPU
```

### プロセス停止

```powershell
# すべてのPythonプロセスを停止
Get-Process -Name python* | Stop-Process -Force
```

## 🔄 Claude Codeとの統合

### メッセージ送信（Claude → 他エージェント）

```python
import json
from pathlib import Path
from datetime import datetime

# メッセージを作成
message = {
    "type": "REVIEW",
    "sender": "claude_code",
    "target": "gpt5",
    "code": "your_code_here",
    "context": "レビューをお願いします",
    "timestamp": datetime.now().isoformat()
}

# inbox にファイルを作成
inbox_dir = Path("a2a_system/shared/claude_inbox")
filename = f"msg_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
filepath = inbox_dir / filename

with open(filepath, 'w', encoding='utf-8') as f:
    json.dump(message, f, ensure_ascii=False, indent=2)
```

### レスポンス受信（他エージェント → Claude）

```python
import json
from pathlib import Path

# outbox からレスポンスを読み取り
outbox_dir = Path("a2a_system/shared/claude_outbox")

for response_file in outbox_dir.glob("*.json"):
    with open(response_file, 'r', encoding='utf-8') as f:
        response = json.load(f)
    
    print(f"Response from {response.get('sender')}: {response.get('type')}")
    
    # 処理後はファイルを削除または移動
    response_file.unlink()
```

## 📝 開発者向け情報

### 新しいワーカーの追加

1. `workers/` ディレクトリに新しいワーカースクリプトを作成
2. 基本的な構造は既存のワーカーを参照
3. `start_a2a.ps1` にワーカー起動処理を追加

### メッセージタイプの追加

1. ワーカーの `_process_message` メソッドに新しいタイプを追加
2. 対応する処理メソッドを実装
3. オーケストレーターの `_select_worker` メソッドを更新

## 📄 ライセンス

このプロジェクトはプライベート使用を目的としています。

## 🤝 貢献

バグ報告や機能リクエストは、GitHubのIssuesまたは直接連絡してください。

---

**Last Updated**: 2025-08-16
**Version**: 1.0.0
**Author**: Claude Code Team