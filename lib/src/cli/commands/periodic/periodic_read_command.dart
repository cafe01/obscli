import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../../../api/obsidian_api.dart';
import '../../obs_runner.dart';

/// Read a periodic note.
///
/// ```
/// obs periodic read <period> [--date YYYY-MM-DD] [--json]
/// ```
class PeriodicReadCommand extends Command<int> {
  PeriodicReadCommand() {
    argParser
      ..addFlag(
        'json',
        negatable: false,
        help: 'Output structured JSON.',
      )
      ..addOption(
        'date',
        help: 'Target specific date (default: current period).',
        valueHelp: 'YYYY-MM-DD',
      );
  }

  @override
  String get name => 'read';

  @override
  String get description => 'Read a periodic note.';

  @override
  String get invocation => 'obs periodic read <period>';

  ObsidianApi get _api => (runner! as ObsCommandRunner).api;

  static const _validPeriods = ['daily', 'weekly', 'monthly', 'quarterly', 'yearly'];

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.isEmpty) {
      stderr.writeln('Usage: obs periodic read <period>');
      return 64;
    }

    final period = args.first;
    if (!_validPeriods.contains(period)) {
      usageException('Invalid period: $period. Must be one of: ${_validPeriods.join(', ')}');
    }

    final date = argResults!['date'] as String?;
    final useJson = argResults!['json'] as bool? ?? false;

    try {
      if (useJson) {
        final data = await _api.readPeriodicNoteStructured(period, date: date);
        const encoder = JsonEncoder.withIndent('  ');
        // ignore: avoid_print
        print(encoder.convert(data));
      } else {
        final content = await _api.readPeriodicNote(period, date: date);
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
