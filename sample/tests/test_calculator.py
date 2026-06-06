"""calculator モジュールのテストコード。"""

import sys
from pathlib import Path

# テスト対象モジュールのパスを追加
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

import pytest

from calculator import add, divide, multiply, subtract


class TestAdd:
    """add 関数のテスト。"""

    @pytest.mark.parametrize(
        "a, b, expected",
        [
            (3, 5, 8.0),        # A-01: 正の整数同士
            (-1, 1, 0.0),       # A-02: 負の数との加算
            (1.5, 2.5, 4.0),    # A-03: 浮動小数点数
            (0, 0, 0.0),        # A-04: ゼロ同士
        ],
    )
    def test_add_normal(self, a: float, b: float, expected: float) -> None:
        """正常系: add 関数が正しい和を返すこと。"""
        assert add(a, b) == expected


class TestSubtract:
    """subtract 関数のテスト。"""

    @pytest.mark.parametrize(
        "a, b, expected",
        [
            (10, 3, 7.0),       # S-01: 正の整数
            (0, 5, -5.0),       # S-02: 結果が負
            (7, 7, 0.0),        # S-03: 同じ値
            (5.5, 2.5, 3.0),    # S-04: 浮動小数点数
        ],
    )
    def test_subtract_normal(self, a: float, b: float, expected: float) -> None:
        """正常系: subtract 関数が正しい差を返すこと。"""
        assert subtract(a, b) == expected


class TestMultiply:
    """multiply 関数のテスト。"""

    @pytest.mark.parametrize(
        "a, b, expected",
        [
            (3, 4, 12.0),       # M-01: 正の整数同士
            (-2, 5, -10.0),     # M-02: 負の数
            (0, 100, 0.0),      # M-03: ゼロとの乗算
            (2.5, 4.0, 10.0),   # M-04: 浮動小数点数
        ],
    )
    def test_multiply_normal(self, a: float, b: float, expected: float) -> None:
        """正常系: multiply 関数が正しい積を返すこと。"""
        assert multiply(a, b) == expected


class TestDivide:
    """divide 関数のテスト。"""

    @pytest.mark.parametrize(
        "a, b, expected",
        [
            (10, 2, 5.0),       # D-01: 割り切れる
            (7, 2, 3.5),        # D-02: 割り切れない
            (0, 5, 0.0),        # D-03: 分子がゼロ
            (5.0, 2.0, 2.5),    # D-04: 浮動小数点数
        ],
    )
    def test_divide_normal(self, a: float, b: float, expected: float) -> None:
        """正常系: divide 関数が正しい商を返すこと。"""
        assert divide(a, b) == expected

    @pytest.mark.parametrize(
        "a, b",
        [
            (1, 0),    # E-01: ゼロ除算
            (-3, 0),   # E-03: 負数のゼロ除算
        ],
    )
    def test_divide_zero_raises(self, a: float, b: float) -> None:
        """異常系: ゼロ除算時に ValueError が送出されること。"""
        with pytest.raises(ValueError):
            divide(a, b)

    def test_divide_zero_error_message(self) -> None:
        """異常系: ゼロ除算のエラーメッセージが正しいこと。(E-02)"""
        with pytest.raises(ValueError, match="0による除算はできません"):
            divide(5, 0)
