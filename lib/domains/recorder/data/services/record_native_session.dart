/// Recorder-facing session contract shared by the FFI and HarmonyOS engines.
abstract interface class RecordNativeSession {
  int getSessionId();
  int getReturnCode();
  String? getLogs();
  void setLogCallback(void Function(String message) callback);
  void setStatisticsCallback(void Function(RecordNativeStatistics statistics) callback);
  void setCompleteCallback(void Function(RecordNativeSession session) callback);
  Future<void> executeAsync();
  Future<void> cancel();
}

class RecordNativeStatistics {
  const RecordNativeStatistics({
    required this.time,
    required this.size,
    this.bitrate = 0,
    this.speed = 0,
    this.videoFrameNumber = 0,
    this.videoFps = 0,
  });
  final int time;
  final int size;
  final double bitrate;
  final double speed;
  final int videoFrameNumber;
  final double videoFps;
}
