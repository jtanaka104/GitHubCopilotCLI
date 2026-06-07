# ファイル管理（FileManager）テスト項目書

## 1. テスト対象

- モジュール: `file_manager`
- ファイル: `src/file_manager.py`

## 2. 正常系テスト項目

### 2.1 read_text 関数

| # | テストケース | 入力 | 期待値 |
|---|---|---|---|
| R-01 | 存在するテキストファイルの読み込み | file_path=存在するファイル | ファイル内容の文字列 |

### 2.2 write_text 関数

| # | テストケース | 入力 | 期待値 |
|---|---|---|---|
| W-01 | ファイルに書き込み（親ディレクトリが存在する） | file_path=out.txt, content="data" | ファイルに "data" が書き込まれる |
| W-02 | 親ディレクトリが存在しない場所への書き込み | file_path=dir/out.txt, content="x" | 親ディレクトリが自動作成されファイルが書き込まれる |

### 2.3 file_exists 関数

| # | テストケース | 入力 | 期待値 |
|---|---|---|---|
| E-01 | 存在するファイルの確認 | file_path=存在するファイル | True |
| E-02 | 存在しないファイルの確認 | file_path=missing.txt | False |

### 2.4 copy_file 関数

| # | テストケース | 入力 | 期待値 |
|---|---|---|---|
| C-01 | ファイルを別ファイル名へコピー | src=src.txt, dst=dst.txt | コピー先の Path を返す、内容が一致 |
| C-02 | コピー先にディレクトリを指定 | src=src.txt, dst=backup/ | コピー先は backup/src.txt |

## 3. 異常系テスト項目

### 3.1 read_text

| # | テストケース | 入力 | 期待値 |
|---|---|---|---|
| R-E01 | 読み込み対象が存在しない | file_path=missing.txt | FileNotFoundError を送出 |

### 3.2 copy_file

| # | テストケース | 入力 | 期待値 |
|---|---|---|---|
| C-E01 | コピー元が存在しない | src=missing.txt, dst=dst.txt | FileNotFoundError を送出 |

## 4. 注意事項

- 文字コードは UTF-8 固定で検証すること。
- 親ディレクトリの自動作成が有効であることを確認すること。
