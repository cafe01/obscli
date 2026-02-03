import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../../../api/obsidian_api.dart';
import '../../obs_runner.dart';

/// Full-text search across the vault.
///
/// ```
/// obs search text <query> [--context-length <n>] [--json]
/// ```
class SearchTextCommand extends Command<int> {
  SearchTextCommand() {
    argParser
      ..addFlag(
        'json',
        negatable: false,
        help: 'Output raw JSON array of matches.',
      )
      ..addOption(
        'context-length',
        help: 'Characters of context around each match.',
        valueHelp: 'n',
      );
  }

  @override
  String get name => 'text';

  @override
  String get description => 'Full-text search across the vault.';

  @override
  String get invocation => 'obs search text <query>';

  ObsidianApi get _api => (runner! as ObsCommandRunner).api;

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.isEmpty) {
      stderr.writeln('Usage: obs search text <query>');
      return 64;
    }

    final query = args.join(' ');
    final contextLengthStr = argResults!['context-length'] as String?;
    final contextLength = contextLengthStr != null
        ? int.tryParse(contextLengthStr)
        : null;
    final useJson = argResults!['json'] as bool? ?? false;

    try {
      final results = await _api.searchSimple(query, contextLength: contextLength);

      if (useJson) {
        const encoder = JsonEncoder.withIndent('  ');
        // ignore: avoid_print
        print(encoder.convert(results));
      } else {
        // Format as grep-like output: filename.md:line -- ...match context...
        for (final result in results) {
          final filename = result['filename'] as String? ?? 'unknown';
          final matches = result['matches'] as List<dynamic>? ?? [];

          for (final match in matches) {
            if (match is Map<String, dynamic>) {
              final line = match['line'] as int? ?? 0;
              final context = match['match'] as String? ??
                            match['context'] as String? ?? '';
              // ignore: avoid_print
              print('$filename:$line -- $context');
            }
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
