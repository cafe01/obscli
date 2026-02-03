import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../../../api/obsidian_api.dart';
import '../../format.dart';
import '../../obs_runner.dart';

/// Modify a section of a periodic note.
///
/// ```
/// obs periodic patch <period> [--date YYYY-MM-DD] [--heading <text>]
///     [--block <id>] [--frontmatter] [--insert-position beginning|end]
///     [--content <text>] [--json]
/// ```
class PeriodicPatchCommand extends Command<int> {
  PeriodicPatchCommand() {
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
        help: 'Content for the patch (alternative to stdin).',
        valueHelp: 'text',
      )
      ..addOption(
        'heading',
        help: 'Target heading section.',
        valueHelp: 'text',
      )
      ..addOption(
        'block',
        help: 'Target block reference (^block-id).',
        valueHelp: 'id',
      )
      ..addFlag(
        'frontmatter',
        negatable: false,
        help: 'Target the YAML frontmatter.',
      )
      ..addOption(
        'insert-position',
        help: 'Insert at beginning or end of targeted section.',
        allowed: ['beginning', 'end'],
        defaultsTo: 'end',
      );
  }

  @override
  String get name => 'patch';

  @override
  String get description => 'Modify a section of a periodic note.';

  @override
  String get invocation => 'obs periodic patch <period>';

  ObsidianApi get _api => (runner! as ObsCommandRunner).api;

  static const _validPeriods = ['daily', 'weekly', 'monthly', 'quarterly', 'yearly'];

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.isEmpty) {
      stderr.writeln('Usage: obs periodic patch <period>');
      return 64;
    }

    final period = args.first;
    if (!_validPeriods.contains(period)) {
      usageException('Invalid period: $period. Must be one of: ${_validPeriods.join(', ')}');
    }

    final content = argResults!['content'] as String? ?? _readStdin();
    final date = argResults!['date'] as String?;
    final heading = argResults!['heading'] as String?;
    final block = argResults!['block'] as String?;
    final frontmatter = argResults!['frontmatter'] as bool? ?? false;
    final insertPosition = argResults!['insert-position'] as String?;
    final useJson = argResults!['json'] as bool? ?? false;

    try {
      await _api.patchPeriodicNote(
        period,
        content,
        date: date,
        heading: heading,
        blockId: block,
        frontmatter: frontmatter,
        insertPosition: insertPosition,
      );

      if (useJson) {
        const encoder = JsonEncoder.withIndent('  ');
        final target = frontmatter
            ? 'frontmatter'
            : heading != null
                ? 'heading: $heading'
                : block != null
                    ? 'block: $block'
                    : 'note';
        // ignore: avoid_print
        print(encoder.convert(<String, dynamic>{
          'period': period,
          'date': date,
          'status': 'patched',
          'target': target,
        }));
      } else {
        final target = frontmatter
            ? 'frontmatter'
            : heading != null
                ? 'heading: $heading'
                : block != null
                    ? 'block: $block'
                    : '';
        final targetStr = target.isNotEmpty ? ' ($target)' : '';
        final dateStr = date != null ? ' $date' : '';
        // ignore: avoid_print
        print(green('Patched $period note$dateStr$targetStr'));
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
