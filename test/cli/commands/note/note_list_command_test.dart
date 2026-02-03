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

  group('note list', () {
    test('displays entries with [dir] prefix for directories', () async {
      when(() => mockApi.listDirectory('/')).thenAnswer(
        (_) async => <Map<String, dynamic>>[
          <String, dynamic>{'name': 'projects', 'type': 'folder'},
          <String, dynamic>{'name': 'note.md', 'type': 'file'},
          <String, dynamic>{'name': 'daily', 'type': 'folder'},
        ],
      );

      final result = await runCapturing(runner, ['note', 'list']);

      expect(result.code, 0);
      expect(result.output, contains('[dir] projects/'));
      expect(result.output, contains('note.md'));
      expect(result.output, contains('[dir] daily/'));
      expect(result.output, isNot(contains('[dir] note.md')));
    });

    test('displays JSON with --json flag', () async {
      when(() => mockApi.listDirectory('/')).thenAnswer(
        (_) async => <Map<String, dynamic>>[
          <String, dynamic>{'name': 'test.md', 'type': 'file'},
        ],
      );

      final result = await runCapturing(runner, ['note', 'list', '--json']);

      expect(result.code, 0);
      expect(result.output, contains('"name"'));
      expect(result.output, contains('"test.md"'));
    });

    test('accepts optional path argument', () async {
      when(() => mockApi.listDirectory('projects/')).thenAnswer(
        (_) async => <Map<String, dynamic>>[
          <String, dynamic>{'name': 'bentos.md', 'type': 'file'},
        ],
      );

      final result =
          await runCapturing(runner, ['note', 'list', 'projects/']);

      expect(result.code, 0);
      expect(result.output, contains('bentos.md'));
      verify(() => mockApi.listDirectory('projects/')).called(1);
    });

    test('defaults to root directory when no path provided', () async {
      when(() => mockApi.listDirectory('/')).thenAnswer(
        (_) async => <Map<String, dynamic>>[],
      );

      await runCapturing(runner, ['note', 'list']);

      verify(() => mockApi.listDirectory('/')).called(1);
    });
  });
}
