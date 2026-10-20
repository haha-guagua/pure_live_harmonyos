import importlib.util
import json
import tempfile
import unittest
import zipfile
from pathlib import Path
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location('harmonyos_release', Path(__file__).resolve().parents[2] / 'tool/prepare_harmonyos_release.py')
release = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(release)


class HarmonyReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / 'docs/releases').mkdir(parents=True)
        (self.root / 'pubspec.yaml').write_text('version: 3.1.19+4108\n')
        (self.root / 'docs/releases/v3.1.19-ohos.1.md').write_text('Documented changes and limitations. ' * 5)
        (self.root / 'docs/INSTALLATION.md').write_text('Only profile-enrolled devices can install this Debug HAP.')
        self.hap = self.root / 'input.hap'
        self.output = self.root / 'release'
        self.root_patch = patch.object(release, 'ROOT', self.root)
        self.root_patch.start()
        self.addCleanup(self.root_patch.stop)
        self.git_patch = patch.object(release.subprocess, 'check_output', return_value='a' * 40)
        self.git_patch.start()
        self.addCleanup(self.git_patch.stop)
        self.make_hap()

    def make_hap(self, code=4108, missing=None):
        with zipfile.ZipFile(self.hap, 'w') as archive:
            archive.writestr('module.json', json.dumps({'app': {'bundleName': 'com.mystyle.purelive.ohos',
                'versionName': '3.1.19', 'versionCode': code, 'debug': True}}))
            for library in ['libmpv.so', 'libmedia_kit_event_loop.so', 'libsqlite3.so', 'libffmpegkit_napi.so', 'libaki_jsbind.so']:
                if library != missing:
                    archive.writestr('libs/arm64-v8a/' + library, b'native-fixture')
            archive.writestr('resources/flutter_assets/NativeAssetsManifest.json', '{}')

    def test_prepares_traceable_assets_without_claiming_device_acceptance(self):
        release.prepare('v3.1.19-ohos.1', self.hap, self.output)
        metadata = json.loads((self.output / 'build-metadata.json').read_text())
        self.assertFalse(metadata['deviceTestedByThisBuild'])
        self.assertEqual(metadata['signing'], 'device-bound-debug')
        self.assertEqual(len(list(self.output.glob('*.hap'))), 1)
        self.assertIn(metadata['sha256'], (self.output / 'SHA256SUMS.txt').read_text())
        self.assertEqual(metadata['commit'], 'a' * 40)

    def test_rejects_unrelated_tag(self):
        with self.assertRaisesRegex(ValueError, 'Expected version tag'):
            release.prepare('main', self.hap, self.output)

    def test_rejects_version_mismatch(self):
        with self.assertRaisesRegex(ValueError, 'pubspec'):
            release.prepare('v9.0.0-ohos.1', self.hap, self.output)

    def test_requires_version_specific_release_notes(self):
        with self.assertRaisesRegex(ValueError, 'release notes'):
            release.prepare('v3.1.19-ohos.2', self.hap, self.output)

    def test_rejects_stale_hap_version(self):
        self.make_hap(code=4107)
        with self.assertRaisesRegex(ValueError, 'identity/version'):
            release.prepare('v3.1.19-ohos.1', self.hap, self.output)

    def test_rejects_missing_recording_engine(self):
        self.make_hap(missing='libffmpegkit_napi.so')
        with self.assertRaisesRegex(ValueError, 'native library'):
            release.prepare('v3.1.19-ohos.1', self.hap, self.output)

    def test_rejects_mixed_old_release_output(self):
        self.output.mkdir()
        (self.output / 'old.hap').write_bytes(b'old')
        with self.assertRaisesRegex(ValueError, 'empty'):
            release.prepare('v3.1.19-ohos.1', self.hap, self.output)


if __name__ == '__main__':
    unittest.main()
