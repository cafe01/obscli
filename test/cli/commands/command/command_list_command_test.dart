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

  group('command list', () {
    test('displays commands in two-column table', () async {
      when(() => mockApi.listCommands()).thenAnswer(
        (_) async => <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'app:reload',
            'name': 'Reload app',
          },
          <String, dynamic>{
            'id': 'dataview:refresh',
            'name': 'Refresh Dataview',
          },
        ],
      );

      final result = await runCapturing(runner, ['command', 'list']);

      expect(result.code, 0);
      expect(result.output, contains('app:reload'));
      expect(result.output, contains('Reload app'));
      expect(result.output, contains('dataview:refresh'));
      expect(result.output, contains('Refresh Dataview'));
      expect(result.output, contains('--'));
    });

    test('filters commands by name', () async {
      when(() => mockApi.listCommands()).thenAnswer(
        (_) async => <Map<String, dynamic>>[
          <String, dynamic>{'id': 'app:reload', 'name': 'Reload app'},
          <String, dynamic>{'id': 'dataview:refresh', 'name': 'Refresh Dataview'},
          <String, dynamic>{'id': 'graph:open', 'name': 'Open graph'},
        ],
      );

      final result = await runCapturing(runner, [
        'command',
        'list',
        '--filter',
        'dataview',
      ]);

      expect(result.code, 0);
      expect(result.output, contains('dataview:refresh'));
      expect(result.output, isNot(contains('app:reload')));
      expect(result.output, isNot(contains('graph:open')));
    });

    test('filter is case-insensitive', () async {
      when(() => mockApi.listCommands()).thenAnswer(
        (_) async => <Map<String, dynamic>>[
          <String, dynamic>{'id': 'app:reload', 'name': 'Reload App'},
        ],
      );

      final result = await runCapturing(runner, [
        'command',
        'list',
        '--filter',
        'RELOAD',
      ]);

      expect(result.code, 0);
      expect(result.output, contains('app:reload'));
    });

    test('displays JSON with --json flag', () async {
      when(() => mockApi.listCommands()).thenAnswer(
        (_) async => <Map<String, dynamic>>[
          <String, dynamic>{'id': 'test', 'name': 'Test'},
        ],
      );

      final result = await runCapturing(runner, ['command', 'list', '--json']);

      expect(result.code, 0);
      expect(result.output, contains('"id"'));
      expect(result.output, contains('"test"'));
    });
  });
}
