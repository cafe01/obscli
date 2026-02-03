import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../api/http_obsidian_api.dart';
import '../api/obsidian_api.dart';
import '../config/config_resolver.dart';
import '../config/config_store.dart';
import 'commands/active/active_command.dart';
import 'commands/api/api_command.dart';
import 'commands/auth/auth_command.dart';
import 'commands/command/command_command.dart';
import 'commands/config/config_command.dart';
import 'commands/note/note_command.dart';
import 'commands/periodic/periodic_command.dart';
import 'commands/search/search_command.dart';
import 'commands/status_command.dart';
import 'format.dart';

/// Top-level command runner for the Obsidian CLI.
///
/// Mirrors the Obsidian REST API as CLI subcommands.
/// Think `gh` for GitHub, but for your Obsidian vault.
///
/// ```
/// obs <command> [subcommand] [flags]
/// ```
class ObsCommandRunner extends CommandRunner<int> {
  /// Creates the runner, optionally injecting an [ObsidianApi] for testing.
  ObsCommandRunner({ObsidianApi? api})
      : _injectedApi = api,
        super(
          'obs',
          'Obsidian CLI -- interact with your Obsidian vault from the '
              'command line.',
        ) {
    // Vault operations
    addCommand(NoteCommand());
    addCommand(ActiveCommand());
    addCommand(PeriodicCommand());

    // Query operations
    addCommand(SearchCommand());
    addCommand(ObsidianCommandCommand());

    // Plumbing
    addCommand(AuthCommand());
    addCommand(ConfigCommand());
    addCommand(ApiCommand());
    addCommand(StatusCommand());

    // Global flags
    argParser
      ..addFlag(
        'version',
        negatable: false,
        help: 'Print the obs CLI version.',
      )
      ..addFlag(
        'json',
        negatable: false,
        help: 'Output in JSON format.',
      )
      ..addFlag(
        'no-color',
        negatable: false,
        help: 'Disable colored output.',
      )
      ..addFlag(
        'verbose',
        negatable: false,
        help: 'Enable verbose/debug output.',
      )
      ..addOption(
        'host',
        help: 'Obsidian REST API host URL.',
        valueHelp: 'url',
      )
      ..addOption(
        'api-key',
        help: 'Bearer token for authentication.',
        valueHelp: 'key',
      );
  }

  final ObsidianApi? _injectedApi;
  ObsidianApi? _defaultApi;
  ArgResults? _globalResults;

  /// The Obsidian API backend.
  ///
  /// Uses the injected API if provided; otherwise lazily constructs an
  /// [HttpObsidianApi] with config resolution.
  ObsidianApi get api {
    if (_injectedApi != null) return _injectedApi;
    return _defaultApi ??= _buildDefaultApi();
  }

  ObsidianApi _buildDefaultApi() {
    final store = ConfigStore();
    final resolver = ConfigResolver(
      flagHost: _globalResults?['host'] as String?,
      flagApiKey: _globalResults?['api-key'] as String?,
      store: store,
    );
    return HttpObsidianApi(client: _createHttpClient(), config: resolver);
  }

  /// Creates an HTTP client that allows self-signed certificates for localhost.
  http.Client _createHttpClient() {
    final ioClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) {
        // Allow self-signed certificates for localhost/127.0.0.1
        return host == 'localhost' || host == '127.0.0.1';
      };
    return IOClient(ioClient);
  }

  @override
  Future<int?> run(Iterable<String> args) async {
    try {
      _globalResults = parse(args);
      final results = _globalResults!;

      // Respect --no-color flag and NO_COLOR env var (https://no-color.org).
      final noColorFlag = results['no-color'] as bool? ?? false;
      final noColorEnv = Platform.environment.containsKey('NO_COLOR');
      colorEnabled = !noColorFlag && !noColorEnv;

      if (results['version'] == true) {
        // ignore: avoid_print
        print('obs version 0.1.0');
        return 0;
      }

      return await super.run(args);
    } on UsageException catch (e) {
      // ignore: avoid_print
      print(e.message);
      // ignore: avoid_print
      print('');
      // ignore: avoid_print
      print(e.usage);
      return 64;
    }
  }
}
