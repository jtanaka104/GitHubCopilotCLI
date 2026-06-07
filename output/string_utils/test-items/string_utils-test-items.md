# 文字列ユーティリティ（StringUtils）テスト項目書

## 1. テスト対象

- モジュール: `string_utils`
- ファイル: `src/string_utils.py`

## 2. 正常系テスト項目

### 2.1 reverse 関数

| # | テストケース | 入力 | 期待値 |
|---|---|---|---|
| R-01 | 複数文字列の反転 | s="hello" | "olleh" |
| R-02 | 空文字の反転 | s="" | "" |
| R-03 | 1文字の反転 | s="a" | "a" |
| R-04 | 文字列に記号を含む場合 | s="a!b" | "b!a" |

### 2.2 is_palindrome 関数

| # | テストケース | 入力 | 期待値 |
|---|---|---|---|
| P-01 | 単純な回文 | s="racecar" | True |
| P-02 | 大文字小文字無視 | s="Racecar" | True |
| P-03 | スペースを含む回文 | s="A  b  A" | True |
| P-04 | 空文字は回文 | s="" | True |
| P-05 | 非回文 | s="hello" | False |

### 2.3 word_count 関数

| # | テストケース | 入力 | 期待値 |
|---|---|---|---|
| W-01 | 通常の単語数 | s="hello world" | 2 |
| W-02 | 前後スペースと連続スペース | s="  hello   world  " | 2 |
| W-03 | 空文字 | s="" | 0 |
| W-04 | 単語1つ | s="one" | 1 |

### 2.4 truncate 関数

| # | テストケース | 入力 | 期待値 |
|---|---|---|---|
| T-01 | 切り詰めが発生する（デフォルトsuffix） | s="Hello, World!", max_length=8 | "Hello..." |
| T-02 | 切り詰め不要 | s="Hello", max_length=10 | "Hello" |
| T-03 | カスタムsuffixで切り詰め | s="Hello, World!", max_length=6, suffix="…" | "Hello…" |

## 3. 異常系テスト項目

### 3.1 TypeError の確認

| # | テストケース | 入力 | 期待値 |
|---|---|---|---|
| E-01 | reverse に非文字列を渡す | s=None | TypeError: "引数は文字列である必要があります" |
| E-02 | is_palindrome に非文字列を渡す | s=123 | TypeError: "引数は文字列である必要があります" |
| E-03 | word_count に非文字列を渡す | s=object() | TypeError: "引数は文字列である必要があります" |
| E-04 | truncate に非文字列 s を渡す | s=5, max_length=10 | TypeError: "引数は文字列である必要があります" |

### 3.2 truncate の ValueError

| # | テストケース | 入力 | 期待値 |
|---|---|---|---|
| E-05 | max_length が suffix の長さ以下 | s="Hi", max_length=1, suffix='.' | ValueError: "max_lengthはsuffixより長くする必要があります" |

## 4. 境界値テスト項目

| # | テストケース | 入力 | 期待値 |
|---|---|---|---|
| B-01 | max_length がちょうど1より大きい場合 | s="ab", max_length=2, suffix="." | "a." |
| B-02 | 非ASCII文字を含む回文判定 | s="あいあ" | True |
