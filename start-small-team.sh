#!/bin/bash
# スモールチーム統合起動スクリプト
# GPT-5 + A2A + LINE連携を1コマンドで起動（2ペイン tmux構成）

REPO_ROOT="/home/planj/Claude-Code-Communication"
A2A_DIR="$REPO_ROOT/a2a_system"
SESSION_NAME="gpt5-a2a-line"

# モード解析
MODE="${1:-start}"

if [ "$MODE" = "stop" ]; then
    echo "=========================================================="
    echo "🛑 スモールチーム完全停止中..."
    echo "=========================================================="
    echo ""

    # tmuxセッション停止
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        tmux kill-session -t "$SESSION_NAME"
        echo "  ✓ tmuxセッション停止"
    fi

    # バックエンドプロセス停止
    pkill -f "broker.py" 2>/dev/null && echo "  ✓ Broker 停止"
    pkill -f "gpt5_worker.py" 2>/dev/null && echo "  ✓ GPT-5 Worker 停止"
    pkill -f "orchestrator.py" 2>/dev/null && echo "  ✓ Orchestrator 停止"
    pkill -f "bridges/claude_bridge.py" 2>/dev/null && echo "  ✓ Claude Bridge 停止"
    pkill -f "github_issue_reader.py" 2>/dev/null && echo "  ✓ GitHub Issue Reader 停止"

    sleep 1
    echo ""
    echo "✅ 全プロセス停止完了"
    exit 0
fi

echo "=========================================================="
echo "🚀 スモールチーム統合起動"
echo "=========================================================="
echo ""
echo "構成:"
echo "  📊 バックエンド: Broker + GPT-5 + Bridge + GitHub Issue Reader"
echo "  💬 フロントエンド: GPT-5チャット + システムモニター (2ペイン均等)"
echo ""

# 既存セッション確認（自動削除）
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "⚠️  既存のセッション '$SESSION_NAME' が存在します"
    echo "🔄 自動的に停止して再起動します..."
    tmux kill-session -t "$SESSION_NAME"
    sleep 1
    echo "✅ セッション停止完了"
fi

# .envファイル読み込み
if [ -f "$REPO_ROOT/.env" ]; then
    set -a
    source "$REPO_ROOT/.env"
    set +a
    echo "✅ .envファイル読み込み完了"
else
    echo "⚠️  .envファイルが見つかりません"
fi
echo ""

# 作業ディレクトリ移動
cd "$A2A_DIR" || exit 1

# ===== バックエンドシステム起動 =====
echo "[1/2] バックエンドシステム起動中..."
echo ""

# 既存プロセスのクリーンアップ
echo "🧹 既存プロセスのクリーンアップ..."
pkill -f "broker.py" 2>/dev/null && echo "  ✓ Broker 停止" || true
pkill -f "gpt5_worker.py" 2>/dev/null && echo "  ✓ GPT-5 Worker 停止" || true
pkill -f "orchestrator.py" 2>/dev/null && echo "  ✓ Orchestrator 停止" || true
pkill -f "bridges/claude_bridge.py" 2>/dev/null && echo "  ✓ Claude Bridge 停止" || true
pkill -f "github_issue_reader.py" 2>/dev/null && echo "  ✓ GitHub Issue Reader 停止" || true
sleep 2
echo ""

# 1. Broker起動
echo "[1/5] 📡 ZeroMQ Broker 起動中..."
python3 zmq_broker/broker.py >> "$A2A_DIR/broker.log" 2>&1 &
BROKER_PID=$!
sleep 2
if ps -p $BROKER_PID > /dev/null 2>&1; then
    echo "      ✅ 起動成功 (PID: $BROKER_PID)"
else
    echo "      ❌ 起動失敗"
    exit 1
fi
echo ""

# 2. Orchestrator起動
echo "[2/5] 🎯 Orchestrator 起動中..."
python3 orchestrator/orchestrator.py >> "$A2A_DIR/orchestrator.log" 2>&1 &
ORCH_PID=$!
sleep 1
if ps -p $ORCH_PID > /dev/null 2>&1; then
    echo "      ✅ 起動成功 (PID: $ORCH_PID)"
