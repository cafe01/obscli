import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../../../api/obsidian_api.dart';
import '../../obs_runner.dart';

/// Execute a JsonLogic structured query.
///
/// ```
/// obs search jsonlogic [--query <json>] [--json]
/// ```
class SearchJsonLogicCommand extends Command<int> {
  SearchJsonLogicCommand() {
    argParser
      ..addFlag(
        'json',
        negatable: false,
        help: 'Output raw JSON result.',
      )
      ..addOption(
        'query',
        help: 'JsonLogic query as JSON string.',
        valueHelp: 'json',
      );
  }

  @override
  String get name => 'jsonlogic';

  @override
  String get description => 'Execute a JsonLogic structured query.';

  ObsidianApi get _api => (runner! as ObsCommandRunner).api;

  @override
  Future<int> run() async {
    String queryStr;
    final queryOption = argResults!['query'] as String?;

    if (queryOption != null) {
      queryStr = queryOption;
    } else {
      // Read from stdin
      final buffer = StringBuffer();
      String? line;
      while ((line = stdin.readLineSync()) != null) {
        if (buffer.isNotEmpty) buffer.writeln();
        buffer.write(line);
      }
      queryStr = buffer.toString();
    }

    if (queryStr.trim().isEmpty) {
      stderr.writeln('Usage: obs search jsonlogic --query <json>');
      stderr.writeln('   or: echo <json> | obs search jsonlogic');
      return 64;
    }

    final useJson = argResults!['json'] as bool? ?? false;

    try {
      // Parse the query JSON
      final dynamic decoded = jsonDecode(queryStr);
      if (decoded is! Map<String, dynamic>) {
        stderr.writeln('Error: Query must be a JSON object');
        return 1;
      }

      final result = await _api.searchJsonLogic(decoded);

      if (useJson) {
        const encoder = JsonEncoder.withIndent('  ');
        // ignore: avoid_print
        print(encoder.convert(result));
      } else {
        // Format as a simple list of matching files
        final files = result['files'] as List<dynamic>? ??
                     result['results'] as List<dynamic>? ??
                     [];
        for (final file in files) {
          // ignore: avoid_print
          print(file);
        }
      }
      return 0;
    } on FormatException catch (e) {
      stderr.writeln('Error: Invalid JSON: $e');
      return 1;
    } catch (e) {
      stderr.writeln('Error: $e');
      return 1;
    }
  }
}
