# Dot-source in a child PowerShell process; caller owns the shared heavy-task lease.
function Set-HarmonyEnvironment {
    param([string]$FlutterSdk, [string]$DevEcoStudio, [string]$PubCache)
    $ErrorActionPreference = 'Stop'
    $policy = Get-Content (Join-Path $PSScriptRoot 'toolchain.json') -Raw | ConvertFrom-Json
    $version = Get-Content (Join-Path $FlutterSdk 'bin\cache\flutter.version.json') -Raw | ConvertFrom-Json
    if ($version.frameworkVersion -ne $policy.sdk -or $version.frameworkRevision -ne $policy.revision -or $version.dartSdkVersion -ne $policy.dart) {
        throw 'HarmonyOS SDK provenance/version mismatch.'
    }
    foreach ($file in $policy.frameworkFiles.PSObject.Properties) {
        $text = [IO.File]::ReadAllText((Join-Path $FlutterSdk $file.Name)).Replace("`r`n", "`n")
        $bytes = [Text.UTF8Encoding]::new($false).GetBytes($text)
        $hash = ([BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
        if ($hash -ne $file.Value) { throw 'Required SDK compatibility patch/hash mismatch.' }
    }
    $hostKernel = Join-Path $FlutterSdk $policy.hostKernel.path
    if (-not (Test-Path $hostKernel) -or (Get-FileHash $hostKernel -Algorithm SHA256).Hash.ToLowerInvariant() -ne $policy.hostKernel.sha256) {
        throw 'The host test kernel does not match the verified host engine.'
    }
    foreach ($component in @($policy.hostRuntime, $policy.hostFrontend)) {
        $path = Join-Path $FlutterSdk $component.path
        if (-not (Test-Path $path) -or (Get-FileHash $path -Algorithm SHA256).Hash.ToLowerInvariant() -ne $component.sha256) {
            throw 'The host AOT runtime/frontend does not match the verified host engine.'
        }
    }
    $git = Get-Command git -ErrorAction Stop
    $env:PATH = (Join-Path $FlutterSdk 'bin') + ';' + (Split-Path $git.Source) + ';' +
        (Join-Path $DevEcoStudio 'tools\node') + ';' + (Join-Path $DevEcoStudio 'tools\ohpm\bin') + ';' +
        (Join-Path $DevEcoStudio 'tools\hvigor\bin') + ';' + $env:PATH
    $env:PUB_CACHE = $PubCache
    $env:PYTHONUTF8 = '1'
    $env:PYTHONIOENCODING = 'utf-8'
    $env:JAVA_HOME = Join-Path $DevEcoStudio 'jbr'
    $env:DEVECO_SDK_HOME = Join-Path $DevEcoStudio 'sdk'
    $env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
    $env:NO_PROXY = (@($env:NO_PROXY, 'localhost', '127.0.0.1', '::1') | Where-Object { $_ }) -join ','
    $proxy = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
    if ($proxy.ProxyEnable -and $proxy.ProxyServer -match '^127\.0\.0\.1:\d+$') {
        $env:HTTPS_PROXY = 'http://' + $proxy.ProxyServer
        $env:HTTP_PROXY = $env:HTTPS_PROXY
    }
}

function Invoke-HarmonyRepoCheck {
    param([string]$Name, [string]$Python, [string[]]$Arguments, [string]$LogRoot, [string]$WorkTree, [string]$SourceCheckout)
    if (Test-Path (Join-Path $WorkTree '.git')) {
        Invoke-HarmonyCheck $Name $Python $Arguments $LogRoot
        return
    }
    $gitDir = Join-Path $SourceCheckout '.git'
    if (-not (Test-Path $gitDir -PathType Container)) { throw 'Provide -SourceCheckout with the canonical Git checkout for this build mirror.' }
    $count = [Environment]::GetEnvironmentVariable('GIT_CONFIG_COUNT')
    $index = if ($count) { [int]$count } else { 0 }
    $key = 'GIT_CONFIG_KEY_' + $index
    $value = 'GIT_CONFIG_VALUE_' + $index
    $saved = @{}
    foreach ($variableName in @('GIT_DIR', 'GIT_WORK_TREE', 'GIT_CONFIG_COUNT', $key, $value)) { $saved[$variableName] = [Environment]::GetEnvironmentVariable($variableName) }
    try {
        $env:GIT_DIR = $gitDir
        $env:GIT_WORK_TREE = $WorkTree
        $env:GIT_CONFIG_COUNT = [string]($index + 1)
        [Environment]::SetEnvironmentVariable($key, 'safe.directory')
        [Environment]::SetEnvironmentVariable($value, $WorkTree)
        Invoke-HarmonyCheck $Name $Python $Arguments $LogRoot
    } finally {
        foreach ($variableName in $saved.Keys) { [Environment]::SetEnvironmentVariable($variableName, $saved[$variableName]) }
    }
}

function Invoke-HarmonyCheck {
    param([string]$Name, [string]$Executable, [string[]]$Arguments, [string]$LogRoot)
    [void](New-Item -ItemType Directory -Force $LogRoot)
    $log = Join-Path $LogRoot ($Name -replace '[^a-zA-Z0-9_.-]', '_')
    Write-Output ("HarmonyOS check: $Name")
    $savedErrorPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & $Executable @Arguments *> ($log + '.log')
        $result = $LASTEXITCODE
    } finally { $ErrorActionPreference = $savedErrorPreference }
    if ($result -ne 0) {
        Get-Content ($log + '.log') -Tail 70
        throw ("Check failed: $Name (exit $result)")
    }
    Get-Content ($log + '.log') | Select-String 'All tests passed|tests? passed|No issues found|Ran [0-9]+ tests' | Select-Object -Last 1 | ForEach-Object Line
}
