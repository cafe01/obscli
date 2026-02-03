import 'package:args/command_runner.dart';

import '../../../config/config_store.dart';
import '../../format.dart';

/// List all configuration values.
///
/// ```
/// obs config list
/// ```
class ConfigListCommand extends Command<int> {
  @override
  String get name => 'list';

  @override
  String get description => 'List all configuration values.';

  @override
  Future<int> run() async {
    final store = ConfigStore();
    final config = store.readAll();

    if (config.isEmpty) {
      // ignore: avoid_print
      print(dim('No configuration set.'));
      // ignore: avoid_print
      print('');
      // ignore: avoid_print
      print('Run ${cyan('obs auth setup')} to configure authentication.');
      return 0;
    }

    // ignore: avoid_print
    print(bold('Configuration'));
    // ignore: avoid_print
    print('');
    for (final entry in config.entries) {
      // Mask API key value for security
      final value = entry.key == 'api-key' && entry.value.toString().length > 8
          ? '${entry.value.toString().substring(0, 8)}...'
          : entry.value;
      // ignore: avoid_print
      print('  ${cyan(entry.key)}: $value');
    }
    // ignore: avoid_print
    print('');
    // ignore: avoid_print
    print(dim('Config file: ${store.configPath}'));
    return 0;
  }
}
