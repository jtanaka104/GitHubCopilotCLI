# ファイル管理（FileManager）詳細設計書

## 1. 概要

テキストファイルの読み書き・存在確認・コピーを行うユーティリティ関数を提供するモジュール。  
パス操作には `pathlib.Path` を使用し、文字コードは UTF-8 固定とする。

## 2. モジュール情報

| 項目 | 内容 |
|------|------|
| モジュール名 | `file_manager` |
| ファイルパス | `src/file_manager.py` |
| 対応 Python | 3.10 以上 |
| 外部依存 | `pathlib`、`shutil`（標準ライブラリのみ） |

## 3. 関数仕様

### 3.1 `read_text(file_path)`

| 項目 | 内容 |
|------|------|
| 概要 | テキストファイルを読み込んで文字列として返す |
| 引数 `file_path` | `str \| Path` — 読み込むファイルのパス |
| 戻り値 | `str` — ファイルの内容 |
| 例外 | `FileNotFoundError` — ファイルが存在しない場合 |
| 例外 | `OSError` — 読み込みに失敗した場合 |

```python
read_text("data.txt")          # => ファイル内容の文字列
read_text(Path("data.txt"))    # => ファイル内容の文字列
read_text("missing.txt")       # => FileNotFoundError
```

### 3.2 `write_text(file_path, content)`

| 項目 | 内容 |
|------|------|
| 概要 | 文字列をテキストファイルに書き込む（上書き） |
| 引数 `file_path` | `str \| Path` — 書き込むファイルのパス |
| 引数 `content` | `str` — 書き込む内容 |
| 戻り値 | `None` |
| 例外 | `OSError` — 書き込みに失敗した場合 |
| 副作用 | 親ディレクトリが存在しない場合は自動作成する |

```python
write_text("output.txt", "Hello, World!")   # ファイルに書き込む
write_text(Path("out/data.txt"), "data")    # 親ディレクトリを自動作成
```

### 3.3 `file_exists(file_path)`

| 項目 | 内容 |
|------|------|
| 概要 | ファイルが存在するかどうかを確認する |
| 引数 `file_path` | `str \| Path` — 確認するファイルのパス |
| 戻り値 | `bool` — ファイルが存在する場合 True、そうでない場合 False |
| 例外 | なし |

```python
file_exists("data.txt")     # => True または False
file_exists("missing.txt")  # => False
```

### 3.4 `copy_file(src_path, dst_path)`

| 項目 | 内容 |
|------|------|
| 概要 | ファイルを指定した場所にコピーする |
| 引数 `src_path` | `str \| Path` — コピー元のファイルパス |
| 引数 `dst_path` | `str \| Path` — コピー先のファイルパス（またはディレクトリ） |
| 戻り値 | `Path` — コピー先のファイルパス |
| 例外 | `FileNotFoundError` — src_path が存在しない場合 |
| 例外 | `OSError` — コピーに失敗した場合 |
| 副作用 | コピー先の親ディレクトリが存在しない場合は自動作成する |

```python
copy_file("src.txt", "dst.txt")      # => Path("dst.txt")
copy_file("src.txt", "backup/")      # => Path("backup/src.txt")
copy_file("missing.txt", "dst.txt")  # => FileNotFoundError
```

## 4. エラー処理方針

- ファイルが存在しない場合は `FileNotFoundError` を送出する
- 書き込み・コピーの失敗は `OSError` を送出する
- 親ディレクトリは `parents=True` で自動作成する

## 5. 依存関係

| ライブラリ | 用途 |
|-----------|------|
| `pathlib.Path` | パス操作 |
| `shutil.copy2` | ファイルコピー（メタデータ保持） |
