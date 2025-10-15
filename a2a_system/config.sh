#!/bin/bash
# A2A System Configuration
# 設定ファイル - start_a2a.sh や monitor_a2a.sh から読み込まれる

# ZeroMQ設定
export A2A_BROKER_PORT=5555
export A2A_MONITOR_PORT=5557

# プロセス設定
export A2A_BROKER_SCRIPT="zmq_broker/broker.py"
export A2A_ORCHESTRATOR_SCRIPT="orchestrator/orchestrator.py"
export A2A_GPT5_WORKER_SCRIPT="workers/gpt5_worker.py"
export A2A_GROK4_WORKER_SCRIPT="workers/grok4_worker.py"
export A2A_CLAUDE_BRIDGE_SCRIPT="bridges/claude_bridge.py"

# ログ設定
export A2A_LOG_DIR="."
export A2A_BROKER_LOG="broker.log"
export A2A_ORCHESTRATOR_LOG="orchestrator.log"
export A2A_GPT5_LOG="gpt5_worker.log"
export A2A_GROK4_LOG="grok4_worker.log"
export A2A_CLAUDE_BRIDGE_LOG="claude_bridge.log"

# プロセス起動間隔（秒）
export A2A_STARTUP_DELAY_BROKER=2
export A2A_STARTUP_DELAY_ORCHESTRATOR=1
export A2A_STARTUP_DELAY_WORKER=1
export A2A_STARTUP_DELAY_BRIDGE=1

# 監視設定
export A2A_MONITOR_INTERVAL=30  # 秒
export A2A_AUTO_RESTART=true

# パス設定
export A2A_SHARED_DIR="shared"
export A2A_INBOX_DIR="shared/claude_inbox"
export A2A_OUTBOX_DIR="shared/claude_outbox"
