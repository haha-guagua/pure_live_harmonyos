"""Validate the phone candidate; this never claims real-device acceptance."""
import argparse
import hashlib
import json
import re
import struct
import zipfile
from pathlib import Path


def inspect(hap: Path, root: Path) -> dict:
    policy = json.loads((root / "tools/harmonyos/toolchain.json").read_text(encoding="utf-8-sig"))
    version = re.search(r"^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$", (root / "apps/pure_live/pubspec.yaml").read_text(encoding="utf-8-sig"), re.M)
    if not version:
        raise ValueError("Application version is missing")
    with zipfile.ZipFile(hap) as archive:
        if archive.testzip() is not None:
            raise ValueError("HAP CRC mismatch")
        metadata = json.loads(archive.read("module.json"))
        app = metadata["app"]
        expected = {"bundleName": policy["bundle"], "versionName": version[1], "versionCode": int(version[2]), "debug": True}
        if any(app.get(key) != value for key, value in expected.items()):
            raise ValueError("Application bundle, version or mode mismatch")
        if int(app.get("minAPIVersion", 0)) % 1000 < policy["minimumApi"]:
            raise ValueError("Minimum API is too low for the recorder")
        names = archive.namelist()
        login = next((item for item in metadata.get('module', {}).get('abilities', [])
                      if item.get('name') == 'WebLoginAbility'), None)
        if login is None or login.get('exported') is not False:
            raise ValueError('Native login ability must exist and remain private')
        required = ["libflutter.so", "libmpv.so", "libmedia_kit_event_loop.so", "libsqlite3.so", "libffmpegkit_napi.so", "libaki_jsbind.so", "libc++_shared.so"]
        for name in required:
            data = archive.read(f"libs/arm64-v8a/{name}")
            if data[:5] != b"\x7fELF\x02" or struct.unpack_from("<H", data, 18)[0] != 183:
                raise ValueError(f"Native library is not arm64 ELF: {name}")
            if b"libc.so.6\0" in data:
                raise ValueError(f"Linux glibc library must not enter OHOS: {name}")
        manifests = [name for name in names if name.endswith("NativeAssetsManifest.json")]
        if len(manifests) != 1:
            raise ValueError("Missing or ambiguous Flutter native-assets manifest")
        asset_root = manifests[0].rsplit("/", 1)[0]
        for asset in ["AssetManifest.bin", "FontManifest.json", "kernel_blob.bin", "assets/translations/zh.json", "assets/translations/en.json"]:
            if f"{asset_root}/{asset}" not in names:
                raise ValueError(f"Required Flutter application asset is missing: {asset}")
        manifest = archive.read(manifests[0]).decode("utf-8")
        for name in ["libmpv.so", "libmedia_kit_event_loop.so", "libsqlite3.so"]:
            if name not in manifest:
                raise ValueError(f"Native asset is not mapped: {name}")
        if "ohos_arm64" not in manifest:
            raise ValueError("Native-assets mapping does not target OHOS arm64")
    with hap.open("rb") as stream:
        digest = hashlib.file_digest(stream, "sha256").hexdigest()
    return {**expected, "hap": hap.name, "bytes": hap.stat().st_size, "sha256": digest, "sdk": policy["sdk"], "nativeLoginPrivate": True, "deviceTested": False}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("hap", type=Path)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    evidence = inspect(args.hap, args.root)
    text = json.dumps(evidence, ensure_ascii=False, indent=2) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(text, encoding="utf-8")
    print(text)
