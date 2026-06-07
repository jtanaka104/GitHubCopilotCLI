#Requires -Version 5.1
<#
.SYNOPSIS
    Generate source/test artifacts via Open Interpreter -> Ollama -> Gemma.

.DESCRIPTION
    For each design markdown in input/, this script calls Open Interpreter in
    auto execution mode (-y). Open Interpreter uses Ollama local backend model
    (default: gemma4:12b-it-q4_K_M) to generate and write files.

    Flow:
      PowerShell script
        -> Open Interpreter (-y)
        -> Ollama local API
        -> Gemma 12b q4 model

.PARAMETER InputDir
    Directory containing design markdown files. Default: .\input

.PARAMETER OutputDir
    Output root directory. Default: .\output

.PARAMETER Filter
    File filter for input markdown files. Default: *.md

.PARAMETER OllamaModel
    Ollama model name. Default: gemma4:12b

.PARAMETER InterpreterCommand
    Open Interpreter command name. Default: interpreter

.PARAMETER StartTask
    Start task number (1-3). Default: 1

.PARAMETER EndTask
    End task number (1-3). Default: 3

.PARAMETER InterpreterTimeoutSeconds
    Timeout in seconds for one Open Interpreter call. Default: 1200

.PARAMETER DisableLlmFunctions
    Pass --no-llm_supports_functions to Open Interpreter. Default: enabled.

.PARAMETER PrintLlmIo
    Print the prompt sent to Open Interpreter and the returned text.
#>

[CmdletBinding()]
param(
    [string]$InputDir           = '.\input',
    [string]$OutputDir          = '.\output',
    [string]$Filter             = '*.md',
    [string]$OllamaModel        = 'gemma4:12b',
    [switch]$DisableLlmFunctions = $true,
    [switch]$PrintLlmIo,
    [string]$InterpreterCommand = 'interpreter',
    [ValidateRange(60, 7200)]
    [int]$InterpreterTimeoutSeconds = 1200,
    [ValidateRange(1, 3)]
    [int]$StartTask             = 1,
    [ValidateRange(1, 3)]
    [int]$EndTask               = 3
)

Set-StrictMode -Version 1
$ErrorActionPreference = 'Stop'

function Test-CommandExists {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$CommandName
    )

    return ($null -ne (Get-Command $CommandName -ErrorAction SilentlyContinue))
}

function Expand-PromptTemplate {
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Template,

        [Parameter(Mandatory)]
        [hashtable]$Variables
    )

    $result = $Template
    foreach ($key in $Variables.Keys) {
        $result = $result.Replace("{$key}", $Variables[$key])
    }

    return $result
}

function Test-OllamaModelAvailable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModelName
    )

    $listOutput = (& ollama list 2>$null) | Out-String
    return ($listOutput -match "(?m)^\s*$([regex]::Escape($ModelName))\s+")
}

function Test-OllamaModelIsQ4 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModelName
    )

    try {
        $showOutput = (& ollama show $ModelName 2>$null) | Out-String
        $quantLine = [regex]::Match($showOutput, '(?im)^\s*quantization\s+(.+)$')
        if ($quantLine.Success) {
            $quantization = $quantLine.Groups[1].Value.Trim()
            return ($quantization -match '(?i)q4|4bit|4-bit')
        }
    } catch {
        # ignore and fallback to model name pattern
    }

    return ($ModelName -match '(?i)q4|4bit|4-bit')
}

