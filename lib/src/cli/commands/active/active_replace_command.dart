import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../../../api/obsidian_api.dart';
import '../../format.dart';
import '../../obs_runner.dart';

/// Replace the active file's content.
///
/// ```
/// obs active replace [--content <text>] [--json]
/// ```
class ActiveReplaceCommand extends Command<int> {
  ActiveReplaceCommand() {
    argParser
      ..addFlag(
        'json',
        negatable: false,
        help: 'Output in JSON format.',
      )
      ..addOption(
        'content',
        help: 'Replacement content (alternative to stdin).',
        valueHelp: 'text',
      );
  }

  @override
  String get name => 'replace';

  @override
  String get description => "Replace the active file's content.";

  ObsidianApi get _api => (runner! as ObsCommandRunner).api;

  @override
  Future<int> run() async {
    final content = argResults!['content'] as String? ?? _readStdin();
    final useJson = argResults!['json'] as bool? ?? false;

    try {
      await _api.replaceActiveFile(content);

      if (useJson) {
        const encoder = JsonEncoder.withIndent('  ');
        // ignore: avoid_print
        print(encoder.convert(<String, dynamic>{
          'status': 'replaced',
        }));
      } else {
        // ignore: avoid_print
        print(green('Replaced active file'));
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
