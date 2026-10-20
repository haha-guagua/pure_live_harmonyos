[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$FlutterSdk, [Parameter(Mandatory=$true)][string]$RepoRoot)
$ErrorActionPreference='Stop'
$before='4b9a4335577b73af3d9854f8dc9ba726807db32ee15b537853fb49dc2c830f76'
$after='60c4756d1a3eaffbda8431fa1bf0effd9d06d56b9356212dabfdb624df9d1fd6'
$relative='src\main\ets\embedding\engine\systemchannels\PlatformChannel.ets'
function Patch-Channel([string]$file) {
    $hash=(Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant()
    if($hash -eq $after){return $false}
    if($hash -ne $before){throw "Unrecognized Flutter OH platform channel: $file"}
    $source=[IO.File]::ReadAllText($file)
    $needle='this.platform.platformMessageHandler.showSystemUiMode(mode);'
    $source=$source.Replace($needle,($needle+"`n            result.success(null);"))
    $bytes=[Text.UTF8Encoding]::new($false).GetBytes($source)
    $hash=([BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($bytes))).Replace('-','').ToLowerInvariant()
    if($hash -ne $after){throw 'Platform channel patch output hash mismatch'}
    [IO.File]::WriteAllBytes($file,$bytes)
    return $true
}
$backup=Join-Path (Split-Path -Parent $FlutterSdk) 'FlutterOH-compat-backups\fullscreen-callback-3.41.10-ohos-1.0.1'
[void](New-Item -ItemType Directory -Path $backup -Force)
foreach($name in @('flutter.har','flutter_embedding_debug.har')) {
    $archive=Join-Path $FlutterSdk ('bin\cache\artifacts\engine\ohos-arm64\'+$name)
    $temp=Join-Path ([IO.Path]::GetTempPath()) ('pure-live-channel-'+[guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $temp)
    try {
        & tar.exe -xzf $archive -C $temp
        if($LASTEXITCODE -ne 0){throw 'Cannot unpack Flutter HAR'}
        if(Patch-Channel (Join-Path $temp ('package\'+$relative))) {
            $original=Join-Path $backup $name
            if(-not (Test-Path -LiteralPath $original)){Copy-Item -LiteralPath $archive -Destination $original}
            $patched=Join-Path $temp 'patched.har'
            & tar.exe -czf $patched -C $temp package
            if($LASTEXITCODE -ne 0){throw 'Cannot repack Flutter HAR'}
            Copy-Item -LiteralPath $patched -Destination $archive -Force
        }
    } finally {Remove-Item -LiteralPath $temp -Recurse -Force}
}
# Existing ohpm installations can retain an unpacked copy of the old HAR.
$installed=Join-Path $RepoRoot 'ohos\oh_modules\.ohpm'
if(Test-Path -LiteralPath $installed) {
    Get-ChildItem -LiteralPath $installed -Directory -Filter '@ohos+flutter_ohos@*' | ForEach-Object {
        $channel=Join-Path $_.FullName ('oh_modules\@ohos\flutter_ohos\'+$relative)
        if(Test-Path -LiteralPath $channel){[void](Patch-Channel $channel)}
    }
}
Write-Output 'Verified Flutter OH fullscreen callback patch (arm64 Debug); originals backed up.'
