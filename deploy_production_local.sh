#!/bin/bash
# ローカルホームディレクトリへの本番環境デプロイ

set -e

PROD_ROOT="/home/planj/learning-engine-prod"
PROD_DATA="$PROD_ROOT/data"
PROD_CACHE="$PROD_ROOT/cache"
PROD_LOGS="$PROD_ROOT/logs"
PROD_METRICS="$PROD_ROOT/metrics"

echo "🚀 本番環境デプロイ開始"
echo "=================================="

# ディレクトリ作成
echo "📁 本番環境ディレクトリ作成..."
mkdir -p "$PROD_ROOT"
mkdir -p "$PROD_DATA"
mkdir -p "$PROD_CACHE"
mkdir -p "$PROD_LOGS"
mkdir -p "$PROD_METRICS"

# 本番環境設定
echo "⚙️  本番環境設定ファイル作成..."
cat > "$PROD_ROOT/config.json" <<'CONFIG'
{
  "environment": "production",
  "storage": {
    "type": "json",
    "path": "/home/planj/learning-engine-prod/data",
    "backup_interval": 3600,
    "retention_days": 30
  },
  "cache": {
    "enabled": true,
    "type": "adaptive",
    "ttl_base": 300,
    "max_size_mb": 500
  },
  "indexing": {
    "layers": 6,
    "enable_semantic": true,
    "enable_ml_scoring": true,
    "enable_graph": true
  },
  "monitoring": {
    "enabled": true,
    "metrics_path": "/home/planj/learning-engine-prod/metrics",
    "log_level": "INFO"
  }
}
CONFIG

# メタデータ
echo "📊 メタデータ作成..."
cat > "$PROD_ROOT/metadata.json" <<'META'
{
  "version": "3.0.0",
  "deployed_date": "2025-10-17",
  "environment": "production",
  "status": "active",
  "patterns_count": 0,
  "phase": 3,
  "features": [
    "semantic_similarity",
    "pattern_indexing",
    "ml_scoring",
    "semantic_graph",
    "advanced_learning"
  ]
}
META

# 本番環境確認
echo "✅ 本番環境構成確認..."
for dir in data cache logs metrics; do
  [ -d "$PROD_ROOT/$dir" ] && echo "  ✓ $dir" || echo "  ✗ $dir"
done

echo ""
echo "✅ 本番環境デプロイ完了"
echo "本番ルート: $PROD_ROOT"
echo "=================================="
