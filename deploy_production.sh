#!/bin/bash

# 本番環境デプロイスクリプト
# Phase 3 学習機能を本番環境へ段階的にデプロイ

set -e

echo "🚀 本番環境デプロイ開始"
echo "=================================="

# 1. 本番環境ディレクトリ構成
echo "📁 本番環境ディレクトリ構成..."
PROD_ROOT="/opt/learning-engine"
PROD_DATA="$PROD_ROOT/data"
PROD_CACHE="$PROD_ROOT/cache"
PROD_LOGS="$PROD_ROOT/logs"
PROD_METRICS="$PROD_ROOT/metrics"

mkdir -p "$PROD_ROOT"
mkdir -p "$PROD_DATA"
mkdir -p "$PROD_CACHE"
mkdir -p "$PROD_LOGS"
mkdir -p "$PROD_METRICS"

# 2. 本番環境設定ファイル
echo "⚙️  本番環境設定..."
cat > "$PROD_ROOT/config.json" <<'EOF'
{
  "environment": "production",
  "storage": {
    "type": "json",
    "path": "/opt/learning-engine/data",
    "backup_interval": 3600,
    "retention_days": 30
  },
  "cache": {
    "enabled": true,
    "type": "adaptive",
    "ttl_base": 300,
    "max_size_mb": 500,
    "cleanup_interval": 600
  },
  "indexing": {
    "layers": 6,
    "enable_semantic": true,
    "enable_ml_scoring": true,
    "enable_graph": true
  },
  "learning": {
    "continuous_enabled": true,
    "feedback_required": true,
    "min_confidence": 0.6,
    "update_interval": 60
  },
  "monitoring": {
    "enabled": true,
    "metrics_path": "/opt/learning-engine/metrics",
    "log_level": "INFO",
    "performance_threshold_ms": 50,
    "alert_enabled": true
  },
  "performance": {
    "max_patterns": 100000,
    "batch_size": 100,
    "timeout_seconds": 300,
    "retry_attempts": 3
  }
}
EOF

# 3. 本番環境ロギング設定
echo "📋 本番環境ロギング設定..."
cat > "$PROD_ROOT/logging.json" <<'EOF'
{
  "version": 1,
  "disable_existing_loggers": false,
  "formatters": {
    "standard": {
      "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    },
    "detailed": {
      "format": "%(asctime)s - %(name)s - %(levelname)s - [%(filename)s:%(lineno)d] - %(message)s"
    }
  },
  "handlers": {
    "console": {
      "class": "logging.StreamHandler",
      "level": "INFO",
      "formatter": "standard",
      "stream": "ext://sys.stdout"
    },
    "file": {
      "class": "logging.handlers.RotatingFileHandler",
      "level": "DEBUG",
      "formatter": "detailed",
      "filename": "/opt/learning-engine/logs/learning_engine.log",
      "maxBytes": 10485760,
      "backupCount": 10
    },
    "error_file": {
      "class": "logging.handlers.RotatingFileHandler",
      "level": "ERROR",
      "formatter": "detailed",
      "filename": "/opt/learning-engine/logs/errors.log",
      "maxBytes": 10485760,
      "backupCount": 5
    }
  },
  "loggers": {
    "": {
      "level": "INFO",
      "handlers": ["console", "file", "error_file"]
    }
  }
}
EOF

# 4. 本番環境初期化スクリプト
echo "🔧 本番環境初期化スクリプト..."
cat > "$PROD_ROOT/init_production.py" <<'PYTHON_EOF'
#!/usr/bin/env python3
"""本番環境初期化スクリプト"""

import json
import os
from pathlib import Path

def initialize_production():
    """本番環境を初期化"""
    prod_root = Path("/opt/learning-engine")

    print("🚀 本番環境初期化開始...")

    # 1. ディレクトリ権限設定
    print("📁 ディレクトリ権限設定...")
    os.makedirs(prod_root / "data", exist_ok=True)
    os.makedirs(prod_root / "cache", exist_ok=True)
    os.makedirs(prod_root / "logs", exist_ok=True)
    os.makedirs(prod_root / "metrics", exist_ok=True)

    # 2. 初期メタデータ作成
    print("📊 初期メタデータ作成...")
    metadata = {
        "version": "3.0.0",
        "initialized_date": "2025-10-17",
        "environment": "production",
        "status": "initialized",
        "patterns_count": 0,
        "graph_nodes": 0,
        "cache_size_mb": 0
    }

    with open(prod_root / "metadata.json", "w") as f:
        json.dump(metadata, f, indent=2)

    # 3. 本番環境チェック
    print("✅ 本番環境チェック...")
    required_dirs = ["data", "cache", "logs", "metrics"]
    for dir_name in required_dirs:
        dir_path = prod_root / dir_name
        if dir_path.exists():
            print(f"  ✓ {dir_name}ディレクトリ: OK")
        else:
            print(f"  ✗ {dir_name}ディレクトリ: 作成失敗")
            return False

    required_files = ["config.json", "logging.json", "metadata.json"]
    for file_name in required_files:
        file_path = prod_root / file_name
        if file_path.exists():
            print(f"  ✓ {file_name}: OK")
        else:
            print(f"  ✗ {file_name}: 作成失敗")
            return False

    print("\n✅ 本番環境初期化完了")
    return True

if __name__ == "__main__":
    initialize_production()
PYTHON_EOF

chmod +x "$PROD_ROOT/init_production.py"

# 5. Python初期化スクリプト実行
echo "⚙️  本番環境初期化実行..."
python3 "$PROD_ROOT/init_production.py"

# 6. 本番環境モニタリング開始
echo "📡 本番環境モニタリング開始..."
cat > "$PROD_ROOT/monitor_production.sh" <<'EOF'
#!/bin/bash

PROD_ROOT="/opt/learning-engine"

while true; do
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

  # リソース監視
  MEM_USAGE=$(free -m | awk 'NR==2{print $3}')
  CPU_LOAD=$(uptime | awk -F'load average:' '{print $2}')

  # ログファイルサイズ
  LOG_SIZE=$(du -sh "$PROD_ROOT/logs" 2>/dev/null | awk '{print $1}')

  # キャッシュサイズ
  CACHE_SIZE=$(du -sh "$PROD_ROOT/cache" 2>/dev/null | awk '{print $1}')

  echo "[$TIMESTAMP] MEM: ${MEM_USAGE}MB | CPU: $CPU_LOAD | LOG: $LOG_SIZE | CACHE: $CACHE_SIZE" >> "$PROD_ROOT/logs/monitoring.log"

  # アラート確認（メモリが80%以上）
  MEM_PERCENT=$(free | awk 'NR==2{printf("%d", $3/$2 * 100)}')
  if [ "$MEM_PERCENT" -gt 80 ]; then
    echo "[ALERT] メモリ使用率が高い: ${MEM_PERCENT}%" >> "$PROD_ROOT/logs/alerts.log"
  fi

  sleep 60
done
EOF

chmod +x "$PROD_ROOT/monitor_production.sh"

# 7. デプロイ完了
echo ""
echo "✅ 本番環境デプロイ完了"
echo "=================================="
echo "本番環境パス: $PROD_ROOT"
echo "設定ファイル: $PROD_ROOT/config.json"
echo "ログディレクトリ: $PROD_LOGS"
echo "メトリクスディレクトリ: $PROD_METRICS"
echo ""
echo "次のステップ："
echo "1. 本番環境設定確認: cat $PROD_ROOT/config.json"
echo "2. モニタリング開始: $PROD_ROOT/monitor_production.sh &"
echo "3. サービス起動: systemctl start learning-engine"
echo ""
