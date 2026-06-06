#Requires -Version 5.1
<#
.SYNOPSIS
    ユーザーレベルの Copilot CLI 指示ファイルをセットアップする。

.DESCRIPTION
    $HOME/.copilot/copilot-instructions.md を作成します。

    このファイルは Copilot CLI のみが読み込み、このPC上のすべてのリポジトリに
    共通して適用されます。IDE Chat や Cloud Agent には影響しません。

    【他の指示ファイルとの違い】
    ファイル                                    読み込み元      範囲
    ─────────────────────────────────────────────────────────────────
    ~/.copilot/copilot-instructions.md        CLI のみ        全リポジトリ（このPC）
    .github/copilot-instructions.md          IDE+CLI+Agent   そのリポジトリのみ
    .github/instructions/*.instructions.md  IDE+CLI+Agent   applyTo に一致するファイル
    AGENTS.md                                 CLI+Agent       そのリポジトリのみ

.PARAMETER Force
    既存のファイルを上書きする場合に指定してください。

.EXAMPLE
    # 初回セットアップ
    .\scripts\Set-UserInstructions.ps1

.EXAMPLE
    # 上書き
    .\scripts\Set-UserInstructions.ps1 -Force
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$copilotDir = Join-Path $HOME '.copilot'
$targetFile = Join-Path $copilotDir 'copilot-instructions.md'

# ─── ディレクトリ作成 ─────────────────────────────────────────
if (-not (Test-Path $copilotDir)) {
    if ($PSCmdlet.ShouldProcess($copilotDir, 'ディレクトリ作成')) {
        New-Item -ItemType Directory -Path $copilotDir -Force | Out-Null
        Write-Host "ディレクトリを作成しました: $copilotDir" -ForegroundColor Green
    }
}

# ─── 既存ファイルの確認 ───────────────────────────────────────
if ((Test-Path $targetFile) -and -not $Force) {
    Write-Warning @"
$targetFile は既に存在します。
上書きする場合は -Force を指定してください:
  .\scripts\Set-UserInstructions.ps1 -Force
"@
    return
}

# ─── ファイル内容（個人スタイル設定） ────────────────────────
# このファイルは Copilot CLI がすべてのリポジトリで共通して読み込みます。
# リポジトリ固有のルールは .github/copilot-instructions.md に書くこと。
$content = @'
# ユーザーレベル Copilot CLI 指示

このファイルは Copilot CLI が **このPC上のすべてのリポジトリ** で共通して読み込む個人設定ファイルです。
IDE Chat や Cloud Agent には影響しません。

## 個人スタイル設定

- コメントは日本語で書くこと
- 変数名・関数名は英語のスネークケースとすること（例: `read_text`, `max_length`）
- エラーメッセージは日本語で記述すること

## コード品質

- 型ヒントは必ず付与すること
- docstring は Google スタイルで記述すること（Args / Returns / Raises）
- テストコードは pytest を使用すること
- `pytest.mark.parametrize` を積極的に使用すること

## 出力形式

- コードのみを出力し、不要な説明は省略すること
- ファイル書き込みを求められた場合は必ず write ツールを使用すること
- 作業完了後は生成したファイルのパス一覧を報告すること

## セキュリティ

- シークレット・パスワード・APIキーをソースコードにハードコードしないこと
- ユーザー入力のファイルパスは必ず検証すること
'@

# ─── ファイル書き込み ─────────────────────────────────────────
if ($PSCmdlet.ShouldProcess($targetFile, 'ファイル作成')) {
    Set-Content -Path $targetFile -Value $content -Encoding UTF8
    Write-Host "作成しました: $targetFile" -ForegroundColor Green
    Write-Host @"

【このファイルの効果】
  - Copilot CLI がすべてのリポジトリで共通して読み込みます
  - IDE Chat（VS Code の Copilot Chat 等）には適用されません
  - リポジトリの .github/copilot-instructions.md と組み合わせて動作します

【各指示ファイルの読み込み範囲まとめ】
  ~/.copilot/copilot-instructions.md        CLI のみ・全リポジトリ共通
  .github/copilot-instructions.md          IDE + CLI + Cloud Agent・そのリポジトリのみ
  .github/instructions/*.instructions.md  IDE + CLI + Cloud Agent・applyTo パターンのファイルのみ
  AGENTS.md                                 CLI + Cloud Agent のみ・そのリポジトリのみ
"@ -ForegroundColor Cyan
}
