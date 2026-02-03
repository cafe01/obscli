import 'dart:async';

import 'package:obscli/src/cli/obs_runner.dart';

/// Run a command and capture all print output.
Future<({int? code, String output})> runCapturing(
  ObsCommandRunner runner,
  List<String> args,
) async {
  final lines = <String>[];
  final code = await runZonedGuarded(
    () => runner.run(args),
    (_, _) {},
    zoneSpecification: ZoneSpecification(
      print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
        lines.add(line);
      },
    ),
  );
  return (code: code, output: lines.join('\n'));
}
