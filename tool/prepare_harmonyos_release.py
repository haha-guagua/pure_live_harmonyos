"""Validate a HarmonyOS test HAP and prepare explicit, versioned release assets."""
import argparse
import hashlib
import json
import re
import shutil
import subprocess
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def prepare(tag: str, hap: Path, output: Path) -> None:
    match = re.fullmatch(r"v(\d+\.\d+\.\d+)-ohos\.([1-9]\d*)", tag)
    if not match:
        raise ValueError("Expected version tag vX.Y.Z-ohos.N")
    version = re.search(r"^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$", (ROOT / "pubspec.yaml").read_text(encoding="utf-8"), re.M)
    if not version or match[1] != version[1]:
        raise ValueError("Tag does not match pubspec application version")
    notes = ROOT / "docs" / "releases" / f"{tag}.md"
    if not notes.is_file() or len(notes.read_text(encoding="utf-8").strip()) < 100:
        raise ValueError("Write the version-specific release notes before tagging")
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    with zipfile.ZipFile(hap) as archive:
        if archive.testzip() is not None:
            raise ValueError("HAP ZIP integrity check failed")
        app = json.loads(archive.read("module.json"))["app"]
        expected = {"bundleName": "com.mystyle.purelive.ohos", "versionName": version[1],
                    "versionCode": int(version[2]), "debug": True}
        if any(app.get(key) != value for key, value in expected.items()):
            raise ValueError("HAP application identity/version/build mode mismatch")
        names = archive.namelist()
        required = ["libmpv.so", "libmedia_kit_event_loop.so", "libsqlite3.so", "libffmpegkit_napi.so", "libaki_jsbind.so"]
        if any(f"libs/arm64-v8a/{name}" not in names for name in required):
            raise ValueError("Required arm64 native library missing")
        if not any(name.endswith("NativeAssetsManifest.json") for name in names):
            raise ValueError("Flutter native-assets manifest missing")
    if output.exists() and any(output.iterdir()):
        raise ValueError("Release output must be empty to prevent stale asset publication")
    output.mkdir(parents=True, exist_ok=True)
    asset = output / f"PureLive-{tag}-harmonyos-arm64-debug-device-signed.hap"
    shutil.copyfile(hap, asset)
    hasher = hashlib.sha256()
    with asset.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            hasher.update(chunk)
    digest = hasher.hexdigest()
    (output / "SHA256SUMS.txt").write_text(f"{digest}  {asset.name}\n", encoding="utf-8")
    metadata = {"tag": tag, "commit": commit, "applicationVersion": f"{version[1]}+{version[2]}",
                "bundleName": expected["bundleName"], "platform": "HarmonyOS", "architecture": "arm64-v8a",
                "configuration": "Debug", "signing": "device-bound-debug", "minimumApi": 20,
                "deviceTestedByThisBuild": False, "asset": asset.name, "bytes": asset.stat().st_size, "sha256": digest}
    (output / "build-metadata.json").write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    shutil.copyfile(ROOT / "docs" / "INSTALLATION.md", output / "INSTALLATION.md")
    content = notes.read_text(encoding="utf-8").rstrip()
    content += f"\n\n## 构建信息\n\n- 源码提交：`{commit}`\n- 应用版本：`{metadata['applicationVersion']}`\n"
    content += f"- 安装包：`{asset.name}`\n- SHA-256：`{digest}`\n"
    content += "\n本次自动构建不执行真机验收。历史实机证据仅适用于发布说明明确列出的版本与场景。\n"
    (output / "RELEASE_NOTES.md").write_text(content + "\n", encoding="utf-8")
    print(f"Prepared {tag}: {asset.stat().st_size} bytes, SHA256 {digest}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tag", required=True)
    parser.add_argument("--hap", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    prepare(args.tag, args.hap, args.output)
