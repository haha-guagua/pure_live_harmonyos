"""Regression of previous missing-manifest, wrong ABI and package-collision failures."""
import importlib.util
import json
import struct
import tempfile
import unittest
import zipfile
from pathlib import Path

spec = importlib.util.spec_from_file_location("inspect_hap", Path(__file__).with_name("inspect_hap.py"))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class CandidateValidationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "tools/harmonyos").mkdir(parents=True)
        (self.root / "apps/pure_live").mkdir(parents=True)
        (self.root / "tools/harmonyos/toolchain.json").write_text(json.dumps({
            "bundle": "com.mystyle.purelive.next.ohos", "minimumApi": 24, "sdk": "fixture-sdk"}))
        (self.root / "apps/pure_live/pubspec.yaml").write_text("version: 5.5.0+5132\n")

    def candidate(self, *, omit=None, architecture=183, glibc=False, bundle=None, minimum_api=24,
                  login=True, exported=False):
        hap = self.root / "fixture.hap"
        app = {"bundleName": bundle or "com.mystyle.purelive.next.ohos", "versionName": "5.5.0",
               "versionCode": 5132, "debug": True, "minAPIVersion": minimum_api}
        header = bytearray(64)
        header[:5] = b"\x7fELF\x02"
        struct.pack_into("<H", header, 18, architecture)
        if glibc:
            header.extend(b"libc.so.6\0")
        entries = {"module.json": json.dumps({"app": app, 'module': {'abilities':
            [{'name': 'WebLoginAbility', 'exported': exported}] if login else []}}).encode()}
        for name in ["libflutter.so", "libmpv.so", "libmedia_kit_event_loop.so", "libsqlite3.so", "libffmpegkit_napi.so", "libaki_jsbind.so", "libc++_shared.so"]:
            entries[f"libs/arm64-v8a/{name}"] = header
        prefix = "resources/rawfile/flutter_assets/"
        entries[prefix + "NativeAssetsManifest.json"] = b'{"ohos_arm64":["libmpv.so","libmedia_kit_event_loop.so","libsqlite3.so"]}'
        for name in ["AssetManifest.bin", "FontManifest.json", "kernel_blob.bin", "assets/translations/zh.json", "assets/translations/en.json"]:
            entries[prefix + name] = b"fixture"
        with zipfile.ZipFile(hap, "w") as archive:
            for name, data in entries.items():
                if omit is None or not name.endswith(omit):
                    archive.writestr(name, data)
        return hap

    def test_records_build_checks_without_claiming_device_acceptance(self):
        result = module.inspect(self.candidate(), self.root)
        self.assertFalse(result["deviceTested"])
        self.assertEqual(result["bundleName"], "com.mystyle.purelive.next.ohos")

    def test_rejects_missing_native_assets_manifest(self):
        with self.assertRaisesRegex(ValueError, "manifest"):
            module.inspect(self.candidate(omit="NativeAssetsManifest.json"), self.root)

    def test_rejects_old_bundle_that_would_replace_the_working_app(self):
        with self.assertRaisesRegex(ValueError, "bundle"):
            module.inspect(self.candidate(bundle="com.mystyle.purelive.ohos"), self.root)

    def test_rejects_api_below_the_engine_requirement(self):
        with self.assertRaisesRegex(ValueError, "Minimum API"):
            module.inspect(self.candidate(minimum_api=20), self.root)

    def test_rejects_desktop_abi(self):
        with self.assertRaisesRegex(ValueError, "arm64"):
            module.inspect(self.candidate(architecture=62), self.root)

    def test_rejects_linux_glibc_dependency(self):
        with self.assertRaisesRegex(ValueError, "glibc"):
            module.inspect(self.candidate(glibc=True), self.root)

    def test_rejects_missing_application_kernel(self):
        with self.assertRaisesRegex(ValueError, "kernel_blob"):
            module.inspect(self.candidate(omit="kernel_blob.bin"), self.root)

    def test_rejects_missing_native_login_ability(self):
        with self.assertRaisesRegex(ValueError, 'login ability'):
            module.inspect(self.candidate(login=False), self.root)

    def test_rejects_public_native_login_ability(self):
        with self.assertRaisesRegex(ValueError, 'login ability'):
            module.inspect(self.candidate(exported=True), self.root)


if __name__ == "__main__":
    unittest.main()
