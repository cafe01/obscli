import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../../../api/obsidian_api.dart';
import '../../format.dart';
import '../../obs_runner.dart';

/// Open a note in the Obsidian GUI.
///
/// ```
/// obs note open <path> [--new-leaf] [--json]
/// ```
class NoteOpenCommand extends Command<int> {
  NoteOpenCommand() {
    argParser
      ..addFlag(
        'json',
        negatable: false,
        help: 'Output in JSON format.',
      )
      ..addFlag(
        'new-leaf',
        negatable: false,
        help: 'Open in a new pane/tab.',
      );
  }

  @override
  String get name => 'open';

  @override
  String get description => 'Open a note in the Obsidian GUI.';

  @override
  String get invocation => 'obs note open <path>';

  ObsidianApi get _api => (runner! as ObsCommandRunner).api;

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.isEmpty) {
      stderr.writeln('Usage: obs note open <path>');
      return 64;
    }

    final path = args.first;
    final newLeaf = argResults!['new-leaf'] as bool? ?? false;
    final useJson = argResults!['json'] as bool? ?? false;

    try {
      await _api.openNote(path, newLeaf: newLeaf);

      if (useJson) {
        const encoder = JsonEncoder.withIndent('  ');
        // ignore: avoid_print
        print(encoder.convert(<String, dynamic>{
          'path': path,
          'status': 'opened',
        }));
      } else {
        // ignore: avoid_print
        print(green('Opened: $path'));
      }
      return 0;
    } catch (e) {
      stderr.writeln('Error: $e');
      return 1;
    }
  }
}
