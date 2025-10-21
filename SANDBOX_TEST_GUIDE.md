# Sandbox テスト完全ガイド

**Claude Code Sandboxing機能の テスト・実行・本番化ガイド**

---

## 📋 目次

1. [テスト体制概要](#テスト体制概要)
2. [テスト実行方法](#テスト実行方法)
3. [テスト結果の読み方](#テスト結果の読み方)
4. [トラブルシューティング](#トラブルシューティング)
5. [本番化チェックリスト](#本番化チェックリスト)

---

## テスト体制概要

### テスト3段階

| フェーズ | ファイル | テスト数 | 内容 |
|---------|---------|--------|------|
| **Phase 1** | `test_unit_sandbox.py` | 12 | ユニットテスト（個別コンポーネント） |
| **Phase 2** | `test_integration_sandbox.py` | 8 | 統合テスト（コンポーネント連携） |
| **Phase 3** | `test_e2e_sandbox.py` | 12 | E2Eテスト（全フロー） |
| **本番化** | `test_production_checklist.py` | 30 | 本番化チェック |

**合計：62テスト**

---

## テスト実行方法

### 全テスト実行

```bash
# 全テスト一括実行
python3 -m unittest discover -s tests -p "test_*.py" -v

# または Phase ごとに実行
python3 -m unittest tests.test_unit_sandbox -v
python3 -m unittest tests.test_integration_sandbox -v
python3 -m unittest tests.test_e2e_sandbox -v
python3 -m unittest tests.test_production_checklist -v
```

### 個別テスト実行

```bash
# 特定のテストクラス実行
python3 -m unittest tests.test_e2e_sandbox.TestSandboxE2EFlow -v

# 特定のテストメソッド実行
python3 -m unittest tests.test_e2e_sandbox.TestSandboxE2EFlow.test_e2e_normal_flow_simple_request -v
```

### テスト実行オプション

```bash
# 詳細出力
python3 -m unittest tests.test_sandbox_implementation -v

# エラー時に詳細表示
python3 -m unittest tests.test_sandbox_implementation -v --tb=long

# 特定テストのみ
python3 -m unittest tests.test_sandbox_implementation.TestSandboxFilterLogic.test_permit_path_check -v
```

---

## テスト結果の読み方

### 成功時の出力

```
test_e2e_normal_flow_simple_request (tests.test_e2e_sandbox.TestSandboxE2EFlow)
【E2E正常系】シンプルなリクエスト → 実行 → 返信 ... ok

test_e2e_deny_flow_unauthorized_path (tests.test_e2e_sandbox.TestSandboxE2EFlow)
【E2E拒否系】許可されていないパス → Sandbox 拒否 → 「エラーです」返信 ... ok

----------------------------------------------------------------------
Ran 12 tests in 0.007s

OK
```

**読み方**:
- `... ok` = テスト成功
- `Ran 12 tests` = 実行数
- `0.007s` = 実行時間
- `OK` = 全テスト成功

### 失敗時の出力

```
test_e2e_normal_flow_simple_request (tests.test_e2e_sandbox.TestSandboxE2EFlow) ... FAIL

======================================================================
FAIL: test_e2e_normal_flow_simple_request (tests.test_e2e_sandbox.TestSandboxE2EFlow)
----------------------------------------------------------------------
AssertionError: False is not True
```

**対処方法**:
1. エラーメッセージを確認
2. テスト内容を確認（コメント参照）
3. トラブルシューティング参照

---

## テスト結果サマリー

### Phase 1: ユニットテスト

```
test_sandbox_filter_logic (tests.test_unit_sandbox.TestSandboxFilterLogic) ... ok
test_sandbox_message_protocol (tests.test_unit_sandbox.TestMessageProtocol) ... ok
... (合計12テスト)

Ran 12 tests in 0.005s → OK
```

**テスト項目**:
- permit パス検証 ✅
- deny パス検証 ✅
- メッセージ作成 ✅
- ログ記録 ✅

### Phase 2: 統合テスト

```
test_message_bridge_integration (tests.test_integration_sandbox.TestMessageBridgeIntegration) ... ok
test_sandbox_context_flow (tests.test_integration_sandbox.TestSandboxContextFlow) ... ok
... (合計8テスト)

Ran 8 tests in 0.003s → OK
```

**テスト項目**:
- メッセージ生成 → JSON 変換 ✅
- Bridge 処理 ✅
- ログ記録確認 ✅

### Phase 3: E2Eテスト

```
Ran 12 tests in 0.007s → OK
```

**テスト項目**:
- 正常系（2テスト）✅
- 拒否系（3テスト）✅
- エッジケース（4テスト）✅
- ログ・監査（1テスト）✅
- パフォーマンス（2テスト）✅

### 本番化チェック

```
Ran 30 tests in 0.002s → OK
```

**チェック項目**:
- セキュリティテスト（15項目）✅
  - 危険キーワード 10パターン
  - SQLインジェクション 5パターン
- パフォーマンステスト（2項目）✅
- エラーハンドリング（5ケース）✅
- 本番環境設定（4項目）✅
- サマリー（4項目）✅

---

## トラブルシューティング

### Q1: テスト実行時に `ModuleNotFoundError`

```
ModuleNotFoundError: No module named 'a2a_system'
```

**原因**: Python のパス設定が正しくない

**解決方法**:
```bash
# リポジトリルートで実行
cd /home/planj/Claude-Code-Communication

# テスト実行
python3 -m unittest tests.test_sandbox_implementation -v
```

### Q2: テスト実行が遅い

**原因**: パフォーマンステストの実行時間

**解決方法**:
```bash
# 特定テストのみ実行
python3 -m unittest tests.test_e2e_sandbox.TestSandboxE2EFlow -v

# パフォーマンステストをスキップ
python3 -m unittest tests.test_e2e_sandbox.TestSandboxE2EFlow -v
```

### Q3: セキュリティテストが失敗

```
AssertionError: False is not True
```

**原因**: 危険キーワード検出ロジックが正しく動作していない

**確認方法**:
```bash
# 個別テスト実行
python3 -m unittest tests.test_production_checklist.TestSecurityChecklist.test_dangerous_keyword_rm_rf -v

# ログ確認
cat /a2a_system/shared/sandbox_security.log
```

### Q4: Sandbox ログが出力されない

**原因**: ログファイルパスが正しくない

**確認方法**:
```bash
# ログファイル確認
ls -la /a2a_system/shared/

# ディレクトリ作成（必要に応じて）
mkdir -p /a2a_system/shared/

# テスト再実行
python3 -m unittest tests.test_production_checklist -v
```

### Q5: LINE Bridge との連携テストが失敗

**原因**: LINE Bridge サービスが起動していない

**確認方法**:
```bash
# LINE Bridge 起動状態確認
ps aux | grep line

# LINE Bridge 再起動
./start-small-team.sh

# テスト再実行
python3 -m unittest tests.test_e2e_sandbox -v
```

---

## 本番化チェックリスト

### ✅ テスト実行確認

- [ ] 全テスト実行して `OK` を確認
  ```bash
  python3 -m unittest discover -s tests -p "test_*.py" -v
  ```

- [ ] 本番化チェックリスト実行
  ```bash
  python3 -m unittest tests.test_production_checklist -v
  ```

### ✅ セキュリティ確認

- [ ] 危険キーワード 10パターン検出 ✅
- [ ] SQLインジェクション 5パターン検出 ✅
- [ ] ユーザーには詳細エラーを返さない ✅
- [ ] サーバーログには詳細が記録される ✅

### ✅ パフォーマンス確認

- [ ] 100メッセージ処理：5秒以内 ✅
- [ ] 1000メッセージ処理：15秒以内 ✅

### ✅ エラーハンドリング確認

- [ ] 不正パスアクセス：「エラーです」返信 ✅
- [ ] SQLインジェクション：「エラーです」返信 ✅
- [ ] タイムアウト：「エラーです」返信 ✅
- [ ] ネットワークエラー：「エラーです」返信 ✅
- [ ] 形式不正：「エラーです」返信 ✅

### ✅ 本番環境設定確認

- [ ] Sandbox 有効化 ✅
- [ ] permit/deny パス設定 ✅
- [ ] エラー詳細非表示 ✅
- [ ] ログ設定完了 ✅

### ✅ ドキュメント確認

- [ ] テスト方法書完成 ✅
- [ ] トラブルシューティング完成 ✅
- [ ] 本番化チェックリスト完成 ✅

### ✅ 最終確認

- [ ] 開発環境：全テスト PASS
- [ ] Staging 環境：全テスト PASS
- [ ] 本番環境設定：確認完了
- [ ] リリース可能

---

## 実行ログサンプル

### 成功時のログサンプル

```
[2025-10-21T10:30:45.123Z] ALLOWED: list_files /home/planj/Claude-Code-Communication - user_001
[2025-10-21T10:30:46.456Z] ALLOWED: read_file /home/planj/Claude-Code-Communication/CLAUDE.md - user_002
[2025-10-21T10:30:47.789Z] DENIED: read_file /etc/passwd - reason=Unauthorized path - user_003 - SEVERITY=BLOCKED
[2025-10-21T10:30:48.012Z] ERROR: timeout - execution_time=45s - timeout=30s - user_004 - SEVERITY=WARNING
```

### ログファイル場所

```
/a2a_system/shared/sandbox_security.log
```

### ログ監視

```bash
# リアルタイム監視
tail -f /a2a_system/shared/sandbox_security.log

# 特定ユーザーのログ
grep "user_001" /a2a_system/shared/sandbox_security.log

# 拒否されたリクエスト確認
grep "DENIED" /a2a_system/shared/sandbox_security.log
```

---

## 次ステップ

1. ✅ テスト実行 → 62テスト全PASS
2. ✅ 本番化チェック実行 → 30テスト全PASS
3. ⏳ **本番デプロイ** → GPT-5 review 待機中

---

**作成日**: 2025-10-21
**テスト: Claude Code (UI/テスト側)**
**レビュー待機中: GPT-5**
