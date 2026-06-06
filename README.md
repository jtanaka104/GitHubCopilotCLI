# GitHub Copilot CLI 自動生成サンプル

PowerShell スクリプトから GitHub Copilot CLI を非インタラクティブに呼び出し、  
詳細設計書（Markdown）を入力として **Python ソースコード・テスト項目書・テストコード** を  
自動生成するサンプルプロジェクトです。

---

## 前提条件

| ツール | バージョン | インストール方法 |
|--------|-----------|----------------|
| copilot CLI | 最新版 | `winget install GitHub.Copilot` |
| PowerShell | 5.1 以上 | Windows 10/11 に標準搭載 |
| Python | 3.10 以上 | https://www.python.org/downloads/ |
| pytest | 最新版 | `pip install pytest` |
| GitHub アカウント | Copilot 契約あり | — |

### copilot CLI のインストール確認

```powershell
copilot --version
```

### 認証

```powershell
# GitHub CLI でログイン済みの場合、GH_TOKEN 経由で自動認証される
gh auth login

# または環境変数で直接指定
$env:COPILOT_GITHUB_TOKEN = "ghp_xxxxxxxxxxxx"  # PAT（Copilot Requests スコープ必要）
```

---

## セットアップ

```powershell
# 1. リポジトリのクローン（または既存フォルダへの移動）
cd C:\Programing\GitHubCopilotCLI

# 2. ユーザーレベル指示ファイルのセットアップ（初回のみ）
.\scripts\Set-UserInstructions.ps1
```

---

## 使い方

### 全設計書を一括処理

```powershell
.\scripts\Invoke-FullPipeline.ps1
```

`input/` ディレクトリ内の全 `.md` ファイルが処理され、`output/` に生成されます。

### 特定の設計書のみ処理

```powershell
.\scripts\Invoke-FullPipeline.ps1 -Filter "string_utils.md"
```

### 特定のタスク範囲のみ実行

`StartTask` と `EndTask` パラメータ（1～3）を指定して、実行するタスクの範囲を限定できます。

```powershell
# タスク1（ソースコード生成）のみ実行
.\scripts\Invoke-FullPipeline.ps1 -StartTask 1 -EndTask 1

# タスク2（テスト項目書）とタスク3（テストコード）のみ実行
# （事前にタスク1が完了している必要がある）
.\scripts\Invoke-FullPipeline.ps1 -StartTask 2 -EndTask 3
```

### 生成結果の確認

```powershell
# 生成ファイルの一覧
Get-ChildItem .\output\ -Recurse -File

# テストの実行
pytest .\output\string_utils\tests\
pytest .\output\file_manager\tests\
```

### 新しい設計書の追加

`input/` ディレクトリに新しい `.md` ファイルを追加してパイプラインを実行するだけです。

```powershell
# 例: my_module.md を追加
Copy-Item .\my_design.md .\input\my_module.md
.\scripts\Invoke-FullPipeline.ps1 -Filter "my_module.md"
```

---

## ディレクトリ構造

```
.
├── .github/
│   ├── copilot-instructions.md               ← (A) リポジトリ全体共通ルール
│   └── inst                 ← 各タスク範囲に対応したプロンプトテンプレート群
│   ├── generate-task1.md
│   ├── generate-task1-2.md
│   ├── generate-task1-3.md
│   ├── ... (他4ファイル)(B) src/*.py 生成ルール
│       ├── create-test-items.instructions.md ← (B) test-items/*.md 生成ルール
│       └── create-test-code.instructions.md  ← (B) tests/test_*.py 生成ルール
├── sample/                  ← 参照用サンプル（手本）
│   ├── design/calculator.md
│   ├── src/calculator.py
│   ├── test-items/calculator-test-items.md
│   └── tests/test_calculator.py
├── input/                   ← 処理対象の詳細設計書（ここに追加）
│   ├── string_utils.md
│   └── file_manager.md
├── output/                  ← 生成ファイルの出力先（自動作成）
├── prompts/
│   └── generate-all.md      ← 3タスク一括プロンプトテンプレート
├── scripts/
│   ├── Invoke-CopilotGenerate.ps1
│   ├── Invoke-FullPipeline.ps1  ← メイン実行スクリプト
│   └── Set-UserInstructions.ps1
├── AGENTS.md                ← (C) CLI/エージェント向け指示
└── README.md
```
指示のベストプラクティス

このプロジェクトでは、CLIによる自動生成の安定性を最大化するため、以下のハイブリッドアプローチを採用しています。

1.  **`instructions` ファイル**: リポジトリ全体の**普遍的なルール**（コーディング規約、docstring形式など）を定義します。
2.  **プロンプト**:
    -   `instructions` ファイルに従うよう**強く指示**します。
    -   **具体的なサンプルファイル**（`sample/`配下）を「手本」として提示し、品質やフォーマットの**揺らぎを抑制**します。

このアプローチにより、`instructions` の保守性と、プロンプトによる直接的な指示の安定性を両立させています。

---

## 
---

## 各指示ファイルの役割と効果

### (A) `.github/copilot-instructions.md` — リポジトリ全体共通ルール

**読み込まれる場面**: IDE Chat・Copilot CLI・Cloud Agent のすべてのリクエスト  
**範囲**: このリポジトリ内のすべての操作

