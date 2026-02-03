import 'dart:io';

import 'package:test/test.dart';
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

  group('ConfigStore', () {
    test('reads empty map when config file does not exist', () {
      final config = store.readAll();
      expect(config, isEmpty);
    });

    test('writes and reads config values', () {
      store.write('host', 'https://example.com');
      store.write('api-key', 'secret123');

      final config = store.readAll();
      expect(config['host'], 'https://example.com');
      expect(config['api-key'], 'secret123');
    });

    test('read returns single value', () {
      store.write('host', 'https://example.com');

      expect(store.read('host'), 'https://example.com');
      expect(store.read('missing'), isNull);
    });

    test('overwrites existing values', () {
      store.write('host', 'old-value');
      store.write('host', 'new-value');

      expect(store.read('host'), 'new-value');
    });

    test('creates config directory if missing', () {
      final nestedDir = Directory('${tempDir.path}/nested/path');
      final nestedStore = ConfigStore(configDir: nestedDir.path);

      nestedStore.write('test', 'value');

      expect(nestedDir.existsSync(), isTrue);
      expect(nestedStore.read('test'), 'value');

      nestedDir.deleteSync(recursive: true);
    });

    test('handles empty config file', () {
      File(store.configPath).writeAsStringSync('');

      final config = store.readAll();
      expect(config, isEmpty);
    });

    test('handles YAML comment in config file', () {
      store.write('host', 'test');

      final content = File(store.configPath).readAsStringSync();
      expect(content, contains('# obscli configuration'));
    });

    test('preserves multiple config values', () {
      store.write('host', 'value1');
      store.write('api-key', 'value2');
      store.write('no-color', 'true');

      final config = store.readAll();
      expect(config.length, 3);
      expect(config['host'], 'value1');
      expect(config['api-key'], 'value2');
      expect(config['no-color'], 'true');
    });
  });
}
