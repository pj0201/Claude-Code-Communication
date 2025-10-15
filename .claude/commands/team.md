---
description: GPT-5とA2Aシステムを起動してチームサポートを開始
---

以下のコマンドを実行して、GPT-5チャットとA2Aシステムを別ウィンドウで起動してください：

```bash
/home/planj/Claude-Code-Communication/add-team-support.sh
```

これにより、新しいtmuxセッション"team-support"が起動し、以下が利用可能になります：

- **GPT-5独立チャット**: 直接相談・壁打ち可能
- **A2Aシステム**: エージェント間通信（ZeroMQ）

**使い方**:
1. 別ターミナルでスクリプトを実行
2. GPT-5チャットで相談
3. A2Aログを監視

**再接続**: `tmux attach -t team-support`
**終了**: `tmux kill-session -t team-support`
