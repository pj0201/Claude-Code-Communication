# MCPツール・外部ツールディレクトリ

このディレクトリには、マルチエージェントチームが使用するMCPサーバーや外部ツールを配置します。

## 📂 ディレクトリ構造

```
tools/
├── README.md                      # このファイル
├── chrome-mcp-setup.md            # Chrome MCP セットアップガイド
├── mcp-chrome/                    # Chrome MCP Server（gitサブモジュール）
├── o3-search-mcp/                 # O3 Search MCP（gitサブモジュール）
└── mcp-server-browserbase/        # Browserbase MCP Server（gitサブモジュール）
```

## 🔧 主要MCPツール

### 1. Chrome MCP Server
- **リポジトリ**: https://github.com/pj0201/mcp-chrome.git
- **用途**: Chromeブラウザの直接制御
- **セットアップ**: `chrome-mcp-setup.md` 参照

### 2. O3 Search MCP
- **リポジトリ**: https://github.com/pj0201/o3-search-mcp.git
- **用途**: O3推論エンジン専用検索ツール

### 3. Browserbase MCP Server
- **リポジトリ**: （公式リポジトリURL）
- **用途**: LLMによる自然言語ブラウザ制御

## 🚀 セットアップ手順

### gitサブモジュールの初期化
```bash
cd /home/planj/Claude-Code-Communication

# 全サブモジュールを一括初期化
git submodule update --init --recursive

# または個別に追加
git submodule add https://github.com/pj0201/mcp-chrome.git tools/mcp-chrome
git submodule add https://github.com/pj0201/o3-search-mcp.git tools/o3-search-mcp
```

### 各ツールのビルド・インストール
```bash
# Chrome MCP
cd tools/mcp-chrome
npm install
npm run build

# O3 Search MCP
cd tools/o3-search-mcp
npm install
npm run build

# Browserbase MCP
cd tools/mcp-server-browserbase
npm install
npm run build
```

## 📋 MCP設定

各エージェントのMCP設定は `.claude/settings.json` または `mcp.json` で管理します。

### 設定例
```json
{
  "mcpServers": {
    "chrome": {
      "command": "node",
      "args": ["/home/planj/Claude-Code-Communication/tools/mcp-chrome/dist/index.js"]
    },
    "o3-search": {
      "command": "node",
      "args": ["/home/planj/Claude-Code-Communication/tools/o3-search-mcp/dist/index.js"]
    }
  }
}
```

## 🔍 ツール使用ガイドライン

### Context7 MCP Server
- **対象**: 全エージェント
- **用途**: 最新ライブラリ・フレームワークの仕様取得
- **優先度**: ⭐⭐⭐⭐⭐

### Serena MCP Server
- **対象**: Worker全員
- **用途**: セマンティックコード理解・解析・編集
- **優先度**: ⭐⭐⭐⭐⭐

### Grok CLI
- **対象**: GROK4専用
- **用途**: xAI Grokモデルのターミナル統合
- **優先度**: ⭐⭐⭐⭐

## ⚠️ 重要事項

1. **セキュリティ**: 環境変数・認証情報は `.env` に保存（`.gitignore`登録必須）
2. **バージョン管理**: サブモジュールは適切なバージョンでピン留め
3. **依存関係**: 各ツールの `package.json` で依存関係を管理

## 📚 参考ドキュメント

- CLAUDE.md - チーム運営ガイド
- /home/planj/Claude-Code-Communication/README.md - プロジェクト全体概要
