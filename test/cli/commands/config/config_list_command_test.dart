import 'package:test/test.dart';
import 'package:obscli/src/cli/obs_runner.dart';

import '../../../helpers/test_runner.dart';

void main() {
  late ObsCommandRunner runner;

  setUp(() {
    runner = ObsCommandRunner();
  });

  group('config list', () {
    test('runs successfully', () async {
      final result = await runCapturing(runner, ['config', 'list']);

      expect(result.code, 0);
      // Output contains either config values or "No configuration set"
      expect(result.output, isNotEmpty);
    });

    test('shows config section header', () async {
      final result = await runCapturing(runner, ['config', 'list']);

      expect(result.code, 0);
      expect(result.output, anyOf(
        contains('Configuration'),
        contains('No configuration set'),
      ));
    });
  });
}
