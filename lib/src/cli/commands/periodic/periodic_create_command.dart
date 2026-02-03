import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../../../api/obsidian_api.dart';
import '../../format.dart';
import '../../obs_runner.dart';

/// Create a periodic note.
///
/// ```
/// obs periodic create <period> [--date YYYY-MM-DD] [--content <text>] [--json]
/// ```
class PeriodicCreateCommand extends Command<int> {
  PeriodicCreateCommand() {
    argParser
      ..addFlag(
        'json',
        negatable: false,
        help: 'Output in JSON format.',
      )
      ..addOption(
        'date',
        help: 'Target specific date (default: current period).',
        valueHelp: 'YYYY-MM-DD',
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
  String get description => 'Create or replace a periodic note.';

  @override
  String get invocation => 'obs periodic create <period>';

  ObsidianApi get _api => (runner! as ObsCommandRunner).api;

  static const _validPeriods = ['daily', 'weekly', 'monthly', 'quarterly', 'yearly'];

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.isEmpty) {
      stderr.writeln('Usage: obs periodic create <period>');
      return 64;
    }

    final period = args.first;
    if (!_validPeriods.contains(period)) {
      usageException('Invalid period: $period. Must be one of: ${_validPeriods.join(', ')}');
    }

    final content = argResults!['content'] as String? ?? _readStdin();
    final date = argResults!['date'] as String?;
    final useJson = argResults!['json'] as bool? ?? false;

    try {
      await _api.createPeriodicNote(period, content, date: date);

      if (useJson) {
        const encoder = JsonEncoder.withIndent('  ');
        // ignore: avoid_print
        print(encoder.convert(<String, dynamic>{
          'period': period,
          'date': date,
          'status': 'created',
        }));
      } else {
        final dateStr = date != null ? ' ($date)' : '';
        // ignore: avoid_print
        print(green('Created $period note$dateStr'));
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
