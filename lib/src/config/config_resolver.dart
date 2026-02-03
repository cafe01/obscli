import 'dart:io';

import 'config_store.dart';

/// Resolves configuration values with priority:
/// CLI flag > environment variable > config file > default.
class ConfigResolver {
  /// Creates a resolver.
  ///
  /// [flagHost] and [flagApiKey] are from CLI flags.
  /// [store] is the config file backend.
  ConfigResolver({
    this.flagHost,
    this.flagApiKey,
    ConfigStore? store,
  }) : _store = store ?? ConfigStore();

  /// Host from `--host` flag (highest priority).
  final String? flagHost;

  /// API key from `--api-key` flag (highest priority).
  final String? flagApiKey;

  final ConfigStore _store;

  /// Default Obsidian REST API host.
  static const defaultHost = 'https://127.0.0.1:27124';

  /// Resolved host: flag > env > config > default.
  String get host {
    return flagHost ??
        Platform.environment['OBS_HOST'] ??
        _store.read('host') ??
        defaultHost;
  }

  /// Resolved API key: flag > env > config > null.
  String? get apiKey {
    return flagApiKey ??
        Platform.environment['OBS_API_KEY'] ??
        _store.read('api-key');
  }
}
