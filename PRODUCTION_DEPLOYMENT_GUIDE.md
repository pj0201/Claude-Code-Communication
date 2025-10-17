# 本番環境デプロイメント・ガイド

**デプロイ日時**: 2025-10-17
**バージョン**: Phase 3
**ステータス**: ✅ **本番環境対応完了**

---

## 📋 本番環境構成

### ディレクトリ構造

```
/home/planj/learning-engine-prod/
├── config.json              # 本番設定ファイル
├── metadata.json            # メタデータ
├── engine/                  # 学習機能エンジン
│   ├── advanced_learning_engine.py
│   ├── semantic_similarity.py
│   ├── pattern_indexing.py
│   ├── ml_similarity_scoring.py
│   ├── semantic_graph.py
│   └── [その他モジュール]
├── data/                    # パターンデータ
├── cache/                   # キャッシング
├── logs/                    # ログファイル
├── metrics/                 # パフォーマンスメトリクス
├── start.sh                 # 起動スクリプト
├── stop.sh                  # 停止スクリプト
└── status.sh                # ステータス確認
```

---

## 🚀 本番環境起動

### 1. 起動コマンド

```bash
# 本番環境起動
/home/planj/learning-engine-prod/start.sh

# ステータス確認
/home/planj/learning-engine-prod/status.sh

# ログ確認
tail -f /home/planj/learning-engine-prod/logs/startup.log
```

### 2. 起動時のパラメータ

```
--environment production        # 本番環境フラグ
--config [設定ファイル]         # 設定ファイルパス
--data-dir [データディレクトリ] # データ保存先
--cache-dir [キャッシュ]        # キャッシュ保存先
--log-dir [ログディレクトリ]    # ログ出力先
--metrics-dir [メトリクス]      # メトリクス保存先
```

---

## 🔧 本番環境設定

### config.json - 主要設定項目

```json
{
  "environment": "production",
  "storage": {
    "type": "json",
    "backup_interval": 3600,      # バックアップ間隔（秒）
    "retention_days": 30          # リテンション期間
  },
  "cache": {
    "enabled": true,
    "type": "adaptive",
    "ttl_base": 300,              # 基本TTL（秒）
    "max_size_mb": 500            # キャッシュ上限（MB）
  },
  "indexing": {
    "layers": 6,                  # インデックス層数
    "enable_semantic": true,      # セマンティック検索
    "enable_ml_scoring": true,    # ML スコアリング
    "enable_graph": true          # グラフ分析
  },
  "monitoring": {
    "enabled": true,
    "log_level": "INFO",
    "performance_threshold_ms": 50 # パフォーマンス閾値
  }
}
```

---

## 📊 本番環境操作

### ステータス確認

```bash
/home/planj/learning-engine-prod/status.sh
```

**出力例**:
```
📊 本番環境ステータス
==================================
✅ ステータス: 実行中 (PID: 12345)
...

📈 リソース使用状況
500M    /home/planj/learning-engine-prod/data
300M    /home/planj/learning-engine-prod/cache
100M    /home/planj/learning-engine-prod/logs
50M     /home/planj/learning-engine-prod/metrics
```

### ログ監視

```bash
# リアルタイムログ監視
tail -f /home/planj/learning-engine-prod/logs/startup.log

# エラーログ確認
grep ERROR /home/planj/learning-engine-prod/logs/*.log

# 最新ログ（最後の50行）
tail -50 /home/planj/learning-engine-prod/logs/startup.log
```

### パフォーマンス確認

```bash
# メトリクスディレクトリ確認
ls -lh /home/planj/learning-engine-prod/metrics/

# キャッシュ効率確認
tail -f /home/planj/learning-engine-prod/metrics/cache_stats.json
```

---

## 🛑 本番環境停止

### 停止コマンド

```bash
# 本番環境停止
/home/planj/learning-engine-prod/stop.sh

# グレースフルシャットダウン（リソース保存）
kill -SIGTERM $(cat /home/planj/learning-engine-prod/learning_engine.pid)
```

