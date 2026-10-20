"""Validate matching signed/unsigned HarmonyOS HAPs and prepare release assets."""
import argparse
import hashlib
import json
import re
import shutil
import subprocess
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def digest(stream):
    hasher = hashlib.sha256()
    for chunk in iter(lambda: stream.read(1024 * 1024), b''):
        hasher.update(chunk)
    return hasher.hexdigest()


def prepare(tag: str, hap: Path, output: Path, unsigned_hap: Path = None) -> None:
    match = re.fullmatch(r'v(\d+\.\d+\.\d+)-ohos\.([1-9]\d*)', tag)
    if not match:
        raise ValueError('Expected version tag vX.Y.Z-ohos.N')
    version = re.search(r'^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$', (ROOT / 'pubspec.yaml').read_text(encoding='utf-8'), re.M)
    if not version or match[1] != version[1]:
        raise ValueError('Tag does not match pubspec application version')
    notes = ROOT / 'docs/releases' / f'{tag}.md'
    if not notes.is_file() or len(notes.read_text(encoding='utf-8').strip()) < 100:
        raise ValueError('Write the version-specific release notes before tagging')
    if unsigned_hap is None or unsigned_hap.resolve() == hap.resolve():
        raise ValueError('Provide distinct signed and unsigned HAP files')
    commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    payloads = []
    for package in [hap, unsigned_hap]:
        with zipfile.ZipFile(package) as archive:
            if archive.testzip() is not None:
                raise ValueError('HAP ZIP integrity check failed')
            app = json.loads(archive.read('module.json'))['app']
            expected = {'bundleName': 'com.mystyle.purelive.ohos', 'versionName': version[1],
                        'versionCode': int(version[2]), 'debug': True}
            if any(app.get(key) != value for key, value in expected.items()):
                raise ValueError('HAP application identity/version/build mode mismatch')
            minimum_api = int(app.get('minAPIVersion', 0)) % 1000
            if minimum_api < 20:
                raise ValueError('HAP minimum API must cover the native recording engine (API 20+)')
            names = archive.namelist()
            required = ['libmpv.so', 'libmedia_kit_event_loop.so', 'libsqlite3.so', 'libffmpegkit_napi.so', 'libaki_jsbind.so']
            if any(f'libs/arm64-v8a/{name}' not in names for name in required):
                raise ValueError('Required arm64 native library missing')
            if not any(name.endswith('NativeAssetsManifest.json') for name in names):
                raise ValueError('Flutter native-assets manifest missing')
            hashes = {}
            for name in names:
                if name == '.pages.info':  # Added by this SDK's code-signing stage.
                    continue
                with archive.open(name) as stream:
                    hashes[name] = digest(stream)
            payloads.append(hashes)
    if payloads[0] != payloads[1]:
        raise ValueError('Signed and unsigned HAP payloads differ; use one build')
    if output.exists() and any(output.iterdir()):
        raise ValueError('Release output must be empty to prevent stale asset publication')
    output.mkdir(parents=True, exist_ok=True)
    assets = []
    for source, suffix, signing in [(hap, 'device-signed', 'device-bound-debug'), (unsigned_hap, 'unsigned', 'unsigned')]:
        asset = output / f'PureLive-{tag}-harmonyos-arm64-debug-{suffix}.hap'
        shutil.copyfile(source, asset)
        with asset.open('rb') as stream:
            checksum = digest(stream)
        assets.append({'asset': asset.name, 'signing': signing, 'bytes': asset.stat().st_size, 'sha256': checksum})
    (output / 'SHA256SUMS.txt').write_text(''.join(f"{a['sha256']}  {a['asset']}\n" for a in assets), encoding='utf-8')
    metadata = {'tag': tag, 'commit': commit, 'applicationVersion': f'{version[1]}+{version[2]}',
                'bundleName': expected['bundleName'], 'platform': 'HarmonyOS', 'architecture': 'arm64-v8a',
                'configuration': 'Debug', 'minimumApi': minimum_api, 'deviceTestedByThisBuild': False, 'assets': assets}
    (output / 'build-metadata.json').write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    shutil.copyfile(ROOT / 'docs/INSTALLATION.md', output / 'INSTALLATION.md')
    content = notes.read_text(encoding='utf-8').rstrip()
    content += f"\n\n## 构建信息\n\n- 源码提交：`{commit}`\n- 应用版本：`{metadata['applicationVersion']}`\n"
    for asset in assets:
        content += f"- `{asset['asset']}`：{asset['bytes']}字节，SHA-256 `{asset['sha256']}`\n"
    content += '\n自动构建不执行真机验收。历史实机证据仅适用于说明明确列出的版本与场景。\n'
    (output / 'RELEASE_NOTES.md').write_text(content + '\n', encoding='utf-8')
    print(f'Prepared {tag}: matching signed and unsigned HAPs')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--tag', required=True)
    parser.add_argument('--hap', type=Path, required=True)
    parser.add_argument('--unsigned-hap', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    prepare(args.tag, args.hap, args.output, args.unsigned_hap)
