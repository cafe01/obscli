import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../../../api/obsidian_api.dart';
import '../../obs_runner.dart';

/// List all available Obsidian commands.
///
/// ```
/// obs command list [--filter <text>] [--json]
/// ```
class CommandListCommand extends Command<int> {
  CommandListCommand() {
    argParser
      ..addFlag(
        'json',
        negatable: false,
        help: 'Output raw JSON array.',
      )
      ..addOption(
        'filter',
        help: 'Client-side text filter on command name/ID.',
        valueHelp: 'text',
      );
  }

  @override
  String get name => 'list';

  @override
  String get description => 'List all available Obsidian commands.';

  ObsidianApi get _api => (runner! as ObsCommandRunner).api;

  @override
  Future<int> run() async {
    final filter = argResults!['filter'] as String?;
    final useJson = argResults!['json'] as bool? ?? false;

    try {
      var commands = await _api.listCommands();

      // Apply client-side filter if provided
      if (filter != null && filter.isNotEmpty) {
        final filterLower = filter.toLowerCase();
        commands = commands.where((cmd) {
          final id = (cmd['id'] as String? ?? '').toLowerCase();
          final name = (cmd['name'] as String? ?? '').toLowerCase();
          return id.contains(filterLower) || name.contains(filterLower);
        }).toList();
      }

      if (useJson) {
        const encoder = JsonEncoder.withIndent('  ');
        // ignore: avoid_print
        print(encoder.convert(commands));
      } else {
        // Format as two-column table: ID -- Name
        var maxIdLength = 0;
        for (final cmd in commands) {
          final id = cmd['id'] as String? ?? '';
          if (id.length > maxIdLength) {
            maxIdLength = id.length;
          }
        }

        for (final cmd in commands) {
          final id = cmd['id'] as String? ?? '';
          final name = cmd['name'] as String? ?? '';
          // ignore: avoid_print
          print('${id.padRight(maxIdLength)} -- $name');
        }
      }
      return 0;
    } catch (e) {
      stderr.writeln('Error: $e');
      return 1;
    }
  }
}