else
    echo "      ⚠️  起動失敗（続行します）"
fi
echo ""

# 3. GPT-5 Worker起動
echo "[3/5] 🤖 GPT-5 Worker 起動中..."
if [ -z "$OPENAI_API_KEY" ]; then
    echo "      ⚠️  OPENAI_API_KEY 未設定 - スキップ"
else
    python3 workers/gpt5_worker.py >> "$A2A_DIR/gpt5_worker.log" 2>&1 &
    GPT5_PID=$!
    sleep 1
    if ps -p $GPT5_PID > /dev/null 2>&1; then
        echo "      ✅ 起動成功 (PID: $GPT5_PID)"
    else
        echo "      ❌ 起動失敗"
    fi
fi
echo ""

# 4. Claude Bridge起動
echo "[4/5] 🌉 Claude Bridge 起動中..."
python3 bridges/claude_bridge.py >> "$A2A_DIR/claude_bridge.log" 2>&1 &
BRIDGE_PID=$!
sleep 2
if ps -p $BRIDGE_PID > /dev/null 2>&1; then
    echo "      ✅ 起動成功 (PID: $BRIDGE_PID)"
else
    echo "      ❌ 起動失敗"
    exit 1
fi
echo ""

# 5. GitHub Issue Reader 起動（Claude Code が Issue を自律的に読むため）
echo "[5/5] 📖 GitHub Issue Reader 起動中..."
python3 github_issue_reader.py >> "$A2A_DIR/github_issue_reader.log" 2>&1 &
ISSUE_READER_PID=$!
sleep 2
if ps -p $ISSUE_READER_PID > /dev/null 2>&1; then
    echo "      ✅ 起動成功 (PID: $ISSUE_READER_PID)"
else
    echo "      ⚠️  起動失敗（続行します）"
fi
echo ""

echo ""
echo "=========================================================="
echo "✅ バックエンド起動完了"
echo "=========================================================="
echo ""
echo "📊 起動プロセス:"
echo "  [1] Broker                (PID: $BROKER_PID)"
[ -n "$ORCH_PID" ] && echo "  [2] Orchestrator          (PID: $ORCH_PID)"
[ -n "$GPT5_PID" ] && echo "  [3] GPT-5 Worker          (PID: $GPT5_PID)"
echo "  [4] Claude Bridge         (PID: $BRIDGE_PID)"
[ -n "$ISSUE_READER_PID" ] && echo "  [5] GitHub Issue Reader   (PID: $ISSUE_READER_PID)"
echo ""
echo "💡 Note:"
echo "  • Wrapper削除（issue方式では不要）"
echo "  • GitHub Issue 自律読み込み機能追加"
echo ""

# ===== tmuxセッション作成 =====
echo "[2/2] tmuxセッション作成中..."
sleep 2

# tmuxセッション作成
tmux new-session -d -s "$SESSION_NAME" -n "monitor"

# 水平分割で2ペイン作成
tmux split-window -h -t "$SESSION_NAME:monitor.0"

# 均等レイアウトに変更
tmux select-layout -t "$SESSION_NAME:monitor" even-horizontal

# ペイン0: GPT-5 チャットインターフェース（.envファイル読み込み後に起動）
tmux send-keys -t "$SESSION_NAME:monitor.0" "cd $REPO_ROOT" C-m
tmux send-keys -t "$SESSION_NAME:monitor.0" "clear" C-m
tmux send-keys -t "$SESSION_NAME:monitor.0" "set -a && source .env && set +a && python3 gpt5-chat.py" C-m

# ペイン1: Claude Bridge ログ監視（GPT-5通信確認用）
tmux send-keys -t "$SESSION_NAME:monitor.1" "cd $REPO_ROOT" C-m
tmux send-keys -t "$SESSION_NAME:monitor.1" "clear" C-m
tmux send-keys -t "$SESSION_NAME:monitor.1" "echo '============================================================'" C-m
tmux send-keys -t "$SESSION_NAME:monitor.1" "echo '🌉 Claude Bridge ログ監視（GPT-5通信）'" C-m
tmux send-keys -t "$SESSION_NAME:monitor.1" "echo '============================================================'" C-m
tmux send-keys -t "$SESSION_NAME:monitor.1" "tail -f a2a_system/claude_bridge.log" C-m

