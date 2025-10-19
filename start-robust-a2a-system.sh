#!/bin/bash
# 堅牢なA2Aシステム起動スクリプト
# Broker、Bridge、GPT-5 Worker、監視システムを統合起動

set -e

PROJECT_DIR="/home/planj/Claude-Code-Communication"
cd "$PROJECT_DIR"

echo "=================================================="
echo "🚀 堅牢なA2Aシステム起動"
echo "=================================================="
echo ""

# 既存プロセスのクリーンアップ
echo "🧹 既存プロセスをクリーンアップ..."
pkill -f "broker.py" || true
pkill -f "claude_bridge.py" || true
pkill -f "gpt5_worker.py" || true
pkill -f "system_supervisor.py" || true
sleep 2

# 必要なディレクトリの作成
echo "📁 必要なディレクトリを作成..."
mkdir -p a2a_system/shared/context_storage
mkdir -p a2a_system/shared/learned_patterns
mkdir -p a2a_system/shared/claude_inbox/processed
mkdir -p a2a_system/shared/claude_outbox

# 統合テストの実行
echo ""
echo "🧪 統合システムテスト実行..."
python3 a2a_system/test_integrated_system.py
TEST_RESULT=$?

if [ $TEST_RESULT -ne 0 ]; then
    echo ""
    echo "❌ テストが失敗しました。システムを起動していません。"
    exit 1
fi

echo ""
echo "=================================================="
echo "✅ テスト成功。システムを起動します。"
echo "=================================================="
echo ""

# システム監視スーパーバイザーを起動
echo "🌐 A2Aシステム監視スーパーバイザーを起動..."
python3 a2a_system/system_supervisor.py &
SUPERVISOR_PID=$!

echo "✅ スーパーバイザーPID: $SUPERVISOR_PID"
echo ""

# 起動確認
echo "⏳ システム起動確認（15秒待機）..."
sleep 15

# プロセス確認
echo ""
echo "=================================================="
echo "📊 システム状態確認"
echo "=================================================="

BROKER=$(pgrep -f "broker.py" || echo "NOT_RUNNING")
BRIDGE=$(pgrep -f "claude_bridge.py" || echo "NOT_RUNNING")
WORKER=$(pgrep -f "gpt5_worker.py" || echo "NOT_RUNNING")

echo "🔹 Broker:  $BROKER"
echo "🔹 Bridge:  $BRIDGE"
echo "🔹 Worker:  $WORKER"

if [ "$BROKER" != "NOT_RUNNING" ] && [ "$BRIDGE" != "NOT_RUNNING" ] && [ "$WORKER" != "NOT_RUNNING" ]; then
    echo ""
    echo "✅ 全プロセスが正常に起動しました。"
    echo ""
    echo "📝 ログファイル:"
    echo "  - Broker:     a2a_system/broker.log"
    echo "  - Bridge:     a2a_system/claude_bridge.log"
    echo "  - Worker:     a2a_system/gpt5_worker.log"
    echo "  - Supervisor: a2a_system/system_supervisor.log"
    echo ""
    echo "📚 コンテキスト・学習ファイル:"
    echo "  - Context:    a2a_system/shared/context_storage/"
    echo "  - Patterns:   a2a_system/shared/learned_patterns/"
    echo ""
    echo "🎯 システム起動完了。監視スーパーバイザーが実行中です。"
    echo "⏹️  停止するには: kill $SUPERVISOR_PID"
else
    echo ""
    echo "❌ 一部のプロセスが起動していません。"
    echo ""
    echo "📝 ログを確認してください:"
    [ "$BROKER" = "NOT_RUNNING" ] && echo "  - Broker ログ: a2a_system/broker.log"
    [ "$BRIDGE" = "NOT_RUNNING" ] && echo "  - Bridge ログ: a2a_system/claude_bridge.log"
    [ "$WORKER" = "NOT_RUNNING" ] && echo "  - Worker ログ: a2a_system/gpt5_worker.log"
    exit 1
fi

# スーパーバイザーの実行を継続
wait $SUPERVISOR_PID
