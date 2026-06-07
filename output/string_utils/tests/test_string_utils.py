"""string_utils モジュールのテストコード。"""

import sys
from pathlib import Path

# テスト対象モジュールのパスを追加
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

import pytest

from string_utils import reverse, is_palindrome, word_count, truncate


class TestReverse:
    """reverse 関数のテスト。"""

    @pytest.mark.parametrize(
        "s, expected",
        [
            ("hello", "olleh"),
            ("", ""),
            ("a", "a"),
            ("a!b", "b!a"),
        ],
    )
    def test_reverse_normal(self, s: str, expected: str) -> None:
        """正常系: 文字列が正しく反転されること。"""
        assert reverse(s) == expected

    def test_reverse_type_error(self) -> None:
        """異常系: 非文字列を渡すと TypeError が送出されること。"""
        with pytest.raises(TypeError, match="引数は文字列である必要があります"):
            reverse(None)  # type: ignore[arg-type]


class TestIsPalindrome:
    """is_palindrome 関数のテスト。"""

    @pytest.mark.parametrize(
        "s, expected",
        [
            ("racecar", True),
            ("Racecar", True),
            ("A  b  A", True),
            ("", True),
            ("hello", False),
        ],
    )
    def test_is_palindrome_normal(self, s: str, expected: bool) -> None:
        """正常系: 回文判定が正しいこと。"""
        assert is_palindrome(s) is expected

    def test_is_palindrome_type_error(self) -> None:
        """異常系: 非文字列を渡すと TypeError が送出されること。"""
        with pytest.raises(TypeError, match="引数は文字列である必要があります"):
            is_palindrome(123)  # type: ignore[arg-type]


class TestWordCount:
    """word_count 関数のテスト。"""

    @pytest.mark.parametrize(
        "s, expected",
        [
            ("hello world", 2),
            ("  hello   world  ", 2),
            ("", 0),
            ("one", 1),
        ],
    )
    def test_word_count_normal(self, s: str, expected: int) -> None:
        """正常系: 単語数が正しくカウントされること。"""
        assert word_count(s) == expected

    def test_word_count_type_error(self) -> None:
        """異常系: 非文字列を渡すと TypeError が送出されること。"""
        with pytest.raises(TypeError, match="引数は文字列である必要があります"):
            word_count(object())  # type: ignore[arg-type]


class TestTruncate:
    """truncate 関数のテスト。"""

    @pytest.mark.parametrize(
        "s, max_length, suffix, expected",
        [
            ("Hello, World!", 8, "...", "Hello..."),
            ("Hello", 10, "...", "Hello"),
            ("Hello, World!", 6, "…", "Hello…"),
        ],
    )
    def test_truncate_normal(self, s: str, max_length: int, suffix: str, expected: str) -> None:
        """正常系: 切り詰めが期待通りに動作すること。"""
        assert truncate(s, max_length, suffix) == expected

    def test_truncate_default_suffix(self) -> None:
        """デフォルトの suffix が使われること。"""
        assert truncate("Hello, World!", 8) == "Hello..."

    def test_truncate_type_error_for_s(self) -> None:
        """異常系: s が非文字列のとき TypeError を送出すること。"""
        with pytest.raises(TypeError, match="引数は文字列である必要があります"):
            truncate(5, 10, ".")  # type: ignore[arg-type]

    def test_truncate_value_error_for_max_length(self) -> None:
        """異常系: max_length が suffix の長さ以下のとき ValueError を送出すること。"""
        with pytest.raises(ValueError, match="max_lengthはsuffixより長くする必要があります"):
            truncate("Hi", 1, ".")
