import 'package:mocktail/mocktail.dart';
import 'package:obscli/src/api/obsidian_api.dart';

/// Mocktail mock of [ObsidianApi] for use in command tests.
class MockObsidianApi extends Mock implements ObsidianApi {}
