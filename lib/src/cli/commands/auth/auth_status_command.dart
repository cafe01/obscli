import 'dart:convert';

import 'package:args/command_runner.dart';

import '../../../api/obsidian_api.dart';
import '../../../config/config_store.dart';
import '../../format.dart';
import '../../obs_runner.dart';

/// Show current authentication and connection status.
///
/// ```
/// obs auth status [--json]
/// ```
class AuthStatusCommand extends Command<int> {
  AuthStatusCommand() {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output in JSON format.',
    );
  }

  @override
  String get name => 'status';

  @override
  String get description => 'Show authentication and connection status.';

  ObsidianApi get _api => (runner! as ObsCommandRunner).api;

  @override
  Future<int> run() async {
    final store = ConfigStore();
    final config = store.readAll();
    final host = config['host'] as String? ?? '(not set)';
    final apiKey = config['api-key'] as String?;
    final hasKey = apiKey != null && apiKey.isNotEmpty;

    if (argResults!['json'] == true) {
      final data = <String, dynamic>{
        'host': host,
        'api_key_configured': hasKey,
        'config_path': store.configPath,
      };

      try {
        final status = await _api.getStatus();
        data['connected'] = true;
        data['server_status'] = status;
      } catch (e) {
        data['connected'] = false;
        data['error'] = e.toString();
      }

      const encoder = JsonEncoder.withIndent('  ');
      // ignore: avoid_print
      print(encoder.convert(data));
      return 0;
    }

    // Human-readable output
    // ignore: avoid_print
    print(bold('Authentication Status'));
    // ignore: avoid_print
    print('');
    // ignore: avoid_print
    print('  Host:    $host');
    // ignore: avoid_print
    print('  API Key: ${hasKey ? green('configured') : yellow('not set')}');
    // ignore: avoid_print
    print('');
    // ignore: avoid_print
    print('  Config:  ${dim(store.configPath)}');
    // ignore: avoid_print
    print('');

    // Test connection
    // ignore: avoid_print
    print('Testing connection...');
    try {
      final status = await _api.getStatus();
      // ignore: avoid_print
      print(green('Connected successfully!'));
      final serverStatus = status['status'] as String?;
      if (serverStatus != null) {
        // ignore: avoid_print
        print('  Server status: $serverStatus');
      }
      return 0;
    } catch (e) {
      // ignore: avoid_print
      print(red('Connection failed: $e'));
      // ignore: avoid_print
      print('');
      // ignore: avoid_print
      print('Run ${cyan('obs auth setup')} to configure authentication.');
      return 1;
    }
  }
}
