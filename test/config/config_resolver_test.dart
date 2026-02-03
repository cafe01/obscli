import 'dart:io';

import 'package:test/test.dart';
import 'package:obscli/src/config/config_resolver.dart';
import 'package:obscli/src/config/config_store.dart';

void main() {
  late Directory tempDir;
  late ConfigStore store;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('obscli_test_');
    store = ConfigStore(configDir: tempDir.path);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('ConfigResolver', () {
    test('uses default host when no config', () {
      final resolver = ConfigResolver(store: store);

      expect(resolver.host, ConfigResolver.defaultHost);
    });

    test('uses config file value when set', () {
      store.write('host', 'https://custom.com');
      final resolver = ConfigResolver(store: store);

      expect(resolver.host, 'https://custom.com');
    });

    test('CLI flag overrides config file', () {
      store.write('host', 'https://config.com');
      final resolver = ConfigResolver(
        flagHost: 'https://flag.com',
        store: store,
      );

      expect(resolver.host, 'https://flag.com');
    });

    test('apiKey returns null when not configured', () {
      final resolver = ConfigResolver(store: store);

      expect(resolver.apiKey, isNull);
    });

    test('apiKey reads from config file', () {
      store.write('api-key', 'secret123');
      final resolver = ConfigResolver(store: store);

      expect(resolver.apiKey, 'secret123');
    });

    test('CLI flag overrides config for apiKey', () {
      store.write('api-key', 'config-key');
      final resolver = ConfigResolver(
        flagApiKey: 'flag-key',
        store: store,
      );

      expect(resolver.apiKey, 'flag-key');
    });

    test('resolution priority: flag > env > config > default', () {
      // This test verifies the documented priority order
      // Note: Testing env vars would require mocking Platform.environment
      store.write('host', 'config-host');

      // With config only
      var resolver = ConfigResolver(store: store);
      expect(resolver.host, 'config-host');

      // With flag (overrides config)
      resolver = ConfigResolver(
        flagHost: 'flag-host',
        store: store,
      );
      expect(resolver.host, 'flag-host');

      // With no config (falls back to default)
      final emptyStore = ConfigStore(configDir: tempDir.path + '/empty');
      resolver = ConfigResolver(store: emptyStore);
      expect(resolver.host, ConfigResolver.defaultHost);
    });
  });
}
