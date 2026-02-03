import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Reads and writes the obscli config file at `~/.config/obscli/config.yaml`.
class ConfigStore {
  /// Creates a config store.
  ///
  /// [configDir] overrides the default `~/.config/obscli` location (for testing).
  ConfigStore({String? configDir})
      : configDir = configDir ?? _defaultConfigDir();

  /// Directory containing the config file.
  final String configDir;

  /// Path to the config file.
  String get configPath => p.join(configDir, 'config.yaml');

  /// Read all config values from disk.
  ///
  /// Returns an empty map if the file does not exist.
  Map<String, dynamic> readAll() {
    final file = File(configPath);
    if (!file.existsSync()) return <String, dynamic>{};

    final content = file.readAsStringSync();
    if (content.trim().isEmpty) return <String, dynamic>{};

    final yaml = loadYaml(content);
    if (yaml is! YamlMap) return <String, dynamic>{};

    return Map<String, dynamic>.from(yaml);
  }

  /// Read a single config value.
  String? read(String key) {
    final all = readAll();
    final value = all[key];
    return value?.toString();
  }

  /// Write a single config value.
  void write(String key, String value) {
    final all = readAll();
    all[key] = value;
    _writeAll(all);
  }

  /// Write all config values to disk.
  void _writeAll(Map<String, dynamic> values) {
    final dir = Directory(configDir);
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final buf = StringBuffer('# obscli configuration\n');
    for (final entry in values.entries) {
      buf.writeln('${entry.key}: "${entry.value}"');
    }
    File(configPath).writeAsStringSync(buf.toString());
  }

  static String _defaultConfigDir() {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
    return p.join(home, '.config', 'obscli');
  }
}
