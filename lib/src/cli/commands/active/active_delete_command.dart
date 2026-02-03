import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../../../api/obsidian_api.dart';
import '../../format.dart';
import '../../obs_runner.dart';

/// Delete the active file.
///
/// ```
/// obs active delete [--confirm] [--json]
/// ```
class ActiveDeleteCommand extends Command<int> {
  ActiveDeleteCommand() {
    argParser
      ..addFlag(
        'json',
        negatable: false,
        help: 'Output in JSON format.',
      )
      ..addFlag(
        'confirm',
        negatable: false,
        help: 'Skip confirmation prompt.',
      );
  }

  @override
  String get name => 'delete';

  @override
  String get description => 'Delete the active file.';

  ObsidianApi get _api => (runner! as ObsCommandRunner).api;

  @override
  Future<int> run() async {
    final confirm = argResults!['confirm'] as bool? ?? false;
    final useJson = argResults!['json'] as bool? ?? false;

    // Check for confirmation if not provided
    if (!confirm) {
      stderr.write('Delete active file? (y/N): ');
      final response = stdin.readLineSync() ?? '';
      if (response.toLowerCase() != 'y') {
        stderr.writeln('Cancelled.');
        return 1;
      }
    }

    try {
      await _api.deleteActiveFile();

      if (useJson) {
        const encoder = JsonEncoder.withIndent('  ');
        // ignore: avoid_print
        print(encoder.convert(<String, dynamic>{
          'status': 'deleted',
        }));
      } else {
        // ignore: avoid_print
        print(green('Deleted active file'));
      }
      return 0;
    } catch (e) {
      stderr.writeln('Error: $e');
      return 1;
    }
  }
}
