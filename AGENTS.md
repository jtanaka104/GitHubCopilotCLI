# GitHub Copilot CLI 自動生成サンプル — エージェント向け指示

このファイルは Copilot CLI（およびエージェントモード）が自動的に読み込む指示ファイルです。
このリポジトリで作業する際は以下の指示に従ってください。

> **AGENTS.md の読み込み範囲**: CLI + Cloud Agent のみ（IDE Chat には読み込まれません）

## プロジェクト概要

GitHub Copilot CLI を PowerShell スクリプトから非インタラクティブに呼び出し、
詳細設計書（Markdown）から Python ソースコード・テスト項目書・テストコードを
自動生成するサンプルプロジェクト。

**1 回の CLI 呼び出しで 3 タスクを処理する設計**により、同一詳細設計書の
コンテキストがタスク間で共有され、KV キャッシュのヒット率が高まります。

## ディレクトリ構造

```
.
├── .github/
│   ├── copilot-instructions.md          # リポジトリ全体の共通ルール（全Copilot読み込み）
│   └── instructions/
│       ├── create-source.instructions.md      # src/*.py 生成ルール
│       ├── create-test-items.instructions.md  # test-items/*.md 生成ルール
│       └── create-test-code.instructions.md   # tests/test_*.py 生成ルール
├── sample/                              # 参照用サンプル（変更禁止）
│   ├── design/calculator.md
│   ├── src/calculator.py
│   ├── test-items/calculator-test-items.md
│   └── tests/test_calculator.py
├── input/                               # 処理対象の詳細設計書（ここに追加する）
│   ├── string_utils.md
│   └── file_manager.md
├── output/                              # 生成ファイルの出力先（自動作成）
│   └── {module_name}/
│       ├── src/{module_name}.py
│       ├── test-items/{module_name}-test-items.md
│       └── tests/test_{module_name}.py
├── prompts/
│   └── generate-all.md                  # 3タスク一括プロンプトテンプレート
├── scripts/
│   ├── Invoke-CopilotGenerate.ps1       # 共通ヘルパー関数
│   ├── Invoke-FullPipeline.ps1          # メイン実行スクリプト
│   └── Set-UserInstructions.ps1         # ユーザーレベル指示ファイルのセットアップ
└── AGENTS.md                            # このファイル
```

## ビルド・テストコマンド

```powershell
# 全パイプライン実行（input/ の全設計書を処理）
.\scripts\Invoke-FullPipeline.ps1

# 特定の設計書のみ処理
.\scripts\Invoke-FullPipeline.ps1 -Filter "string_utils.md"

# 入出力ディレクトリを明示指定
.\scripts\Invoke-FullPipeline.ps1 -InputDir .\input -OutputDir .\output

# 生成されたテストを実行
pytest .\output\string_utils\tests\
pytest .\output\file_manager\tests\

# ユーザーレベル指示ファイルのセットアップ（初回のみ）
.\scripts\Set-UserInstructions.ps1
```

## コーディング規約

- Python 3.10+ / pytest を使用すること
- 型ヒントと Google スタイル docstring は必須
- コメントは日本語で記述すること
- テストは `pytest.mark.parametrize` でパラメータ化すること
- 外部ライブラリは使用しないこと（標準ライブラリのみ）

## ファイル生成規則

新しい設計書 `input/{module_name}.md` を処理すると、以下が生成される:

| ファイル | 内容 |
|---------|------|
| `output/{module_name}/src/{module_name}.py` | Python ソースコード |
| `output/{module_name}/test-items/{module_name}-test-items.md` | テスト項目書 |
| `output/{module_name}/tests/test_{module_name}.py` | pytest テストコード |

## 注意事項

- `output/` ディレクトリのファイルは自動生成されるため、直接編集しないこと
- `sample/` ディレクトリのファイルは参照用のため、変更しないこと
- 新しい詳細設計書は `input/` ディレクトリに追加すること
