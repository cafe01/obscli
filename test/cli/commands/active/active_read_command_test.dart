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

  group('active read', () {
    test('displays markdown content by default', () async {
      when(() => mockApi.readActiveFile())
          .thenAnswer((_) async => '# Active File\n\nContent here');

      final result = await runCapturing(runner, ['active', 'read']);

      expect(result.code, 0);
      expect(result.output, contains('# Active File'));
      expect(result.output, contains('Content here'));
      verify(() => mockApi.readActiveFile()).called(1);
    });

    test('displays structured JSON with --json flag', () async {
      when(() => mockApi.readActiveFileStructured()).thenAnswer(
        (_) async => <String, dynamic>{
          'content': '# Active',
          'frontmatter': <String, dynamic>{'title': 'Active Note'},
        },
      );

      final result = await runCapturing(runner, ['active', 'read', '--json']);

      expect(result.code, 0);
      expect(result.output, contains('"content"'));
      expect(result.output, contains('"# Active"'));
      verify(() => mockApi.readActiveFileStructured()).called(1);
    });

    test('exits 1 on API error', () async {
      when(() => mockApi.readActiveFile())
          .thenThrow(Exception('No active file'));

      final result = await runCapturing(runner, ['active', 'read']);

      expect(result.code, 1);
    });
  });
}
