# 文字列ユーティリティ（StringUtils）詳細設計書

## 1. 概要

文字列操作に関するユーティリティ関数を提供するモジュール。  
文字列の反転・回文判定・単語カウント・切り詰め処理を行う。

## 2. モジュール情報

| 項目 | 内容 |
|------|------|
| モジュール名 | `string_utils` |
| ファイルパス | `src/string_utils.py` |
| 対応 Python | 3.10 以上 |
| 外部依存 | なし（標準ライブラリのみ） |

## 3. 関数仕様

### 3.1 `reverse(s)`

| 項目 | 内容 |
|------|------|
| 概要 | 文字列を逆順にして返す |
| 引数 `s` | `str` — 反転対象の文字列 |
| 戻り値 | `str` — 逆順にした文字列 |
| 例外 | `TypeError` — s が str 型でない場合（メッセージ: `"引数は文字列である必要があります"`） |

```python
reverse("hello")  # => "olleh"
reverse("abc")    # => "cba"
reverse("")       # => ""
reverse("a")      # => "a"
```

### 3.2 `is_palindrome(s)`

| 項目 | 内容 |
|------|------|
| 概要 | 文字列が回文かどうかを判定する（大文字小文字・スペースを無視） |
| 引数 `s` | `str` — 判定対象の文字列 |
| 戻り値 | `bool` — 回文であれば True、そうでなければ False |
| 例外 | `TypeError` — s が str 型でない場合（メッセージ: `"引数は文字列である必要があります"`） |

```python
is_palindrome("racecar")   # => True
is_palindrome("Racecar")   # => True（大文字小文字無視）
is_palindrome("A  b  A")   # => True（スペース無視）
is_palindrome("hello")     # => False
is_palindrome("")          # => True
```

### 3.3 `word_count(s)`

| 項目 | 内容 |
|------|------|
| 概要 | 文字列内の単語数を返す（連続する空白は 1 つとして扱う） |
| 引数 `s` | `str` — カウント対象の文字列 |
| 戻り値 | `int` — 単語数 |
| 例外 | `TypeError` — s が str 型でない場合（メッセージ: `"引数は文字列である必要があります"`） |

```python
word_count("hello world")        # => 2
word_count("  hello   world  ")  # => 2（前後・連続スペースを無視）
word_count("")                   # => 0
word_count("one")                # => 1
```

### 3.4 `truncate(s, max_length, suffix="...")`

| 項目 | 内容 |
|------|------|
| 概要 | 文字列を指定した最大長に切り詰め、超過した場合は末尾に suffix を付与する |
| 引数 `s` | `str` — 切り詰め対象の文字列 |
| 引数 `max_length` | `int` — 最大文字数（suffix を含む総文字数） |
| 引数 `suffix` | `str` — 末尾に付与する文字列（デフォルト: `"..."`） |
| 戻り値 | `str` — 切り詰めた文字列。元の文字列が max_length 以下の場合はそのまま返す |
| 例外 | `ValueError` — max_length が suffix の長さ以下の場合（メッセージ: `"max_lengthはsuffixより長くする必要があります"`） |
| 例外 | `TypeError` — s が str 型でない場合（メッセージ: `"引数は文字列である必要があります"`） |

```python
truncate("Hello, World!", 8)          # => "Hello..."  （8文字: 5文字 + "..."）
truncate("Hello", 10)                 # => "Hello"     （切り詰め不要）
truncate("Hello, World!", 6, "…")     # => "Hello…"   （6文字: 5文字 + "…"）
truncate("Hi", 1, ".")               # => ValueError  （max_length <= len(suffix)）
```

## 4. エラー処理方針

- 引数が str 型でない場合は `TypeError` を送出する
- `truncate` の `max_length` が `suffix` の長さ以下の場合は `ValueError` を送出する

## 5. 依存関係

外部ライブラリへの依存なし。標準ライブラリのみ使用。
