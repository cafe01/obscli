import 'package:args/command_runner.dart';

import 'active_append_command.dart';
import 'active_delete_command.dart';
import 'active_patch_command.dart';
import 'active_read_command.dart';
import 'active_replace_command.dart';

/// Parent command for active file operations.
///
/// ```
/// obs active read|replace|append|patch|delete
/// ```
class ActiveCommand extends Command<int> {
  ActiveCommand() {
    addSubcommand(ActiveReadCommand());
    addSubcommand(ActiveReplaceCommand());
    addSubcommand(ActiveAppendCommand());
    addSubcommand(ActivePatchCommand());
    addSubcommand(ActiveDeleteCommand());
  }

  @override
  String get name => 'active';

  @override
  String get description => 'Operate on the currently active file in Obsidian.';
}
