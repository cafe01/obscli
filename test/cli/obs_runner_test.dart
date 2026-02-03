import 'package:test/test.dart';
import 'package:obscli/src/cli/obs_runner.dart';

void main() {
  late ObsCommandRunner runner;

  setUp(() {
    runner = ObsCommandRunner();
  });

  group('ObsCommandRunner', () {
    test('has correct name', () {
      expect(runner.executableName, 'obs');
    });

    test('has description', () {
      expect(runner.description, isNotEmpty);
    });

    group('top-level commands', () {
      test('registers note command', () {
        expect(_findCommand(runner, 'note'), isNotNull);
      });

      test('registers active command', () {
        expect(_findCommand(runner, 'active'), isNotNull);
      });

      test('registers periodic command', () {
        expect(_findCommand(runner, 'periodic'), isNotNull);
      });

      test('registers search command', () {
        expect(_findCommand(runner, 'search'), isNotNull);
      });

      test('registers command command', () {
        expect(_findCommand(runner, 'command'), isNotNull);
      });

      test('registers auth command', () {
        expect(_findCommand(runner, 'auth'), isNotNull);
      });

      test('registers config command', () {
        expect(_findCommand(runner, 'config'), isNotNull);
      });

      test('registers status command', () {
        expect(_findCommand(runner, 'status'), isNotNull);
      });

      test('registers api command', () {
        expect(_findCommand(runner, 'api'), isNotNull);
      });
    });

    group('note subcommands', () {
      final expectedSubcommands = [
        'read',
        'list',
        'create',
        'append',
        'patch',
        'delete',
        'open',
      ];

      for (final sub in expectedSubcommands) {
        test('has $sub subcommand', () {
          final note = _findCommand(runner, 'note')!;
          expect(note.subcommands.containsKey(sub), isTrue);
        });
      }
    });

    group('active subcommands', () {
      for (final sub in ['read', 'replace', 'append', 'patch', 'delete']) {
        test('has $sub subcommand', () {
          final active = _findCommand(runner, 'active')!;
          expect(active.subcommands.containsKey(sub), isTrue);
        });
      }
    });

    group('periodic subcommands', () {
      for (final sub in ['read', 'create', 'append', 'patch', 'delete']) {
        test('has $sub subcommand', () {
          final periodic = _findCommand(runner, 'periodic')!;
          expect(periodic.subcommands.containsKey(sub), isTrue);
        });
      }
    });

    group('search subcommands', () {
      for (final sub in ['text', 'dql', 'jsonlogic']) {
        test('has $sub subcommand', () {
          final search = _findCommand(runner, 'search')!;
          expect(search.subcommands.containsKey(sub), isTrue);
        });
      }
    });

    group('command subcommands', () {
      for (final sub in ['list', 'exec']) {
        test('has $sub subcommand', () {
          final command = _findCommand(runner, 'command')!;
          expect(command.subcommands.containsKey(sub), isTrue);
        });
      }
    });

    group('auth subcommands', () {
      for (final sub in ['setup', 'status']) {
        test('has $sub subcommand', () {
          final auth = _findCommand(runner, 'auth')!;
          expect(auth.subcommands.containsKey(sub), isTrue);
        });
      }
    });

    group('config subcommands', () {
      for (final sub in ['get', 'set', 'list']) {
        test('has $sub subcommand', () {
          final config = _findCommand(runner, 'config')!;
          expect(config.subcommands.containsKey(sub), isTrue);
        });
      }
    });

    group('global flags', () {
      test('accepts --version', () {
        expect(runner.argParser.options.containsKey('version'), isTrue);
      });

      test('accepts --json', () {
        expect(runner.argParser.options.containsKey('json'), isTrue);
      });

      test('accepts --no-color', () {
        expect(runner.argParser.options.containsKey('no-color'), isTrue);
      });

      test('accepts --verbose', () {
        expect(runner.argParser.options.containsKey('verbose'), isTrue);
      });

      test('accepts --host', () {
        expect(runner.argParser.options.containsKey('host'), isTrue);
      });

      test('accepts --api-key', () {
        expect(runner.argParser.options.containsKey('api-key'), isTrue);
      });
    });
  });
}

dynamic _findCommand(ObsCommandRunner runner, String name) {
  return runner.commands[name];
}
