# GPT-5 独立チャットガイド

## 概要

Claude CodeとGPT-5を**2ペイン構成**で同時起動し、以下を実現：

- **左ペイン**: Claude Code（メインエージェント）
- **右ペイン**: GPT-5 独立チャット（ユーザーが直接対話）

## セットアップ

### 1. APIキー設定

```bash
# 環境変数に設定
export OPENAI_API_KEY='your-openai-api-key'

# または .env ファイルに保存
echo "OPENAI_API_KEY=your-api-key" >> ~/.env
source ~/.env
```

### 2. 起動

```bash
# Claude Code + GPT-5を2ペインで起動
./start-claude-with-gpt5.sh
```

## 画面構成

```
┌─────────────────────────────┬──────────────────────┐
│                             │                      │
│   Claude Code               │   GPT-5 Chat         │
│   (左ペイン - 60%)           │   (右ペイン - 40%)    │
│                             │                      │
│   - メインエージェント        │   - 独立チャットUI     │
│   - ファイル操作             │   - ユーザー直接入力   │
│   - コード生成               │   - 相談・壁打ち       │
│                             │                      │
└─────────────────────────────┴──────────────────────┘
```

## 使い方

### ペイン切り替え

| キー操作 | 動作 |
|---------|------|
| `Ctrl+b` → `o` | ペイン切り替え（左⇄右） |
| `Ctrl+b` → `←` / `→` | ペイン移動 |
| `Ctrl+b` → `d` | デタッチ（バックグラウンド化） |

### GPT-5チャット コマンド

| コマンド | 説明 |
|---------|------|
| `/save` | 会話履歴を保存 |
| `/clear` | 会話履歴をクリア |
| `/exit` | GPT-5チャット終了 |

### 再接続

```bash
# デタッチ後に再接続
tmux attach -t claude-gpt5
```

## ユースケース

### 1. アーキテクチャ相談

**左ペイン（Claude Code）**: コード実装中

**右ペイン（GPT-5）**:
```
👤 You: このログイン機能のアーキテクチャ、セキュリティ観点でどう思う？

🤖 GPT-5: JWT認証を推奨します。理由は...
```

### 2. デバッグ壁打ち

**左ペイン（Claude Code）**: エラー調査中

**右ペイン（GPT-5）**:
```
👤 You: なぜこのエラーが出るのか考えを聞かせて

🤖 GPT-5: このエラーは非同期処理の競合が原因です...
```

### 3. コードレビュー依頼

**左ペイン（Claude Code）**: 実装完了

**右ペイン（GPT-5）**:
```
👤 You: 今書いたコード、パフォーマンス改善点ある？

🤖 GPT-5: はい、3点改善可能です...
```

## 終了方法

### 各ペインを個別終了

1. GPT-5チャット: `/exit` または `Ctrl+C`
2. Claude Code: `Ctrl+D` または `exit`

### セッション全体を終了

```bash
tmux kill-session -t claude-gpt5
```

## トラブルシューティング

### APIキーエラー

```bash
❌ OPENAI_API_KEYが設定されていません
```

**解決方法**:
```bash
export OPENAI_API_KEY='your-api-key'
./start-claude-with-gpt5.sh
```

### 既存セッション競合

```bash
❌ sessions should be nested with care
```

**解決方法**:
```bash
# tmux外で実行
tmux kill-session -t claude-gpt5
./start-claude-with-gpt5.sh
```

### Python依存関係エラー

```bash
❌ ModuleNotFoundError: No module named 'openai'
```

**解決方法**:
```bash
pip install openai
```

## ファイル構成

```
Claude-Code-Communication/
├── start-claude-with-gpt5.sh  # 統合起動スクリプト
├── gpt5-chat.py               # GPT-5独立チャットUI
├── GPT5-CHAT-GUIDE.md         # このガイド
└── logs/                      # 会話履歴保存先
    └── gpt5_chat_*.json
```

## 応用：3ペイン構成（A2A追加）

Claude Code + GPT-5 + A2Aシステム監視:

```bash
# 手動で3ペイン構成
tmux new-session -s dev
tmux split-window -h
tmux split-window -v

# ペイン1: Claude Code
# ペイン2: GPT-5チャット
# ペイン3: A2Aシステム監視
```

---

**作成日**: 2025-10-06
**バージョン**: 1.0.0
