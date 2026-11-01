[CmdletBinding()]
param(
    [string]$FlutterSdk = 'E:\DevTools\FlutterOH-3.47.8',
    [string]$DevEcoStudio = 'E:\DevTools\DevEcoStudio',
    [string]$PubCache = 'E:\DevTools\PubCache-OH',
    [string]$Python = 'E:\pl-ci\_tool\Python\3.12.10\x64\python.exe',
    [string]$SourceCheckout = '\\wsl.localhost\Ubuntu\home\gdx\code\PureLive_harmonyos',
    [string]$PosixPython = 'python3',
    [ValidateRange(1, 12)][int]$TestConcurrency = 6,
    [string[]]$TestPath = @(),
    [switch]$All,
    [switch]$Analyze
)
$ErrorActionPreference = 'Stop'
$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new()
$repo = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
. (Join-Path $PSScriptRoot 'environment.ps1')
Set-HarmonyEnvironment -FlutterSdk $FlutterSdk -DevEcoStudio $DevEcoStudio -PubCache $PubCache
. (Join-Path $PSScriptRoot 'build_resource_guard.ps1')
$lease = Enter-PureLiveHeavyTaskSlot -TaskName 'purelive-next-quality' -QueueTimeoutMinutes 30
$started = Get-Date
$success = $false
$logs = Join-Path $repo ('local-artifacts\checks\' + $started.ToString('yyyyMMdd-HHmmss'))
$flutter = Join-Path $FlutterSdk 'bin\flutter.bat'
$dart = Join-Path $FlutterSdk 'bin\cache\dart-sdk\bin\dart.exe'
Push-Location $repo
try {
    Invoke-HarmonyCheck 'dependencies' $flutter @('--suppress-analytics', 'pub', 'get', '--enforce-lockfile') $logs
    & powershell -NoProfile -ExecutionPolicy Bypass -File tools\ffmpeg_kit\fetch.ps1 windows
    if ($LASTEXITCODE -ne 0) { throw 'Native test FFmpeg bundle verification failed.' }
    foreach ($check in @('tools/gate/check_deps.py', 'tools/gate/check_fixtures.py', 'tools/gate/check_ui_structure.py')) {
        Invoke-HarmonyRepoCheck $check $Python @($check) $logs $repo $SourceCheckout
    }
    Invoke-HarmonyCheck 'docs' $Python @('tools/docs/docs.py', '--check') $logs
    Invoke-HarmonyCheck 'owners' $Python @('tools/docs/owners.py', '--check') $logs
    Invoke-HarmonyCheck 'hap-inspector-tests' $Python @('-m', 'unittest', 'discover', '-s', 'tools/harmonyos', '-p', 'test_*.py') $logs
    Invoke-HarmonyCheck 'native-toolchain-output' $dart @('test', 'tools/harmonyos/test', '--reporter=expanded') $logs
    if ($All) {
        $inside = $false
        $members = @()
        foreach ($line in Get-Content pubspec.yaml) {
            if ($line -eq 'workspace:') { $inside = $true; continue }
            if ($inside -and $line -match '^\S') { break }
            if ($inside -and $line -match '^  - (.+)$') { $members += $Matches[1].Trim() }
        }
        foreach ($member in $members) {
            $selection = $member + '-sources'
            Invoke-HarmonyRepoCheck $selection $Python @('tools/harmonyos/source_files.py', $member) $logs $repo $SourceCheckout
            $selectionLog = Join-Path $logs (($selection -replace '[^a-zA-Z0-9_.-]', '_') + '.log')
            $sources = [string[]](Get-Content $selectionLog -Raw | ConvertFrom-Json)
            if ($sources.Count -eq 0) { throw ('No Dart sources selected for ' + $member) }
            $batch = @()
            $length = 0
            $part = 0
            foreach ($source in $sources) {
                if ($length + $source.Length -gt 4000 -and $batch.Count -gt 0) {
                    Invoke-HarmonyCheck ($member + '-format-' + $part) $dart (@('format', '--output=none', '--set-exit-if-changed') + $batch) $logs
                    $batch = @(); $length = 0; $part++
                }
                $batch += $source
                $length += $source.Length + 3
            }
            if ($batch.Count -gt 0) { Invoke-HarmonyCheck ($member + '-format-' + $part) $dart (@('format', '--output=none', '--set-exit-if-changed') + $batch) $logs }
            Push-Location $member
            try { Invoke-HarmonyCheck ($member + '-analyze') $dart @('analyze', '--fatal-infos') $logs }
            finally { Pop-Location }
        }
        # Run the exact pinned framework regression in the resolved app workspace;
        # the SDK source checkout's full development workspace is not installed.
        $sdkRegression = Join-Path $logs 'sdk-regression'
        [void](New-Item -ItemType Directory -Force (Join-Path $sdkRegression 'semantics'))
        [void](New-Item -ItemType Directory -Force (Join-Path $sdkRegression 'widgets'))
        Copy-Item (Join-Path $FlutterSdk 'packages\flutter\test\semantics\semantics_update_test.dart') (Join-Path $sdkRegression 'semantics\semantics_update_test.dart')
        Copy-Item (Join-Path $FlutterSdk 'packages\flutter\test\widgets\button_tester.dart') (Join-Path $sdkRegression 'widgets\button_tester.dart')
        Push-Location apps\pure_live
        try { Invoke-HarmonyCheck 'sdk-semantics-regression' $flutter @('test', '--no-pub', (Join-Path $sdkRegression 'semantics\semantics_update_test.dart'), '--reporter=expanded') $logs }
        finally { Pop-Location }
        $testFailures = @()
        foreach ($member in $members) {
            Push-Location $member
            try {
                if (Test-Path test) {
                    if ((Get-Content pubspec.yaml -Raw) -match 'sdk:\s*flutter') {
                        Invoke-HarmonyCheck ($member + '-test') $flutter @('test', '--no-pub', "--concurrency=$TestConcurrency", '--reporter=expanded') $logs
                    } else {
                        Invoke-HarmonyCheck ($member + '-test') $dart @('test', "--concurrency=$TestConcurrency", '--reporter=expanded') $logs
                    }
                }
            } catch {
                $testFailures += $member
                Write-Warning ('Workspace tests failed: ' + $member + '; see the retained log.')
            } finally { Pop-Location }
        }
        # These include POSIX permission, executable fake-adb and Bash tests.
        # Run the whole set in the canonical WSL checkout, never against a phone.
        if ($SourceCheckout -notmatch '^\\\\wsl(?:\.localhost|\$)\\([^\\]+)\\(.+)$') {
            throw 'The Bash gate regressions require -SourceCheckout in WSL and -PosixPython Python 3.11+.'
        }
        $distribution = $Matches[1]
        $linuxCheckout = '/' + $Matches[2].Replace('\', '/')
        Invoke-HarmonyCheck 'gate-script-tests' 'wsl.exe' @('-d', $distribution, '--cd', $linuxCheckout, '--', $PosixPython, '-m', 'unittest', 'discover', '-s', 'tools/gate/tests') $logs
        if ($testFailures.Count -gt 0) { throw ('Workspace tests failed: ' + ($testFailures -join ', ')) }
    } else {
        Push-Location apps\pure_live
        try {
            if ($TestPath.Count -gt 0) { Invoke-HarmonyCheck 'focused-tests' $flutter (@('test', '--no-pub', "--concurrency=$TestConcurrency", '--reporter=expanded') + $TestPath) $logs }
            if ($Analyze) { Invoke-HarmonyCheck 'app-analyze' $dart @('analyze', '--fatal-infos') $logs }
        } finally { Pop-Location }
    }
    $success = $true
    Write-Output ('gate: passed (HarmonyOS host, all=' + [bool]$All + ')')
} finally {
    [void](New-Item -ItemType Directory -Force $logs)
    [ordered]@{started=$started.ToString('o');ended=(Get-Date).ToString('o');passed=$success;all=[bool]$All;sdk=$FlutterSdk;concurrency=$TestConcurrency;deviceTested=$false} |
        ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $logs 'result.json')
    Pop-Location
    Exit-PureLiveHeavyTaskSlot -Lease $lease
}
