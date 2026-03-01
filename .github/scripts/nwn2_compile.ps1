[CmdletBinding()]
param(
  [string]$CompilerPath = "compilator/nwn2_compiler/bin/NWNScriptCompiler.exe",
  [string]$ScriptGlob = "scripts/al_prototype/al_*.nss",
  [string]$SourceDir = "scripts/al_prototype",
  [string]$StockDir = "compilator/nwn2_compiler/stock_scripts",
  [string]$OutRoot = "out",
  [int]$TopDiagnostics = 50,
  [bool]$FailOnWarnings = $false
)

$ErrorActionPreference = 'Stop'

$checkDir = Join-Path $OutRoot 'check'
$analyzeDir = Join-Path $OutRoot 'analyze'
$optDir = Join-Path $OutRoot 'opt'
$buildDir = Join-Path $OutRoot 'build'
$logDir = Join-Path $OutRoot 'logs'

$dirs = @($OutRoot, $checkDir, $analyzeDir, $optDir, $buildDir, $logDir)
foreach ($dir in $dirs) {
  New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

if (-not (Test-Path -LiteralPath $CompilerPath)) {
  throw "Compiler not found: $CompilerPath"
}

$entryScripts = Get-ChildItem -Path $ScriptGlob -File |
  Where-Object { $_.Name -notmatch '_inc\.nss$' } |
  Sort-Object FullName |
  ForEach-Object { $_.FullName }

if (-not $entryScripts -or $entryScripts.Count -eq 0) {
  throw "No entry scripts found for '$ScriptGlob' (excluding *_inc.nss)."
}

$includePath = "$SourceDir;$StockDir"

function Escape-AnnotationValue {
  param([string]$Value)
  if ($null -eq $Value) { return '' }

  return $Value.Replace('%', '%25').Replace("`r", '%0D').Replace("`n", '%0A')
}

function Emit-AnnotationFromLine {
  param([string]$Line)

  $trimmed = $Line.Trim()
  if ([string]::IsNullOrWhiteSpace($trimmed)) {
    return $false
  }

  $kind = $null
  if ($trimmed -match '(?i)\berror\b|\bfatal\b|\bexception\b') {
    $kind = 'error'
  }
  elseif ($trimmed -match '(?i)\bwarn(?:ing)?\b') {
    $kind = 'warning'
  }

  if (-not $kind) {
    return $false
  }

  $patternWithCol = '^(?<file>.+?)\((?<line>\d+),(?<col>\d+)\):\s*(?<msg>.+)$'
  $patternNoCol = '^(?<file>.+?)\((?<line>\d+)\):\s*(?<msg>.+)$'

  if ($trimmed -match $patternWithCol) {
    $file = Escape-AnnotationValue $Matches['file']
    $lineNo = [int]$Matches['line']
    $colNo = [int]$Matches['col']
    $msg = Escape-AnnotationValue $Matches['msg']
    Write-Host "::$kind file=$file,line=$lineNo,col=$colNo::$msg"
    return $true
  }

  if ($trimmed -match $patternNoCol) {
    $file = Escape-AnnotationValue $Matches['file']
    $lineNo = [int]$Matches['line']
    $msg = Escape-AnnotationValue $Matches['msg']
    Write-Host "::$kind file=$file,line=$lineNo::$msg"
    return $true
  }

  $msg = Escape-AnnotationValue $trimmed
  Write-Host "::$kind::$msg"
  return $true
}

function Get-Counts {
  param([string[]]$Lines)

  $errorCount = 0
  $warningCount = 0
  $diagLines = @()

  foreach ($line in $Lines) {
    $isError = $line -match '(?i)\berror\b|\bfatal\b|\bexception\b'
    $isWarning = $line -match '(?i)\bwarn(?:ing)?\b'

    if ($isError -or $isWarning) {
      $diagLines += $line
    }

    if ($isError) { $errorCount++ }
    if ($isWarning) { $warningCount++ }
  }

  return [PSCustomObject]@{
    ErrorCount = $errorCount
    WarningCount = $warningCount
    DiagnosticLines = $diagLines
  }
}

$modeSpecs = @(
  @{ Name = 'check';   OutDir = $checkDir;   Args = @('-c', '-g') },
  @{ Name = 'analyze'; OutDir = $analyzeDir; Args = @('-c', '-a', '-g') },
  @{ Name = 'opt';     OutDir = $optDir;     Args = @('-c', '-o', '-g') },
  @{ Name = 'build';   OutDir = $buildDir;   Args = @('-c', '-o', '-a') }
)

$results = @()

foreach ($mode in $modeSpecs) {
  $name = $mode.Name
  $outDir = $mode.OutDir
  $logPath = Join-Path $logDir ("$name.log")

  Write-Host "`n=== Running mode: $name ==="

  $args = @() + $mode.Args + @('-i', $includePath, '-b', $outDir) + $entryScripts
  $allOutput = @()

  & $CompilerPath @args 2>&1 | ForEach-Object {
    $line = $_.ToString()
    $allOutput += $line
    Write-Host $line
  }

  $exitCode = $LASTEXITCODE
  $allOutput | Out-File -LiteralPath $logPath -Encoding utf8

  $counts = Get-Counts -Lines $allOutput
  foreach ($diagLine in $counts.DiagnosticLines) {
    Emit-AnnotationFromLine -Line $diagLine | Out-Null
  }

  $results += [PSCustomObject]@{
    Mode = $name
    ExitCode = $exitCode
    LogPath = $logPath
    ErrorCount = $counts.ErrorCount
    WarningCount = $counts.WarningCount
    Diagnostics = $counts.DiagnosticLines
  }

  if ($exitCode -eq 0) {
    Write-Host "Mode '$name' completed successfully."
  }
  else {
    Write-Host "Mode '$name' failed with exit code $exitCode."
  }
}

$failedModes = $results | Where-Object { $_.ExitCode -ne 0 -or $_.ErrorCount -gt 0 }
$warningModes = $results | Where-Object { $_.WarningCount -gt 0 }
$pipelineFailed = ($failedModes.Count -gt 0) -or ($FailOnWarnings -and $warningModes.Count -gt 0)

if ($env:GITHUB_STEP_SUMMARY) {
  $overall = if ($pipelineFailed) { '❌ Failed' } else { '✅ Success' }

  Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Value "## NWN2 compiler pipeline"
  Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Value ""
  Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Value "**$overall**"
  Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Value ""
  Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Value "| Mode | Status | Errors | Warnings | Log |"
  Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Value "| --- | --- | ---: | ---: | --- |"

  foreach ($result in $results) {
    $status = if ($result.ExitCode -eq 0 -and $result.ErrorCount -eq 0) { '✅ success' } else { "❌ fail ($($result.ExitCode))" }
    Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Value "| $($result.Mode) | $status | $($result.ErrorCount) | $($result.WarningCount) | ``$($result.LogPath)`` |"
  }

  $topDiagnosticLines = @()
  foreach ($result in $results) {
    foreach ($line in $result.Diagnostics) {
      $topDiagnosticLines += "[$($result.Mode)] $line"
      if ($topDiagnosticLines.Count -ge $TopDiagnostics) {
        break
      }
    }
    if ($topDiagnosticLines.Count -ge $TopDiagnostics) {
      break
    }
  }

  Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Value ""
  Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Value "### Top diagnostics (up to $TopDiagnostics)"

  if ($topDiagnosticLines.Count -gt 0) {
    Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Value '```text'
    foreach ($line in $topDiagnosticLines) {
      Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Value $line
    }
    Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Value '```'
  }
  else {
    Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Value "No warning/error lines found in logs."
  }

  Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Value ""
  Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Value "Скачай артефакт logs для полного лога."
}

if ($pipelineFailed) {
  if ($failedModes.Count -gt 0) {
    $failedNames = ($failedModes | ForEach-Object { $_.Mode }) -join ', '
    Write-Host "Pipeline failed in mode(s): $failedNames"
  }

  if ($FailOnWarnings -and $warningModes.Count -gt 0) {
    $warningNames = ($warningModes | ForEach-Object { $_.Mode }) -join ', '
    Write-Host "Pipeline configured to fail on warnings. Warning mode(s): $warningNames"
  }

  exit 1
}

Write-Host 'NWN2 compilation pipeline completed successfully.'
