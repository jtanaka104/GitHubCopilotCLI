#Requires -Version 5.1
<#
.SYNOPSIS
    input/ ディレクトリ内の詳細設計書を処理し、Pythonソース・テスト項目書・テストコードを生成する。

.DESCRIPTION
    各詳細設計書に対して、GitHub Copilot CLI を 1 回だけ呼び出して以下を順番に生成します:
      1. Python ソースコード
      2. テスト項目書 (Markdown)
      3. pytest テストコード

    【KV キャッシュ効率化について】
    1 回の CLI 呼び出しでタスク 1〜3 を順番に指示しています。
    プロンプト冒頭に詳細設計書の内容を 1 回だけ埋め込むことで、
    タスク 1〜3 を通じて同一の入力プレフィックスが使い回されます。
    3 回の個別呼び出しに比べ、KV キャッシュのヒット率が高まり
    入力トークンの処理コストが削減されます。

.PARAMETER InputDir
    処理対象の詳細設計書（.md ファイル）が格納されているディレクトリ。
    デフォルト: .\input

.PARAMETER OutputDir
    生成ファイルの出力先ルートディレクトリ。
    デフォルト: .\output

.PARAMETER Filter
    処理するファイル名のパターン（例: "string_utils.md"）。
    省略時は InputDir 内のすべての .md ファイルを処理する。

.EXAMPLE
    # input/ 内の全設計書を処理（プロジェクトルートから実行）
    .\scripts\Invoke-FullPipeline.ps1

.EXAMPLE
    # 特定の設計書のみ処理
    .\scripts\Invoke-FullPipeline.ps1 -Filter "string_utils.md"

.PARAMETER Model
    使用するモデル ID（例: gpt-4o-mini, claude-haiku-3-5, gpt-4o）。
    省略時は copilot CLI のデフォルトモデルを使用する。

    【コスパ推奨】
    本タスク（設計書→コード生成）は推論不要の定型作業のため、
    軽量モデルで十分な品質が得られます:
      - gpt-4o-mini    : 低コスト・高速・推奨
      - claude-haiku-3-5: 低コスト・高速・推奨
    以下は過剰スペックのため非推奨:
      - o1, o3, claude-opus: 推論特化型・高コスト・不要

.EXAMPLE
    # input/ 内の全設計書を処理（プロジェクトルートから実行）
    .\scripts\Invoke-FullPipeline.ps1

.EXAMPLE
    # 入出力ディレクトリを明示指定
    .\scripts\Invoke-FullPipeline.ps1 -InputDir .\input -OutputDir .\output

.EXAMPLE
    # 軽量モデルを指定してコスト削減
    .\scripts\Invoke-FullPipeline.ps1 -Model 'gpt-4o-mini'
    .\scripts\Invoke-FullPipeline.ps1 -Model 'claude-haiku-3-5'

.PARAMETER StartTask
    実行を開始するタスク番号（1〜3）。デフォルト: 1
      1: Python ソースコード生成
      2: テスト項目書生成（output/{module}/src/{module}.py が存在する必要あり）
      3: テストコード生成（ソースとテスト項目書が存在する必要あり）

.PARAMETER EndTask
    実行を終了するタスク番号（1〜3）。StartTask 以上の値を指定すること。デフォルト: 3

.EXAMPLE
    # タスク 1 のみ実行（ソースコードのみ生成）
    .\scripts\Invoke-FullPipeline.ps1 -StartTask 1 -EndTask 1

.EXAMPLE
    # タスク 1〜2 を実行（ソースコードとテスト項目書を生成）
    .\scripts\Invoke-FullPipeline.ps1 -StartTask 1 -EndTask 2

.EXAMPLE
    # タスク 2〜3 を実行（タスク 1 完了済みの場合）
    .\scripts\Invoke-FullPipeline.ps1 -StartTask 2 -EndTask 3

.EXAMPLE
    # タスク 3 のみ再生成
    .\scripts\Invoke-FullPipeline.ps1 -StartTask 3 -EndTask 3
#>

[CmdletBinding()]
param(
    [string]$InputDir  = '.\input',
    [string]$OutputDir = '.\output',
    [string]$Filter    = '*.md',
    [string]$Model     = 'gpt-5-mini',  # デフォルト: GPT-5 mini（低コスト・高速）
    [ValidateRange(1, 3)]
    [int]$StartTask    = 1,             # 実行開始タスク番号（1=ソース生成, 2=テスト項目書生成, 3=テストコード生成）
    [ValidateRange(1, 3)]
    [int]$EndTask      = 3              # 実行終了タスク番号（StartTask 以上の値を指定すること）
)

