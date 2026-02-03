import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../../../api/obsidian_api.dart';
import '../../obs_runner.dart';

/// Execute a Dataview DQL query.
///
/// ```
/// obs search dql <query> [--json]
/// ```
class SearchDqlCommand extends Command<int> {
  SearchDqlCommand() {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output raw JSON result from Dataview.',
    );
  }

  @override
  String get name => 'dql';

  @override
  String get description => 'Execute a Dataview DQL query.';

  @override
  String get invocation => 'obs search dql <query>';

  ObsidianApi get _api => (runner! as ObsCommandRunner).api;

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    String query;

    if (args.isEmpty) {
      stderr.writeln('Usage: obs search dql <query>');
      return 64;
    }

    // If query is "-", read from stdin
    if (args.first == '-') {
      final buffer = StringBuffer();
      String? line;
      while ((line = stdin.readLineSync()) != null) {
        if (buffer.isNotEmpty) buffer.writeln();
        buffer.write(line);
      }
      query = buffer.toString();
    } else {
      query = args.join(' ');
    }

    final useJson = argResults!['json'] as bool? ?? false;

    try {
      final result = await _api.searchDql(query);

      if (useJson) {
        const encoder = JsonEncoder.withIndent('  ');
        // ignore: avoid_print
        print(encoder.convert(result));
      } else {
        _formatDqlResult(result);
      }
      return 0;
    } catch (e) {
      stderr.writeln('Error: $e');
      return 1;
    }
  }

  void _formatDqlResult(Map<String, dynamic> result) {
    final type = result['type'] as String?;

    if (type == 'table') {
      _formatTable(result);
    } else if (type == 'list') {
      _formatList(result);
    } else if (type == 'task') {
      _formatTask(result);
    } else {
      // Unknown type, pretty-print JSON
      const encoder = JsonEncoder.withIndent('  ');
      // ignore: avoid_print
      print(encoder.convert(result));
    }
  }

  void _formatTable(Map<String, dynamic> result) {
    final headers = (result['headers'] as List<dynamic>?)?.cast<String>() ?? [];
    final values = result['values'] as List<dynamic>? ?? [];

    if (headers.isEmpty) return;

    // Calculate column widths
    final columnWidths = <int>[];
    for (var i = 0; i < headers.length; i++) {
      var maxWidth = headers[i].length;
      for (final row in values) {
        if (row is List && i < row.length) {
          final cellStr = row[i]?.toString() ?? '';
          if (cellStr.length > maxWidth) {
            maxWidth = cellStr.length;
          }
        }
      }
      columnWidths.add(maxWidth);
    }

    // Print headers
    final headerParts = <String>[];
    for (var i = 0; i < headers.length; i++) {
      headerParts.add(headers[i].padRight(columnWidths[i]));
    }
    // ignore: avoid_print
    print(headerParts.join(' | '));

    // Print separator
    final separatorParts = <String>[];
    for (final width in columnWidths) {
      separatorParts.add('-' * width);
    }
    // ignore: avoid_print
    print(separatorParts.join('-|-'));

    // Print rows
    for (final row in values) {
      if (row is List) {
        final rowParts = <String>[];
        for (var i = 0; i < headers.length; i++) {
          final cell = i < row.length ? (row[i]?.toString() ?? '') : '';
          rowParts.add(cell.padRight(columnWidths[i]));
        }
        // ignore: avoid_print
        print(rowParts.join(' | '));
      }
    }
  }

  void _formatList(Map<String, dynamic> result) {
    final values = result['values'] as List<dynamic>? ?? [];
    for (final value in values) {
      // ignore: avoid_print
      print('- $value');
    }
  }

  void _formatTask(Map<String, dynamic> result) {
    final values = result['values'] as List<dynamic>? ?? [];
    for (final value in values) {
      if (value is Map<String, dynamic>) {
        final text = value['text'] as String? ?? '';
        final completed = value['completed'] as bool? ?? false;
        final checkbox = completed ? '[x]' : '[ ]';
        // ignore: avoid_print
        print('$checkbox $text');
      }
    }
  }
}
