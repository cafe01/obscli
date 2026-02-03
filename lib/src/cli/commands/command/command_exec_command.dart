import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../../../api/obsidian_api.dart';
import '../../format.dart';
import '../../obs_runner.dart';

/// Execute an Obsidian command by ID.
///
/// ```
/// obs command exec <commandId> [--json]
/// ```
class CommandExecCommand extends Command<int> {
  CommandExecCommand() {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output in JSON format.',
    );
  }

  @override
  String get name => 'exec';

  @override
  String get description => 'Execute an Obsidian command by its ID.';

  @override
  String get invocation => 'obs command exec <commandId>';

  ObsidianApi get _api => (runner! as ObsCommandRunner).api;

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.isEmpty) {
      stderr.writeln('Usage: obs command exec <commandId>');
      return 64;
    }

    final commandId = args.first;
    final useJson = argResults!['json'] as bool? ?? false;

    try {
      await _api.executeCommand(commandId);

      if (useJson) {
        const encoder = JsonEncoder.withIndent('  ');
        // ignore: avoid_print
        print(encoder.convert(<String, dynamic>{
          'commandId': commandId,
          'status': 'executed',
        }));
      } else {
        // ignore: avoid_print
        print(green('Executed: $commandId'));
      }
      return 0;
    } catch (e) {
      stderr.writeln('Error: $e');
      return 1;
    }
  }
}
