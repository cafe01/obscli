import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../../../api/obsidian_api.dart';
import '../../format.dart';
import '../../obs_runner.dart';

/// Create or replace a note in the vault.
///
/// ```
/// obs note create <path> [--content <text>] [--json]
/// ```
class NoteCreateCommand extends Command<int> {
  NoteCreateCommand() {
    argParser
      ..addFlag(
        'json',
        negatable: false,
        help: 'Output in JSON format.',
      )
      ..addOption(
        'content',
        help: 'Note content (alternative to stdin).',
        valueHelp: 'text',
      );
  }

  @override
  String get name => 'create';

  @override
  String get description => 'Create or replace a note.';

  @override
  String get invocation => 'obs note create <path>';

  ObsidianApi get _api => (runner! as ObsCommandRunner).api;

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.isEmpty) {
      stderr.writeln('Usage: obs note create <path>');
      return 64;
    }

    final path = args.first;
    final content = argResults!['content'] as String? ?? _readStdin();
    final useJson = argResults!['json'] as bool? ?? false;

    try {
      await _api.createNote(path, content);

      if (useJson) {
        const encoder = JsonEncoder.withIndent('  ');
        // ignore: avoid_print
        print(encoder.convert(<String, dynamic>{
          'path': path,
          'status': 'created',
        }));
      } else {
        // ignore: avoid_print
        print(green('Created: $path'));
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
