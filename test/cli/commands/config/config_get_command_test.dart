import 'package:test/test.dart';
import 'package:obscli/src/cli/obs_runner.dart';

import '../../../helpers/test_runner.dart';

void main() {
  late ObsCommandRunner runner;

  setUp(() {
    runner = ObsCommandRunner();
  });

  group('config get', () {
    test('exits 1 when key does not exist', () async {
      final result = await runCapturing(runner, ['config', 'get', 'missing-key-xyz']);

      expect(result.code, 1);
    });

    test('exits 64 when no key provided', () async {
      final result = await runCapturing(runner, ['config', 'get']);

      expect(result.code, 64);
    });
  });
}
