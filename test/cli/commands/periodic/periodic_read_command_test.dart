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

  group('periodic read', () {
    test('reads daily note without date', () async {
      when(() => mockApi.readPeriodicNote('daily', date: null))
          .thenAnswer((_) async => '# Today\n\nDaily content');

      final result = await runCapturing(runner, ['periodic', 'read', 'daily']);

      expect(result.code, 0);
      expect(result.output, contains('# Today'));
      verify(() => mockApi.readPeriodicNote('daily', date: null)).called(1);
    });

    test('reads note with specific date', () async {
      when(() => mockApi.readPeriodicNote('daily', date: '2026-02-03'))
          .thenAnswer((_) async => '# 2026-02-03');

      final result = await runCapturing(runner, [
        'periodic',
        'read',
        'daily',
        '--date',
        '2026-02-03',
      ]);

      expect(result.code, 0);
      expect(result.output, contains('# 2026-02-03'));
      verify(() => mockApi.readPeriodicNote('daily', date: '2026-02-03'))
          .called(1);
    });

    test('validates period argument', () async {
      final result =
          await runCapturing(runner, ['periodic', 'read', 'invalid']);

      expect(result.code, 64);
      verifyNever(() => mockApi.readPeriodicNote(any(), date: any(named: 'date')));
    });

    test('accepts all valid periods', () async {
      final validPeriods = ['daily', 'weekly', 'monthly', 'quarterly', 'yearly'];

      for (final period in validPeriods) {
        when(() => mockApi.readPeriodicNote(period, date: null))
            .thenAnswer((_) async => 'content');

        final result =
            await runCapturing(runner, ['periodic', 'read', period]);

        expect(result.code, 0, reason: '$period should be valid');
      }
    });

    test('displays JSON with --json flag', () async {
      when(() => mockApi.readPeriodicNoteStructured('daily', date: null))
          .thenAnswer(
        (_) async => <String, dynamic>{'content': '# Daily'},
      );

      final result =
          await runCapturing(runner, ['periodic', 'read', '--json', 'daily']);

      expect(result.code, 0);
      expect(result.output, contains('"content"'));
    });

    test('exits 64 when no period provided', () async {
      final result = await runCapturing(runner, ['periodic', 'read']);

      expect(result.code, 64);
      verifyNever(() => mockApi.readPeriodicNote(any(), date: any(named: 'date')));
    });
  });
}
