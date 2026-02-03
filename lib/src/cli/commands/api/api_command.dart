import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../../../api/obsidian_api.dart';
import '../../obs_runner.dart';

/// Raw Obsidian REST API escape hatch.
///
/// Make arbitrary API requests, similar to `gh api`.
///
/// ```
/// obs api <endpoint> [-X method] [-H header] [--body <text>]
/// ```
class ApiCommand extends Command<int> {
  ApiCommand() {
    argParser
      ..addOption(
        'method',
        abbr: 'X',
        defaultsTo: 'GET',
        help: 'HTTP method (GET, POST, PUT, PATCH, DELETE).',
      )
      ..addMultiOption(
        'header',
        abbr: 'H',
        help: 'Custom header (repeatable).',
      )
      ..addOption(
        'body',
        help: 'Request body (or read from stdin).',
        valueHelp: 'text',
      );
  }

  @override
  String get name => 'api';

  @override
  String get description => 'Make raw Obsidian REST API requests.';

  @override
  String get invocation => 'obs api <endpoint>';

  ObsidianApi get _api => (runner! as ObsCommandRunner).api;

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.isEmpty) {
      stderr.writeln('Usage: obs api <endpoint>');
      return 64;
    }

    final endpoint = args.first;
    final method = argResults!['method'] as String? ?? 'GET';
    final headersList = argResults!['header'] as List<String>? ?? [];
    final bodyOption = argResults!['body'] as String?;

    // Parse custom headers
    final headers = <String, String>{};
    for (final header in headersList) {
      final parts = header.split(':');
      if (parts.length >= 2) {
        final key = parts[0].trim();
        final value = parts.sublist(1).join(':').trim();
        headers[key] = value;
      }
    }

    // Determine body content
    String? body;
    if (bodyOption != null) {
      body = bodyOption;
    } else if (method.toUpperCase() != 'GET' && method.toUpperCase() != 'DELETE') {
      // Read from stdin for POST/PUT/PATCH if no --body provided
      if (!stdin.hasTerminal) {
        final buffer = StringBuffer();
        String? line;
        while ((line = stdin.readLineSync()) != null) {
          if (buffer.isNotEmpty) buffer.writeln();
          buffer.write(line);
        }
        body = buffer.toString();
      }
    }

    try {
      final result = await _api.rawRequest(
        method,
        endpoint,
        body: body,
        headers: headers,
      );

      // Output raw response
      if (result is String) {
        // ignore: avoid_print
        print(result);
      } else if (result is Map || result is List) {
        const encoder = JsonEncoder.withIndent('  ');
        // ignore: avoid_print
        print(encoder.convert(result));
      } else {
        // ignore: avoid_print
        print(result);
      }
      return 0;
    } catch (e) {
      stderr.writeln('Error: $e');
      return 1;
    }
  }
}
