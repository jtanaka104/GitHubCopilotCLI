---
applyTo: "**/tests/test_*.py"
---

# テストコード生成ルール

`tests/test_*.py` ファイルを生成・編集する際は、以下のルールに従うこと。

## ファイル先頭の必須コード

テスト対象モジュールを `src/` から参照するため、以下を必ずファイル先頭に記述すること:

```python
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "src"))
```

## テスト構造

機能ごとに `class Test{関数名のPascalCase}:` でグループ化すること:

```python
class TestAdd:
    """add 関数のテスト。"""

    @pytest.mark.parametrize(
        "a, b, expected",
        [
            (3, 5, 8.0),    # A-01: 正の整数同士
            (-1, 1, 0.0),   # A-02: 負の数との加算
        ],
    )
    def test_add_normal(self, a: float, b: float, expected: float) -> None:
        """正常系: add 関数が正しい和を返すこと。"""
        assert add(a, b) == expected
```

## 必須要件

1. **グループ化**: 機能（関数）ごとにテストクラスを作成すること
2. **parametrize**: 複数の入力値がある場合は `@pytest.mark.parametrize` を使用すること
3. **型アノテーション**: テストメソッドの引数にも型ヒントを付与すること
4. **テストケース ID**: テストデータ行のコメントにテスト項目書の ID を記載すること
   例: `(3, 5, 8.0),  # A-01: 正の整数同士`

## 例外テストのパターン

```python
def test_divide_zero_error_message(self) -> None:
    """異常系: ゼロ除算のエラーメッセージが正しいこと。(E-02)"""
    with pytest.raises(ValueError, match="0による除算はできません"):
        divide(5, 0)
```

## import 規則

```python
import pytest
from {モジュール名} import {関数名1}, {関数名2}
```

## 禁止事項

- `unittest.TestCase` は使用しないこと（pytest スタイルのみ）
- テストメソッド内での複雑なセットアップは `pytest.fixture` に分離すること
