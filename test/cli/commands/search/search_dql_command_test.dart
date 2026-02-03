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

  group('search dql', () {
    test('formats TABLE results as ASCII table', () async {
      when(() => mockApi.searchDql('TABLE test')).thenAnswer(
        (_) async => <String, dynamic>{
          'type': 'table',
          'headers': <String>['File', 'Status', 'Due'],
          'values': <dynamic>[
            <dynamic>['projects/bentos', 'active', '2026-03-01'],
            <dynamic>['projects/xcli', 'done', '2026-02-15'],
          ],
        },
      );

      final result =
          await runCapturing(runner, ['search', 'dql', 'TABLE test']);

      expect(result.code, 0);
      expect(result.output, contains('File'));
      expect(result.output, contains('Status'));
      expect(result.output, contains('Due'));
      expect(result.output, contains('projects/bentos'));
      expect(result.output, contains('active'));
      expect(result.output, contains('2026-03-01'));
      // Should have separator line with dashes
      expect(result.output, contains('---'));
    });

    test('formats LIST results as bulleted list', () async {
      when(() => mockApi.searchDql('LIST test')).thenAnswer(
        (_) async => <String, dynamic>{
          'type': 'list',
          'values': <dynamic>['daily/2026-02-03', 'projects/bentos'],
        },
      );

      final result =
          await runCapturing(runner, ['search', 'dql', 'LIST test']);

      expect(result.code, 0);
      expect(result.output, contains('- daily/2026-02-03'));
      expect(result.output, contains('- projects/bentos'));
    });

    test('formats TASK results with checkboxes', () async {
      when(() => mockApi.searchDql('TASK test')).thenAnswer(
        (_) async => <String, dynamic>{
          'type': 'task',
          'values': <dynamic>[
            <String, dynamic>{'text': 'Review PR', 'completed': false},
            <String, dynamic>{'text': 'Write tests', 'completed': true},
          ],
        },
      );

      final result =
          await runCapturing(runner, ['search', 'dql', 'TASK test']);

      expect(result.code, 0);
      expect(result.output, contains('[ ] Review PR'));
      expect(result.output, contains('[x] Write tests'));
    });

    test('displays JSON with --json flag', () async {
      when(() => mockApi.searchDql('test')).thenAnswer(
        (_) async => <String, dynamic>{
          'type': 'list',
          'values': <dynamic>['test'],
        },
      );

      final result =
          await runCapturing(runner, ['search', 'dql', '--json', 'test']);

      expect(result.code, 0);
      expect(result.output, contains('"type"'));
      expect(result.output, contains('"list"'));
    });

    test('falls back to JSON for unknown result type', () async {
      when(() => mockApi.searchDql('test')).thenAnswer(
        (_) async => <String, dynamic>{
          'type': 'unknown',
          'data': 'something',
        },
      );

      final result = await runCapturing(runner, ['search', 'dql', 'test']);

      expect(result.code, 0);
      expect(result.output, contains('"type"'));
      expect(result.output, contains('"unknown"'));
    });

    test('exits 64 when no query provided', () async {
      final result = await runCapturing(runner, ['search', 'dql']);

      expect(result.code, 64);
      verifyNever(() => mockApi.searchDql(any()));
    });
  });
}
