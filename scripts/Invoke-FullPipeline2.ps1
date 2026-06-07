#Requires -Version 5.1
<#
.SYNOPSIS
    input/ ディレクトリ内の詳細設計書を処理し、Pythonソース・テスト項目書・テストコードを生成する。

.DESCRIPTION
    各詳細設計書に対して、ローカル推論サーバー（Ollamaなど）のAPIを呼び出して以下を順番に生成します:
      1. Python ソースコード
      2. テスト項目書 (Markdown)
      3. pytest テストコード

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
    .\scripts\Invoke-FullPipeline2.ps1

.EXAMPLE
    # 特定の設計書のみ処理
    .\scripts\Invoke-FullPipeline2.ps1 -Filter "string_utils.md"

.PARAMETER Model
    使用するローカルモデル名（例: gemma:latest, llama3:latest）。
    デフォルト: gemma:latest

.PARAMETER ApiEndpoint
    ローカル推論サーバーのAPIエンドポイント。
    デフォルト: http://localhost:11434/api/generate

.EXAMPLE
    # llama3 モデルを使用
    .\scripts\Invoke-FullPipeline2.ps1 -Model 'llama3:latest'

.PARAMETER StartTask
    実行を開始するタスク番号（1〜3）。デフォルト: 1
      1: Python ソースコード生成
      2: テスト項目書生成（output/{module}/src/{module}.py が存在する必要あり）
      3: テストコード生成（ソースとテスト項目書が存在する必要あり）

.PARAMETER EndTask
    実行を終了するタスク番号（1〜3）。StartTask 以上の値を指定すること。デフォルト: 3
#>

[CmdletBinding()]
param(
    [string]$InputDir    = '.\input',
    [string]$OutputDir   = '.\output',
    [string]$Filter      = '*.md',
    [string]$Model       = 'gemma:latest',
    [string]$ApiEndpoint = 'http://localhost:11434/api/generate',
    [ValidateRange(1, 3)]
    [int]$StartTask      = 1,
    [ValidateRange(1, 3)]
    [int]$EndTask        = 3
)

Set-StrictMode -Version 1
$ErrorActionPreference = 'Stop'

# ─── 引数バリデーション ──────────────────────────────────────
if ($StartTask -gt $EndTask) {
    Write-Error "StartTask ($StartTask) は EndTask ($EndTask) 以下にする必要があります。"
    exit 1
}

# ─── ヘルパー関数の定義 (ローカルLLM呼び出し用) ─────────────
function Invoke-LocalLLMGenerate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prompt,

        [Parameter(Mandatory=$true)]
        [string]$Model,

        [Parameter(Mandatory=$true)]
        [string]$ApiEndpoint
    )

    $body = @{
        model  = $Model
        prompt = $Prompt
        stream = $false # ストリーミングせず、一度にレスポンスを受け取る
    } | ConvertTo-Json

    try {
        Write-Verbose "APIリクエストを送信中... Endpoint: $ApiEndpoint, Model: $Model"
        $response = Invoke-RestMethod -Uri $ApiEndpoint -Method Post -Body $body -ContentType 'application/json'
        
        if ($null -ne $response.response) {
            return $response.response
        } else {
            Write-Error "APIレスポンスに 'response' フィールドが含まれていません。"
            Write-Error "受信したレスポンス: $($response | ConvertTo-Json -Depth 3)"
            return $null
        }
    } catch {
        Write-Error "ローカルLLM APIの呼び出しに失敗しました: $($_.Exception.Message)"
        return $null
    }
}


# ─── 前提チェック ────────────────────────────────────────────
$resolvedInput = [System.IO.Path]::GetFullPath($InputDir)
if (-not (Test-Path $resolvedInput)) {
    Write-Error "InputDir が見つかりません: $resolvedInput"
    exit 1
}

# ─── タスク範囲とプロンプトテンプレートのマッピング ─────────
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
    $designContent = Get-Content $designFile.FullName -Raw -Encoding UTF8

    Write-Host "--- 処理開始: $moduleName ---" -ForegroundColor Yellow

    # 出力先ディレクトリの準備
    $moduleOutputDir = Join-Path $OutputDir $moduleName
    $srcDir          = Join-Path $moduleOutputDir 'src'
    $testItemsDir    = Join-Path $moduleOutputDir 'test-items'
    $testsDir        = Join-Path $moduleOutputDir 'tests'
    
    # 参照用のソースコードとテスト項目書を読み込む（タスク2, 3で必要）
    $sourceCodePath = Join-Path $srcDir "$moduleName.py"
    $sourceCodeContent = ''
    if (Test-Path $sourceCodePath) {
        $sourceCodeContent = Get-Content $sourceCodePath -Raw -Encoding UTF8
    }

    $testItemsPath = Join-Path $testItemsDir "$moduleName-test-items.md"
    $testItemsContent = ''
    if (Test-Path $testItemsPath) {
        $testItemsContent = Get-Content $testItemsPath -Raw -Encoding UTF8
    }

    # プロンプトの組み立て
    $prompt = $template `
        -replace '{{MODULE_NAME}}', $moduleName `
        -replace '{{DESIGN_DOCUMENT}}', $designContent `
        -replace '{{SAMPLE_DESIGN}}', $sampleDesign `
        -replace '{{SAMPLE_SOURCE}}', $sampleSource `
        -replace '{{SAMPLE_TEST_ITEMS}}', $sampleTestItems `
        -replace '{{SAMPLE_TEST_CODE}}', $sampleTestCode `
        -replace '{{EXISTING_SOURCE}}', $sourceCodeContent `
        -replace '{{EXISTING_TEST_ITEMS}}', $testItemsContent

    # ローカルLLM API を呼び出してコンテンツを生成
    $generatedContent = Invoke-LocalLLMGenerate -Prompt $prompt -Model $Model -ApiEndpoint $ApiEndpoint

    if ($null -eq $generatedContent) {
        Write-Error "コンテンツの生成に失敗しました。次のファイルの処理に進みます。"
        continue
    }

    # 生成されたコンテンツを解析して各ファイルに保存
    # （この解析ロジックは、Invoke-CopilotGenerate.ps1 から移植・調整が必要です）
    Write-Host "コンテンツが生成されました。ファイルへの保存処理を実装してください。"
    Write-Host "--- 処理完了: $moduleName ---" -ForegroundColor Yellow
    
    # TODO: Invoke-CopilotGenerate.ps1 のように、生成されたテキストから
    #       各ファイル（.py, .md, test_*.py）を抽出して保存する処理を実装する
    #
    # 例:
    # $generatedContent | Out-File (Join-Path $moduleOutputDir "generated_output.txt") -Encoding utf8
}

Write-Host "すべての処理が完了しました。" -ForegroundColor Green
