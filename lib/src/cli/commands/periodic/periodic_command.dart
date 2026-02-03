import 'package:args/command_runner.dart';

import 'periodic_append_command.dart';
import 'periodic_create_command.dart';
import 'periodic_delete_command.dart';
import 'periodic_patch_command.dart';
import 'periodic_read_command.dart';

/// Parent command for periodic note operations.
///
/// ```
/// obs periodic read|create|append|patch|delete
/// ```
class PeriodicCommand extends Command<int> {
  PeriodicCommand() {
    addSubcommand(PeriodicReadCommand());
    addSubcommand(PeriodicCreateCommand());
    addSubcommand(PeriodicAppendCommand());
    addSubcommand(PeriodicPatchCommand());
    addSubcommand(PeriodicDeleteCommand());
  }

  @override
  String get name => 'periodic';

  @override
  String get description => 'Read and manage periodic notes (daily, weekly, etc).';
}
