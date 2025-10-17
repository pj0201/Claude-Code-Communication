# セキュリティルール（絶対遵守）

## ⚠️ 絶対的禁止事項

### 1. 認証情報の表示・出力禁止
**以下の情報は絶対にチャット・ログ・出力に表示してはならない**：

- GitHub Personal Access Token
- API Keys (OPENAI_API_KEY, XAI_API_KEY, ANTHROPIC_API_KEY等)
- LINE Channel Access Token / Secret
- パスワード
- プライベートキー
- その他すべての認証情報

### 2. .envファイルの取り扱い
- `.env`ファイルの内容を`cat`や`Read`で表示する際は、**認証情報をマスク**する
- トークンやキーを含む行は `***MASKED***` と表示する
- ログファイルに`.env`の内容を出力しない

### 3. Git操作での認証情報
- トークンを含むURLは絶対に表示しない
- `git remote -v` の出力でトークンが見える場合は即座に削除
- トークンを環境変数経由で使用し、コマンド履歴に残さない

### 4. エラーメッセージの取り扱い
- エラーメッセージにトークンが含まれる場合は、マスクしてから表示
- ログファイルにも認証情報を記録しない

## ✅ 正しい取り扱い方法

### トークンを使用したGit操作
```bash
# ❌ 間違い：トークンが表示される
echo "GITHUB_TOKEN=ghp_xxxxx"
git remote set-url origin https://ghp_xxxxx@github.com/...

# ✅ 正しい：トークンを表示せず使用
source .env  # トークンを環境変数にロード
git remote set-url origin https://${GITHUB_TOKEN}@github.com/...
# 使用後は即座に元に戻す
git remote set-url origin https://github.com/...
```

### .envファイルの確認
```bash
# ❌ 間違い：全内容を表示
cat .env

# ✅ 正しい：キーの存在のみ確認
grep -c "GITHUB_TOKEN" .env  # 行数のみ表示
```

## 🚨 違反時の対処

**認証情報を流出させた場合**：
1. **即座にトークン・キーを無効化**（GitHub/OpenAI/X.AI/LINE等）
2. 新しいトークン・キーを生成
3. `.env`ファイルに新しい値を保存
4. チャット履歴を削除（可能な場合）
5. このミスから学び、二度と繰り返さない

---

**このルールは絶対です。いかなる理由があっても例外は認められません。**
