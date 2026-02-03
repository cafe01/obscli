import 'dart:io';

import 'package:obscli/src/cli/obs_runner.dart';

Future<void> main(List<String> args) async {
  final runner = ObsCommandRunner();
  final exitCode = await runner.run(args);
  exit(exitCode ?? 0);
}