echo ""
echo "=========================================================="
echo "✅ スモールチーム起動完了"
echo "=========================================================="
echo ""
echo "📊 tmuxセッション:"
echo "  セッション名: $SESSION_NAME"
echo "  ペイン構成: 2ペイン均等レイアウト"
echo "    - ペイン0: GPT-5 チャットインターフェース (gpt5-chat.py)"
echo "    - ペイン1: Claude Bridge ログ監視 (GPT-5通信確認用)"
echo ""
echo "📺 tmuxレイアウト:"
echo "  ┌─────────────────────────┬─────────────────────────┐"
echo "  │ 🤖 GPT-5 チャット        │ 🌉 Claude Bridge ログ   │"
echo "  │                         │                         │"
echo "  │ gpt5-chat.py (対話可能) │ claude_bridge.log (tail) │"
echo "  │                         │                         │"
echo "  └─────────────────────────┴─────────────────────────┘"
echo ""
echo "🔌 接続方法:"
echo "  tmux attach -t $SESSION_NAME"
echo ""
echo "🛑 停止方法:"
echo "  1. tmux: tmux kill-session -t $SESSION_NAME"
echo "  2. バックエンド: bash $0 stop"
echo ""
echo "💡 使い方:"
echo "  1. tmux attach -t $SESSION_NAME で接続"
echo "  2. ペイン0（左）: GPT-5とチャット - メッセージ入力して対話"
echo "  3. ペイン1（右）: Claude Bridge ログ - GPT-5通信確認"
echo "  4. Ctrl+B → 矢印キー でペイン移動"
echo ""
echo "🔄 ワークフロー:"
echo "  LINE → Issue作成 → GitHub Issue Reader → Claude Code → LINE返信"
echo ""
echo "🎯 システム構成:"
echo "  ✅ Claude Code (開発者本人) - Claude Code CLI"
echo "  ✅ GPT-5 (壁打ち相手) - A2Aエージェント"
echo "  ✅ LINE連携 - GitHub Issue経由の遠隔操作"
echo "  ✅ GitHub Issue Reader - Issue自律読み込み"
echo "=========================================================="

# ===== セッション接続（ロック状態） =====
echo ""
echo "[3/2] セッション接続中..."
echo ""

# セッション存在確認
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "❌ エラー: セッション作成に失敗しました"
    echo ""
    echo "バックエンドプロセスのログを確認してください:"
    echo "  - Broker: $A2A_DIR/broker.log"
    echo "  - GPT-5: $A2A_DIR/gpt5_worker.log"
    echo "  - Bridge: $A2A_DIR/claude_bridge.log"
    echo ""
    exit 1
fi

# ロック状態で接続（Ctrl+C で終了）
echo "✅ セッション接続完了"
echo ""
echo "🔒 ロック状態で起動（フォアグラウンド実行）"
echo "   Ctrl+C で終了するまで保持"
echo ""
echo "📺 tmuxコマンド:"
echo "   • ペイン移動: Ctrl+B → 左右矢印キー"
echo "   • デタッチ: Ctrl+B → D（セッション続行）"
echo "   • 再接続: tmux attach -t $SESSION_NAME"
echo ""

# ロック状態：ユーザーが Ctrl+C で明示的に終了するまで待機
trap "echo ''; echo '========================================================'; echo '🛑 セッション切断'; echo '========================================================'; echo ''; exit 0" INT

tmux attach -t "$SESSION_NAME"

# attach 終了後の処理
echo ""
echo "=========================================================="
echo "✅ セッション接続終了"
echo "=========================================================="
echo ""
echo "📌 確認:"
echo "  • バックエンドプロセスはバックグラウンド実行中です"
echo "  • 再度接続: tmux attach -t $SESSION_NAME"
echo "  • 完全停止: bash $0 stop"
echo ""
