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

  group('search text', () {
    test('displays results in grep-like format', () async {
      when(() => mockApi.searchSimple('test', contextLength: null)).thenAnswer(
        (_) async => <Map<String, dynamic>>[
          <String, dynamic>{
            'filename': 'note.md',
            'matches': <dynamic>[
              <String, dynamic>{
                'match': <String, dynamic>{'start': 10, 'end': 14},
                'context': 'This is a test match',
              },
              <String, dynamic>{
                'match': <String, dynamic>{'start': 8, 'end': 12},
                'context': 'Another test here',
              },
            ],
          },
        ],
      );

      final result = await runCapturing(runner, ['search', 'text', 'test']);

      expect(result.code, 0);
      expect(result.output, contains('note.md -- This is a test match'));
      expect(result.output, contains('note.md -- Another test here'));
    });

    test('displays JSON with --json flag', () async {
      when(() => mockApi.searchSimple('query', contextLength: null)).thenAnswer(
        (_) async => <Map<String, dynamic>>[
          <String, dynamic>{'filename': 'test.md'},
        ],
      );

      final result =
          await runCapturing(runner, ['search', 'text', '--json', 'query']);

      expect(result.code, 0);
      expect(result.output, contains('"filename"'));
      expect(result.output, contains('"test.md"'));
    });

    test('passes context length parameter', () async {
      when(() => mockApi.searchSimple('test', contextLength: 100)).thenAnswer(
        (_) async => <Map<String, dynamic>>[],
      );

      await runCapturing(runner, [
        'search',
        'text',
        'test',
        '--context-length',
        '100',
      ]);

      verify(() => mockApi.searchSimple('test', contextLength: 100)).called(1);
    });

    test('joins multi-word queries', () async {
      when(() => mockApi.searchSimple('hello world', contextLength: null))
          .thenAnswer((_) async => <Map<String, dynamic>>[]);

      await runCapturing(runner, ['search', 'text', 'hello', 'world']);

      verify(() => mockApi.searchSimple('hello world', contextLength: null))
          .called(1);
    });

    test('exits 64 when no query provided', () async {
      final result = await runCapturing(runner, ['search', 'text']);

      expect(result.code, 64);
      verifyNever(() => mockApi.searchSimple(any(), contextLength: any(named: 'contextLength')));
    });
  });
}
