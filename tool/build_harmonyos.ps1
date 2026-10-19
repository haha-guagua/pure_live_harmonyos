[CmdletBinding()]
param(
    [string] $FlutterSdk = 'E:\DevTools\FlutterOH-3.41.10',
    [string] $DevEcoStudio = 'E:\DevTools\DevEcoStudio',
    [string] $PubCache = 'E:\DevTools\PubCache-OH',
    [switch] $SkipPubGet,
    [switch] $Offline,
    [switch] $Codesign
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$localProfile = Join-Path $repoRoot 'ohos\build-profile.json5'
if (-not (Test-Path -LiteralPath $localProfile)) {
    Copy-Item -LiteralPath (Join-Path $repoRoot 'ohos\build-profile.template.json5') -Destination $localProfile
}
$flutter = Join-Path $FlutterSdk 'bin\flutter.bat'
$cppRuntime = Join-Path $DevEcoStudio 'sdk\default\openharmony\native\llvm\lib\aarch64-linux-ohos\libc++_shared.so'
foreach ($required in @($flutter, $cppRuntime)) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Required HarmonyOS tool missing: $required" }
}
$expected = (Get-Content -LiteralPath (Join-Path $repoRoot '.fvmrc') -Raw | ConvertFrom-Json).flutter
$installed = (Get-Content -LiteralPath (Join-Path $FlutterSdk 'bin\cache\flutter.version.json') -Raw | ConvertFrom-Json).frameworkVersion
if ($expected -ne $installed) { throw "SDK mismatch: project=$expected, installed=$installed" }
if ($SkipPubGet -and -not (Test-Path -LiteralPath (Join-Path $repoRoot '.dart_tool\package_config.json'))) {
    throw 'Resolve dependencies before using -SkipPubGet.'
}

. (Join-Path $PSScriptRoot 'build_resource_guard.ps1')
$lease = Enter-PureLiveHeavyTaskSlot -TaskName 'harmonyos-arm64-debug' -QueueTimeoutMinutes 30
$started = Get-Date
$oldLocation = Get-Location
$keys = @('PURE_LIVE_FLUTTER', 'JAVA_HOME', 'DEVECO_SDK_HOME', 'PUB_CACHE', 'PATH')
$previous = @{}
foreach ($key in $keys) { $previous[$key] = [Environment]::GetEnvironmentVariable($key, 'Process') }
$exitCode = $null
$artifactName = if ($Codesign) { 'entry-default-signed.hap' } else { 'entry-default-unsigned.hap' }
$artifact = Join-Path $repoRoot ('build\ohos\hap\' + $artifactName)
try {
    Set-Location -LiteralPath $repoRoot
    $env:PURE_LIVE_FLUTTER = $flutter
    $env:JAVA_HOME = Join-Path $DevEcoStudio 'jbr'
    $env:DEVECO_SDK_HOME = Join-Path $DevEcoStudio 'sdk'
    $env:PUB_CACHE = $PubCache
    $env:PATH = (Join-Path $DevEcoStudio 'tools\node') + ';' +
        (Join-Path $DevEcoStudio 'tools\ohpm\bin') + ';' +
        (Join-Path $DevEcoStudio 'tools\hvigor\bin') + ';' + $env:PATH

    & (Join-Path $PSScriptRoot 'apply_harmonyos_sdk_patch.ps1') -FlutterSdk $FlutterSdk

    # libmpv is prebuilt, so Hvigor does not infer its shared C++ dependency.
    $libraryDir = Join-Path $repoRoot 'ohos\entry\libs\arm64-v8a'
    [void](New-Item -ItemType Directory -Force -Path $libraryDir)
    Copy-Item -LiteralPath $cppRuntime -Destination (Join-Path $libraryDir 'libc++_shared.so') -Force
    if (-not $SkipPubGet) {
        $pubArguments = @('--suppress-analytics', 'pub', 'get', '--enforce-lockfile')
        if ($Offline) { $pubArguments += '--offline' }
        & (Join-Path $PSScriptRoot 'flutterw.ps1') -FlutterArgs $pubArguments
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) { throw "Dependency resolution failed: $exitCode" }
    }
    # Pass the array explicitly: PowerShell's common Debug parameter must not consume --debug.
    $signingArgument = if ($Codesign) { '--codesign' } else { '--no-codesign' }
    & (Join-Path $PSScriptRoot 'flutterw.ps1') -FlutterArgs @('--suppress-analytics', 'build', 'hap', '--debug', '--no-pub', $signingArgument)
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) { throw "HarmonyOS HAP build failed: $exitCode" }
    if (-not (Test-Path -LiteralPath $artifact)) { throw "HAP not found: $artifact" }
    Write-Output "Debug HAP: $artifact"
    Write-Output ('SHA256: ' + (Get-FileHash -Algorithm SHA256 -LiteralPath $artifact).Hash.ToLowerInvariant())
} finally {
    $recordDir = Join-Path $repoRoot 'local-artifacts\build-records'
    [void](New-Item -ItemType Directory -Force -Path $recordDir)
    [ordered]@{
        target = 'HarmonyOS'; architecture = 'arm64'; configuration = 'Debug'; signed = [bool]$Codesign
        sdk = $installed; started = $started.ToString('o'); ended = (Get-Date).ToString('o')
        seconds = ((Get-Date) - $started).TotalSeconds; exitCode = $exitCode
        artifact = $artifact; deviceTested = $false; resourceGuard = $true
        peakCpu = $null; peakMemory = $null; resourceSampling = 'Not collected by this build entrypoint'
    } | ConvertTo-Json | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $recordDir ('harmonyos-debug-' + $started.ToString('yyyyMMdd-HHmmss') + '.json'))
    foreach ($key in $keys) { [Environment]::SetEnvironmentVariable($key, $previous[$key], 'Process') }
    Set-Location -LiteralPath $oldLocation.Path
    Exit-PureLiveHeavyTaskSlot -Lease $lease
}
