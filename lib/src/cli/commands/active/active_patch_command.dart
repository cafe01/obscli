import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../../../api/obsidian_api.dart';
import '../../format.dart';
import '../../obs_runner.dart';

/// Modify a section of the active file.
///
/// ```
/// obs active patch [--heading <text>] [--block <id>] [--frontmatter]
///     [--insert-position beginning|end] [--content <text>] [--json]
/// ```
class ActivePatchCommand extends Command<int> {
  ActivePatchCommand() {
    argParser
      ..addFlag(
        'json',
        negatable: false,
        help: 'Output in JSON format.',
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
  String get description => 'Modify a section of the active file.';

  ObsidianApi get _api => (runner! as ObsCommandRunner).api;

  @override
  Future<int> run() async {
    final content = argResults!['content'] as String? ?? _readStdin();
    final heading = argResults!['heading'] as String?;
    final block = argResults!['block'] as String?;
    final frontmatter = argResults!['frontmatter'] as bool? ?? false;
    final insertPosition = argResults!['insert-position'] as String?;
    final useJson = argResults!['json'] as bool? ?? false;

    try {
      await _api.patchActiveFile(
        content,
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
                    : 'file';
        // ignore: avoid_print
        print(encoder.convert(<String, dynamic>{
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
        // ignore: avoid_print
        print(green('Patched active file$targetStr'));
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
