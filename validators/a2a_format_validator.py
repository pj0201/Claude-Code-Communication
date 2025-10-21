#!/usr/bin/env python3
"""
A2A フォーマットバリデータ
Claude Code → GPT-5 通信メッセージの検証

検証ルール：
- ネスト深さ: MAX 3階層
- フィールド数: 4個固定
- "content" フィールド: 拒否
- 予約語以外のフィールド: 拒否
- null/undefined 値: 拒否
"""

import json
import logging
from typing import Dict, Any, Tuple, List
from datetime import datetime


class A2AFormatValidator:
    """A2A通信メッセージフォーマット検証クラス"""

    # 許可されたメッセージタイプ
    ALLOWED_TYPES = {"QUESTION", "ANSWER", "SEND_LINE", "GITHUB_ISSUE"}

    # 必須フィールド（高速化のため set 使用）
    REQUIRED_FIELDS = {"type", "sender", "target"}

    # 許可されたフィールド
    ALLOWED_FIELDS = {"type", "sender", "target", "question", "answer", "timestamp"}

    # 拒否されるフィールド
    BANNED_FIELDS = {"content", "message", "data", "payload", "request", "response"}

    # ネスト深さの最大値
    MAX_NESTING_DEPTH = 3

    # 固定フィールド数（基本：4、タイムスタンプ付きで5）
    MIN_FIELD_COUNT = 4
    MAX_FIELD_COUNT = 5

    def __init__(self, enable_logging: bool = True):
        """
        初期化

        Args:
            enable_logging: ログ出力の有効化
        """
        self.logger = logging.getLogger(__name__)
        self.enable_logging = enable_logging
        if not enable_logging:
            self.logger.disabled = True

    def validate(self, message: Dict[str, Any]) -> Tuple[bool, str]:
        """
        メッセージの完全検証（高速化版）

        Args:
            message: 検証対象メッセージ

        Returns:
            (成功フラグ, エラーメッセージ)
        """
        # 高速フェイル：NULL チェック + 辞書チェック
        if not message or not isinstance(message, dict):
            if message is None:
                return False, "エラー: メッセージが NULL です"
            return False, f"エラー: メッセージは dict である必要があります（受け取り型: {type(message).__name__}）"

        # 必須フィールド確認（高速化：全て揃っているか確認）
        message_keys = set(message.keys())
        if not self.REQUIRED_FIELDS <= message_keys:  # 高速な部分集合チェック
            missing = self.REQUIRED_FIELDS - message_keys
            return False, f"エラー: 必須フィールド {list(missing)} が見つかりません"

        # Type の検証（最初に行う）
        msg_type = message.get("type")
        if msg_type not in self.ALLOWED_TYPES:
            return False, f"エラー: type '{msg_type}' は許可されていません（許可: {list(self.ALLOWED_TYPES)}）"

        # 拒否フィールドチェック（最優先）
        banned = self.BANNED_FIELDS & message_keys
        if banned:
            return False, f"エラー: 禁止フィールドが検出されました: {', '.join(banned)}"

        # 不正なフィールドチェック（高速化）
        invalid_fields = message_keys - self.ALLOWED_FIELDS
        if invalid_fields:
            return False, f"エラー: 不正なフィールドが検出されました: {', '.join(invalid_fields)}"

        # フィールド数チェック（高速化）
        field_count = len(message_keys & self.ALLOWED_FIELDS)
        if not (self.MIN_FIELD_COUNT <= field_count <= self.MAX_FIELD_COUNT):
            return False, f"エラー: フィールド数が正しくありません（期待: {self.MIN_FIELD_COUNT}〜{self.MAX_FIELD_COUNT}、実際: {field_count}）"

        # NULL 値チェック（高速化）
        null_fields = [k for k, v in message.items() if v is None]
        if null_fields:
            return False, f"エラー: NULL 値が含まれています: {', '.join(null_fields)}"

        # 文字列フィールドの検証
        for field in ["sender", "target"]:
            if not isinstance(message.get(field), str):
                return False, f"エラー: '{field}' は文字列である必要があります"

        # 質問/回答フィールドの確認と検証（統合）
        has_question = "question" in message
        has_answer = "answer" in message

        if msg_type == "QUESTION":
            if not has_question:
                return False, "エラー: QUESTION メッセージに 'question' フィールドが必要です"
            if not isinstance(message["question"], str):
                return False, "エラー: 'question' は文字列である必要があります"

        elif msg_type == "ANSWER":
            if not has_answer:
                return False, "エラー: ANSWER メッセージに 'answer' フィールドが必要です"
            if not isinstance(message["answer"], str):
                return False, "エラー: 'answer' は文字列である必要があります"

        # ネスト深さチェック（必要な場合のみ）
        if any(isinstance(v, (dict, list)) for v in message.values()):
            max_depth = self._get_max_nesting_depth(message)
            if max_depth > self.MAX_NESTING_DEPTH:
                return False, f"エラー: ネスト深さが深すぎます（最大: {self.MAX_NESTING_DEPTH}、実際: {max_depth}）"

        return True, "✅ メッセージ形式は正しいです"

    def _get_max_nesting_depth(self, obj: Any, current_depth: int = 0) -> int:
        """
        ネスト深さを計算

        Args:
            obj: チェック対象オブジェクト
            current_depth: 現在の深さ

        Returns:
            最大ネスト深さ
        """
        if isinstance(obj, dict):
            if not obj:
                return current_depth
            return max(self._get_max_nesting_depth(v, current_depth + 1) for v in obj.values())
        elif isinstance(obj, (list, tuple)):
            if not obj:
                return current_depth
            return max(self._get_max_nesting_depth(item, current_depth + 1) for item in obj)
        else:
            return current_depth

    def log_validation(self, message: Dict[str, Any], is_valid: bool, error_msg: str = "") -> None:
        """
        検証結果をログに記録

        Args:
            message: メッセージ
            is_valid: 成功フラグ
            error_msg: エラーメッセージ
        """
        timestamp = datetime.now().isoformat()
        sender = message.get("sender", "UNKNOWN")
        msg_type = message.get("type", "UNKNOWN")

        if is_valid:
            self.logger.info(f"[{timestamp}] ✅ ALLOWED: {msg_type} from {sender}")
        else:
            self.logger.warning(f"[{timestamp}] ❌ DENIED: {msg_type} from {sender} - {error_msg}")


# ========== グローバル関数 ==========

def validate_a2a_message(message: Dict[str, Any]) -> Tuple[bool, str]:
    """
    A2Aメッセージを検証する（簡易版）

    Args:
        message: 検証対象メッセージ

    Returns:
        (成功フラグ, エラーメッセージ)
    """
    validator = A2AFormatValidator(enable_logging=False)
    return validator.validate(message)


if __name__ == "__main__":
    # テスト用
    logging.basicConfig(level=logging.INFO)

    validator = A2AFormatValidator()

    # ✅ 正しいフォーマット
    correct_message = {
        "type": "QUESTION",
        "sender": "claude_code_worker3",
        "target": "gpt5_intelligent",
        "question": "テスト質問です"
    }

    is_valid, msg = validator.validate(correct_message)
    print(f"正しいメッセージ: {is_valid} - {msg}")
    validator.log_validation(correct_message, is_valid, msg)

    # ❌ 間違ったフォーマット（contentフィールド）
    wrong_message = {
        "type": "QUESTION",
        "content": {
            "question": "テスト質問です"
        }
    }

    is_valid, msg = validator.validate(wrong_message)
    print(f"間違ったメッセージ: {is_valid} - {msg}")
