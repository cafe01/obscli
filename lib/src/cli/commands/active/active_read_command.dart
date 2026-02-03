import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../../../api/obsidian_api.dart';
import '../../obs_runner.dart';

/// Read the currently active file.
///
/// ```
/// obs active read [--json]
/// ```
class ActiveReadCommand extends Command<int> {
  ActiveReadCommand() {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output structured JSON.',
    );
  }

  @override
  String get name => 'read';

  @override
  String get description => 'Read the currently active file.';

  ObsidianApi get _api => (runner! as ObsCommandRunner).api;

  @override
  Future<int> run() async {
    final useJson = argResults!['json'] as bool? ?? false;

    try {
      if (useJson) {
        final data = await _api.readActiveFileStructured();
        const encoder = JsonEncoder.withIndent('  ');
        // ignore: avoid_print
        print(encoder.convert(data));
      } else {
        final content = await _api.readActiveFile();
        // ignore: avoid_print
        print(content);
      }
      return 0;
    } catch (e) {
      stderr.writeln('Error: $e');
      return 1;
    }
  }
}