---

## 📈 本番環境モニタリング

### 推奨監視項目

| 項目 | 正常値 | 警告値 | 障害値 |
|------|--------|--------|--------|
| CPU使用率 | <50% | 50-80% | >80% |
| メモリ使用率 | <60% | 60-85% | >85% |
| ディスク空き | >10GB | 1-10GB | <1GB |
| キャッシュヒット率 | >80% | 60-80% | <60% |
| 検索応答時間 | <10ms | 10-50ms | >50ms |

### 定期メンテナンス

**日次**:
- ✅ ログローテーション（自動）
- ✅ キャッシュクリーンアップ（自動）

**週次**:
- ✅ メトリクス分析
- ✅ パフォーマンスレビュー

**月次**:
- ✅ データバックアップ確認
- ✅ ディスク容量確認
- ✅ 本番環境更新チェック

---

## 🔐 本番環境セキュリティ

### アクセス制限

```bash
# ディレクトリ権限
chmod 700 /home/planj/learning-engine-prod/
chmod 600 /home/planj/learning-engine-prod/config.json
chmod 700 /home/planj/learning-engine-prod/*.sh
```

### ログアーカイブ

```bash
# ログアーカイブ（7日以上前）
find /home/planj/learning-engine-prod/logs -mtime +7 -type f -exec gzip {} \;

# アーカイブ削除（30日以上前）
find /home/planj/learning-engine-prod/logs -mtime +30 -name "*.gz" -delete
```

---

## 🔄 本番環境更新

### Phase 4への更新準備

```bash
# 現在のバージョン確認
cat /home/planj/learning-engine-prod/metadata.json | jq '.version'

# バックアップ取得
cp -r /home/planj/learning-engine-prod /home/planj/learning-engine-prod.backup

# 新バージョンコピー
# (構築スクリプト実行後)
```

---

## 🆘 トラブルシューティング

### よくある問題

**問題1: 起動エラー**
```bash
# ログ確認
cat /home/planj/learning-engine-prod/logs/startup.log

# 依存関係確認
pip3 list | grep -E "psutil|numpy|scipy"

# キャッシュクリア
rm -rf /home/planj/learning-engine-prod/cache/*
```

**問題2: メモリ不足**
```bash
# メモリ使用状況確認
free -h

# キャッシュサイズ削減
# config.jsonの max_size_mb を削減して再起動
```

**問題3: ディスク満杯**
```bash
# ディスク使用状況
du -sh /home/planj/learning-engine-prod/*

# 古いログ削除
find /home/planj/learning-engine-prod/logs -mtime +30 -delete
```

---

## 📞 サポート情報

### ログファイル位置

- メインログ: `/home/planj/learning-engine-prod/logs/startup.log`
- エラーログ: `/home/planj/learning-engine-prod/logs/errors.log`
- メトリクス: `/home/planj/learning-engine-prod/metrics/`

### 重要なコマンド

```bash
# 起動
/home/planj/learning-engine-prod/start.sh

# 停止
/home/planj/learning-engine-prod/stop.sh

# ステータス
/home/planj/learning-engine-prod/status.sh

# ログ監視
tail -f /home/planj/learning-engine-prod/logs/startup.log

# リソース確認
du -sh /home/planj/learning-engine-prod/*
```

---

## ✅ 本番環境チェックリスト

本番環境起動前に以下をご確認ください:

- [ ] 本番ディレクトリ存在: `/home/planj/learning-engine-prod/`
- [ ] 設定ファイル確認: `config.json`
- [ ] エンジンファイル確認: `engine/` ディレクトリ
- [ ] ディレクトリ権限確認: `ls -la learning-engine-prod/`
- [ ] スクリプト実行権限: `ls -la *.sh`
- [ ] ディスク容量確認: 最低 5GB 以上
- [ ] メモリ確認: 最低 2GB 以上

---

**本番環境デプロイメント**: ✅ **完了**

本番環境は即座に起動可能な状態です。
