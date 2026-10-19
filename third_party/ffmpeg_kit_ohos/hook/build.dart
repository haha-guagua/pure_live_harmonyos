import 'dart:io';
import 'package:hooks/hooks.dart';

Future<void> main(List<String> args) async {
  await build(args, (input, output) async {
    stderr.writeln('HarmonyOS compatibility: FFmpeg recording/remuxing unavailable; no native asset emitted.');
  });
}
