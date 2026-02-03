import 'dart:io';

import 'package:args/command_runner.dart';

import '../../../config/config_store.dart';
import '../../format.dart';

/// Set a configuration value.
///
/// ```
/// obs config set <key> <value>
/// ```
class ConfigSetCommand extends Command<int> {
  @override
  String get name => 'set';

  @override
  String get description => 'Set a configuration value.';

  @override
  String get invocation => 'obs config set <key> <value>';

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.length < 2) {
      stderr.writeln('Usage: obs config set <key> <value>');
      return 64;
    }

    final key = args[0];
    final value = args[1];
    final store = ConfigStore();
    store.write(key, value);

    // ignore: avoid_print
    print(green('Set $key = $value'));
    return 0;
  }
}
