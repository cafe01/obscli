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

  group('note create', () {
    test('creates note with --content flag', () async {
      when(() => mockApi.createNote(any(), any()))
          .thenAnswer((_) async => {});

      final result = await runCapturing(runner, [
        'note',
        'create',
        'test.md',
        '--content',
        '# Hello',
      ]);

      expect(result.code, 0);
      expect(result.output, contains('Created: test.md'));
      verify(() => mockApi.createNote('test.md', '# Hello')).called(1);
    });

    test('displays JSON output with --json flag', () async {
      when(() => mockApi.createNote(any(), any()))
          .thenAnswer((_) async => {});

      final result = await runCapturing(runner, [
        'note',
        'create',
        '--json',
        'test.md',
        '--content',
        'content',
      ]);

      expect(result.code, 0);
      expect(result.output, contains('"path"'));
      expect(result.output, contains('"status"'));
      expect(result.output, contains('"created"'));
    });

    test('exits 64 when no path provided', () async {
      final result = await runCapturing(runner, ['note', 'create']);

      expect(result.code, 64);
      verifyNever(() => mockApi.createNote(any(), any()));
    });

    test('exits 1 on API error', () async {
      when(() => mockApi.createNote(any(), any()))
          .thenThrow(Exception('Permission denied'));

      final result = await runCapturing(runner, [
        'note',
        'create',
        'test.md',
        '--content',
        'test',
      ]);

      expect(result.code, 1);
    });
  });
}
