import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_player/live_player.dart';

void main() {
  test('HarmonyOS uses OHCodec and OHAudio rather than Android or Linux drivers', () {
    final platform = mpvPlatformOf(TargetPlatform.ohos);
    expect(platform, MpvPlatform.ohos);
    final config = MpvEngineConfig(platform: platform!);
    expect(config.preferredHardwareDecoder, 'ohcodec');
    expect(config.videoOutput, 'gpu-next');
    expect(config.audioOutput, 'ohaudio');
    expect(config.hwdecFor(software: true), 'no');
    expect(config.liveProperties['ao'], 'ohaudio');
  });

  test('imported Android expert settings cannot select unavailable HarmonyOS outputs', () {
    const config = MpvEngineConfig(
      platform: MpvPlatform.ohos,
      customOutput: true,
      hardwareDecoder: 'mediacodec',
      videoOutputDriver: 'mediacodec_embed',
      audioOutputDriver: 'audiotrack',
    );
    expect(config.preferredHardwareDecoder, 'ohcodec');
    expect(config.videoOutput, 'gpu-next');
    expect(config.audioOutput, 'ohaudio');
    const muted = MpvEngineConfig(platform: MpvPlatform.ohos, customOutput: true, audioOutputDriver: 'null');
    expect(muted.audioOutput, 'null');
    expect(muted.audioDisabled, isTrue);
  });
}
