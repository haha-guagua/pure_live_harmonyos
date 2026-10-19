[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$FlutterSdk)
$ErrorActionPreference='Stop'
$relative='packages\flutter_tools\lib\src\build_system\targets\ohos.dart'
$target=Join-Path $FlutterSdk $relative
$before='feaa1158fdc3cb365349c103f7c69ac549fa2813e37179dad4c8c95875b99be9'
$after='e3f23b9cdfbe6a35a45d6db1a18f9edb8acffe50ebe389cb4b1e280e0aeea70b'
$hash=(Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant()
if($hash -eq $after){return}
if($hash -ne $before){throw 'Unrecognized Flutter OH asset-bundle source; review the pinned patch before building.'}
$source=[IO.File]::ReadAllText($target)
$newline=if($source.Contains("`r`n")){"`r`n"}else{"`n"}
$source=$source.Replace("import '../../build_info.dart';",("import '../../build_info.dart';"+$newline+"import '../../devfs.dart';"))
$needle='      flavor: environment.defines[kFlavor],'
$addition=@(
 '      additionalContent: <String, DevFSContent>{',
 "        'NativeAssetsManifest.json': DevFSFileContent(",
 "          environment.buildDir.childFile('native_assets.json'),",
 '        ),',
 '      },'
) -join $newline
$source=$source.Replace($needle,($needle+$newline+$addition))
$bytes=[Text.UTF8Encoding]::new($false).GetBytes($source)
$computed=([BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($bytes))).Replace('-','').ToLowerInvariant()
if($computed -ne $after){throw 'SDK patch output hash mismatch'}
$backup=Join-Path (Split-Path -Parent $FlutterSdk) 'FlutterOH-compat-backups\native-assets-3.41.10-ohos-1.0.1'
[void](New-Item -ItemType Directory -Path $backup -Force)
if(-not (Test-Path (Join-Path $backup 'ohos.dart'))){Copy-Item -LiteralPath $target -Destination (Join-Path $backup 'ohos.dart')}
[IO.File]::WriteAllBytes($target,$bytes)
# Recompile the tool from the reviewed source; stale snapshots omit this fix.
foreach($name in @('flutter_tools.snapshot','flutter_tools.stamp')){
 $cached=Join-Path $FlutterSdk ('bin\cache\'+$name)
 if(Test-Path -LiteralPath $cached){Move-Item -LiteralPath $cached -Destination (Join-Path $backup $name) -Force}
}
Write-Output 'Applied pinned OH native-assets manifest packaging fix; original tool files backed up.'
