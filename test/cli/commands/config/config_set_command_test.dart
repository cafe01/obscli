import 'package:test/test.dart';
import 'package:obscli/src/cli/obs_runner.dart';

import '../../../helpers/test_runner.dart';

void main() {
  late ObsCommandRunner runner;

  setUp(() {
    runner = ObsCommandRunner();
  });

  group('config set', () {
    test('exits 64 when missing value argument', () async {
      final result = await runCapturing(runner, ['config', 'set', 'host']);

      expect(result.code, 64);
    });

    test('exits 64 when no arguments provided', () async {
      final result = await runCapturing(runner, ['config', 'set']);

      expect(result.code, 64);
    });
  });
}
