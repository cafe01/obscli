import 'package:args/command_runner.dart';

import 'command_exec_command.dart';
import 'command_list_command.dart';

/// Parent command for Obsidian command operations.
///
/// ```
/// obs command list|exec
/// ```
class ObsidianCommandCommand extends Command<int> {
  ObsidianCommandCommand() {
    addSubcommand(CommandListCommand());
    addSubcommand(CommandExecCommand());
  }

  @override
  String get name => 'command';

  @override
  String get description => 'List and execute Obsidian commands.';
}
