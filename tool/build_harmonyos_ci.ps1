[CmdletBinding()]
param([string] $Config = 'E:\DevTools\PureLiveCI\config.json')
$ErrorActionPreference = 'Stop'
# This file contains paths only. Signing credentials stay in the external profile.
if (-not (Test-Path -LiteralPath $Config)) { throw 'Configure the dedicated runner first; see docs/RELEASING.md.' }
$settings = Get-Content -LiteralPath $Config -Raw | ConvertFrom-Json
foreach ($key in @('FlutterSdk', 'DevEcoStudio', 'PubCache', 'SigningProfile')) {
    if (-not $settings.$key -or -not (Test-Path -LiteralPath $settings.$key)) { throw "CI path missing: $key" }
}
$root = Split-Path -Parent $PSScriptRoot
$profile = Join-Path $root 'ohos\build-profile.json5'
try {
    Copy-Item -LiteralPath $settings.SigningProfile -Destination $profile -Force
    & (Join-Path $PSScriptRoot 'build_harmonyos.ps1') -FlutterSdk $settings.FlutterSdk `
        -DevEcoStudio $settings.DevEcoStudio -PubCache $settings.PubCache -Codesign
    # Native build entrypoint throws on failure. Verify signature before publishing.
    $hap = Join-Path $root 'build\ohos\hap\entry-default-signed.hap'
    # Hvigor emits both artifacts during the same signed build. Refresh the
    # Flutter output from that unsigned artifact instead of reusing an old HAP.
    $nativeUnsigned = Join-Path $root 'ohos\entry\build\default\outputs\default\entry-default-unsigned.hap'
    $unsigned = Join-Path $root 'build\ohos\hap\entry-default-unsigned.hap'
    if (-not (Test-Path $nativeUnsigned)) { throw 'Same-build unsigned HAP missing.' }
    Copy-Item -LiteralPath $nativeUnsigned -Destination $unsigned -Force
    $java = Join-Path $settings.DevEcoStudio 'jbr\bin\java.exe'
    $signer = Join-Path $settings.DevEcoStudio 'sdk\default\openharmony\toolchains\lib\hap-sign-tool.jar'
    $verifyDir = Join-Path ([IO.Path]::GetTempPath()) ('pure-live-signature-' + [guid]::NewGuid())
    [void](New-Item -ItemType Directory -Path $verifyDir)
    $verifyLog = Join-Path $verifyDir 'verify.log'
    try {
        & $java -jar $signer verify-app -inFile $hap -outCertChain (Join-Path $verifyDir 'chain.cer') -outProfile (Join-Path $verifyDir 'profile.p7b') *> $verifyLog
        if ($LASTEXITCODE -ne 0) { throw 'HAP signature verification failed; raw signing diagnostics are not published.' }
        $previousErrorPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        & $java -jar $signer verify-app -inFile $unsigned -outCertChain (Join-Path $verifyDir 'unsigned-chain.cer') -outProfile (Join-Path $verifyDir 'unsigned-profile.p7b') *> $verifyLog
        $unsignedVerifyCode = $LASTEXITCODE
        $ErrorActionPreference = $previousErrorPreference
        if ($unsignedVerifyCode -eq 0) { throw 'Unsigned artifact unexpectedly contains a valid package signature.' }
        $global:LASTEXITCODE = 0
        Write-Output 'Signed HAP verified; unsigned HAP correctly has no package signature.'
    } finally { Remove-Item -LiteralPath $verifyDir -Recurse -Force -ErrorAction SilentlyContinue }
} finally {
    # Never retain copied credential-bearing configuration in the runner checkout.
    Remove-Item -LiteralPath $profile -Force -ErrorAction SilentlyContinue
}
