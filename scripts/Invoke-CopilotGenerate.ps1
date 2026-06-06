#Requires -Version 5.1
<#
.SYNOPSIS
    GitHub Copilot CLI を使ったコード生成の共通ヘルパー関数。

.DESCRIPTION
    Invoke-FullPipeline.ps1 から使用される共通関数を提供します。

    - Test-CopilotCLI        : copilot CLI のインストール確認
    - Expand-PromptTemplate  : プロンプトテンプレートへの変数展開
#>

function Test-CopilotCLI {
    <#
    .SYNOPSIS
        copilot CLI がインストールされているか確認する。

    .OUTPUTS
        bool - インストールされていれば $true
    #>
    $cmd = Get-Command copilot -ErrorAction SilentlyContinue
    if (-not $cmd) {
        Write-Error @"
copilot CLI が見つかりません。以下のコマンドでインストールしてください:

  # WinGet を使う場合
  winget install GitHub.Copilot

  # npm を使う場合（Node.js 22 以上が必要）
  npm install -g @github/copilot

インストール後、'copilot --version' で動作確認してください。
"@
        return $false
    }
    Write-Verbose "copilot CLI を確認しました: $($cmd.Source)"
    return $true
}

function Expand-PromptTemplate {
    <#
    .SYNOPSIS
        プロンプトテンプレートの変数プレースホルダーを実際の値に置換する。

    .PARAMETER Template
        変数プレースホルダー（例: {MODULE_NAME}）を含むテンプレート文字列。

    .PARAMETER Variables
        プレースホルダー名と置換値のハッシュテーブル。
        例: @{ MODULE_NAME = "string_utils"; OUTPUT_DIR = "C:/output/string_utils" }

    .OUTPUTS
        string - 変数が展開されたプロンプト文字列

    .NOTES
        String.Replace() を使用するため、正規表現メタ文字（$, \, .）を含む
        置換値も安全に扱えます。
    #>
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Template,

        [Parameter(Mandatory)]
        [hashtable]$Variables
    )

    $result = $Template
    foreach ($key in $Variables.Keys) {
        # String.Replace() はリテラル置換のため正規表現エスケープ不要
        $result = $result.Replace("{$key}", $Variables[$key])
    }
    return $result
}
