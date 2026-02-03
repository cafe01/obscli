import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../../../api/obsidian_api.dart';
import '../../format.dart';
import '../../obs_runner.dart';

/// Delete a note from the vault.
///
/// ```
/// obs note delete <path> [--confirm] [--json]
/// ```
class NoteDeleteCommand extends Command<int> {
  NoteDeleteCommand() {
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
  String get description => 'Delete a note from the vault.';

  @override
  String get invocation => 'obs note delete <path>';

  ObsidianApi get _api => (runner! as ObsCommandRunner).api;

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.isEmpty) {
      stderr.writeln('Usage: obs note delete <path>');
      return 64;
    }

    final path = args.first;
    final confirm = argResults!['confirm'] as bool? ?? false;
    final useJson = argResults!['json'] as bool? ?? false;

    // Check for confirmation if not provided
    if (!confirm) {
      stderr.write('Delete $path? (y/N): ');
      final response = stdin.readLineSync() ?? '';
      if (response.toLowerCase() != 'y') {
        stderr.writeln('Cancelled.');
        return 1;
      }
    }

    try {
      await _api.deleteNote(path);

      if (useJson) {
        const encoder = JsonEncoder.withIndent('  ');
        // ignore: avoid_print
        print(encoder.convert(<String, dynamic>{
          'path': path,
          'status': 'deleted',
        }));
      } else {
        // ignore: avoid_print
        print(green('Deleted: $path'));
      }
      return 0;
    } catch (e) {
      stderr.writeln('Error: $e');
      return 1;
    }
  }
}
