import 'package:args/command_runner.dart';

import 'note_append_command.dart';
import 'note_create_command.dart';
import 'note_delete_command.dart';
import 'note_list_command.dart';
import 'note_open_command.dart';
import 'note_patch_command.dart';
import 'note_read_command.dart';

/// Parent command for vault note operations.
///
/// ```
/// obs note read|list|create|append|patch|delete|open
/// ```
class NoteCommand extends Command<int> {
  NoteCommand() {
    addSubcommand(NoteReadCommand());
    addSubcommand(NoteListCommand());
    addSubcommand(NoteCreateCommand());
    addSubcommand(NoteAppendCommand());
    addSubcommand(NotePatchCommand());
    addSubcommand(NoteDeleteCommand());
    addSubcommand(NoteOpenCommand());
  }

  @override
  String get name => 'note';

  @override
  String get description => 'Read, create, and manage vault notes.';
}