生成されるコードに対して「型ヒント必須」「日本語コメント」「pytest 使用」などの  
**全体的な品質基準**が常に適用されます。

**効果の確認方法**: このファイルの `## コーディング規約` セクションを変更してから  
パイプラインを再実行すると、生成コードが変化します。  
例えば「コメントは英語で記述すること」に変えると英語コメントが生成されます。

---

### (B) `.github/instructions/*.instructions.md` — ファイル種別ごとの品質ルール

**重要な誤解の訂正**:  
これらのファイルは「呼び出すスキル」ではありません。  
`applyTo` パターンに一致するファイルを **生成・編集するときに自動的にコンテキストへ追加** されるルール集です。

| ファイル | applyTo | 自動適用されるタイミング |
|---------|---------|----------------------|
| `create-source.instructions.md` | `**/src/*.py` | `src/*.py` を生成・編集するとき |
| `create-test-items.instructions.md` | `**/test-items/*.md` | `test-items/*.md` を生成・編集するとき |
| `create-test-code.instructions.md` | `**/tests/test_*.py` | `tests/test_*.py` を生成・編集するとき |

**タスクの順序制御はプロンプトテンプレート側（`prompts/generate-all.md`）で行います。**  
instructions ファイルは「そのファイルをどう書くか」のルール定義です。

**効果の確認方法**: `create-source.instructions.md` に  
`- 関数の戻り値は必ず float ではなく Decimal 型にすること` と追加してから再実行すると、  
生成ソースが Decimal 型を使うように変わります。

---

### (C) `AGENTS.md` — CLI/エージェントモード向け指示

**読み込まれる場面**: Copilot CLI・Cloud Agent のリクエスト  
**範囲**: このリポジトリ内（IDE Chat では読み込まれない）

ビルドコマンド・テストコマンド・ディレクトリ構造などの「プロジェクト固有の操作情報」を  
記述します。IDE Chat を使っているときは表示されず、CLI から実行するときだけ有効です。

**効果の確認方法**: `AGENTS.md` に  
`- 生成コードはすべて output/ ディレクトリに保存すること` のような追加指示を書くと  
CLI がその指示を優先します。一方、VS Code の Chat パネルからは影響を受けません。

---

### (D) `~/.copilot/copilot-instructions.md` — ユーザーレベル個人設定

**読み込まれる場面**: Copilot CLI のみ  
**範囲**: このPC上のすべてのリポジトリ（グローバル）

```powershell
# セットアップ
.\scripts\Set-UserInstructions.ps1
```

**効果の確認方法**: このファイルに  
`- 変数名は必ずハンガリアン記法を使うこと` と書いた後、別のリポジトリで  
`copilot -p "変数を3つ宣言して"` を実行すると、そのリポジトリの instructions に  
関係なく個人設定が反映されます。

---

## 指示ファイルの読み込み範囲まとめ

| ファイル | IDE Chat | copilot CLI | Cloud Agent | Code Review |
|---------|:--------:|:-----------:|:-----------:|:-----------:|
| `.github/copilot-instructions.md` | ✅ | ✅ | ✅ | ✅ |
| `.github/instructions/*.instructions.md` | ✅ | ✅ | ✅ | ✅ |
| `AGENTS.md` | ❌ | ✅ | ✅ | ❌ |
| `~/.copilot/copilot-instructions.md` | ❌ | ✅ | ❌ | ❌ |

---

## KV キャッシュ効率化の仕組み

`Invoke-FullPipeline.ps1` は各設計書に対して **1 回だけ** `copilot` を呼び出します。

```
[プロンプト構造]
─────────────────────────────────
詳細設計書の内容（冒頭に 1 回だけ配置）
                ↓ KV キャッシュに格納
─────────────────────────────────
タスク 1: ソースコード作成 → ファイル書き込み
タスク 2: テスト項目書作成 → ファイル書き込み  ← 設計書部分をキャッシュから再利用
タスク 3: テストコード作成 → ファイル書き込み  ← 設計書部分をキャッシュから再利用
─────────────────────────────────
```

3 回の個別呼び出しに比べ、設計書部分の KV キャッシュが再利用されるため  
入力トークンの処理コストが削減されます。また、タスク 1 で生成したソースコードの  
内容がコンテキストに残り続`gpt-5-mini` | 使用するモデルID（例: `gpt-4o-mini`, `claude-3-haiku-20240307`） |
| `-StartTask`| `1` | 開始するタスク番号（1～3） |
| `-EndTask` | `3` | 終了するタスク番号（1～3

---

## スクリプト詳細

### `Invoke-FullPipeline.ps1`

| パラメータ | デフォルト | 説明 |
|-----------|-----------|------|
| `-InputDir` | `.\input` | 処理対象の設計書ディレクトリ |
| `-OutputDir` | `.\output` | 生成ファイルの出力先 |
| `-Filter` | `*.md` | 処理するファイル名のパターン |
| `-Model` | （省略時はCLIデフォルト） | 使用するモデルID（例: `gpt-4o-mini`） |

### `Set-UserInstructions.ps1`

| パラメータ | 説明 |
|-----------|------|
| `-Force` | 既存ファイルを上書きする |
| `-WhatIf` | 実際には作成せず動作確認のみ |
