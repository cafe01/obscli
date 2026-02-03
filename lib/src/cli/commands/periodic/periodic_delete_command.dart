import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../../../api/obsidian_api.dart';
import '../../format.dart';
import '../../obs_runner.dart';

/// Delete a periodic note.
///
/// ```
/// obs periodic delete <period> [--date YYYY-MM-DD] [--confirm] [--json]
/// ```
class PeriodicDeleteCommand extends Command<int> {
  PeriodicDeleteCommand() {
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
      ..addFlag(
        'confirm',
        negatable: false,
        help: 'Skip confirmation prompt.',
      );
  }

  @override
  String get name => 'delete';

  @override
  String get description => 'Delete a periodic note.';

  @override
  String get invocation => 'obs periodic delete <period>';

  ObsidianApi get _api => (runner! as ObsCommandRunner).api;

  static const _validPeriods = ['daily', 'weekly', 'monthly', 'quarterly', 'yearly'];

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.isEmpty) {
      stderr.writeln('Usage: obs periodic delete <period>');
      return 64;
    }

    final period = args.first;
    if (!_validPeriods.contains(period)) {
      usageException('Invalid period: $period. Must be one of: ${_validPeriods.join(', ')}');
    }

    final date = argResults!['date'] as String?;
    final confirm = argResults!['confirm'] as bool? ?? false;
    final useJson = argResults!['json'] as bool? ?? false;

    final dateStr = date != null ? ' $date' : '';

    // Check for confirmation if not provided
    if (!confirm) {
      stderr.write('Delete $period note$dateStr? (y/N): ');
      final response = stdin.readLineSync() ?? '';
      if (response.toLowerCase() != 'y') {
        stderr.writeln('Cancelled.');
        return 1;
      }
    }

    try {
      await _api.deletePeriodicNote(period, date: date);

      if (useJson) {
        const encoder = JsonEncoder.withIndent('  ');
        // ignore: avoid_print
        print(encoder.convert(<String, dynamic>{
          'period': period,
          'date': date,
          'status': 'deleted',
        }));
      } else {
        // ignore: avoid_print
        print(green('Deleted $period note$dateStr'));
      }
      return 0;
    } catch (e) {
      stderr.writeln('Error: $e');
      return 1;
    }
  }
}