function Invoke-OpenInterpreter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$InterpreterCommand,

        [Parameter(Mandatory)]
        [string]$OllamaModel,

        [Parameter(Mandatory)]
        [int]$TimeoutSeconds,

        [Parameter(Mandatory)]
        [bool]$DisableLlmFunctions,

        [Parameter(Mandatory)]
        [string]$Prompt
    )

    $inputFile  = Join-Path $env:TEMP ("oi-in-" + [guid]::NewGuid().ToString() + ".txt")
    $stdoutFile = Join-Path $env:TEMP ("oi-out-" + [guid]::NewGuid().ToString() + ".txt")
    $stderrFile = Join-Path $env:TEMP ("oi-err-" + [guid]::NewGuid().ToString() + ".txt")

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($inputFile, $Prompt, $utf8NoBom)

    try {
        $escapedInputFile = $inputFile.Replace('"', '""')
        $escapedInterpreter = $InterpreterCommand.Replace('"', '""')
        $escapedModel = ("ollama/$OllamaModel").Replace('"', '""')
        $functionFlag = ''
        if ($DisableLlmFunctions) {
            $functionFlag = ' --no-llm_supports_functions'
        }
        $cmdArgs = "/c type `"$escapedInputFile`" | `"$escapedInterpreter`" -y -s --plain$functionFlag --model `"$escapedModel`""

        $proc = Start-Process -FilePath 'cmd.exe' `
            -ArgumentList $cmdArgs `
            -NoNewWindow `
            -PassThru `
            -RedirectStandardOutput $stdoutFile `
            -RedirectStandardError $stderrFile

        $timedOut = -not $proc.WaitForExit($TimeoutSeconds * 1000)
        if ($timedOut) {
            try {
                $proc.Kill()
            } catch {
                # ignore
            }
        }

        $stdoutText = ''
        $stderrText = ''
        if (Test-Path $stdoutFile) {
            $stdoutText = Get-Content $stdoutFile -Raw -Encoding UTF8
        }
        if (Test-Path $stderrFile) {
            $stderrText = Get-Content $stderrFile -Raw -Encoding UTF8
        }

        $outputLines = New-Object System.Collections.Generic.List[string]
        if (-not [string]::IsNullOrWhiteSpace($stdoutText)) {
            ($stdoutText -split "`r?`n") | ForEach-Object {
                if (-not [string]::IsNullOrWhiteSpace($_)) {
                    $outputLines.Add($_)
                    Write-Host $_
                }
            }
        }
        if (-not [string]::IsNullOrWhiteSpace($stderrText)) {
            ($stderrText -split "`r?`n") | ForEach-Object {
                if (-not [string]::IsNullOrWhiteSpace($_)) {
                    $outputLines.Add($_)
                    Write-Host $_
                }
            }
        }

        $exitCode = if ($timedOut) { 124 } else { [int]$proc.ExitCode }

        return [PSCustomObject]@{
            ExitCode = $exitCode
            Output   = $outputLines
        }
    } finally {
        Remove-Item $inputFile  -ErrorAction SilentlyContinue
        Remove-Item $stdoutFile -ErrorAction SilentlyContinue
        Remove-Item $stderrFile -ErrorAction SilentlyContinue
    }
}

if ($StartTask -gt $EndTask) {
    Write-Error "StartTask ($StartTask) must be less than or equal to EndTask ($EndTask)."
    exit 1
}

if (-not (Test-CommandExists -CommandName $InterpreterCommand)) {
    Write-Error "Open Interpreter command not found: $InterpreterCommand"
    Write-Error "Install example: pip install open-interpreter"
    exit 1
}

if (-not (Test-CommandExists -CommandName 'ollama')) {
    Write-Error "ollama command not found. Install Ollama first."
    exit 1
}

try {
    $null = & ollama ps 2>$null
} catch {
    Write-Error "Cannot connect to Ollama server. Start it with: ollama serve"
    exit 1
}

if (-not (Test-OllamaModelAvailable -ModelName $OllamaModel)) {
    Write-Error "Ollama model not found: $OllamaModel"
    Write-Error "Pull example: ollama pull $OllamaModel"
    exit 1
}

if (-not (Test-OllamaModelIsQ4 -ModelName $OllamaModel)) {
    Write-Warning "Model name does not look like 4-bit quantized. For low memory usage, use a q4 variant."
}

$resolvedInput = [System.IO.Path]::GetFullPath($InputDir)
if (-not (Test-Path $resolvedInput)) {
    Write-Error "InputDir not found: $resolvedInput"
    exit 1
}

$designFiles = Get-ChildItem -Path $resolvedInput -Filter $Filter | Sort-Object Name
if ($designFiles.Count -eq 0) {
    Write-Warning "No design files found: $resolvedInput\$Filter"
    exit 0
}

Write-Host "Targets: $($designFiles.Count) file(s)" -ForegroundColor Green
Write-Host "Runtime: Open Interpreter(-y) -> Ollama -> $OllamaModel" -ForegroundColor Green

foreach ($designFile in $designFiles) {
    $moduleName      = $designFile.BaseName
    $resolvedOutput  = [System.IO.Path]::GetFullPath((Join-Path $OutputDir $moduleName))

    New-Item -ItemType Directory -Path (Join-Path $resolvedOutput 'src')        -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $resolvedOutput 'test-items') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $resolvedOutput 'tests')      -Force | Out-Null

    $designPathForPrompt    = $designFile.FullName.Replace('\\', '/')
    $sourcePathForPrompt    = (Join-Path $resolvedOutput "src\$moduleName.py").Replace('\\', '/')
    $testItemsPathForPrompt = (Join-Path $resolvedOutput "test-items\$moduleName-test-items.md").Replace('\\', '/')
    $testCodePathForPrompt  = (Join-Path $resolvedOutput "tests\test_$moduleName.py").Replace('\\', '/')

    if ($StartTask -ge 2) {
        $srcFile = Join-Path $resolvedOutput "src\$moduleName.py"
        if (-not (Test-Path $srcFile)) {
            Write-Warning "[$moduleName] Source file required for StartTask=$($StartTask): $srcFile"
            Write-Warning "[$moduleName] Skipped. Run with -StartTask 1 first."
            continue
        }
    }

    if ($StartTask -ge 3) {
        $testItemsFile = Join-Path $resolvedOutput "test-items\$moduleName-test-items.md"
        if (-not (Test-Path $testItemsFile)) {
            Write-Warning "[$moduleName] Test items file required for task 3: $testItemsFile"
            Write-Warning "[$moduleName] Skipped. Run with -StartTask 1 -EndTask 2 first."
            continue
        }
    }

    $taskLines = New-Object System.Collections.Generic.List[string]
    if ($StartTask -le 1 -and $EndTask -ge 1) {
        $taskLines.Add("- Create source file: $sourcePathForPrompt")
    }
    if ($StartTask -le 2 -and $EndTask -ge 2) {
        $taskLines.Add("- Create test items file: $testItemsPathForPrompt")
    }
    if ($StartTask -le 3 -and $EndTask -ge 3) {
        $taskLines.Add("- Create pytest file: $testCodePathForPrompt")
    }
    $taskListText = ($taskLines -join "`n")

    $oiPrompt = @"
Execute immediately. Do not ask for more instructions.

Working directory: C:/Programing/GitHubCopilotCLI

Read these files only:
- $designPathForPrompt
- C:/Programing/GitHubCopilotCLI/.github/copilot-instructions.md
- C:/Programing/GitHubCopilotCLI/.github/instructions/create-source.instructions.md
- C:/Programing/GitHubCopilotCLI/.github/instructions/create-test-items.instructions.md
- C:/Programing/GitHubCopilotCLI/.github/instructions/create-test-code.instructions.md

Then execute these tasks now:
$taskListText

Rules:
- Do not print explanations.
- Do not ask questions.
- Write files immediately.
- Keep output short.

At the end, print only created/updated file paths.
"@

    Write-Host "`n[$moduleName] Running Open Interpreter..." -ForegroundColor Cyan
    if ($PrintLlmIo) {
        Write-Host "----- OI PROMPT BEGIN [$moduleName] -----" -ForegroundColor DarkCyan
        Write-Host $oiPrompt
        Write-Host "----- OI PROMPT END [$moduleName] -----" -ForegroundColor DarkCyan
    }

    $oiResult = Invoke-OpenInterpreter -InterpreterCommand $InterpreterCommand -OllamaModel $OllamaModel -TimeoutSeconds $InterpreterTimeoutSeconds -DisableLlmFunctions ([bool]$DisableLlmFunctions) -Prompt $oiPrompt

    $oiOutputText = ($oiResult.Output -join "`n")
    if ($PrintLlmIo) {
        Write-Host "----- OI OUTPUT BEGIN [$moduleName] -----" -ForegroundColor DarkYellow
        if ([string]::IsNullOrWhiteSpace($oiOutputText)) {
            Write-Host "<empty>"
        } else {
            Write-Host $oiOutputText
        }
        Write-Host "----- OI OUTPUT END [$moduleName] -----" -ForegroundColor DarkYellow
    }

    $readyLikeResponse = $oiOutputText -match '(?is)i am ready|please provide your first task|please provide your instructions|provide your first goal'
    if ($readyLikeResponse) {
        Write-Warning "[$moduleName] Open Interpreter returned a ready message without executing tasks."
        continue
    }

    if ($oiResult.ExitCode -ne 0) {
        Write-Warning "[$moduleName] Open Interpreter exited with error (code: $($oiResult.ExitCode))"
        continue
    }

    $expectedPaths = New-Object System.Collections.Generic.List[string]
    if ($StartTask -le 1 -and $EndTask -ge 1) {
        $expectedPaths.Add((Join-Path $resolvedOutput "src\$moduleName.py"))
    }
    if ($StartTask -le 2 -and $EndTask -ge 2) {
        $expectedPaths.Add((Join-Path $resolvedOutput "test-items\$moduleName-test-items.md"))
    }
    if ($StartTask -le 3 -and $EndTask -ge 3) {
        $expectedPaths.Add((Join-Path $resolvedOutput "tests\test_$moduleName.py"))
    }

    $missing = @()
    foreach ($path in $expectedPaths) {
        if (-not (Test-Path $path)) {
            $missing += $path
        }
    }

    if ($missing.Count -gt 0) {
        Write-Warning "[$moduleName] Open Interpreter completed but expected files were not created."
        foreach ($missingPath in $missing) {
            Write-Warning "  missing: $missingPath"
        }
        continue
    }

    Write-Host "[$moduleName] Done" -ForegroundColor Green
}

Write-Host "`nAll processing completed. Output: $([System.IO.Path]::GetFullPath($OutputDir))" -ForegroundColor Green
