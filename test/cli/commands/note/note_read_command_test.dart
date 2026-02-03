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

  group('note read', () {
    test('displays markdown content by default', () async {
      when(() => mockApi.readNote('test.md'))
          .thenAnswer((_) async => '# Hello\n\nTest content');

      final result = await runCapturing(runner, ['note', 'read', 'test.md']);

      expect(result.code, 0);
      expect(result.output, contains('# Hello'));
      expect(result.output, contains('Test content'));
      verify(() => mockApi.readNote('test.md')).called(1);
    });

    test('displays structured JSON with --json flag', () async {
      when(() => mockApi.readNoteStructured('test.md')).thenAnswer(
        (_) async => <String, dynamic>{
          'content': '# Hello',
          'frontmatter': <String, dynamic>{'title': 'Test'},
          'tags': <String>['test'],
        },
      );

      final result =
          await runCapturing(runner, ['note', 'read', '--json', 'test.md']);

      expect(result.code, 0);
      expect(result.output, contains('"content"'));
      expect(result.output, contains('"frontmatter"'));
      expect(result.output, contains('"Test"'));
      verify(() => mockApi.readNoteStructured('test.md')).called(1);
    });

    test('exits 64 when no path provided', () async {
      final result = await runCapturing(runner, ['note', 'read']);

      expect(result.code, 64);
      verifyNever(() => mockApi.readNote(any()));
    });

    test('exits 1 on API error', () async {
      when(() => mockApi.readNote(any()))
          .thenThrow(Exception('File not found'));

      final result = await runCapturing(runner, ['note', 'read', 'missing.md']);

      expect(result.code, 1);
    });
  });
}
