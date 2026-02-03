import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../../../api/obsidian_api.dart';
import '../../obs_runner.dart';

/// Read a note's content from the vault.
///
/// ```
/// obs note read <path> [--json]
/// ```
class NoteReadCommand extends Command<int> {
  NoteReadCommand() {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output structured JSON (frontmatter, tags, content).',
    );
  }

  @override
  String get name => 'read';

  @override
  String get description => 'Read a note from the vault.';

  @override
  String get invocation => 'obs note read <path>';

  ObsidianApi get _api => (runner! as ObsCommandRunner).api;

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.isEmpty) {
      stderr.writeln('Usage: obs note read <path>');
      return 64;
    }

    final path = args.first;
    final useJson = argResults!['json'] as bool? ?? false;

    try {
      if (useJson) {
        final data = await _api.readNoteStructured(path);
        const encoder = JsonEncoder.withIndent('  ');
        // ignore: avoid_print
        print(encoder.convert(data));
      } else {
        final content = await _api.readNote(path);
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
