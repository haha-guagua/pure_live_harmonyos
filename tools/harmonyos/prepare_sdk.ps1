[CmdletBinding()]
param([string]$FlutterSdk = 'E:\DevTools\FlutterOH-3.47.8')
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$policy = Get-Content (Join-Path $PSScriptRoot 'toolchain.json') -Raw | ConvertFrom-Json
$repo = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$revision = & git -C $FlutterSdk rev-parse HEAD
if ($LASTEXITCODE -ne 0 -or $revision -ne $policy.revision) { throw 'Install/bootstrap the pinned isolated Flutter OH SDK first.' }
. (Join-Path $PSScriptRoot 'build_resource_guard.ps1')
$lease = Enter-PureLiveHeavyTaskSlot -TaskName 'purelive-next-sdk-prepare' -QueueTimeoutMinutes 30
function Apply-VerifiedSdkPatch {
    param([string]$Path)
    $saved = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & git -C $FlutterSdk apply --reverse --check $Path *> $null
        if ($LASTEXITCODE -eq 0) { return $false }
        & git -C $FlutterSdk apply --check $Path *> $null
        if ($LASTEXITCODE -ne 0) { throw 'SDK patch precondition mismatch; local changes retained.' }
        & git -C $FlutterSdk apply $Path *> $null
        if ($LASTEXITCODE -ne 0) { throw 'SDK patch application failed.' }
        return $true
    } finally { $ErrorActionPreference = $saved }
}
try {
    $kernel = Join-Path $FlutterSdk $policy.hostKernel.path
    if (-not (Test-Path $kernel) -or (Get-FileHash $kernel -Algorithm SHA256).Hash.ToLowerInvariant() -ne $policy.hostKernel.sha256) {
        $zip = Join-Path $env:TEMP 'purelive-next-host-patched-sdk.zip'
        $options = @{UseBasicParsing=$true;TimeoutSec=300}
        $proxy = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
        if ($proxy.ProxyEnable -and $proxy.ProxyServer -match '^127\.0\.0\.1:\d+$') { $options.Proxy = 'http://' + $proxy.ProxyServer }
        Invoke-WebRequest @options -Uri $policy.hostKernel.source -OutFile $zip
        if ((Get-FileHash $zip -Algorithm SHA256).Hash.ToLowerInvariant() -ne $policy.hostKernel.archiveSha256) { throw 'Host kernel archive SHA-256 mismatch.' }
        $target = Join-Path $FlutterSdk 'bin\cache\artifacts\engine\host_common'
        if (Test-Path $target) { Move-Item $target ($target + '.before-' + (Get-Date).ToString('yyyyMMdd-HHmmss')) }
        Expand-Archive $zip -DestinationPath $target
    }
    $runtime = Join-Path $FlutterSdk $policy.hostRuntime.path
    if (-not (Test-Path $runtime) -or (Get-FileHash $runtime -Algorithm SHA256).Hash.ToLowerInvariant() -ne $policy.hostRuntime.sha256) {
        $zip = Join-Path $env:TEMP 'purelive-next-host-runtime.zip'
        $options = @{UseBasicParsing=$true;TimeoutSec=300}
        $proxy = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
        if ($proxy.ProxyEnable -and $proxy.ProxyServer -match '^127\.0\.0\.1:\d+$') { $options.Proxy = 'http://' + $proxy.ProxyServer }
        Invoke-WebRequest @options -Uri $policy.hostRuntime.source -OutFile $zip
        if ((Get-FileHash $zip -Algorithm SHA256).Hash.ToLowerInvariant() -ne $policy.hostRuntime.archiveSha256) { throw 'Host runtime archive SHA-256 mismatch.' }
        $folder = Split-Path $runtime -Parent
        [void](New-Item -ItemType Directory -Force $folder)
        if (Test-Path $runtime) { Copy-Item $runtime ($runtime + '.before-' + (Get-Date).ToString('yyyyMMdd-HHmmss')) }
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $archive = [IO.Compression.ZipFile]::OpenRead($zip)
        try {
            foreach ($name in @('dart-sdk/bin/dartaotruntime.exe', 'dart-sdk/LICENSE', 'dart-sdk/version')) {
                $entry = $archive.GetEntry($name)
                if (-not $entry) { throw 'Host runtime archive layout mismatch.' }
                [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, (Join-Path $folder ([IO.Path]::GetFileName($name))), $true)
            }
        } finally { $archive.Dispose() }
    }
    [void](Apply-VerifiedSdkPatch (Join-Path $repo $policy.semanticsPatch))
    $hostChanged = Apply-VerifiedSdkPatch (Join-Path $PSScriptRoot 'flutter-host-test.patch')
    if ($hostChanged) {
        foreach ($name in @('flutter_tools.snapshot', 'flutter_tools.stamp')) {
            $path = Join-Path $FlutterSdk ('bin\cache\' + $name)
            if (Test-Path $path) { Move-Item $path ($path + '.before-host-fix-' + (Get-Date).ToString('yyyyMMdd-HHmmss')) }
        }
    }
    . (Join-Path $PSScriptRoot 'environment.ps1')
    Set-HarmonyEnvironment -FlutterSdk $FlutterSdk -DevEcoStudio 'E:\DevTools\DevEcoStudio' -PubCache 'E:\DevTools\PubCache-OH'
    Write-Output 'Verified HarmonyOS SDK patches and separate host test kernel.'
} finally { Exit-PureLiveHeavyTaskSlot -Lease $lease }