# PS 5.1 互換: $IsWindows は PS 6+ の自動変数のため手動で定義する
# copilot CLI の内部スクリプトがこの変数を参照するため、Set-StrictMode より前に定義が必要
if (-not (Get-Variable -Name 'IsWindows' -Scope Global -ErrorAction SilentlyContinue)) {
    $global:IsWindows  = ($env:OS -eq 'Windows_NT')
    $global:IsLinux    = (-not $global:IsWindows -and $env:HOME -like '/home/*')
    $global:IsMacOS    = (-not $global:IsWindows -and $env:HOME -like '/Users/*')
}

Set-StrictMode -Version 1
$ErrorActionPreference = 'Stop'

# ─── 引数バリデーション ──────────────────────────────────────
if ($StartTask -gt $EndTask) {
    Write-Error "StartTask ($StartTask) は EndTask ($EndTask) 以下にする必要があります。"
    exit 1
}

# ─── ヘルパー関数の読み込み ──────────────────────────────────
. (Join-Path $PSScriptRoot 'Invoke-CopilotGenerate.ps1')

# ─── 前提チェック ────────────────────────────────────────────
if (-not (Test-CopilotCLI)) { exit 1 }

$resolvedInput = [System.IO.Path]::GetFullPath($InputDir)
if (-not (Test-Path $resolvedInput)) {
    Write-Error "InputDir が見つかりません: $resolvedInput"
    exit 1
}

$resolvedOutputRoot = [System.IO.Path]::GetFullPath($OutputDir)
New-Item -ItemType Directory -Path $resolvedOutputRoot -Force | Out-Null
$stdoutLogFile = Join-Path $resolvedOutputRoot 'copilot-stdout.log'
$sessionStamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
Add-Content -Path $stdoutLogFile -Encoding UTF8 -Value "===== Pipeline Start: $sessionStamp / StartTask=$StartTask EndTask=$EndTask / Model=$Model ====="

# 文字化けを避けるため、ネイティブコマンド入出力のエンコーディングを UTF-8 に統一する
$utf8NoBomForConsole = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = $utf8NoBomForConsole
try {
    [Console]::OutputEncoding = $utf8NoBomForConsole
} catch {
    # ホスト環境によっては設定不可のため無視する
}

$copilotCommand = 'copilot'
$copilotCmd = Get-Command 'copilot.cmd' -ErrorAction SilentlyContinue
if ($copilotCmd) {
    # PowerShell ラッパー経由の stderr 例外化を避けるため cmd シムを優先
    $copilotCommand = $copilotCmd.Source
}

# ─── タスク範囲とプロンプトテンプレートのマッピング ─────────
# タスク実行範囲（StartTask-EndTask）に対応するプロンプトファイルを選択する
$promptDir = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\prompts'))
$promptMap = @{
    '1-1' = 'generate-task1.md'
    '1-2' = 'generate-task1-2.md'
    '1-3' = 'generate-task1-3.md'
    '2-2' = 'generate-task2.md'
    '2-3' = 'generate-task2-3.md'
    '3-3' = 'generate-task3.md'
}
$taskKey      = "$StartTask-$EndTask"
$templateFile = Join-Path $promptDir $promptMap[$taskKey]
if (-not (Test-Path $templateFile)) {
    Write-Error "プロンプトテンプレートが見つかりません: $templateFile"
    exit 1
}

# ─── サンプルファイルの読み込み ──────────────────────────────
# サンプルは品質・構造の手本としてプロンプトに埋め込まれる
$sampleBase = [System.IO.Path]::GetFullPath(
    (Join-Path $PSScriptRoot '..\sample')
)

Write-Verbose "サンプルディレクトリ: $sampleBase"

$sampleDesign    = Get-Content (Join-Path $sampleBase 'design\calculator.md')                -Raw -Encoding UTF8
$sampleSource    = Get-Content (Join-Path $sampleBase 'src\calculator.py')                   -Raw -Encoding UTF8
$sampleTestItems = Get-Content (Join-Path $sampleBase 'test-items\calculator-test-items.md') -Raw -Encoding UTF8
$sampleTestCode  = Get-Content (Join-Path $sampleBase 'tests\test_calculator.py')            -Raw -Encoding UTF8

$template = Get-Content $templateFile -Raw -Encoding UTF8

