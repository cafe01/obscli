import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:http/http.dart' as http;

import '../../../api/http_obsidian_api.dart';
import '../../../config/config_resolver.dart';
import '../../../config/config_store.dart';
import '../../format.dart';

/// Interactive setup wizard for API key authentication.
///
/// ```
/// obs auth setup
/// ```
class AuthSetupCommand extends Command<int> {
  @override
  String get name => 'setup';

  @override
  String get description =>
      'Interactive setup wizard for API key and host configuration.';

  @override
  Future<int> run() async {
    final store = ConfigStore();

    // ignore: avoid_print
    print(bold('Obsidian CLI Setup'));
    // ignore: avoid_print
    print('');

    // Prompt for host
    stdout.write('Enter Obsidian REST API host '
        '[${ConfigResolver.defaultHost}]: ');
    final hostInput = stdin.readLineSync() ?? '';
    final host = hostInput.trim().isEmpty
        ? ConfigResolver.defaultHost
        : hostInput.trim();

    // Prompt for API key
    stdout.write('Enter API key: ');
    final apiKey = stdin.readLineSync() ?? '';
    if (apiKey.trim().isEmpty) {
      stderr.writeln(red('Error: API key cannot be empty'));
      return 1;
    }

    // ignore: avoid_print
    print('');
    // ignore: avoid_print
    print('Testing connection...');

    // Test the configuration
    final resolver = ConfigResolver(
      flagHost: host,
      flagApiKey: apiKey.trim(),
      store: store,
    );
    final api = HttpObsidianApi(
      client: http.Client(),
      config: resolver,
    );

    try {
      final status = await api.getStatus();
      // ignore: avoid_print
      print(green('Connection successful!'));
      final serverStatus = status['status'] as String?;
      if (serverStatus != null) {
        // ignore: avoid_print
        print('  Server status: $serverStatus');
      }
    } catch (e) {
      stderr.writeln(red('Connection failed: $e'));
      stderr.writeln('');
      stderr.writeln('Please check:');
      stderr.writeln('  - Obsidian is running');
      stderr.writeln('  - Local REST API plugin is enabled');
      stderr.writeln('  - Host URL is correct');
      stderr.writeln('  - API key is valid');
      return 1;
    }

    // Save configuration
    store.write('host', host);
    store.write('api-key', apiKey.trim());

    // ignore: avoid_print
    print('');
    // ignore: avoid_print
    print(green('Configuration saved to ${store.configPath}'));
    return 0;
  }
}
