import 'package:args/command_runner.dart';

import 'search_dql_command.dart';
import 'search_jsonlogic_command.dart';
import 'search_text_command.dart';

/// Parent command for search operations.
///
/// ```
/// obs search text|dql|jsonlogic
/// ```
class SearchCommand extends Command<int> {
  SearchCommand() {
    addSubcommand(SearchTextCommand());
    addSubcommand(SearchDqlCommand());
    addSubcommand(SearchJsonLogicCommand());
  }

  @override
  String get name => 'search';

  @override
  String get description => 'Search across the vault.';
}
