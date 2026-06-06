"""四則演算を提供する計算機モジュール。"""


def add(a: float, b: float) -> float:
    """2つの数値を加算する。

    Args:
        a: 被加数
        b: 加数

    Returns:
        aとbの和
    """
    return float(a + b)


def subtract(a: float, b: float) -> float:
    """aからbを減算する。

    Args:
        a: 被減数
        b: 減数

    Returns:
        aとbの差
    """
    return float(a - b)


def multiply(a: float, b: float) -> float:
    """2つの数値を乗算する。

    Args:
        a: 被乗数
        b: 乗数

    Returns:
        aとbの積
    """
    return float(a * b)


def divide(a: float, b: float) -> float:
    """aをbで除算する。

    Args:
        a: 被除数
        b: 除数

    Returns:
        aをbで割った商

    Raises:
        ValueError: bが0のとき
    """
    if b == 0:
        raise ValueError("0による除算はできません")
    return float(a / b)
