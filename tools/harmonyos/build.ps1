[CmdletBinding()]
param(
    [string]$FlutterSdk = 'E:\DevTools\FlutterOH-3.47.8',
    [string]$DevEcoStudio = 'E:\DevTools\DevEcoStudio',
    [string]$PubCache = 'E:\DevTools\PubCache-OH',
    [string]$Python = 'E:\pl-ci\_tool\Python\3.12.10\x64\python.exe',
    [string]$SigningProfile,
    [switch]$Codesign,
    [switch]$SkipPubGet
)
$ErrorActionPreference = 'Stop'
$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new()
$repo = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$app = Join-Path $repo 'apps\pure_live'
. (Join-Path $PSScriptRoot 'environment.ps1')
Set-HarmonyEnvironment -FlutterSdk $FlutterSdk -DevEcoStudio $DevEcoStudio -PubCache $PubCache
if ($Codesign -and (-not $SigningProfile -or -not (Test-Path $SigningProfile))) { throw 'Provide your own external signing profile for the new bundle; old app profiles are not reused.' }
$localBuildProfile = Join-Path $app 'ohos\build-profile.json5'
if (Test-Path $localBuildProfile) { throw 'Existing local build profile retained; move it outside the checkout and pass -SigningProfile if needed.' }
. (Join-Path $PSScriptRoot 'build_resource_guard.ps1')
$lease = Enter-PureLiveHeavyTaskSlot -TaskName 'purelive-next-ohos-arm64-debug' -QueueTimeoutMinutes 30
$started = Get-Date
$logs = Join-Path $repo ('local-artifacts\builds\' + $started.ToString('yyyyMMdd-HHmmss'))
$success = $false
Push-Location $app
try {
    $selected = if ($Codesign) { $SigningProfile } else { Join-Path $app 'ohos\build-profile.template.json5' }
    Copy-Item $selected $localBuildProfile
    $library = Join-Path $app 'ohos\entry\libs\arm64-v8a'
    [void](New-Item -ItemType Directory -Force $library)
    Copy-Item (Join-Path $DevEcoStudio 'sdk\default\openharmony\native\llvm\lib\aarch64-linux-ohos\libc++_shared.so') (Join-Path $library 'libc++_shared.so') -Force
    $flutter = Join-Path $FlutterSdk 'bin\flutter.bat'
    Invoke-HarmonyCheck 'ohos-engine-cache' $flutter @('precache', '--ohos') $logs
    Invoke-HarmonyCheck 'ohos-fullscreen-channel' $Python @((Join-Path $PSScriptRoot 'inspect_engine.py'), (Join-Path $FlutterSdk 'bin\cache\artifacts\engine\ohos-arm64\flutter.har'), '--output', (Join-Path $logs 'engine.json')) $logs
    if (-not $SkipPubGet) { Invoke-HarmonyCheck 'dependencies' $flutter @('pub', 'get', '--enforce-lockfile') $logs }
    $sign = if ($Codesign) { '--codesign' } else { '--no-codesign' }
    Invoke-HarmonyCheck 'ohos-arm64-debug' $flutter @('--suppress-analytics', 'build', 'hap', '--debug', '--no-pub', $sign) $logs
    $filename = if ($Codesign) { 'entry-default-signed.hap' } else { 'entry-default-unsigned.hap' }
    $hap = Join-Path $app ('build\ohos\hap\' + $filename)
    Invoke-HarmonyCheck 'hap-content' $Python @((Join-Path $PSScriptRoot 'inspect_hap.py'), $hap, '--root', $repo, '--output', (Join-Path $logs 'artifact.json')) $logs
    $success = $true
    Write-Output ('Verified candidate: ' + $hap)
} finally {
    Remove-Item $localBuildProfile -ErrorAction SilentlyContinue
    [void](New-Item -ItemType Directory -Force $logs)
    [ordered]@{started=$started.ToString('o');ended=(Get-Date).ToString('o');passed=$success;target='ohos-arm64';configuration='Debug';signed=[bool]$Codesign;deviceTested=$false} |
        ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $logs 'result.json')
    Pop-Location
    Exit-PureLiveHeavyTaskSlot -Lease $lease
}
