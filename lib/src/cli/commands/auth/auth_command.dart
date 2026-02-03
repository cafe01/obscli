import 'package:args/command_runner.dart';

import 'auth_setup_command.dart';
import 'auth_status_command.dart';

/// Parent command for authentication.
///
/// ```
/// obs auth setup|status
/// ```
class AuthCommand extends Command<int> {
  AuthCommand() {
    addSubcommand(AuthSetupCommand());
    addSubcommand(AuthStatusCommand());
  }

  @override
  String get name => 'auth';

  @override
  String get description => 'Manage API key authentication.';
}
