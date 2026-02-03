import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:obscli/src/cli/obs_runner.dart';

import '../../helpers/mock_obsidian_api.dart';
import '../../helpers/test_runner.dart';

void main() {
  late MockObsidianApi mockApi;
  late ObsCommandRunner runner;

  setUp(() {
    mockApi = MockObsidianApi();
    runner = ObsCommandRunner(api: mockApi);
  });

  group('status', () {
    test('displays connection status', () async {
      when(() => mockApi.getStatus()).thenAnswer(
        (_) async => <String, dynamic>{
          'status': 'OK',
          'versions': <String, dynamic>{
            'obsidian': '1.5.0',
            'self': '1.2.0',
          },
        },
      );

      final result = await runCapturing(runner, ['status']);

      expect(result.code, 0);
      expect(result.output, contains('Connected to Obsidian REST API'));
      expect(result.output, contains('OK'));
      expect(result.output, contains('1.5.0'));
      expect(result.output, contains('1.2.0'));
    });

    test('displays JSON with --json flag', () async {
      when(() => mockApi.getStatus()).thenAnswer(
        (_) async => <String, dynamic>{'status': 'OK'},
      );

      final result = await runCapturing(runner, ['status', '--json']);

      expect(result.code, 0);
      expect(result.output, contains('"status"'));
      expect(result.output, contains('"OK"'));
    });

    test('exits 1 on connection error', () async {
      when(() => mockApi.getStatus())
          .thenThrow(Exception('Connection refused'));

      final result = await runCapturing(runner, ['status']);

      expect(result.code, 1);
    });

    test('handles minimal response gracefully', () async {
      when(() => mockApi.getStatus())
          .thenAnswer((_) async => <String, dynamic>{});

      final result = await runCapturing(runner, ['status']);

      expect(result.code, 0);
      expect(result.output, contains('Connected'));
    });
  });
}
