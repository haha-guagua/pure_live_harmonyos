import 'package:ffmpeg_kit_extended_flutter/ffmpeg_kit_extended_flutter.dart';
import 'record_native_session.dart';

class FfiRecordNativeSession implements RecordNativeSession {
  FfiRecordNativeSession(this.session, this.cancelSession);
  final FFmpegSession session;
  final void Function(FFmpegSession) cancelSession;
  @override
  int getSessionId() => session.getSessionId();
  @override
  int getReturnCode() => session.getReturnCode();
  @override
  String? getLogs() => session.getLogs();
  @override
  void setLogCallback(void Function(String) callback) => session.setLogCallback((entry) => callback(entry.message));
  @override
  void setStatisticsCallback(void Function(RecordNativeStatistics) callback) => session.setStatisticsCallback(
    (s) => callback(
      RecordNativeStatistics(
        time: s.time,
        size: s.size,
        bitrate: s.bitrate,
        speed: s.speed,
        videoFrameNumber: s.videoFrameNumber,
        videoFps: s.videoFps,
      ),
    ),
  );
  @override
  void setCompleteCallback(void Function(RecordNativeSession) callback) =>
      session.setCompleteCallback((_) => callback(this));
  @override
  Future<void> executeAsync() async {
    await session.executeAsync();
  }

  @override
  Future<void> cancel() async {
    cancelSession(session);
  }
}
