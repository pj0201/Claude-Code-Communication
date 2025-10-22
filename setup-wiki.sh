#!/bin/bash
# GitHub WIKI リポジトリをセットアップ

set -e

REPO_URL="$1"
WIKI_TARGET_DIR="${2:-.wiki}"

if [ -z "$REPO_URL" ]; then
    echo "使用方法: ./setup-wiki.sh <WIKI-REPO-URL> [TARGET-DIR]"
    echo ""
    echo "例："
    echo "  ./setup-wiki.sh https://github.com/pj0201/Claude-Code-Communication.wiki.git .wiki"
    echo ""
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 GitHub WIKI セットアップ"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# WIKI リポジトリの存在確認
if [ -d "$WIKI_TARGET_DIR" ]; then
    echo "✅ WIKI リポジトリが既に存在します: $WIKI_TARGET_DIR"
    echo "   (既存のリポジトリをそのまま使用します)"
else
    echo "📦 WIKI リポジトリをクローン中..."
    git clone "$REPO_URL" "$WIKI_TARGET_DIR"
    echo "✅ クローン完了: $WIKI_TARGET_DIR"
fi

echo ""
echo "✅ WIKI セットアップ完了！"
echo ""
echo "次のステップ:"
echo "1. .env ファイルを編集して WIKI_REPO_PATH を設定："
echo "   WIKI_REPO_PATH=$(pwd)/$WIKI_TARGET_DIR"
echo ""
echo "2. デーモンを起動："
echo "   python3 a2a_system/learning_engine_daemon.py"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
