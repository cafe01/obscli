import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../../../api/obsidian_api.dart';
import '../../obs_runner.dart';

/// List directory contents in the vault.
///
/// ```
/// obs note list [path] [--json]
/// ```
class NoteListCommand extends Command<int> {
  NoteListCommand() {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output raw JSON array.',
    );
  }

  @override
  String get name => 'list';

  @override
  String get description => 'List directory contents in the vault.';

  @override
  String get invocation => 'obs note list [path]';

  ObsidianApi get _api => (runner! as ObsCommandRunner).api;

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    final path = args.isEmpty ? '/' : args.first;
    final useJson = argResults!['json'] as bool? ?? false;

    try {
      final entries = await _api.listDirectory(path);

      if (useJson) {
        const encoder = JsonEncoder.withIndent('  ');
        // ignore: avoid_print
        print(encoder.convert(entries));
      } else {
        for (final entry in entries) {
          final name = entry['name'] as String?;
          final type = entry['type'] as String?;
          if (name == null) continue;

          if (type == 'folder') {
            // ignore: avoid_print
            print('[dir] $name/');
          } else {
            // ignore: avoid_print
            print(name);
          }
        }
      }
      return 0;
    } catch (e) {
      stderr.writeln('Error: $e');
      return 1;
    }
  }
}
