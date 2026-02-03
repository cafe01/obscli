import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../../api/obsidian_api.dart';
import '../obs_runner.dart';

/// Check connection to the Obsidian REST API.
///
/// Top-level command (not in a group).
///
/// ```
/// obs status [--json]
/// ```
class StatusCommand extends Command<int> {
  StatusCommand() {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output raw JSON from API root.',
    );
  }

  @override
  String get name => 'status';

  @override
  String get description => 'Check connection to the Obsidian REST API.';

  ObsidianApi get _api => (runner! as ObsCommandRunner).api;

  @override
  Future<int> run() async {
    try {
      final data = await _api.getStatus();

      if (argResults!['json'] == true) {
        // ignore: avoid_print
        print(_formatJson(data));
      } else {
        // ignore: avoid_print
        print('Connected to Obsidian REST API');
        final status = data['status'] as String?;
        final versions = data['versions'] as Map<String, dynamic>?;
        if (status != null) {
          // ignore: avoid_print
          print('  Status: $status');
        }
        if (versions != null) {
          final obsidian = versions['obsidian'] as String?;
          final plugin = versions['self'] as String?;
          if (obsidian != null) {
            // ignore: avoid_print
            print('  Obsidian: $obsidian');
          }
          if (plugin != null) {
            // ignore: avoid_print
            print('  Plugin: $plugin');
          }
        }
      }
      return 0;
    } catch (e) {
      stderr.writeln('Error: $e');
      return 1;
    }
  }

  String _formatJson(Map<String, dynamic> data) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }
}
