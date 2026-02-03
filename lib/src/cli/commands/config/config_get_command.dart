import 'dart:io';

import 'package:args/command_runner.dart';

import '../../../config/config_store.dart';

/// Get a configuration value.
///
/// ```
/// obs config get <key>
/// ```
class ConfigGetCommand extends Command<int> {
  @override
  String get name => 'get';

  @override
  String get description => 'Get a configuration value.';

  @override
  String get invocation => 'obs config get <key>';

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.isEmpty) {
      stderr.writeln('Usage: obs config get <key>');
      return 64;
    }

    final key = args.first;
    final store = ConfigStore();
    final value = store.read(key);

    if (value == null) {
      stderr.writeln('Config key "$key" not set');
      return 1;
    }

    // ignore: avoid_print
    print(value);
    return 0;
  }
}
