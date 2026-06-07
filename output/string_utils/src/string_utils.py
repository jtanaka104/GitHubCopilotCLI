"""string_utils モジュール。

文字列操作ユーティリティを提供する。
"""

from typing import Any


def reverse(s: str) -> str:
    """文字列を逆順にして返す。

    Args:
        s: 反転対象の文字列

    Returns:
        逆順にした文字列

    Raises:
        TypeError: s が str 型でない場合（メッセージ: "引数は文字列である必要があります"）
    """
    # 型チェック（仕様に準拠）
    if not isinstance(s, str):
        raise TypeError("引数は文字列である必要があります")
    # スライスで逆順にする
    return s[::-1]


def is_palindrome(s: str) -> bool:
    """文字列が回文かどうかを判定する（大文字小文字・スペースを無視）。

    Args:
        s: 判定対象の文字列

    Returns:
        回文であれば True、そうでなければ False

    Raises:
        TypeError: s が str 型でない場合（メッセージ: "引数は文字列である必要があります"）
    """
    if not isinstance(s, str):
        raise TypeError("引数は文字列である必要があります")
    # 空白を除去して小文字化することで比較を行う
    normalized = "".join(s.split()).lower()
    return normalized == normalized[::-1]


def word_count(s: str) -> int:
    """文字列内の単語数を返す（連続する空白は 1 つとして扱う）。

    Args:
        s: カウント対象の文字列

    Returns:
        単語数

    Raises:
        TypeError: s が str 型でない場合（メッセージ: "引数は文字列である必要があります"）
    """
    if not isinstance(s, str):
        raise TypeError("引数は文字列である必要があります")
    # split() は連続する空白を無視し、空文字列では空リストを返す
    parts = s.split()
    return len(parts)


def truncate(s: str, max_length: int, suffix: str = "...") -> str:
    """文字列を指定した最大長に切り詰め、超過した場合は末尾に suffix を付与する。

    Args:
        s: 切り詰め対象の文字列
        max_length: 最大文字数（suffix を含む総文字数）
        suffix: 末尾に付与する文字列（デフォルト: "..."）

    Returns:
        切り詰めた文字列。元の文字列が max_length 以下の場合はそのまま返す

    Raises:
        TypeError: s が str 型でない場合（メッセージ: "引数は文字列である必要があります"）
        ValueError: max_length が suffix の長さ以下の場合（メッセージ: "max_lengthはsuffixより長くする必要があります"）
    """
    if not isinstance(s, str):
        raise TypeError("引数は文字列である必要があります")
    if not isinstance(max_length, int):
        raise TypeError("max_length は整数である必要があります")
    if not isinstance(suffix, str):
        raise TypeError("suffix は文字列である必要があります")
    # max_length は suffix より長くなければならない（仕様）
    if max_length <= len(suffix):
        raise ValueError("max_lengthはsuffixより長くする必要があります")
    # 切り詰め不要
    if len(s) <= max_length:
        return s
    # 実際に残せる文字数を計算して切り詰める
    keep = max_length - len(suffix)
    return s[:keep] + suffix
