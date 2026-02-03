import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:obscli/src/cli/obs_runner.dart';

import '../../../helpers/mock_obsidian_api.dart';
import '../../../helpers/test_runner.dart';

void main() {
  late MockObsidianApi mockApi;
  late ObsCommandRunner runner;

  setUp(() {
    mockApi = MockObsidianApi();
    runner = ObsCommandRunner(api: mockApi);
  });

  group('command exec', () {
    test('executes command by ID', () async {
      when(() => mockApi.executeCommand('app:reload'))
          .thenAnswer((_) async => {});

      final result =
          await runCapturing(runner, ['command', 'exec', 'app:reload']);

      expect(result.code, 0);
      expect(result.output, contains('Executed: app:reload'));
      verify(() => mockApi.executeCommand('app:reload')).called(1);
    });

    test('displays JSON with --json flag', () async {
      when(() => mockApi.executeCommand('test-command'))
          .thenAnswer((_) async => {});

      final result = await runCapturing(runner, [
        'command',
        'exec',
        '--json',
        'test-command',
      ]);

      expect(result.code, 0);
      expect(result.output, contains('"commandId"'));
      expect(result.output, contains('"test-command"'));
      expect(result.output, contains('"executed"'));
    });

    test('exits 64 when no command ID provided', () async {
      final result = await runCapturing(runner, ['command', 'exec']);

      expect(result.code, 64);
      verifyNever(() => mockApi.executeCommand(any()));
    });

    test('exits 1 on API error', () async {
      when(() => mockApi.executeCommand(any()))
          .thenThrow(Exception('Command not found'));

      final result =
          await runCapturing(runner, ['command', 'exec', 'invalid']);

      expect(result.code, 1);
    });
  });
}
