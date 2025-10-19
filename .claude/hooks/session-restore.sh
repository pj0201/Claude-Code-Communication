#!/bin/bash
# セッション開始時にコンテキストを自動復元

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANAGER="$SCRIPT_DIR/session_context_manager.py"

if [ -f "$MANAGER" ]; then
    python3 "$MANAGER"
fi
