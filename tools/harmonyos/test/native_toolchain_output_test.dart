import 'dart:convert';
import 'dart:io';

import 'package:native_toolchain_c/src/utils/run_process.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

final class _Process implements Process {
  _Process(this.bytes);
  final List<int> bytes;
  @override
  Stream<List<int>> get stdout =>
      Stream.fromIterable(bytes.map((byte) => [byte]));
  @override
  Stream<List<int>> get stderr => const Stream.empty();
  @override
  Future<int> get exitCode async => 0;
  @override
  int get pid => 123;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Manager implements ProcessManager {
  _Manager(this.bytes);
  final List<int> bytes;
  @override
  Future<Process> start(
    List<Object> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) async => _Process(bytes);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('localized vswhere JSON survives UTF-8 split at every byte', () async {
    final json = jsonEncode([
      {
        'installationPath': r'E:\DevTools\VSBuildTools',
        'displayName': 'Visual Studio 生成工具',
      },
    ]);
    final result = await runProcess(
      executable: Uri.file('vswhere.exe'),
      arguments: ['-format', 'json', '-utf8'],
      logger: null,
      processManager: _Manager(utf8.encode(json)),
    );
    expect(jsonDecode(result.stdout), jsonDecode(json));
    expect(result.exitCode, 0);
  });
}