# ─── 処理対象ファイルの列挙 ──────────────────────────────────
$designFiles = Get-ChildItem -Path $resolvedInput -Filter $Filter | Sort-Object Name

if ($designFiles.Count -eq 0) {
    Write-Warning "処理対象の設計書が見つかりません: $resolvedInput\$Filter"
    exit 0
}

Write-Host "処理対象: $($designFiles.Count) ファイル" -ForegroundColor Green

# ─── 各設計書をループして処理 ────────────────────────────────
foreach ($designFile in $designFiles) {
    $moduleName    = $designFile.BaseName
    $resolvedOutput = [System.IO.Path]::GetFullPath(
        (Join-Path $OutputDir $moduleName)
    )
    # プロンプト内のパスはフォワードスラッシュで統一（可読性向上）
    $outputDirForPrompt = $resolvedOutput.Replace('\', '/')

    $designContent = Get-Content $designFile.FullName -Raw -Encoding UTF8

    Write-Host "`n[$moduleName] 処理開始 ..." -ForegroundColor Cyan
    Write-Host "  設計書  : $($designFile.FullName)" -ForegroundColor Gray
    Write-Host "  出力先  : $resolvedOutput"          -ForegroundColor Gray

    # 出力ディレクトリの事前作成
    # （copilot の write ツールがディレクトリ未存在でも動作するよう保険として作成）
    New-Item -ItemType Directory -Path (Join-Path $resolvedOutput 'src')        -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $resolvedOutput 'test-items') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $resolvedOutput 'tests')      -Force | Out-Null

    # ─── プロンプトの変数展開 ────────────────────────────────
    # 基本変数（全テンプレート共通）
    $variables = @{
        DESIGN_CONTENT    = $designContent
        MODULE_NAME       = $moduleName
        OUTPUT_DIR        = $outputDirForPrompt
        SAMPLE_DESIGN     = $sampleDesign
        SAMPLE_SOURCE     = $sampleSource
        SAMPLE_TEST_ITEMS = $sampleTestItems
        SAMPLE_TEST_CODE  = $sampleTestCode
    }

    # StartTask >= 2: 既存ソースコードをコンテキストに追加
    if ($StartTask -ge 2) {
        $srcFile = Join-Path $resolvedOutput "src\$moduleName.py"
        if (-not (Test-Path $srcFile)) {
            Write-Warning "[$moduleName] タスク $StartTask の実行にはソースファイルが必要です: $srcFile"
            Write-Warning "[$moduleName] スキップします。先に -StartTask 1 で実行してください。"
            continue
        }
        $variables['SOURCE_CONTENT'] = Get-Content $srcFile -Raw -Encoding UTF8
    }

    # StartTask >= 3: 既存テスト項目書をコンテキストに追加
    if ($StartTask -ge 3) {
        $testItemsFile = Join-Path $resolvedOutput "test-items\$moduleName-test-items.md"
        if (-not (Test-Path $testItemsFile)) {
            Write-Warning "[$moduleName] タスク 3 の実行にはテスト項目書が必要です: $testItemsFile"
            Write-Warning "[$moduleName] スキップします。先に -StartTask 1 -EndTask 2 で実行してください。"
            continue
        }
        $variables['TEST_ITEMS_CONTENT'] = Get-Content $testItemsFile -Raw -Encoding UTF8
    }

    $prompt = Expand-PromptTemplate -Template $template -Variables $variables

    # ─── GitHub Copilot CLI の呼び出し ───────────────────────
    # 【PS 5.1 の引数渡し問題の回避策】
    # プロンプト内のダブルクォート（コードサンプル等）を -p 引数で渡すと
    # PS 5.1 がエスケープできずパースエラーになる。
    # 解決策:
    #   1. プロンプト全文を一時 .md ファイルに書き出す
    #   2. -p にはシンプルな ASCII 文字列だけを渡す
    #   3. copilot が --allow-all-tools の read ツールでファイルを読み込んで実行する
    #
    # --allow-all-tools : 非インタラクティブモードに必須 + ファイル読み込みツールを有効化
    # --no-ask-user     : ユーザーへの質問を無効化（完全自律実行）
    # -p                : 非インタラクティブモードのトリガー（ASCII文字列のみ）
    $modelLabel     = if ($Model) { $Model } else { 'default' }
    $taskRangeLabel = if ($StartTask -eq $EndTask) { "タスク $StartTask のみ" } else { "タスク $StartTask-$EndTask" }
    Write-Host "  copilot CLI を呼び出しています（モデル: $modelLabel / $taskRangeLabel を処理）..." -ForegroundColor Yellow

    $runStamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Add-Content -Path $stdoutLogFile -Encoding UTF8 -Value ""
    Add-Content -Path $stdoutLogFile -Encoding UTF8 -Value "----- [$moduleName] $runStamp -----"
    Add-Content -Path $stdoutLogFile -Encoding UTF8 -Value "DesignFile: $($designFile.FullName)"
    Add-Content -Path $stdoutLogFile -Encoding UTF8 -Value "OutputDir : $resolvedOutput"
    Add-Content -Path $stdoutLogFile -Encoding UTF8 -Value "TaskRange : $taskRangeLabel"
    Add-Content -Path $stdoutLogFile -Encoding UTF8 -Value "Model     : $modelLabel"

    # プロンプトをプロジェクトルート直下の一時 .md ファイルに書き出す
    $projectRoot   = Split-Path $PSScriptRoot -Parent
    $tmpPromptFile = Join-Path $projectRoot ".prompt_tmp_$moduleName.md"
    $utf8NoBom     = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($tmpPromptFile, $prompt, $utf8NoBom)

    # -p に渡す文字列はシンプルな ASCII のみ（バックスラッシュ・スペースなし）
    # copilot が read ツールでファイルを読み込んで全タスクを実行する
    $tmpPromptFileForward = $tmpPromptFile.Replace('\', '/')
    $safePrompt = "Read the file at $tmpPromptFileForward and execute all the tasks described in it."

    try {
        $copilotArgs = @('--allow-all-tools', '--no-ask-user', '-p', $safePrompt)
        if ($Model) { $copilotArgs += @('--model', $Model) }
        $copilotArgLine = "--allow-all-tools --no-ask-user -p `"$safePrompt`""
        if ($Model) {
            $copilotArgLine += " --model `"$Model`""
        }

        $tmpStdoutFile = Join-Path $env:TEMP ("copilot-out-" + [guid]::NewGuid().ToString() + ".log")
        $tmpStderrFile = Join-Path $env:TEMP ("copilot-err-" + [guid]::NewGuid().ToString() + ".log")
        try {
            $proc = Start-Process -FilePath $copilotCommand `
                -ArgumentList $copilotArgLine `
                -NoNewWindow `
                -Wait `
                -PassThru `
                -RedirectStandardOutput $tmpStdoutFile `
                -RedirectStandardError $tmpStderrFile

            if (Test-Path $tmpStdoutFile) {
                Get-Content -Path $tmpStdoutFile -Encoding UTF8 | ForEach-Object {
                    Write-Host $_
                    Add-Content -Path $stdoutLogFile -Encoding UTF8 -Value $_
                }
            }

            if (Test-Path $tmpStderrFile) {
                Get-Content -Path $tmpStderrFile -Encoding UTF8 | ForEach-Object {
                    Write-Host $_
                    Add-Content -Path $stdoutLogFile -Encoding UTF8 -Value $_
                }
            }

            $global:LASTEXITCODE = [int]$proc.ExitCode
        } finally {
            Remove-Item $tmpStdoutFile -Force -ErrorAction SilentlyContinue
            Remove-Item $tmpStderrFile -Force -ErrorAction SilentlyContinue
        }
    } finally {
        Remove-Item $tmpPromptFile -Force -ErrorAction SilentlyContinue
    }

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "[$moduleName] copilot CLI がエラーで終了しました (exit code: $LASTEXITCODE)"
    } else {
        Write-Host "[$moduleName] 完了" -ForegroundColor Green
        Write-Host "  生成先:" -ForegroundColor Gray
        if ($StartTask -le 1) {
            Write-Host "    $outputDirForPrompt/src/$moduleName.py" -ForegroundColor Gray
        }
        if ($StartTask -le 2 -and $EndTask -ge 2) {
            Write-Host "    $outputDirForPrompt/test-items/$moduleName-test-items.md" -ForegroundColor Gray
        }
        if ($EndTask -ge 3) {
            Write-Host "    $outputDirForPrompt/tests/test_$moduleName.py" -ForegroundColor Gray
        }
    }
}

Write-Host "`n全処理完了。出力先: $([System.IO.Path]::GetFullPath($OutputDir))" -ForegroundColor Green
Write-Host "実行ログ: $stdoutLogFile" -ForegroundColor Green
