import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../../../api/obsidian_api.dart';
import '../../format.dart';
import '../../obs_runner.dart';

/// Append content to the active file.
///
/// ```
/// obs active append [--content <text>] [--json]
/// ```
class ActiveAppendCommand extends Command<int> {
  ActiveAppendCommand() {
    argParser
      ..addFlag(
        'json',
        negatable: false,
        help: 'Output in JSON format.',
      )
      ..addOption(
        'content',
        help: 'Content to append (alternative to stdin).',
        valueHelp: 'text',
      );
  }

  @override
  String get name => 'append';

  @override
  String get description => 'Append content to the active file.';

  ObsidianApi get _api => (runner! as ObsCommandRunner).api;

  @override
  Future<int> run() async {
    final content = argResults!['content'] as String? ?? _readStdin();
    final useJson = argResults!['json'] as bool? ?? false;

    try {
      await _api.appendToActiveFile(content);

      if (useJson) {
        const encoder = JsonEncoder.withIndent('  ');
        // ignore: avoid_print
        print(encoder.convert(<String, dynamic>{
          'status': 'appended',
        }));
      } else {
        // ignore: avoid_print
        print(green('Appended to active file'));
      }
      return 0;
    } catch (e) {
      stderr.writeln('Error: $e');
      return 1;
    }
  }

  /// Read all content from stdin until EOF.
  String _readStdin() {
    final buffer = StringBuffer();
    String? line;
    while ((line = stdin.readLineSync()) != null) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.write(line);
    }
    return buffer.toString();
  }
}
